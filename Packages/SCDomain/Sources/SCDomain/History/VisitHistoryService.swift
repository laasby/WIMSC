import Foundation
import SwiftData
import SCData

/// Manages visit history records — adding, querying, and computing statistics.
@Observable
public final class VisitHistoryService {
    private let modelContext: ModelContext

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Adding visits

    /// Insert a new manual visit record.
    public func addVisit(
        superchargerId: String,
        kwhDelivered: Double? = nil,
        cost: Double? = nil,
        currency: String? = nil,
        durationMinutes: Int? = nil,
        startSoc: Int? = nil,
        endSoc: Int? = nil,
        ambientTempCelsius: Double? = nil,
        stallNumber: Int? = nil,
        notes: String? = nil
    ) throws {
        let record = VisitRecord(
            superchargerId: superchargerId,
            visitedAt: .now,
            kwhDelivered: kwhDelivered,
            cost: cost,
            currency: currency,
            durationMinutes: durationMinutes,
            startSoc: startSoc,
            endSoc: endSoc,
            ambientTempCelsius: ambientTempCelsius,
            stallNumber: stallNumber,
            notes: notes,
            source: .manual
        )
        modelContext.insert(record)
        try modelContext.save()
    }

    // MARK: - Querying

    /// All visits for a specific site, newest first.
    public func visits(for superchargerId: String) throws -> [VisitRecord] {
        var descriptor = FetchDescriptor<VisitRecord>(
            predicate: #Predicate { $0.superchargerId == superchargerId },
            sortBy: [SortDescriptor(\.visitedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 500
        return try modelContext.fetch(descriptor)
    }

    /// All visits across all sites, newest first.
    public func allVisits() throws -> [VisitRecord] {
        let descriptor = FetchDescriptor<VisitRecord>(
            sortBy: [SortDescriptor(\.visitedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    // MARK: - Statistics

    /// Total kWh delivered across all visits.
    public func totalKwhDelivered() throws -> Double {
        let visits = try allVisits()
        return visits.compactMap(\.kwhDelivered).reduce(0, +)
    }

    /// Total cost across all visits, grouped by currency.
    public func totalCostByCurrency() throws -> [String: Double] {
        let visits = try allVisits()
        var result: [String: Double] = [:]
        for visit in visits {
            guard let cost = visit.cost, let currency = visit.currency else { continue }
            result[currency, default: 0] += cost
        }
        return result
    }

    /// Average cost per kWh for NOK visits.
    public func averageCostPerKwhNOK() throws -> Double? {
        let visits = try allVisits()
        let nokVisits = visits.filter { $0.currency == "NOK" }
        let pairs = nokVisits.compactMap { v -> (Double, Double)? in
            guard let cost = v.cost, let kwh = v.kwhDelivered, kwh > 0 else { return nil }
            return (cost, kwh)
        }
        guard !pairs.isEmpty else { return nil }
        let totalCost = pairs.map(\.0).reduce(0, +)
        let totalKwh = pairs.map(\.1).reduce(0, +)
        return totalKwh > 0 ? totalCost / totalKwh : nil
    }

    /// Year-over-year cost summary: [year: totalNOK]
    public func yearOverYearCost() throws -> [Int: Double] {
        let visits = try allVisits()
        var result: [Int: Double] = [:]
        let calendar = Calendar.current
        for visit in visits {
            guard let cost = visit.cost, visit.currency == "NOK" else { continue }
            let year = calendar.component(.year, from: visit.visitedAt)
            result[year, default: 0] += cost
        }
        return result
    }

    /// Number of visits in the last 30 days.
    public func recentVisitCount() throws -> Int {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: .now) ?? .now
        let descriptor = FetchDescriptor<VisitRecord>(
            predicate: #Predicate { $0.visitedAt >= cutoff }
        )
        return try modelContext.fetchCount(descriptor)
    }
}
