import Foundation
import SwiftData
import SCData

/// Analyses charging session history to surface underperforming stalls and sites.
@Observable
public final class SessionForensicsService {
    private let modelContext: ModelContext

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Stall analysis

    /// Returns forensic findings for a specific site.
    /// Compares each stall's sessions against the site median kW.
    public func analyseSite(_ superchargerId: String) throws -> [StallFinding] {
        let visits = try fetchVisits(for: superchargerId)
        let stallVisits = Dictionary(grouping: visits.filter { $0.stallNumber != nil }, by: { $0.stallNumber! })

        let stallAverages: [(stallNumber: Int, avgKw: Double)] = stallVisits.compactMap { stallNum, records in
            let kws = records.compactMap { computeKw(from: $0) }
            guard !kws.isEmpty else { return nil }
            return (stallNum, kws.reduce(0, +) / Double(kws.count))
        }

        let siteMedian = median(stallAverages.map(\.avgKw))

        let reports = try fetchReports(for: superchargerId)
        let reportsByStall = Dictionary(grouping: reports, by: { $0.stallNumber })

        return stallAverages.map { entry in
            let isUnderperforming: Bool
            if let median = siteMedian, entry.avgKw > 0 {
                isUnderperforming = entry.avgKw < median * 0.75
            } else {
                isUnderperforming = false
            }
            return StallFinding(
                stallNumber: entry.stallNumber,
                sessionCount: stallVisits[entry.stallNumber]?.count ?? 0,
                averageKw: entry.avgKw,
                siteMedianKw: siteMedian,
                isUnderperforming: isUnderperforming,
                recentIssues: reportsByStall[entry.stallNumber] ?? []
            )
        }
        .sorted { $0.stallNumber < $1.stallNumber }
    }

    /// Returns a human-readable alert string if any stall underperforms by >25%.
    public func underperformingStallAlert(for superchargerId: String, siteName: String) throws -> String? {
        let findings = try analyseSite(superchargerId)
        guard let worst = findings.filter(\.isUnderperforming).min(by: { ($0.averageKw ?? 0) < ($1.averageKw ?? 0) }),
              let avgKw = worst.averageKw,
              let medianKw = worst.siteMedianKw else { return nil }
        return "Stall \(worst.stallNumber) at \(siteName) pulled \(Int(avgKw)) kW — site median is \(Int(medianKw)) kW"
    }

    // MARK: - Site-level stats

    /// Average kWh per session at a site.
    public func averageKwhPerSession(for superchargerId: String) throws -> Double? {
        let visits = try fetchVisits(for: superchargerId)
        let values = visits.compactMap(\.kwhDelivered)
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    /// Average cost per session (NOK) at a site.
    public func averageCostPerSession(for superchargerId: String) throws -> Double? {
        let visits = try fetchVisits(for: superchargerId)
        let nokCosts = visits.compactMap { v -> Double? in
            guard v.currency == "NOK", let cost = v.cost else { return nil }
            return cost
        }
        guard !nokCosts.isEmpty else { return nil }
        return nokCosts.reduce(0, +) / Double(nokCosts.count)
    }

    // MARK: - Helpers

    private func fetchVisits(for superchargerId: String) throws -> [VisitRecord] {
        let descriptor = FetchDescriptor<VisitRecord>(
            predicate: #Predicate { $0.superchargerId == superchargerId }
        )
        return try modelContext.fetch(descriptor)
    }

    private func fetchReports(for superchargerId: String) throws -> [StallReport] {
        let descriptor = FetchDescriptor<StallReport>(
            predicate: #Predicate { $0.superchargerId == superchargerId },
            sortBy: [SortDescriptor(\.reportedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    private func computeKw(from visit: VisitRecord) -> Double? {
        guard let kwh = visit.kwhDelivered,
              let minutes = visit.durationMinutes,
              minutes > 0 else { return nil }
        return kwh / (Double(minutes) / 60.0)
    }

    private func median(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        let sorted = values.sorted()
        let mid = sorted.count / 2
        return sorted.count.isMultiple(of: 2)
            ? (sorted[mid - 1] + sorted[mid]) / 2
            : sorted[mid]
    }
}

public struct StallFinding: Identifiable {
    public var id: Int { stallNumber }
    public var stallNumber: Int
    public var sessionCount: Int
    public var averageKw: Double?
    public var siteMedianKw: Double?
    public var isUnderperforming: Bool
    public var recentIssues: [StallReport]

    public init(
        stallNumber: Int,
        sessionCount: Int,
        averageKw: Double?,
        siteMedianKw: Double?,
        isUnderperforming: Bool,
        recentIssues: [StallReport]
    ) {
        self.stallNumber = stallNumber
        self.sessionCount = sessionCount
        self.averageKw = averageKw
        self.siteMedianKw = siteMedianKw
        self.isUnderperforming = isUnderperforming
        self.recentIssues = recentIssues
    }
}
