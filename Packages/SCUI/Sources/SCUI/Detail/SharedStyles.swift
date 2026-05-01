import SwiftUI
import SCData

// MARK: - OLED-aware background color

extension Color {
    /// True black in dark mode for OLED displays, white in light mode.
    static var darkBackground: Color {
        Color(uiColor: UIColor { tc in
            tc.userInterfaceStyle == .dark ? .black : .systemBackground
        })
    }
}

// MARK: - SiteStatus helpers (internal — shared across Map and Detail)

extension SiteStatus {
    var displayName: String {
        switch self {
        case .open:         return "Open"
        case .construction: return "Construction"
        case .closed:       return "Closed"
        case .permit:       return "Permit"
        case .plan:         return "Planned"
        }
    }

    var dotColor: Color {
        switch self {
        case .open:         return Color(red: 0/255, green: 119/255, blue: 187/255)
        case .construction: return .orange
        case .closed:       return .gray
        case .permit:       return .yellow
        case .plan:         return Color(white: 0.7)
        }
    }
}

// MARK: - DataSource display name

extension DataSource {
    var displayName: String {
        switch self {
        case .superchargeInfo: return "Supercharge.info"
        case .teslaFindUs:     return "Tesla Find Us"
        case .openChargeMap:   return "Open Charge Map"
        }
    }
}

// MARK: - Badge views (internal — shared by Map and Detail)

struct GenerationBadge: View {
    let generation: ChargerGeneration

    var body: some View {
        Text(GenerationPinStyle.label(for: generation))
            .font(.caption2.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(GenerationPinStyle.color(for: generation), in: RoundedRectangle(cornerRadius: 4))
            .accessibilityLabel("\(GenerationPinStyle.label(for: generation)) generation charger")
    }
}

struct MagicDockBadge: View {
    var body: some View {
        Text("MD")
            .font(.caption2.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.teal, in: RoundedRectangle(cornerRadius: 4))
            .accessibilityLabel("Magic Dock")
    }
}

struct StatusDot: View {
    let status: SiteStatus

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(status.dotColor)
                .frame(width: 8, height: 8)
                .accessibilityHidden(true)
            Text(status.displayName)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Status: \(status.displayName)")
    }
}
