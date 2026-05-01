import SwiftUI
import SCData

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
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(GenerationPinStyle.color(for: generation), in: RoundedRectangle(cornerRadius: 4))
    }
}

struct MagicDockBadge: View {
    var body: some View {
        Text("MD")
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.teal, in: RoundedRectangle(cornerRadius: 4))
    }
}

struct StatusDot: View {
    let status: SiteStatus

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(status.dotColor)
                .frame(width: 8, height: 8)
            Text(status.displayName)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
