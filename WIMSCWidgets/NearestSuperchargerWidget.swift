import WidgetKit
import SwiftUI
import CoreLocation

struct NearestSuperchargerEntry: TimelineEntry {
    var date: Date
    var siteName: String
    var distanceKm: Double?
    var stallCount: Int
    var maxKw: Int
    var status: String
}

struct NearestSuperchargerProvider: TimelineProvider {
    func placeholder(in context: Context) -> NearestSuperchargerEntry {
        NearestSuperchargerEntry(date: .now, siteName: "Lyngdal", distanceKm: 12.3, stallCount: 8, maxKw: 250, status: "Open")
    }

    func getSnapshot(in context: Context, completion: @escaping (NearestSuperchargerEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NearestSuperchargerEntry>) -> Void) {
        // Widgets can't access SwiftData directly without an App Group.
        // Return a placeholder entry with a 30-minute refresh.
        let entry = NearestSuperchargerEntry(date: .now, siteName: "—", distanceKm: nil, stallCount: 0, maxKw: 0, status: "Open")
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

struct NearestSuperchargerWidgetView: View {
    var entry: NearestSuperchargerEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Nearest SC", systemImage: "bolt.fill")
                .font(.caption2.bold())
                .foregroundStyle(.secondary)
            Text(entry.siteName)
                .font(.headline)
                .lineLimit(1)
            if let dist = entry.distanceKm {
                Text(String(format: "%.1f km", dist))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if family != .systemSmall {
                HStack {
                    Text("\(entry.stallCount) stalls")
                    Text("·")
                    Text("\(entry.maxKw) kW")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
            Text(entry.status)
                .font(.caption.bold())
                .foregroundStyle(entry.status == "Open" ? .blue : .gray)
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct NearestSuperchargerWidget: Widget {
    static let kind = "NearestSupercharger"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: NearestSuperchargerProvider()) { entry in
            NearestSuperchargerWidgetView(entry: entry)
        }
        .configurationDisplayName("Nearest Supercharger")
        .description("Shows the nearest Tesla Supercharger.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryCircular])
    }
}
