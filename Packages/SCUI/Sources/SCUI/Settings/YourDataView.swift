import SwiftUI
import SwiftData
import SCData

/// Shows the user exactly what data is stored on-device, and offers a JSON export.
public struct YourDataView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var favouriteCount: Int = 0
    @State private var visitCount: Int = 0
    @State private var noteCount: Int = 0
    @State private var exportJSON: String = ""
    @State private var showExportSheet: Bool = false

    public init() {}

    public var body: some View {
        List {
            Section("What's stored on this device") {
                DataRow(label: "Favourite sites", value: "\(favouriteCount)")
                DataRow(label: "Visit records", value: "\(visitCount)")
                DataRow(label: "Sites with notes", value: "\(noteCount)")
                DataRow(label: "Analytics", value: "None")
                DataRow(label: "Advertising IDs", value: "None")
                DataRow(label: "Third-party SDKs", value: "None")
            }

            Section("iCloud") {
                DataRow(label: "Sync", value: "Off (opt-in)")
                DataRow(label: "What syncs", value: "Favourites, notes, visits (if enabled)")
            }

            Section {
                Button("Export all my data as JSON") {
                    exportData()
                    showExportSheet = true
                }
            }
        }
        .navigationTitle("Your Data")
        .sheet(isPresented: $showExportSheet) {
            ShareLink(item: exportJSON, subject: Text("WIMSC Data Export"))
        }
        .task { await loadCounts() }
    }

    private func loadCounts() async {
        favouriteCount = (try? modelContext.fetchCount(
            FetchDescriptor<Supercharger>(predicate: #Predicate { $0.isFavourite })
        )) ?? 0
        visitCount = (try? modelContext.fetchCount(FetchDescriptor<VisitRecord>())) ?? 0
        noteCount = (try? modelContext.fetchCount(
            FetchDescriptor<Supercharger>(predicate: #Predicate { $0.userNotes != nil })
        )) ?? 0
    }

    private func exportData() {
        let visits = (try? modelContext.fetch(FetchDescriptor<VisitRecord>())) ?? []
        let favs = (try? modelContext.fetch(
            FetchDescriptor<Supercharger>(predicate: #Predicate { $0.isFavourite })
        )) ?? []

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        struct Export: Encodable {
            var exportedAt: Date
            var favouriteSiteIds: [String]
            var visits: [VisitExport]
        }
        struct VisitExport: Encodable {
            var superchargerId: String
            var visitedAt: Date
            var kwhDelivered: Double?
            var cost: Double?
            var currency: String?
            var durationMinutes: Int?
        }

        let export = Export(
            exportedAt: .now,
            favouriteSiteIds: favs.map(\.id),
            visits: visits.map { v in
                VisitExport(
                    superchargerId: v.superchargerId,
                    visitedAt: v.visitedAt,
                    kwhDelivered: v.kwhDelivered,
                    cost: v.cost,
                    currency: v.currency,
                    durationMinutes: v.durationMinutes
                )
            }
        )
        exportJSON = (try? String(data: encoder.encode(export), encoding: .utf8)) ?? "{}"
    }
}

private struct DataRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value)
        }
        .font(.subheadline)
    }
}
