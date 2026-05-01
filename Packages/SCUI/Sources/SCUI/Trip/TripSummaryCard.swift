import SwiftUI
import SCData
import SCDomain

public struct TripSummaryCard: View {
    public let plan: TripPlan

    public init(plan: TripPlan) {
        self.plan = plan
    }

    public var body: some View {
        let summary = TripSummary.from(plan: plan)
        VStack(alignment: .leading, spacing: 8) {
            Text("Trip Summary")
                .font(.headline)
            HStack(spacing: 20) {
                StatChip(label: "Distance", value: "\(Int(summary.totalDistanceKm)) km", icon: "road.lanes")
                StatChip(label: "Drive", value: "\(summary.drivingMinutes) min", icon: "car")
                StatChip(label: "Stops", value: "\(summary.numberOfStops)", icon: "bolt.fill")
                StatChip(label: "Charge", value: "\(summary.totalChargeMinutes) min", icon: "clock")
            }
            if !plan.recommendedStops.isEmpty {
                Divider()
                Text("Recommended stops:")
                    .font(.caption).foregroundStyle(.secondary)
                ForEach(plan.recommendedStops) { stop in
                    HStack {
                        Image(systemName: "bolt.fill").foregroundStyle(.blue).frame(width: 16)
                        Text(stop.supercharger.name).font(.caption)
                        Spacer()
                        Text("~\(stop.estimatedChargeMinutes) min").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            if !plan.warnings.isEmpty {
                ForEach(plan.warnings, id: \.self) { w in
                    Label(w, systemImage: "exclamationmark.triangle")
                        .font(.caption).foregroundStyle(.orange)
                }
            }
        }
        .padding()
        .background(Color(uiColor: .systemBackground), in: RoundedRectangle(cornerRadius: 14))
        .shadow(radius: 4)
    }
}

private struct StatChip: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: icon).font(.caption2).foregroundStyle(.secondary)
            Text(value).font(.caption.bold())
            Text(label).font(.system(size: 9)).foregroundStyle(.secondary)
        }
    }
}
