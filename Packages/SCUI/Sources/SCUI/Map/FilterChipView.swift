import SwiftUI

/// Pill-shaped chip used in the active-filter row.
public struct FilterChip: View {
    public let label: String
    public let isActive: Bool
    public var onRemove: (() -> Void)?

    public init(
        label: String,
        isActive: Bool = true,
        onRemove: (() -> Void)? = nil
    ) {
        self.label = label
        self.isActive = isActive
        self.onRemove = onRemove
    }

    public var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
            if let onRemove {
                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.caption2.weight(.bold))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            isActive ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.1)
        )
        .foregroundStyle(isActive ? Color.accentColor : Color.secondary)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .strokeBorder(
                    isActive ? Color.accentColor.opacity(0.5) : Color.secondary.opacity(0.3),
                    lineWidth: 1
                )
        )
    }
}
