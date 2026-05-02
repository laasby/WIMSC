import Foundation
import Observation

/// Observable store for live Supercharger availability fetched from the Tesla Fleet API.
/// Inject via environment; views that read `sites` automatically re-render on updates.
@Observable
@MainActor
public final class LiveAvailabilityStore {

    public private(set) var sites: [TeslaChargerSite] = []
    public private(set) var isFetching: Bool = false
    public private(set) var lastError: String?

    private let client = TeslaFleetAvailabilityClient()
    private var lastFetchCenter: (lat: Double, lng: Double)?
    private var lastFetchTime: Date?
    private let staleSeconds: TimeInterval = 60
    private let locationTolerance: Double = 0.1 // ~10 km

    public init() {}

    /// Refreshes live availability for sites near the given coordinate.
    /// Skips the network call if the data is still fresh and the location hasn't changed much.
    public func refresh(
        latitude: Double,
        longitude: Double,
        tokenProvider: @escaping @Sendable () async throws -> String
    ) async {
        if let lastTime = lastFetchTime,
           lastTime.timeIntervalSinceNow > -staleSeconds,
           let center = lastFetchCenter,
           abs(center.lat - latitude) < locationTolerance,
           abs(center.lng - longitude) < locationTolerance {
            return
        }

        isFetching = true
        lastError = nil
        defer { isFetching = false }

        do {
            let token = try await tokenProvider()
            let fetched = try await client.fetchNearby(
                latitude: latitude,
                longitude: longitude,
                accessToken: token
            )
            sites = fetched
            lastFetchCenter = (latitude, longitude)
            lastFetchTime = .now
        } catch {
            lastError = error.localizedDescription
        }
    }

    /// Returns the best-matching live site for the given coordinates, or nil if none within 500 m.
    public func availability(forLatitude lat: Double, longitude lng: Double) -> TeslaChargerSite? {
        guard let closest = sites.min(by: {
            haversineKm($0.latitude, $0.longitude, lat, lng) <
            haversineKm($1.latitude, $1.longitude, lat, lng)
        }) else { return nil }
        return haversineKm(closest.latitude, closest.longitude, lat, lng) < 0.5 ? closest : nil
    }

    private func haversineKm(_ lat1: Double, _ lng1: Double, _ lat2: Double, _ lng2: Double) -> Double {
        let dlat = lat1 - lat2
        let dlng = (lng1 - lng2) * cos(lat1 * .pi / 180)
        return sqrt(dlat * dlat + dlng * dlng) * 111.0
    }
}
