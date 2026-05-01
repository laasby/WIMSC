import SwiftUI
import SCData

/// A circular badge shown on the map when multiple Superchargers are grouped into a cluster.
/// Tapping it zooms into the cluster area.
struct ClusterMarkerView: View {
    let count: Int
    let generation: ChargerGeneration
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(GenerationPinStyle.color(for: generation).opacity(0.9))
                    .frame(width: diameter, height: diameter)
                    .shadow(radius: 3)

                VStack(spacing: 0) {
                    Text("⚡")
                        .font(.system(size: fontSize * 0.75))
                    Text("\(count)")
                        .font(.system(size: fontSize, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(count) Superchargers")
        .accessibilityHint("Tap to zoom in")
    }

    /// Scale the cluster badge with count — larger clusters get slightly bigger badges.
    private var diameter: CGFloat {
        switch count {
        case ..<5:   return 40
        case 5..<15: return 48
        case 15..<50: return 56
        default:     return 64
        }
    }

    private var fontSize: CGFloat { diameter * 0.28 }
}
