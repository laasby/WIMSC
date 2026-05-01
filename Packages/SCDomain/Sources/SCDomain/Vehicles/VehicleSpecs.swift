import Foundation
import SCData

/// Default specifications for known Tesla models.
/// Used to pre-fill the "Add Vehicle" form.
public struct VehicleSpec {
    public let model: TeslaModel
    public let displayName: String
    public let batteryCapacityKwh: Double
    public let defaultEfficiencyWhPerKm: Double
    public let defaultWheelSizeInches: Int
    public let maxChargeRateKw: Int

    public init(
        model: TeslaModel,
        displayName: String,
        batteryCapacityKwh: Double,
        defaultEfficiencyWhPerKm: Double,
        defaultWheelSizeInches: Int,
        maxChargeRateKw: Int
    ) {
        self.model = model
        self.displayName = displayName
        self.batteryCapacityKwh = batteryCapacityKwh
        self.defaultEfficiencyWhPerKm = defaultEfficiencyWhPerKm
        self.defaultWheelSizeInches = defaultWheelSizeInches
        self.maxChargeRateKw = maxChargeRateKw
    }
}

public enum VehicleSpecs {
    public static let all: [VehicleSpec] = [
        VehicleSpec(model: .model3,     displayName: "Model 3",    batteryCapacityKwh: 75,  defaultEfficiencyWhPerKm: 155, defaultWheelSizeInches: 18, maxChargeRateKw: 250),
        VehicleSpec(model: .modelY,     displayName: "Model Y",    batteryCapacityKwh: 75,  defaultEfficiencyWhPerKm: 165, defaultWheelSizeInches: 19, maxChargeRateKw: 250),
        VehicleSpec(model: .modelS,     displayName: "Model S",    batteryCapacityKwh: 100, defaultEfficiencyWhPerKm: 175, defaultWheelSizeInches: 19, maxChargeRateKw: 250),
        VehicleSpec(model: .modelX,     displayName: "Model X",    batteryCapacityKwh: 100, defaultEfficiencyWhPerKm: 195, defaultWheelSizeInches: 20, maxChargeRateKw: 250),
        VehicleSpec(model: .cybertruck, displayName: "Cybertruck", batteryCapacityKwh: 123, defaultEfficiencyWhPerKm: 220, defaultWheelSizeInches: 20, maxChargeRateKw: 250),
        VehicleSpec(model: .semi,       displayName: "Semi",       batteryCapacityKwh: 900, defaultEfficiencyWhPerKm: 800, defaultWheelSizeInches: 22, maxChargeRateKw: 1000),
    ]

    public static func spec(for model: TeslaModel) -> VehicleSpec? {
        all.first { $0.model == model }
    }
}
