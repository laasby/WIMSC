import SwiftUI
import CoreLocation
import SCData
import SCDomain

// MARK: - Generation stripe color

private extension ChargerGeneration {
    var stripeColor: Color {
        switch self {
        case .v2: return Color(red: 0/255, green: 119/255, blue: 187/255)   // #0077BB
        case .v3: return Color(red: 238/255, green: 119/255, blue: 51/255)  // #EE7733
        case .v4: return Color(red: 170/255, green: 51/255, blue: 119/255)  // #AA3377
        case .unknown: return Color.gray
        }
    }
}

// MARK: - Row

public struct SuperchargerRow: View {
    public let supercharger: Supercharger
    public let userLocation: CLLocation?

    public init(supercharger: Supercharger, userLocation: CLLocation?) {
        self.supercharger = supercharger
        self.userLocation = userLocation
    }

    public var body: some View {
        HStack(spacing: 12) {
            // Generation color stripe
            Rectangle()
                .fill(supercharger.generation.stripeColor)
                .frame(width: 4)
                .cornerRadius(2)
                .frame(maxHeight: .infinity)
                .accessibilityLabel("\(supercharger.generation.rawValue.uppercased()) charger")

            // Main content
            VStack(alignment: .leading, spacing: 3) {
                Text(supercharger.name)
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(locationLine)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                HStack(spacing: 6) {
                    Text("\(supercharger.stallCount) stalls · \(supercharger.maxKilowatts) kW")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if supercharger.hasMagicDock {
                        Text("MD")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.teal, in: Capsule())
                            .accessibilityLabel("Magic Dock")
                    }
                }
            }

            Spacer(minLength: 0)

            // Status dot
            Circle()
                .fill(supercharger.status.dotColor)
                .frame(width: 12, height: 12)
                .accessibilityLabel("Status: \(supercharger.status.displayName)")
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(rowAccessibilityLabel)
    }

    private var rowAccessibilityLabel: String {
        var parts = [supercharger.name, locationLine]
        parts.append("\(supercharger.stallCount) stalls, \(supercharger.maxKilowatts) kilowatts")
        parts.append("Status: \(supercharger.status.displayName)")
        if supercharger.hasMagicDock { parts.append("Magic Dock available") }
        return parts.joined(separator: ". ")
    }

    private var locationLine: String {
        let place = [supercharger.city, supercharger.country]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")

        let distanceStr: String
        if let loc = userLocation {
            let siteLoc = CLLocation(latitude: supercharger.latitude, longitude: supercharger.longitude)
            distanceStr = DistanceFormatter.string(from: siteLoc.distance(from: loc))
        } else {
            distanceStr = "—"
        }

        return "\(place) · \(distanceStr)"
    }
}
