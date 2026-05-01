import SwiftUI
import SCData
import SCDomain

/// Shows live/last-known stall availability in the detail view.
public struct AvailabilityView: View {
    public let availability: StallAvailability?
    public let stallCount: Int
    public let waitDescription: String

    public init(availability: StallAvailability?, stallCount: Int, waitDescription: String) {
        self.availability = availability
        self.stallCount = stallCount
        self.waitDescription = waitDescription
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let avail = availability, avail.availableStalls >= 0 {
                stallBar(avail)

                HStack(spacing: 16) {
                    availChip(label: "Available", count: avail.availableStalls, color: .blue)
                    availChip(label: "In use", count: avail.occupiedStalls, color: .orange)
                    if avail.offlineStalls > 0 {
                        availChip(label: "Offline", count: avail.offlineStalls, color: .gray)
                    }
                }

                Text("Updated \(avail.fetchedAt.formatted(.relative(presentation: .named)))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Live availability not available")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Image(systemName: "clock")
                    .foregroundStyle(.secondary)
                Text(waitDescription)
                    .font(.subheadline)
            }
        }
    }

    private func stallBar(_ avail: StallAvailability) -> some View {
        GeometryReader { geo in
            HStack(spacing: 2) {
                let total = max(avail.totalStalls, 1)
                let availFrac = CGFloat(avail.availableStalls) / CGFloat(total)
                let occupFrac = CGFloat(avail.occupiedStalls) / CGFloat(total)
                let offFrac = CGFloat(avail.offlineStalls) / CGFloat(total)
                RoundedRectangle(cornerRadius: 3).fill(Color.blue).frame(width: geo.size.width * availFrac)
                RoundedRectangle(cornerRadius: 3).fill(Color.orange).frame(width: geo.size.width * occupFrac)
                if avail.offlineStalls > 0 {
                    RoundedRectangle(cornerRadius: 3).fill(Color.gray.opacity(0.4)).frame(width: geo.size.width * offFrac)
                }
            }
        }
        .frame(height: 10)
        .clipShape(RoundedRectangle(cornerRadius: 5))
    }

    private func availChip(label: String, count: Int, color: Color) -> some View {
        VStack(spacing: 1) {
            Text("\(count)").font(.headline).foregroundStyle(color)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
    }
}
