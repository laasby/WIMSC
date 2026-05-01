import SwiftUI
import CoreLocation
import SCData

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
