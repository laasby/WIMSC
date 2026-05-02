import SwiftUI
import SCData

/// Shows live or static stall availability in the detail view.
public struct AvailabilityView: View {
    public let stallCount: Int
    public let live: TeslaChargerSite?

    public init(stallCount: Int, live: TeslaChargerSite? = nil) {
        self.stallCount = stallCount
        self.live = live
    }

    public var body: some View {
        if let live {
            liveView(live)
        } else {
            staticView
        }
    }

    // MARK: - Live availability

    private func liveView(_ site: TeslaChargerSite) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if site.isClosed {
                Label("Site closed", systemImage: "lock.fill")
                    .font(.headline)
                    .foregroundStyle(.red)
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(site.availableStalls)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(availabilityColor(site))
                    Text("/ \(site.totalStalls) available")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                stallBar(site)
            }

            HStack(spacing: 4) {
                Image(systemName: "clock")
                Text("Updated \(site.fetchedAt, style: .relative) ago")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private func stallBar(_ site: TeslaChargerSite) -> some View {
        let fraction = site.totalStalls > 0
            ? Double(site.availableStalls) / Double(site.totalStalls)
            : 0
        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(height: 8)
                RoundedRectangle(cornerRadius: 4)
                    .fill(availabilityColor(site))
                    .frame(width: geo.size.width * fraction, height: 8)
                    .animation(.easeInOut, value: fraction)
            }
        }
        .frame(height: 8)
    }

    private func availabilityColor(_ site: TeslaChargerSite) -> Color {
        let fraction = site.totalStalls > 0
            ? Double(site.availableStalls) / Double(site.totalStalls)
            : 0
        if fraction > 0.5 { return .green }
        if fraction > 0.2 { return .orange }
        return .red
    }

    // MARK: - Static (no Tesla account)

    private var staticView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(stallCount)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                Text("stalls")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Label("Connect Tesla account in Settings for live availability.", systemImage: "person.badge.key")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
