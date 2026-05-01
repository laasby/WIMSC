import Foundation
import SwiftData

/// A user-registered Tesla vehicle used for range and charging calculations.
@Model
public final class UserVehicle {
    public var id: UUID
    public var name: String
    public var model: TeslaModel
    public var batteryCapacityKwh: Double
    /// Typical real-world efficiency in Wh/km.
    public var efficiencyWhPerKm: Double
    public var wheelSizeInches: Int
    /// Minimum desired state of charge on arrival (0–100%).
    public var preferredMinArrivalSoc: Int
    public var isDefault: Bool

    public init(
        id: UUID = UUID(),
        name: String,
        model: TeslaModel,
        batteryCapacityKwh: Double,
        efficiencyWhPerKm: Double,
        wheelSizeInches: Int,
        preferredMinArrivalSoc: Int = 10,
        isDefault: Bool = false
    ) {
        self.id = id
        self.name = name
        self.model = model
        self.batteryCapacityKwh = batteryCapacityKwh
        self.efficiencyWhPerKm = efficiencyWhPerKm
        self.wheelSizeInches = wheelSizeInches
        self.preferredMinArrivalSoc = preferredMinArrivalSoc
        self.isDefault = isDefault
    }
}
