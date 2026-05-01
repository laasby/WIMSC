import Foundation
import SCData

/// Answers: "Should I Supercharge here, or drive home and charge there?"
public struct ArbitrageResult {
    public enum Recommendation {
        case superchargeNow(reason: String)
        case chargeAtHome(reason: String)
        case comparable(reason: String)
    }

    public var recommendation: Recommendation
    public var superchargerCostPerKwh: Double?
    public var homeCostPerKwh: Double?
    /// Positive = home is cheaper.
    public var savingsPerKwh: Double?
    public var currency: String = "NOK"

    public init(
        recommendation: Recommendation,
        superchargerCostPerKwh: Double? = nil,
        homeCostPerKwh: Double? = nil,
        savingsPerKwh: Double? = nil,
        currency: String = "NOK"
    ) {
        self.recommendation = recommendation
        self.superchargerCostPerKwh = superchargerCostPerKwh
        self.homeCostPerKwh = homeCostPerKwh
        self.savingsPerKwh = savingsPerKwh
        self.currency = currency
    }
}

public enum ArbitrageCalculator {

    /// Given the current Supercharger's pricing, tonight's spot prices, and home charger efficiency,
    /// recommend whether to Supercharge now or wait and charge at home.
    ///
    /// - Parameters:
    ///   - supercharger: The Supercharger being evaluated.
    ///   - tonightPrices: Hourly prices for the user's home zone (tonight = next 8 hours).
    ///   - homeChargerEfficiencyPercent: Home charger round-trip efficiency (default 90%).
    ///   - gridFeeNokPerKwh: Fixed grid fee added on top of spot price (default 0.05 NOK/kWh).
    public static func calculate(
        supercharger: Supercharger,
        tonightPrices: [HourlyPrice],
        homeChargerEfficiencyPercent: Double = 90,
        gridFeeNokPerKwh: Double = 0.05
    ) -> ArbitrageResult {
        // Need a NOK per-kWh price from the Supercharger.
        guard
            let pricing = supercharger.pricing,
            let scRaw = pricing.perKwh,
            pricing.currency == "NOK"
        else {
            return ArbitrageResult(
                recommendation: .comparable(reason: "Supercharger pricing unavailable"),
                currency: "NOK"
            )
        }
        let scCost = scRaw

        // Find the cheapest hour in the next 8 hours.
        let now = Date()
        let eightHoursFromNow = now.addingTimeInterval(8 * 3600)
        let upcoming = tonightPrices.filter { $0.startsAt >= now && $0.startsAt <= eightHoursFromNow }

        guard let cheapestHour = upcoming.min(by: { $0.nokPerKwh < $1.nokPerKwh }) else {
            return ArbitrageResult(
                recommendation: .superchargeNow(reason: "No home price data — charge now"),
                superchargerCostPerKwh: scCost,
                currency: "NOK"
            )
        }

        // Adjust for charger efficiency and grid fee.
        let homeCost = (cheapestHour.nokPerKwh / (homeChargerEfficiencyPercent / 100.0)) + gridFeeNokPerKwh
        let savings = scCost - homeCost
        let threshold = 0.15 // 15% difference triggers a recommendation

        let recommendation: ArbitrageResult.Recommendation
        if homeCost < scCost * (1 - threshold) {
            let fmt = String(format: "%.2f", savings)
            recommendation = .chargeAtHome(reason: "Home charging saves \(fmt) kr/kWh tonight")
        } else if scCost <= homeCost {
            recommendation = .superchargeNow(reason: "Supercharging is cheaper than home tonight")
        } else {
            recommendation = .comparable(reason: "Costs are within 15% — either option is fine")
        }

        return ArbitrageResult(
            recommendation: recommendation,
            superchargerCostPerKwh: scCost,
            homeCostPerKwh: homeCost,
            savingsPerKwh: savings,
            currency: "NOK"
        )
    }
}
