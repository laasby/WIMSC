import Foundation

/// Fetches live Supercharger availability from the Tesla Fleet API.
/// Uses the EU regional endpoint — correct for Norway and all European sites.
public struct TeslaFleetAvailabilityClient: Sendable {

    private static let baseURL = "https://fleet-api.prd.eu.vn.cloud.tesla.com"

    public init() {}

    public func fetchNearby(
        latitude: Double,
        longitude: Double,
        radius: Int = 150,
        accessToken: String
    ) async throws -> [TeslaChargerSite] {
        var components = URLComponents(string: "\(Self.baseURL)/api/1/dx/charging/nearby_charging_sites")!
        components.queryItems = [
            .init(name: "latitude", value: "\(latitude)"),
            .init(name: "longitude", value: "\(longitude)"),
            .init(name: "count", value: "50"),
            .init(name: "radius", value: "\(radius)"),
        ]

        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("wimsc/1.0", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10

        let (data, response) = try await URLSession.shared.data(for: request)

        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw TeslaAvailabilityError.httpError(http.statusCode)
        }

        return try parseResponse(data)
    }

    private func parseResponse(_ data: Data) throws -> [TeslaChargerSite] {
        struct Root: Decodable {
            let response: Response
        }
        struct Response: Decodable {
            let superchargers: [SiteDTO]
        }
        struct SiteDTO: Decodable {
            let name: String
            let location: Location
            let available_stalls: Int
            let total_stalls: Int
            let site_closed: Bool
        }
        struct Location: Decodable {
            let lat: Double
            let long: Double
        }

        let root = try JSONDecoder().decode(Root.self, from: data)
        return root.response.superchargers.map {
            TeslaChargerSite(
                name: $0.name,
                latitude: $0.location.lat,
                longitude: $0.location.long,
                availableStalls: $0.available_stalls,
                totalStalls: $0.total_stalls,
                isClosed: $0.site_closed
            )
        }
    }
}

public enum TeslaAvailabilityError: LocalizedError {
    case httpError(Int)

    public var errorDescription: String? {
        switch self {
        case .httpError(let code): return "Tesla API returned HTTP \(code)."
        }
    }
}
