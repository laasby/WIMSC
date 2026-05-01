import SwiftUI
import SCData
import SCDomain

/// Shown on the detail view when there are recent stall issue reports.
public struct StallReliabilityBanner: View {
    public let summary: String

    public init(summary: String) {
        self.summary = summary
    }

    public var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(summary)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
        .padding(12)
        .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal)
    }
}
