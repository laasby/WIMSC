import Foundation
import CoreLocation

@Observable
@MainActor
public final class LiveAvailabilityStore {
    public var availability: [String: TeslaFleetSiteAvailability] = [:]
    public var lastRefreshed: Date?

    /// Set by the main app to supply a fresh access token on demand.
    public var tokenProvider: (@Sendable () async throws -> String)?

    private let client = TeslaFleetAvailabilityClient()

    public init() {}

    public func refresh(latitude: Double, longitude: Double, allSites: [Supercharger]) async {
        guard let tokenProvider else { return }
        do {
            let token = try await tokenProvider()
            let results = try await client.fetchNearby(
                latitude: latitude, longitude: longitude, accessToken: token
            )
            var updated: [String: TeslaFleetSiteAvailability] = [:]
            for site in results {
                if let matched = closestSupercharger(to: site, in: allSites, withinMeters: 200) {
                    updated[matched.id] = site
                }
            }
            availability.merge(updated) { _, new in new }
            lastRefreshed = .now
        } catch {
            // silently swallow — live data is best-effort
        }
    }

    public func availabilityFor(_ supercharger: Supercharger) -> TeslaFleetSiteAvailability? {
        availability[supercharger.id]
    }

    private func closestSupercharger(to site: TeslaFleetSiteAvailability,
                                      in list: [Supercharger],
                                      withinMeters threshold: Double) -> Supercharger? {
        let siteLocation = CLLocation(latitude: site.latitude, longitude: site.longitude)
        return list
            .map { sc in (sc, CLLocation(latitude: sc.latitude, longitude: sc.longitude).distance(from: siteLocation)) }
            .filter { $0.1 <= threshold }
            .min(by: { $0.1 < $1.1 })
            .map { $0.0 }
    }
}
