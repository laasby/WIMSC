import SwiftUI
import SCData
import SCDomain

/// Shows current spot price context and the home-vs-Supercharger arbitrage recommendation.
public struct SpotPriceView: View {
    public let arbitrageResult: ArbitrageResult?
    public let currentPrices: [HourlyPrice]
    public let selectedZone: NOPriceZone

    public init(
        arbitrageResult: ArbitrageResult?,
        currentPrices: [HourlyPrice],
        selectedZone: NOPriceZone
    ) {
        self.arbitrageResult = arbitrageResult
        self.currentPrices = currentPrices
        self.selectedZone = selectedZone
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let result = arbitrageResult {
                arbitrageBanner(result)
            }

            if !currentPrices.isEmpty {
                priceChart
            }
        }
    }

    @ViewBuilder
    private func arbitrageBanner(_ result: ArbitrageResult) -> some View {
        HStack(spacing: 10) {
            Image(systemName: arbitrageIcon(result))
                .font(.title2)
                .foregroundStyle(arbitrageColor(result))

            VStack(alignment: .leading, spacing: 2) {
                Text(arbitrageHeadline(result))
                    .font(.subheadline.weight(.semibold))
                Text(arbitrageSubtitle(result))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(arbitrageColor(result).opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
    }

    private var priceChart: some View {
        let maxPrice = currentPrices.map(\.nokPerKwh).max() ?? 1
        return VStack(alignment: .leading, spacing: 6) {
            Text("Today's prices — \(selectedZone.displayName)")
                .font(.caption)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .bottom, spacing: 3) {
                    ForEach(currentPrices) { hour in
                        let isNow = Calendar.current.isDate(hour.startsAt, equalTo: .now, toGranularity: .hour)
                        VStack(spacing: 2) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(isNow ? Color.blue : Color.gray.opacity(0.4))
                                .frame(width: 16, height: max(4, CGFloat(hour.nokPerKwh / maxPrice) * 50))
                            Text(hourLabel(hour.startsAt))
                                .font(.system(size: 8))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
            .frame(height: 70)
        }
    }

    private func hourLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH"
        return formatter.string(from: date)
    }

    private func arbitrageIcon(_ result: ArbitrageResult) -> String {
        switch result.recommendation {
        case .superchargeNow: return "bolt.fill"
        case .chargeAtHome:   return "house.fill"
        case .comparable:     return "equal.circle"
        }
    }

    private func arbitrageColor(_ result: ArbitrageResult) -> Color {
        switch result.recommendation {
        case .superchargeNow: return .blue
        case .chargeAtHome:   return .green
        case .comparable:     return .orange
        }
    }

    private func arbitrageHeadline(_ result: ArbitrageResult) -> String {
        switch result.recommendation {
        case .superchargeNow(let r): return r
        case .chargeAtHome(let r):   return r
        case .comparable(let r):     return r
        }
    }

    private func arbitrageSubtitle(_ result: ArbitrageResult) -> String {
        if let sc = result.superchargerCostPerKwh, let home = result.homeCostPerKwh {
            return String(format: "SC: %.2f kr/kWh  ·  Home: %.2f kr/kWh", sc, home)
        }
        return ""
    }
}
