import SwiftUI
import SCData
import SCDomain

public struct StopDetailRow: View {
    public let stop: SuperchargerOnRoute

    public init(stop: SuperchargerOnRoute) {
        self.stop = stop
    }

    public var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "bolt.fill")
                .foregroundStyle(.blue)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(stop.supercharger.name).font(.subheadline.weight(.medium))
                Text("\(stop.supercharger.stallCount) stalls · \(stop.supercharger.maxKilowatts) kW · \(String(format: "+%.1f km", stop.deviationKm)) off route")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("→ \(stop.recommendedChargeToSoc)%").font(.caption.bold())
                Text("~\(stop.estimatedChargeMinutes) min").font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
