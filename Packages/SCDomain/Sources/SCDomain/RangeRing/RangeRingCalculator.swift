import Foundation
import MapKit
import SCData

/// Computes a reachability polygon from a centre point using MapKit isochrones (route-based).
/// Falls back to a circular approximation if isochrone calculation fails.
@Observable
public final class RangeRingCalculator {

    public private(set) var polygon: MKPolygon?
    public private(set) var isCalculating: Bool = false
    public private(set) var reachableSuperchargers: [Supercharger] = []
    public private(set) var justOutsideSuperchargers: [Supercharger] = []
    public private(set) var rangeKm: Double = 0

    public init() {}

    /// Calculate the range ring for a vehicle at a given location and SoC.
    /// - Parameters:
    ///   - centre: Current vehicle location
    ///   - vehicle: The selected vehicle (uses RangeCalculator)
    ///   - currentSoc: Current battery %
    ///   - ambientCelsius: Ambient temperature
    ///   - allSuperchargers: Full list to classify as in/outside ring
    public func calculate(
        centre: CLLocation,
        vehicle: UserVehicle?,
        currentSoc: Int,
        ambientCelsius: Double = 15,
        allSuperchargers: [Supercharger]
    ) async {
        isCalculating = true
        defer { isCalculating = false }

        let estimatedRange: Double
        if let vehicle {
            estimatedRange = RangeCalculator.rangeKm(
                vehicle: vehicle,
                currentSocPercent: currentSoc,
                ambientCelsius: ambientCelsius
            )
        } else {
            estimatedRange = Double(currentSoc) * 3.5
        }
        rangeKm = estimatedRange

        let centreCoord = centre.coordinate
        let rayCount = 16
        let bearingStep = 360.0 / Double(rayCount)

        // Shoot 16 rays concurrently to build an isochrone polygon.
        var results = [Int: CLLocationCoordinate2D]()

        await withTaskGroup(of: (Int, CLLocationCoordinate2D?).self) { group in
            for i in 0..<rayCount {
                let bearing = Double(i) * bearingStep
                let targetCoord = Self.coordinate(from: centreCoord, bearing: bearing, distanceKm: estimatedRange)

                group.addTask {
                    let request = MKDirections.Request()
                    request.source = MKMapItem(placemark: MKPlacemark(coordinate: centreCoord))
                    request.destination = MKMapItem(placemark: MKPlacemark(coordinate: targetCoord))
                    request.transportType = .automobile

                    do {
                        let directions = MKDirections(request: request)
                        let eta = try await directions.calculateETA()
                        let travelTimeHours = eta.expectedTravelTime / 3_600.0
                        let reachableKm = min(80.0 * travelTimeHours, estimatedRange)
                        let reachableCoord = Self.coordinate(from: centreCoord, bearing: bearing, distanceKm: reachableKm)
                        return (i, reachableCoord)
                    } catch {
                        return (i, nil)
                    }
                }
            }

            for await (index, coord) in group {
                if let coord {
                    results[index] = coord
                }
            }
        }

        // Build polygon: use isochrone if all rays succeeded, else circular fallback.
        let endpoints: [CLLocationCoordinate2D]
        if results.count == rayCount {
            endpoints = (0..<rayCount).compactMap { results[$0] }
        } else {
            endpoints = (0..<36).map { i in
                Self.coordinate(from: centreCoord, bearing: Double(i) * (360.0 / 36.0), distanceKm: estimatedRange)
            }
        }

        let newPolygon = MKPolygon(coordinates: endpoints, count: endpoints.count)
        polygon = newPolygon

        reachableSuperchargers = allSuperchargers.filter { sc in
            isInside(
                CLLocationCoordinate2D(latitude: sc.latitude, longitude: sc.longitude),
                polygon: newPolygon
            )
        }

        let bufferKm = estimatedRange * 1.2
        justOutsideSuperchargers = allSuperchargers.filter { sc in
            let coord = CLLocationCoordinate2D(latitude: sc.latitude, longitude: sc.longitude)
            guard !isInside(coord, polygon: newPolygon) else { return false }
            let distanceKm = centre.distance(from: CLLocation(latitude: sc.latitude, longitude: sc.longitude)) / 1_000.0
            return distanceKm <= bufferKm
        }
    }

    /// Clear the range ring.
    public func clear() {
        polygon = nil
        reachableSuperchargers = []
        justOutsideSuperchargers = []
        rangeKm = 0
    }

    // MARK: - Helpers

    private static func coordinate(
        from origin: CLLocationCoordinate2D,
        bearing: Double,
        distanceKm: Double
    ) -> CLLocationCoordinate2D {
        let R = 6_371.0
        let d = distanceKm / R
        let lat1 = origin.latitude * .pi / 180
        let lon1 = origin.longitude * .pi / 180
        let bearingRad = bearing * .pi / 180
        let lat2 = asin(sin(lat1) * cos(d) + cos(lat1) * sin(d) * cos(bearingRad))
        let lon2 = lon1 + atan2(sin(bearingRad) * sin(d) * cos(lat1), cos(d) - sin(lat1) * sin(lat2))
        return CLLocationCoordinate2D(latitude: lat2 * 180 / .pi, longitude: lon2 * 180 / .pi)
    }

    /// Ray-casting point-in-polygon test using MKMapPoint coordinates (reliable without rendering).
    private func isInside(_ coordinate: CLLocationCoordinate2D, polygon: MKPolygon) -> Bool {
        let testPoint = MKMapPoint(coordinate)
        let ptCount = polygon.pointCount
        let pts = polygon.points()
        var inside = false
        var j = ptCount - 1
        for i in 0..<ptCount {
            let pi = pts[i]
            let pj = pts[j]
            if ((pi.y > testPoint.y) != (pj.y > testPoint.y)) &&
                (testPoint.x < (pj.x - pi.x) * (testPoint.y - pi.y) / (pj.y - pi.y) + pi.x) {
                inside = !inside
            }
            j = i
        }
        return inside
    }
}
