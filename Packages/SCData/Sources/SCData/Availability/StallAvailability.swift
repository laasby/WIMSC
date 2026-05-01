import Foundation
import SwiftData

/// Snapshot of live or last-known stall availability at a site.
@Model
public final class StallAvailability {
    public var superchargerId: String
    public var fetchedAt: Date
    public var totalStalls: Int
    public var availableStalls: Int
    public var occupiedStalls: Int
    public var offlineStalls: Int
    public var stallDetails: [StallDetail]
    public var source: AvailabilitySource

    public init(
        superchargerId: String,
        fetchedAt: Date = .now,
        totalStalls: Int,
        availableStalls: Int,
        occupiedStalls: Int,
        offlineStalls: Int,
        stallDetails: [StallDetail] = [],
        source: AvailabilitySource
    ) {
        self.superchargerId = superchargerId
        self.fetchedAt = fetchedAt
        self.totalStalls = totalStalls
        self.availableStalls = availableStalls
        self.occupiedStalls = occupiedStalls
        self.offlineStalls = offlineStalls
        self.stallDetails = stallDetails
        self.source = source
    }
}

public struct StallDetail: Codable {
    public var stallNumber: Int
    public var status: StallStatus
    public var lastReportedKw: Int?

    public init(stallNumber: Int, status: StallStatus, lastReportedKw: Int? = nil) {
        self.stallNumber = stallNumber
        self.status = status
        self.lastReportedKw = lastReportedKw
    }
}

public enum StallStatus: String, Codable {
    case available, occupied, offline, unknown
}

public enum AvailabilitySource: String, Codable {
    case teslaFleetAPI   // authoritative
    case teslaFindUs     // semi-public
    case communityReport // user-reported
    case cached          // from local cache
}
