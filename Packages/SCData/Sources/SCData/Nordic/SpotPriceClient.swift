import Foundation

/// Fetches NO1–NO5 spot electricity prices.
/// Uses the Tibber API if a token is configured; otherwise falls back to the Hvakosterstrommen.no free API.
public struct SpotPriceClient {
    public let session: URLSession
    private let tibberToken: String?

    public init(session: URLSession = .shared, tibberToken: String? = nil) {
        self.session = session
        self.tibberToken = tibberToken
    }

    /// Fetch today's hourly prices for a given NO price zone.
    public func fetchTodayPrices(zone: NOPriceZone) async -> [HourlyPrice] {
        if let token = tibberToken {
            if let prices = try? await fetchTibberPrices(token: token, zone: zone) {
                return prices
            }
        }
        return (try? await fetchHvakosterPrices(zone: zone)) ?? []
    }

    /// Fetch today's prices for all NO zones.
    public func fetchAllZones() async -> [NOPriceZone: [HourlyPrice]] {
        await withTaskGroup(of: (NOPriceZone, [HourlyPrice]).self) { group in
            for zone in NOPriceZone.allCases {
                group.addTask { (zone, await self.fetchTodayPrices(zone: zone)) }
            }
            var result: [NOPriceZone: [HourlyPrice]] = [:]
            for await (zone, prices) in group {
                result[zone] = prices
            }
            return result
        }
    }

    // MARK: - Hvakosterstrommen fallback

    private func fetchHvakosterPrices(zone: NOPriceZone) async throws -> [HourlyPrice] {
        let now = Date()
        let calendar = Calendar.current
        let year = calendar.component(.year, from: now)
        let month = calendar.component(.month, from: now)
        let day = calendar.component(.day, from: now)
        let dateStr = String(format: "%04d/%02d-%02d", year, month, day)
        let urlStr = "https://www.hvakosterstrommen.no/api/v1/prices/\(dateStr)_\(zone.rawValue).json"
        guard let url = URL(string: urlStr) else { throw URLError(.badURL) }

        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        let raw = try JSONDecoder().decode([HvakosterEntry].self, from: data)
        return raw.compactMap { entry -> HourlyPrice? in
            guard let date = ISO8601DateFormatter().date(from: entry.time_start) else { return nil }
            return HourlyPrice(id: UUID(), startsAt: date, nokPerKwh: entry.NOK_per_kWh, zone: zone)
        }
    }

    private struct HvakosterEntry: Decodable {
        let NOK_per_kWh: Double
        let EUR_per_kWh: Double
        let EXR: Double
        let time_start: String
        let time_end: String
    }

    // MARK: - Tibber

    private func fetchTibberPrices(token: String, zone: NOPriceZone) async throws -> [HourlyPrice] {
        guard let url = URL(string: "https://api.tibber.com/v1-beta/gql") else {
            throw URLError(.badURL)
        }
        let query = """
        { "query": "{ viewer { homes { currentSubscription { priceInfo { today { total startsAt } } } } } }" }
        """
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = query.data(using: .utf8)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let dataObj = json["data"] as? [String: Any],
            let viewer = dataObj["viewer"] as? [String: Any],
            let homes = viewer["homes"] as? [[String: Any]],
            let firstHome = homes.first,
            let sub = firstHome["currentSubscription"] as? [String: Any],
            let priceInfo = sub["priceInfo"] as? [String: Any],
            let today = priceInfo["today"] as? [[String: Any]]
        else {
            throw URLError(.cannotParseResponse)
        }
        let iso = ISO8601DateFormatter()
        return today.compactMap { entry -> HourlyPrice? in
            guard
                let total = entry["total"] as? Double,
                let startsAtStr = entry["startsAt"] as? String,
                let date = iso.date(from: startsAtStr)
            else { return nil }
            return HourlyPrice(id: UUID(), startsAt: date, nokPerKwh: total, zone: zone)
        }
    }
}

// MARK: - Models

public enum NOPriceZone: String, CaseIterable, Codable, Identifiable {
    case no1 = "NO1"
    case no2 = "NO2"
    case no3 = "NO3"
    case no4 = "NO4"
    case no5 = "NO5"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .no1: return "NO1 – Øst-Norge"
        case .no2: return "NO2 – Sør-Norge"
        case .no3: return "NO3 – Midt-Norge"
        case .no4: return "NO4 – Nord-Norge"
        case .no5: return "NO5 – Vest-Norge"
        }
    }
}

public struct HourlyPrice: Identifiable, Codable {
    public var id: UUID
    public var startsAt: Date
    public var nokPerKwh: Double
    public var zone: NOPriceZone

    public init(id: UUID, startsAt: Date, nokPerKwh: Double, zone: NOPriceZone) {
        self.id = id
        self.startsAt = startsAt
        self.nokPerKwh = nokPerKwh
        self.zone = zone
    }
}
