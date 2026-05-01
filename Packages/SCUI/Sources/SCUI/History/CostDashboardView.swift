import SwiftUI
import SwiftData
import SCData
import SCDomain

public struct CostDashboardView: View {
    @State private var historyService: VisitHistoryService
    @State private var selectedYear: Int = Calendar.current.component(.year, from: .now)
    @State private var allVisits: [VisitRecord] = []
    @State private var yearStats: [Int: Double] = [:]
    @State private var totalKwh: Double = 0
    @State private var totalNOK: Double = 0
    @State private var avgCostPerKwh: Double? = nil

    public init(modelContext: ModelContext) {
        _historyService = State(initialValue: VisitHistoryService(modelContext: modelContext))
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    statsCardsRow
                    yearSelector
                    yearBarChart
                    visitList
                }
                .padding()
            }
            .navigationTitle("Charging History")
            .task { await loadData() }
        }
    }

    // MARK: - Stats Cards

    private var statsCardsRow: some View {
        let sessions = allVisits.count
        let avgStr = avgCostPerKwh.map { String(format: "%.2f kr", $0) } ?? "—"
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(value: String(format: "%.1f", totalKwh), label: "Total kWh")
            StatCard(value: String(format: "%.0f kr", totalNOK), label: "Total Cost (NOK)")
            StatCard(value: "\(sessions)", label: "Sessions")
            StatCard(value: avgStr, label: "Avg kr/kWh")
        }
    }

    // MARK: - Year Selector

    private var yearSelector: some View {
        let years = Array(yearStats.keys).sorted(by: >)
        guard !years.isEmpty else { return AnyView(EmptyView()) }
        return AnyView(
            Picker("Year", selection: $selectedYear) {
                ForEach(years, id: \.self) { year in
                    Text(String(year)).tag(year)
                }
            }
            .pickerStyle(.segmented)
        )
    }

    // MARK: - Year Bar Chart

    private var yearBarChart: some View {
        let calendar = Calendar.current
        let monthlyData: [Double] = (1...12).map { month in
            allVisits
                .filter {
                    let y = calendar.component(.year, from: $0.visitedAt)
                    let m = calendar.component(.month, from: $0.visitedAt)
                    return y == selectedYear && m == month
                }
                .compactMap { $0.currency == "NOK" ? $0.cost : $0.kwhDelivered }
                .reduce(0, +)
        }
        let maxVal = monthlyData.max() ?? 1
        let currentMonth = calendar.component(.month, from: .now)
        let monthSymbols = ["J","F","M","A","M","J","J","A","S","O","N","D"]

        return VStack(alignment: .leading, spacing: 8) {
            Text("Monthly (\(selectedYear))")
                .font(.headline)
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(0..<12, id: \.self) { i in
                    let isCurrentMonth = (i + 1) == currentMonth && selectedYear == Calendar.current.component(.year, from: .now)
                    let barHeight = maxVal > 0 ? CGFloat(monthlyData[i] / maxVal) * 80 : 2
                    VStack(spacing: 2) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(isCurrentMonth ? Color.accentColor : Color.accentColor.opacity(0.4))
                            .frame(height: max(2, barHeight))
                        Text(monthSymbols[i])
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 100)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Visit List

    private var visitList: some View {
        let calendar = Calendar.current
        let visitsForYear = allVisits.filter {
            calendar.component(.year, from: $0.visitedAt) == selectedYear
        }
        let grouped = Dictionary(grouping: visitsForYear) {
            calendar.component(.month, from: $0.visitedAt)
        }
        let sortedMonths = grouped.keys.sorted(by: >)

        return VStack(alignment: .leading, spacing: 12) {
            Text("Sessions")
                .font(.headline)
            if visitsForYear.isEmpty {
                Text("No sessions recorded for \(selectedYear).")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(sortedMonths, id: \.self) { month in
                        Section {
                            ForEach(grouped[month] ?? [], id: \.id) { visit in
                                VisitRow(visit: visit)
                                Divider()
                            }
                        } header: {
                            Text(monthName(month))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 6)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func loadData() async {
        allVisits = (try? historyService.allVisits()) ?? []
        totalKwh = (try? historyService.totalKwhDelivered()) ?? 0
        yearStats = (try? historyService.yearOverYearCost()) ?? [:]
        totalNOK = yearStats.values.reduce(0, +)
        avgCostPerKwh = try? historyService.averageCostPerKwhNOK()
    }

    private func monthName(_ month: Int) -> String {
        let df = DateFormatter()
        df.dateFormat = "MMMM"
        var comps = DateComponents()
        comps.month = month
        comps.year = selectedYear
        return Calendar.current.date(from: comps).map { df.string(from: $0) } ?? "\(month)"
    }
}

// MARK: - Subviews

private struct StatCard: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct VisitRow: View {
    let visit: VisitRecord

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(visit.superchargerId)
                    .font(.subheadline.weight(.medium))
                Text(visit.visitedAt, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                if let kwh = visit.kwhDelivered {
                    Text(String(format: "%.1f kWh", kwh))
                        .font(.subheadline)
                }
                if let cost = visit.cost, let currency = visit.currency {
                    Text(String(format: "%.0f %@", cost, currency))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let dur = visit.durationMinutes {
                    Text("\(dur) min")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
    }
}
