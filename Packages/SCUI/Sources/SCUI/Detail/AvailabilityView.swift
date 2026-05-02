import SwiftUI
import SCData

/// Shows static stall count information in the detail view.
public struct AvailabilityView: View {
    public let stallCount: Int

    public init(stallCount: Int) {
        self.stallCount = stallCount
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(stallCount)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Text("stalls")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Text("Real-time availability not available without a Tesla account connection.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
