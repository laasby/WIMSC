import SwiftUI
import SCData
import SCDomain

public struct VehicleDetailView: View {
    public let vehicle: UserVehicle
    @State private var vehicleService: VehicleService
    @State private var currentSoc: Int = 80

    public init(vehicle: UserVehicle, vehicleService: VehicleService) {
        self.vehicle = vehicle
        _vehicleService = State(initialValue: vehicleService)
    }

    public var body: some View {
        Form {
            Section("Vehicle") {
                DetailRow(label: "Name", value: vehicle.name)
                DetailRow(label: "Model", value: VehicleSpecs.spec(for: vehicle.model)?.displayName ?? vehicle.model.rawValue)
                DetailRow(label: "Battery", value: "\(Int(vehicle.batteryCapacityKwh)) kWh")
                DetailRow(label: "Efficiency", value: "\(Int(vehicle.efficiencyWhPerKm)) Wh/km")
                DetailRow(label: "Wheels", value: "\(vehicle.wheelSizeInches)\"")
                DetailRow(label: "Min arrival SoC", value: "\(vehicle.preferredMinArrivalSoc)%")
            }

            Section("Range Estimate") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current SoC: \(currentSoc)%")
                        .font(.subheadline)
                    Slider(value: Binding(
                        get: { Double(currentSoc) },
                        set: { currentSoc = Int($0) }
                    ), in: 0...100, step: 5)
                    Text(RangeCalculator.rangeDescription(vehicle: vehicle, currentSocPercent: currentSoc))
                        .font(.headline)
                }
            }

            Section {
                if !vehicle.isDefault {
                    Button("Set as Default") {
                        try? vehicleService.setDefault(vehicle)
                    }
                }
            }
        }
        .navigationTitle(vehicle.name)
    }
}
