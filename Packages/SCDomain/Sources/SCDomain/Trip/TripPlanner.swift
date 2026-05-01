import Foundation
import MapKit
import SCData

/// Plans a route between two points and identifies Supercharger stops.
public struct TripPlan {
    public var origin: CLLocationCoordinate2D
    public var destination: CLLocationCoordinate2D
    public var routePolyline: MKPolyline?
    public var totalDistanceKm: Double
    public var estimatedDrivingMinutes: Int
    public var superchargersNearRoute: [SuperchargerOnRoute]
    public var recommendedStops: [SuperchargerOnRoute]
    public var warnings: [String]
}

public struct SuperchargerOnRoute: Identifiable {
    public var id: String { supercharger.id }
    public var supercharger: Supercharger
    public var deviationKm: Double
    public var distanceFromOriginKm: Double
    public var recommendedChargeToSoc: Int
    public var estimatedChargeMinutes: Int
}

@Observable
public final class TripPlanner {
    public var origin: String = ""
    public var destination: String = ""
    public var startingSoc: Int = 80
    public var targetArrivalSoc: Int = 10
    public var corridorWidthKm: Double = 10
    public var minimumKilowatts: Int = 0
    public var vehicle: UserVehicle?

    public private(set) var currentPlan: TripPlan?
    public private(set) var isPlanning: Bool = false
    public private(set) var error: String?

    private let allSuperchargers: [Supercharger]

    public init(superchargers: [Supercharger]) {
        self.allSuperchargers = superchargers
    }

