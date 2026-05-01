import SwiftUI
import SCData

/// Map pin that overlays a colored availability dot when live data is available.
struct AvailabilityPinView: View {
    let stallCount: Int
    let generation: ChargerGeneration
    let availableStalls: Int
    let totalStalls: Int

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(systemName: GenerationPinStyle.systemImage(for: generation))
                .font(.title2)
                .foregroundStyle(GenerationPinStyle.color(for: generation))
                .padding(6)
                .background(.background, in: Circle())
                .shadow(radius: 2)

            Circle()
                .fill(availabilityColor)
                .frame(width: 12, height: 12)
                .overlay(Circle().stroke(.background, lineWidth: 1.5))
                .offset(x: 4, y: -4)
        }
    }

    private var availabilityColor: Color {
        guard totalStalls > 0 else { return .gray }
        let ratio = Double(availableStalls) / Double(totalStalls)
        if ratio > 0.5 { return .green }
        if ratio > 0.2 { return .yellow }
        return .red
    }
}
