import Foundation
import SwiftData
import SCData

/// Manages the user's paired vehicles.
@Observable
public final class VehicleService {
    private let modelContext: ModelContext
    public private(set) var vehicles: [UserVehicle] = []
    public private(set) var selectedVehicle: UserVehicle?

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    public func load() throws {
        let descriptor = FetchDescriptor<UserVehicle>(
            sortBy: [SortDescriptor(\.name)]
        )
        vehicles = try modelContext.fetch(descriptor)
        if selectedVehicle == nil {
            selectedVehicle = vehicles.first(where: \.isDefault) ?? vehicles.first
        }
    }

    public func addVehicle(
        name: String,
        model: TeslaModel,
        batteryCapacityKwh: Double,
        efficiencyWhPerKm: Double,
        wheelSizeInches: Int,
        preferredMinArrivalSoc: Int
    ) throws {
        let isFirst = vehicles.isEmpty
        let vehicle = UserVehicle(
            name: name,
            model: model,
            batteryCapacityKwh: batteryCapacityKwh,
            efficiencyWhPerKm: efficiencyWhPerKm,
            wheelSizeInches: wheelSizeInches,
            preferredMinArrivalSoc: preferredMinArrivalSoc,
            isDefault: isFirst
        )
        modelContext.insert(vehicle)
        try modelContext.save()
        try load()
    }

    public func deleteVehicle(_ vehicle: UserVehicle) throws {
        let wasDefault = vehicle.isDefault
        modelContext.delete(vehicle)
        try modelContext.save()
        try load()
        if wasDefault, let first = vehicles.first {
            try setDefault(first)
        }
    }

    public func setDefault(_ vehicle: UserVehicle) throws {
        for v in vehicles {
            v.isDefault = (v.id == vehicle.id)
        }
        try modelContext.save()
        selectedVehicle = vehicle
        try load()
    }

    public func selectVehicle(_ vehicle: UserVehicle) {
        selectedVehicle = vehicle
    }
}
