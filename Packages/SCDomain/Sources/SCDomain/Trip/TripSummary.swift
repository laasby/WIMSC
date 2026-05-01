import Foundation
import SCData

/// Summary statistics for a planned trip.
public struct TripSummary {
    public var totalDistanceKm: Double
    public var drivingMinutes: Int
    public var numberOfStops: Int
    public var totalChargeMinutes: Int
    public var totalTripMinutes: Int
    public var estimatedCostNOK: Double?

    public static func from(plan: TripPlan) -> TripSummary {
        let numberOfStops = plan.recommendedStops.count
        let totalChargeMinutes = plan.recommendedStops.reduce(0) { $0 + $1.estimatedChargeMinutes }
        let totalTripMinutes = plan.estimatedDrivingMinutes + totalChargeMinutes

        var estimatedCostNOK: Double? = nil
        // Estimate cost from pricing info if available
        let pricePerKwh = plan.recommendedStops
            .compactMap { $0.supercharger.pricing?.perKwh }
            .first
        if let pricePerKwh {
            // Rough estimate: average energy per stop based on charge minutes is hard to know,
            // so we use a simple heuristic of 50 kWh per charging session at NOK rate.
            estimatedCostNOK = pricePerKwh * 50.0 * Double(numberOfStops)
        }

        return TripSummary(
            totalDistanceKm: plan.totalDistanceKm,
            drivingMinutes: plan.estimatedDrivingMinutes,
            numberOfStops: numberOfStops,
            totalChargeMinutes: totalChargeMinutes,
            totalTripMinutes: totalTripMinutes,
            estimatedCostNOK: estimatedCostNOK
        )
    }
}
