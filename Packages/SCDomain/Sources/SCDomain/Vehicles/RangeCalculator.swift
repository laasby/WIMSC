import Foundation
import SCData

/// Calculates range, stop estimates, and ETA adjustments per vehicle.
public enum RangeCalculator {

    /// Estimated range in km for a given vehicle and SoC.
    public static func rangeKm(
        vehicle: UserVehicle,
        currentSocPercent: Int,
        ambientCelsius: Double = 15
    ) -> Double {
        let baseRange = (vehicle.batteryCapacityKwh * 1000.0 / vehicle.efficiencyWhPerKm)
            * (Double(currentSocPercent) / 100.0)

        let temperatureFactor: Double
        if ambientCelsius < 0 {
            temperatureFactor = 0.8
        } else if ambientCelsius > 20 {
            temperatureFactor = 1.02
        } else {
            temperatureFactor = 1.0
        }
        return baseRange * temperatureFactor
    }

    /// Whether the vehicle can reach a destination without stopping.
    public static func canReach(
        vehicle: UserVehicle,
        currentSocPercent: Int,
        distanceKm: Double,
        arrivalSocPercent: Int,
        ambientCelsius: Double = 15
    ) -> Bool {
        let availableRange = rangeKm(vehicle: vehicle, currentSocPercent: currentSocPercent, ambientCelsius: ambientCelsius)
        let minReserveRange = rangeKm(vehicle: vehicle, currentSocPercent: arrivalSocPercent, ambientCelsius: ambientCelsius)
        return availableRange - minReserveRange >= distanceKm
    }

    /// Estimated charge time in minutes to reach target SoC at a given charger generation.
    public static func estimatedChargeMinutes(
        vehicle: UserVehicle,
        fromSoc: Int,
        toSoc: Int,
        chargerGeneration: ChargerGeneration,
        ambientCelsius: Double = 15
    ) -> Int {
        guard toSoc > fromSoc else { return 0 }
        let kwhNeeded = vehicle.batteryCapacityKwh * Double(toSoc - fromSoc) / 100.0
        let efficiency = 0.92
        let chargerMaxKw = Double(chargerGeneration.maxKilowatts)
        let hours = kwhNeeded / (chargerMaxKw * efficiency)
        return Int((hours * 60).rounded(.up))
    }

    /// Human-readable range string e.g. "~312 km remaining"
    public static func rangeDescription(
        vehicle: UserVehicle,
        currentSocPercent: Int,
        ambientCelsius: Double = 15
    ) -> String {
        let km = rangeKm(vehicle: vehicle, currentSocPercent: currentSocPercent, ambientCelsius: ambientCelsius)
        return "~\(Int(km.rounded())) km remaining"
    }
}
