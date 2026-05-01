import Foundation
import SwiftData

/// A user or API-sourced report about the condition of a specific stall.
@Model
public final class StallReport {
    public var id: UUID
    public var superchargerId: String
    public var stallNumber: Int
    public var reportedAt: Date
    public var issue: StallIssue
    public var reportedKilowatts: Int?
    public var notes: String?
    /// "user" or "teslaFleetAPI".
    public var source: String

    public init(
        id: UUID = UUID(),
        superchargerId: String,
        stallNumber: Int,
        reportedAt: Date,
        issue: StallIssue,
        reportedKilowatts: Int? = nil,
        notes: String? = nil,
        source: String = "user"
    ) {
        self.id = id
        self.superchargerId = superchargerId
        self.stallNumber = stallNumber
        self.reportedAt = reportedAt
        self.issue = issue
        self.reportedKilowatts = reportedKilowatts
        self.notes = notes
        self.source = source
    }
}
