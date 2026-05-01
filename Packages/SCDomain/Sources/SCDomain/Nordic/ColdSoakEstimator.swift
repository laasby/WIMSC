import Foundation
import SCData

/// Estimates the charging speed penalty due to cold battery temperature.
public enum ColdSoakEstimator {

    private struct PenaltyLevel {
        let minTemp: Double
        let penaltyPercent: Double
        let warmupMinutes: Int
    }

    private static let levels: [PenaltyLevel] = [
        PenaltyLevel(minTemp:  5.0, penaltyPercent:  0, warmupMinutes:  0),
        PenaltyLevel(minTemp:  0.0, penaltyPercent: 10, warmupMinutes:  5),
        PenaltyLevel(minTemp: -10.0, penaltyPercent: 25, warmupMinutes: 15),
        PenaltyLevel(minTemp: -20.0, penaltyPercent: 45, warmupMinutes: 30),
        PenaltyLevel(minTemp: -.infinity, penaltyPercent: 60, warmupMinutes: 45),
    ]

    /// Returns an estimated peak kW achievable given ambient temperature and charger generation.
    public static func estimatedPeakKilowatts(
        ambientCelsius: Double,
        generation: ChargerGeneration,
        preconditioned: Bool = false
    ) -> Int {
        let maxKw = generation.maxKilowatts
        guard !preconditioned else { return maxKw }
        let penalty = penaltyPercent(for: ambientCelsius)
        return Int(Double(maxKw) * (1.0 - penalty / 100.0))
    }

    /// Returns approximate time in minutes to reach normal charging speed from cold-soaked state.
    public static func warmupMinutes(ambientCelsius: Double) -> Int {
        level(for: ambientCelsius).warmupMinutes
    }

    /// Returns a human-readable warning string if conditions warrant it; nil above 5°C.
    public static func warningMessage(ambientCelsius: Double, generation: ChargerGeneration) -> String? {
        guard ambientCelsius < 5.0 else { return nil }
        let peak = estimatedPeakKilowatts(ambientCelsius: ambientCelsius, generation: generation)
        let warmup = warmupMinutes(ambientCelsius: ambientCelsius)
        let penalty = penaltyPercent(for: ambientCelsius)
        return String(
            format: "Cold battery at %.0f°C: expect ~%d kW peak (%.0f%% penalty). "
                  + "Allow ~%d min warm-up for full speed. Preconditioning eliminates this penalty.",
            ambientCelsius, peak, penalty, warmup
        )
    }

    // MARK: - Private helpers

    private static func level(for temp: Double) -> PenaltyLevel {
        levels.first { temp >= $0.minTemp } ?? levels.last!
    }

    private static func penaltyPercent(for temp: Double) -> Double {
        level(for: temp).penaltyPercent
    }
}
