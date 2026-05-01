import SwiftUI
import CoreLocation
import SCData

// MARK: - Status helpers (SCUI-local extension)

private extension SiteStatus {
    var displayName: String {
        switch self {
        case .open:         return "Open"
        case .construction: return "Construction"
        case .closed:       return "Closed"
        case .permit:       return "Permit"
        case .plan:         return "Planned"
        }
    }

    /// Colorblind-safe status color — blue/orange palette, never red/green.
    var dotColor: Color {
        switch self {
        case .open:         return Color(red: 0/255, green: 119/255, blue: 187/255) // blue
        case .construction: return .orange
        case .closed:       return .gray
        case .permit:       return .yellow
        case .plan:         return Color(white: 0.7)
        }
    }
}

// MARK: - Small badge views

private struct GenerationBadge: View {
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

private struct MagicDockBadge: View {
    var body: some View {
        Text("MD")
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.teal, in: RoundedRectangle(cornerRadius: 4))
    }
}

private struct StatusDot: View {
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

// MARK: - SuperchargerCalloutView

/// Compact bottom sheet shown when a map pin is tapped.
public struct SuperchargerCalloutView: View {
    public let supercharger: Supercharger
    public var userLocation: CLLocation?
    public var onNavigate: () -> Void
    public var onDismiss: () -> Void

    public init(
        supercharger: Supercharger,
        userLocation: CLLocation? = nil,
        onNavigate: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.supercharger = supercharger
        self.userLocation = userLocation
        self.onNavigate = onNavigate
        self.onDismiss = onDismiss
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            // Header row
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(supercharger.name)
                        .font(.headline)
                    Text("\(supercharger.city), \(supercharger.country)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            // Badge row
            HStack(spacing: 8) {
                GenerationBadge(generation: supercharger.generation)
                if supercharger.hasMagicDock {
                    MagicDockBadge()
                }
                StatusDot(status: supercharger.status)
            }

            // Stats row
            HStack(spacing: 20) {
                Label("⚡ \(supercharger.stallCount) stalls", systemImage: "bolt.fill")
                    .font(.subheadline)
                    .labelStyle(.titleOnly)
                Text("\(supercharger.maxKilowatts) kW max")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if let dist = distanceText {
                    Text(dist)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            // Details button
            Button(action: onNavigate) {
                Text("Details")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .padding(.bottom, 8)
    }

    private var distanceText: String? {
        guard let userLoc = userLocation else { return nil }
        let site = CLLocation(latitude: supercharger.latitude, longitude: supercharger.longitude)
        let metres = userLoc.distance(from: site)
        if metres < 1000 {
            return String(format: "%.0f m", metres)
        } else {
            return String(format: "%.1f km", metres / 1000)
        }
    }
}
