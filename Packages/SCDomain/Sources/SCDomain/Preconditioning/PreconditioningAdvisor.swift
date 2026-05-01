import Foundation
import SCData

/// Advises when and whether to trigger Tesla battery preconditioning before arriving at a Supercharger.
public struct PreconditioningAdvice {
    /// Whether preconditioning is recommended.
    public var shouldPrecondition: Bool
    /// How many km before the Supercharger the driver should trigger preconditioning.
    public var triggerDistanceKm: Double
    /// How many minutes before arrival to trigger (depends on speed).
    public var triggerMinutesBefore: Int
    /// Expected peak kW without preconditioning.
    public var coldPeakKw: Int
    /// Expected peak kW with preconditioning.
    public var warmPeakKw: Int
    /// SoC penalty estimate in % points lost to preconditioning (heating the pack).
    public var socCostPercent: Double
    /// Human-readable recommendation.
    public var message: String
}

public enum PreconditioningAdvisor {

    /// Compute a preconditioning recommendation.
    ///
    /// - Parameters:
    ///   - destination: The target Supercharger
    ///   - ambientCelsius: Current/forecast ambient temperature
    ///   - vehicle: The selected vehicle (nil = use generic estimate)
    ///   - distanceToChargerKm: Remaining distance to the Supercharger
    ///   - averageSpeedKmh: Expected average driving speed (default 80 km/h)
    public static func advise(
        destination: Supercharger,
        ambientCelsius: Double,
        vehicle: UserVehicle?,
        distanceToChargerKm: Double,
        averageSpeedKmh: Double = 80
    ) -> PreconditioningAdvice {
        let generation = destination.generation

        guard ambientCelsius < 5 else {
            return PreconditioningAdvice(
                shouldPrecondition: false,
                triggerDistanceKm: 0,
                triggerMinutesBefore: 0,
                coldPeakKw: generation.maxKilowatts,
                warmPeakKw: generation.maxKilowatts,
                socCostPercent: 0,
                message: "Battery is warm — no preconditioning needed"
            )
        }

        let coldPeakKw = ColdSoakEstimator.estimatedPeakKilowatts(
            ambientCelsius: ambientCelsius,
            generation: generation,
            preconditioned: false
        )
        let warmPeakKw = ColdSoakEstimator.estimatedPeakKilowatts(
            ambientCelsius: ambientCelsius,
            generation: generation,
            preconditioned: true
        )

        var warmupMinutes = Double(ColdSoakEstimator.warmupMinutes(ambientCelsius: ambientCelsius))

        switch generation {
        case .v4:
            warmupMinutes *= 1.2
        case .v2:
            warmupMinutes *= 0.7
        default:
            break
        }

        let triggerMinutesBefore = Int(warmupMinutes) + 5
        let triggerDistanceKm = (Double(triggerMinutesBefore) / 60.0) * averageSpeedKmh

        let batteryKwh = vehicle?.batteryCapacityKwh ?? 75.0
        let socCostPercent = (warmupMinutes / 60.0) * 3.5 / batteryKwh * 100

        let shouldPrecondition = coldPeakKw < Int(Double(warmPeakKw) * 0.85)

        let message: String
        if distanceToChargerKm < triggerDistanceKm {
            message = "Start preconditioning now — \(String(format: "%.0f", distanceToChargerKm)) km remaining"
        } else {
            message = "Start preconditioning in \(String(format: "%.0f", triggerDistanceKm)) km / \(triggerMinutesBefore) min for full \(generation.rawValue.uppercased()) speed (\(warmPeakKw) kW vs \(coldPeakKw) kW cold)"
        }

        return PreconditioningAdvice(
            shouldPrecondition: shouldPrecondition,
            triggerDistanceKm: triggerDistanceKm,
            triggerMinutesBefore: triggerMinutesBefore,
            coldPeakKw: coldPeakKw,
            warmPeakKw: warmPeakKw,
            socCostPercent: socCostPercent,
            message: message
        )
    }
}
