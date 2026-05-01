import Foundation

/// Fetches live or near-live stall availability.
/// Tries supercharge.info first; falls back to cached data gracefully.
public struct AvailabilityClient {
    public let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    /// Fetch availability for a specific site. Returns nil if unavailable.
    public func fetchAvailability(siteId: String, stallCount: Int) async -> StallAvailability? {
        if let result = await fetchFromSuperchargeInfo(siteId: siteId, stallCount: stallCount) {
            return result
        }
        // Return a sentinel with availableStalls == -1 so UI shows "availability unknown"
        return StallAvailability(
            superchargerId: siteId,
            totalStalls: stallCount,
            availableStalls: -1,
            occupiedStalls: 0,
            offlineStalls: 0,
            source: .cached
        )
    }

    // MARK: - Private

    private func fetchFromSuperchargeInfo(siteId: String, stallCount: Int) async -> StallAvailability? {
        guard let url = URL(string: "https://supercharge.info/service/supercharger/status?siteId=\(siteId)") else {
            return nil
        }
        do {
            let (data, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }
            return parseStatus(data: data, siteId: siteId, stallCount: stallCount)
        } catch {
            return nil
        }
    }

    private func parseStatus(data: Data, siteId: String, stallCount: Int) -> StallAvailability? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }

        // supercharge.info status response: { "availableStalls": N, "totalStalls": N, ... }
        let available = (json["availableStalls"] as? Int) ?? -1
        let total = (json["totalStalls"] as? Int) ?? stallCount
        let occupied = (json["occupiedStalls"] as? Int) ?? (available >= 0 ? max(0, total - available) : 0)
        let offline = (json["offlineStalls"] as? Int) ?? 0

        return StallAvailability(
            superchargerId: siteId,
            totalStalls: total,
            availableStalls: available,
            occupiedStalls: occupied,
            offlineStalls: offline,
            source: .teslaFindUs
        )
    }
}
