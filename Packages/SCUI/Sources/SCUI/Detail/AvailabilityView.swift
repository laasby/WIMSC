import SwiftUI
import SCData
import SCDomain

/// Shows live/last-known stall availability in the detail view.
public struct AvailabilityView: View {
    public let availability: StallAvailability?
    public let stallCount: Int
    public let waitDescription: String

    // Tesla Fleet live data (nil when not authenticated or no data)
    public let liveAvailableStalls: Int?
    public let liveTotalStalls: Int?
    public let liveLastRefreshed: Date?
    public let isAuthenticated: Bool
    public let onSignIn: () -> Void

    public init(
        availability: StallAvailability?,
        stallCount: Int,
        waitDescription: String,
        liveAvailableStalls: Int? = nil,
        liveTotalStalls: Int? = nil,
        liveLastRefreshed: Date? = nil,
        isAuthenticated: Bool = false,
        onSignIn: @escaping () -> Void = {}
    ) {
        self.availability = availability
        self.stallCount = stallCount
        self.waitDescription = waitDescription
        self.liveAvailableStalls = liveAvailableStalls
        self.liveTotalStalls = liveTotalStalls
        self.liveLastRefreshed = liveLastRefreshed
        self.isAuthenticated = isAuthenticated
        self.onSignIn = onSignIn
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if isAuthenticated {
                if let available = liveAvailableStalls, let total = liveTotalStalls, total > 0 {
                    liveStallSection(available: available, total: total)
                } else {
                    Text("Fetching live availability…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                teslaSignInCard
            }

            if let avail = availability, avail.availableStalls >= 0 {
                Divider()
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
            } else if !isAuthenticated {
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

    // MARK: - Live section

    private func liveStallSection(available: Int, total: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(available)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(availabilityColor(available: available, total: total))
                Text("/ \(total) stalls available")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.2))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(availabilityColor(available: available, total: total))
                        .frame(width: geo.size.width * CGFloat(available) / CGFloat(max(total, 1)))
                }
            }
            .frame(height: 10)
            .clipShape(RoundedRectangle(cornerRadius: 4))

            if let refreshed = liveLastRefreshed {
                Text("Last updated \(refreshed.formatted(.relative(presentation: .named)))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var teslaSignInCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Live stall counts available", systemImage: "bolt.fill")
                .font(.subheadline.weight(.semibold))
            Text("Sign in with your Tesla account to see real-time stall availability.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button(action: onSignIn) {
                Label("Sign in with Tesla", systemImage: "person.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
        .padding(12)
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
    }

    private func availabilityColor(available: Int, total: Int) -> Color {
        guard total > 0 else { return .gray }
        let ratio = Double(available) / Double(total)
        if ratio > 0.5 { return .green }
        if ratio > 0.2 { return .yellow }
        return .red
    }

    // MARK: - Existing helpers

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
