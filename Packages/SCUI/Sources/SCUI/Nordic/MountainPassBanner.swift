import SwiftUI
import SCData

/// A compact banner shown on the detail view for Norwegian sites,
/// indicating the status of a mountain pass.
public struct MountainPassBanner: View {
    public let pass: MountainPass

    public init(pass: MountainPass) {
        self.pass = pass
    }

    public var body: some View {
        HStack(spacing: 10) {
            Image(systemName: statusIcon)
                .foregroundStyle(statusColor)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text(pass.name)
                    .font(.subheadline.weight(.medium))
                Text(pass.statusDescription ?? statusLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(statusLabel)
                .font(.caption.bold())
                .foregroundStyle(statusColor)
        }
        .padding(12)
        .background(statusBackgroundColor, in: RoundedRectangle(cornerRadius: 10))
    }

    private var statusIcon: String {
        switch pass.status {
        case .open:       return "road.lanes"
        case .restricted: return "exclamationmark.triangle.fill"
        case .closed:     return "xmark.octagon.fill"
        case .unknown:    return "questionmark.circle"
        }
    }

    private var statusColor: Color {
        switch pass.status {
        case .open:       return .blue
        case .restricted: return .orange
        case .closed:     return Color(white: 0.5)
        case .unknown:    return .gray
        }
    }

    private var statusBackgroundColor: Color {
        switch pass.status {
        case .open:       return Color.blue.opacity(0.1)
        case .restricted: return Color.orange.opacity(0.1)
        case .closed:     return Color(white: 0.5).opacity(0.1)
        case .unknown:    return Color.gray.opacity(0.1)
        }
    }

    private var statusLabel: String {
        switch pass.status {
        case .open:       return "Open"
        case .restricted: return "Restricted"
        case .closed:     return "Closed"
        case .unknown:    return "Unknown"
        }
    }
}
