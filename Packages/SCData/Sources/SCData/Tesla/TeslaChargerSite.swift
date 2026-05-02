import Foundation

/// A Supercharger site with live availability data from the Tesla Fleet API.
public struct TeslaChargerSite: Sendable {
    public let name: String
    public let latitude: Double
    public let longitude: Double
    public let availableStalls: Int
    public let totalStalls: Int
    public let isClosed: Bool
    public let fetchedAt: Date

    public init(
        name: String,
        latitude: Double,
        longitude: Double,
        availableStalls: Int,
        totalStalls: Int,
        isClosed: Bool,
        fetchedAt: Date = .now
    ) {
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.availableStalls = availableStalls
        self.totalStalls = totalStalls
        self.isClosed = isClosed
        self.fetchedAt = fetchedAt
    }
}
