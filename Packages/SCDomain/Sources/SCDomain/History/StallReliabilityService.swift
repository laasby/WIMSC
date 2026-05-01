import Foundation
import SwiftData
import SCData

/// Tracks and surfaces per-stall reliability at a site.
@Observable
public final class StallReliabilityService {
    private let modelContext: ModelContext

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// File a report for a specific stall.
    public func reportStall(
        superchargerId: String,
        stallNumber: Int,
        issue: StallIssue,
        reportedKilowatts: Int? = nil,
        notes: String? = nil
    ) throws {
        let report = StallReport(
            superchargerId: superchargerId,
            stallNumber: stallNumber,
            reportedAt: .now,
            issue: issue,
            reportedKilowatts: reportedKilowatts,
            notes: notes,
            source: "user"
        )
        modelContext.insert(report)
        try modelContext.save()
    }

    /// Returns stall reports for a site in the last N days.
    public func recentReports(
        for superchargerId: String,
        days: Int = 14
    ) throws -> [StallReport] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: .now) ?? .now
        let descriptor = FetchDescriptor<StallReport>(
            predicate: #Predicate {
                $0.superchargerId == superchargerId && $0.reportedAt >= cutoff
            },
            sortBy: [SortDescriptor(\.reportedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Returns a human-readable reliability summary for the detail view.
    /// Returns nil if no issues found.
    public func reliabilitySummary(for superchargerId: String) throws -> String? {
        let reports = try recentReports(for: superchargerId)
        let brokenStalls = reports
            .filter { $0.issue == .broken || $0.issue == .degraded }
            .map(\.stallNumber)
        let uniqueStalls = Array(Set(brokenStalls)).sorted()
        guard !uniqueStalls.isEmpty else { return nil }

        let stallNames: String
        if uniqueStalls.count == 1 {
            stallNames = "Stall \(uniqueStalls[0])"
        } else {
            let allButLast = uniqueStalls.dropLast().map { "Stall \($0)" }.joined(separator: ", ")
            stallNames = "\(allButLast) and Stall \(uniqueStalls.last!)"
        }
        return "\(stallNames) reported broken in the last 14 days"
    }

    /// Returns site-level reliability score 0.0–1.0 (1.0 = all ok).
    public func reliabilityScore(for superchargerId: String, stallCount: Int) throws -> Double {
        guard stallCount > 0 else { return 1.0 }
        let reports = try recentReports(for: superchargerId)
        let brokenCount = Set(
            reports
                .filter { $0.issue == .broken }
                .map(\.stallNumber)
        ).count
        let score = 1.0 - (Double(brokenCount) / Double(stallCount))
        return max(0.0, min(1.0, score))
    }
}
