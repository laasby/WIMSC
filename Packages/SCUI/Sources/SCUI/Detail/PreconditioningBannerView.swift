import SwiftUI
import SCData
import SCDomain

/// Banner shown in the detail view when preconditioning is recommended.
public struct PreconditioningBannerView: View {
    public let advice: PreconditioningAdvice

    public init(advice: PreconditioningAdvice) {
        self.advice = advice
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: advice.shouldPrecondition ? "thermometer.sun.fill" : "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(advice.shouldPrecondition ? .orange : .blue)
                VStack(alignment: .leading, spacing: 2) {
                    Text(advice.shouldPrecondition ? "Preconditioning recommended" : "Battery warm enough")
                        .font(.subheadline.weight(.semibold))
                    Text(advice.message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if advice.shouldPrecondition {
                HStack(spacing: 16) {
                    VStack(spacing: 2) {
                        Text("\(advice.coldPeakKw) kW")
                            .font(.subheadline.bold())
                            .foregroundStyle(.orange)
                        Text("Cold").font(.caption2).foregroundStyle(.secondary)
                    }
                    Image(systemName: "arrow.right").foregroundStyle(.secondary)
                    VStack(spacing: 2) {
                        Text("\(advice.warmPeakKw) kW")
                            .font(.subheadline.bold())
                            .foregroundStyle(.blue)
                        Text("Preconditioned").font(.caption2).foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(spacing: 2) {
                        Text(String(format: "−%.1f%%", advice.socCostPercent))
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        Text("SoC cost").font(.caption2).foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 2)

                if advice.triggerDistanceKm > 0 {
                    Label("Trigger at \(String(format: "%.0f", advice.triggerDistanceKm)) km from charger (~\(advice.triggerMinutesBefore) min before)",
                          systemImage: "location.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .background(
            advice.shouldPrecondition
                ? Color.orange.opacity(0.1)
                : Color.blue.opacity(0.1),
            in: RoundedRectangle(cornerRadius: 10)
        )
    }
}