    /// Geocode origin + destination, fetch route, find Superchargers along corridor, compute stops.
    public func plan(ambientCelsius: Double = 15) async {
        guard !origin.isEmpty, !destination.isEmpty else { return }
        isPlanning = true
        error = nil
        defer { isPlanning = false }

        do {
            let originCoord = try await geocode(origin)
            let destCoord = try await geocode(destination)
            let route = try await fetchRoute(from: originCoord, to: destCoord)

            let totalDistanceKm = route.distance / 1000.0
            let drivingMinutes = Int(route.expectedTravelTime / 60.0)

            let nearby = superchargersNear(route: route, withinKm: corridorWidthKm, minKw: minimumKilowatts)
            let recommended = recommendStops(
                along: nearby,
                vehicle: vehicle,
                startSoc: startingSoc,
                targetArrivalSoc: targetArrivalSoc,
                totalKm: totalDistanceKm,
                ambientCelsius: ambientCelsius
            )

            var warnings: [String] = []
            if vehicle == nil {
                warnings.append("No vehicle selected — using default range estimates")
            }
            if recommended.isEmpty && !nearby.isEmpty {
                warnings.append("Route may be out of range without stopping")
            }

            currentPlan = TripPlan(
                origin: originCoord,
                destination: destCoord,
                routePolyline: route.polyline,
                totalDistanceKm: totalDistanceKm,
                estimatedDrivingMinutes: drivingMinutes,
                superchargersNearRoute: nearby,
                recommendedStops: recommended,
                warnings: warnings
            )
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func geocode(_ address: String) async throws -> CLLocationCoordinate2D {
        try await withCheckedThrowingContinuation { continuation in
            CLGeocoder().geocodeAddressString(address) { placemarks, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let coord = placemarks?.first?.location?.coordinate {
                    continuation.resume(returning: coord)
                } else {
                    continuation.resume(throwing: URLError(.cannotFindHost))
                }
            }
        }
    }

    private func fetchRoute(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) async throws -> MKRoute {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: from))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: to))
        request.transportType = .automobile
        let directions = MKDirections(request: request)
        let response = try await directions.calculate()
        guard let route = response.routes.first else {
            throw URLError(.cannotFindHost)
        }
        return route
    }

    private func superchargersNear(route: MKRoute, withinKm: Double, minKw: Int) -> [SuperchargerOnRoute] {
        let polyline = route.polyline
        let totalDistanceKm = route.distance / 1000.0
        let pointCount = polyline.pointCount
        guard pointCount > 0 else { return [] }

        let rawPoints = polyline.points()
        let buffer = UnsafeBufferPointer(start: rawPoints, count: pointCount)

        // Accumulate cumulative distance along polyline for each point
        var cumulative = [Double](repeating: 0, count: pointCount)
        for i in 1..<pointCount {
            cumulative[i] = cumulative[i - 1] + buffer[i - 1].distance(to: buffer[i])
        }
        let totalPolylineLength = cumulative.last ?? 1

        var result: [SuperchargerOnRoute] = []

        for sc in allSuperchargers {
            guard sc.status == .open else { continue }
            guard minKw == 0 || sc.maxKilowatts >= minKw else { continue }

            let scPoint = MKMapPoint(CLLocationCoordinate2D(latitude: sc.latitude, longitude: sc.longitude))

            var minDist = Double.infinity
            var closestIdx = 0
            for (i, pt) in buffer.enumerated() {
                let d = pt.distance(to: scPoint)
                if d < minDist {
                    minDist = d
                    closestIdx = i
                }
            }

            let deviationKm = minDist / 1000.0
            guard deviationKm <= withinKm else { continue }

            let distanceFromOriginKm = totalDistanceKm * (cumulative[closestIdx] / max(totalPolylineLength, 1))

            result.append(SuperchargerOnRoute(
                supercharger: sc,
                deviationKm: deviationKm,
                distanceFromOriginKm: distanceFromOriginKm,
                recommendedChargeToSoc: 80,
                estimatedChargeMinutes: 0
            ))
        }

        return result.sorted { $0.distanceFromOriginKm < $1.distanceFromOriginKm }
    }

    private func recommendStops(
        along candidates: [SuperchargerOnRoute],
        vehicle: UserVehicle?,
        startSoc: Int,
        targetArrivalSoc: Int,
        totalKm: Double,
        ambientCelsius: Double
    ) -> [SuperchargerOnRoute] {
        guard let vehicle else { return [] }

        let minSoc = vehicle.preferredMinArrivalSoc

        var currentSoc = startSoc
        var currentDistanceKm = 0.0
        var stops: [SuperchargerOnRoute] = []
        var remaining = candidates.filter { $0.distanceFromOriginKm > 0 }

        var iterations = 0
        while iterations < 50 {
            iterations += 1
            let distToDestination = totalKm - currentDistanceKm

            if RangeCalculator.canReach(
                vehicle: vehicle,
                currentSocPercent: currentSoc,
                distanceKm: distToDestination,
                arrivalSocPercent: targetArrivalSoc,
                ambientCelsius: ambientCelsius
            ) {
                break
            }

            // Find the furthest reachable charger from current position
            let reachable = remaining.filter { candidate in
                let segmentKm = candidate.distanceFromOriginKm - currentDistanceKm
                guard segmentKm > 0 else { return false }
                return RangeCalculator.canReach(
                    vehicle: vehicle,
                    currentSocPercent: currentSoc,
                    distanceKm: segmentKm,
                    arrivalSocPercent: minSoc,
                    ambientCelsius: ambientCelsius
                )
            }

            guard let bestStop = reachable.last else {
                // No reachable charger — trip may be infeasible
                break
            }

            let segmentKm = bestStop.distanceFromOriginKm - currentDistanceKm
            let arrivalSocAtStop = arrivalSoc(
                vehicle: vehicle,
                fromSoc: currentSoc,
                distanceKm: segmentKm,
                ambientCelsius: ambientCelsius
            )
            let chargeTo = 80
            let chargeMinutes = RangeCalculator.estimatedChargeMinutes(
                vehicle: vehicle,
                fromSoc: arrivalSocAtStop,
                toSoc: chargeTo,
                chargerGeneration: bestStop.supercharger.generation,
                ambientCelsius: ambientCelsius
            )

            var stop = bestStop
            stop.recommendedChargeToSoc = chargeTo
            stop.estimatedChargeMinutes = chargeMinutes
            stops.append(stop)

            currentSoc = chargeTo
            currentDistanceKm = bestStop.distanceFromOriginKm
            remaining = remaining.filter { $0.distanceFromOriginKm > currentDistanceKm }
        }

        return stops
    }

    /// Calculates approximate SoC after driving distanceKm from a given starting SoC.
    private func arrivalSoc(
        vehicle: UserVehicle,
        fromSoc: Int,
        distanceKm: Double,
        ambientCelsius: Double
    ) -> Int {
        let temperatureFactor: Double
        if ambientCelsius < 0 { temperatureFactor = 0.8 }
        else if ambientCelsius > 20 { temperatureFactor = 1.02 }
        else { temperatureFactor = 1.0 }

        let fullRangeKm = (vehicle.batteryCapacityKwh * 1000.0 / vehicle.efficiencyWhPerKm) * temperatureFactor
        let socConsumedPerKm = 100.0 / fullRangeKm
        let socConsumed = distanceKm * socConsumedPerKm
        return max(0, fromSoc - Int(socConsumed.rounded(.up)))
    }
}
