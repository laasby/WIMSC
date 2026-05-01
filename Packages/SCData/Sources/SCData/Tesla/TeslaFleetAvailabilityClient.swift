import Foundation

public struct TeslaFleetSiteAvailability: Sendable {
    public let name: String
    public let latitude: Double
    public let longitude: Double
    public let availableStalls: Int
    public let totalStalls: Int
    public let siteClosed: Bool

    public init(name: String, latitude: Double, longitude: Double,
                availableStalls: Int, totalStalls: Int, siteClosed: Bool) {
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.availableStalls = availableStalls
        self.totalStalls = totalStalls
        self.siteClosed = siteClosed
    }
}

public struct TeslaFleetAvailabilityClient: Sendable {
    public init() {}

    public func fetchNearby(latitude: Double, longitude: Double,
                            accessToken: String) async throws -> [TeslaFleetSiteAvailability] {
        let base = longitude < 30
            ? "https://fleet-api.prd.eu.vn.cloud.tesla.com"
            : "https://fleet-api.prd.na.vn.cloud.tesla.com"

        var components = URLComponents(string: "\(base)/api/1/dx/charging/sites")!
        components.queryItems = [
            .init(name: "latitude", value: String(latitude)),
            .init(name: "longitude", value: String(longitude)),
            .init(name: "radius_m", value: "50000"),
        ]
        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: request)
        let envelope = try JSONDecoder().decode(FleetResponse.self, from: data)
        return envelope.response
            .filter { $0.type == "supercharger" }
            .map {
                TeslaFleetSiteAvailability(
                    name: $0.name,
                    latitude: $0.location.lat,
                    longitude: $0.location.long,
                    availableStalls: $0.availableStalls ?? 0,
                    totalStalls: $0.totalStalls ?? 0,
                    siteClosed: $0.siteClosed ?? false
                )
            }
    }

    // MARK: - Decodable models

    private struct FleetResponse: Decodable {
        let response: [FleetSite]
    }

    private struct FleetSite: Decodable {
        let name: String
        let type: String
        let availableStalls: Int?
        let totalStalls: Int?
        let siteClosed: Bool?
        let location: FleetLocation

        enum CodingKeys: String, CodingKey {
            case name, type, location
            case availableStalls = "available_stalls"
            case totalStalls = "total_stalls"
            case siteClosed = "site_closed"
        }
    }

    private struct FleetLocation: Decodable {
        let lat: Double
        let long: Double
    }
}
