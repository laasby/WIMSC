import SwiftUI
import SCData
import SCDomain

public struct VehicleRow: View {
    public let vehicle: UserVehicle

    public init(vehicle: UserVehicle) {
        self.vehicle = vehicle
    }

    public var body: some View {
        HStack(spacing: 12) {
            Image(systemName: modelIcon(vehicle.model))
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(vehicle.name)
                        .font(.headline)
                    if vehicle.isDefault {
                        Text("Default")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue, in: Capsule())
                    }
                }
                Text("\(modelDisplayName(vehicle.model)) · \(Int(vehicle.batteryCapacityKwh)) kWh · \(vehicle.wheelSizeInches)\"")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func modelIcon(_ model: TeslaModel) -> String {
        switch model {
        case .model3, .modelY, .modelS, .modelX: return "car.fill"
        case .cybertruck: return "truck.box.fill"
        case .semi: return "truck.box.badge.clock.fill"
        }
    }

    private func modelDisplayName(_ model: TeslaModel) -> String {
        VehicleSpecs.spec(for: model)?.displayName ?? model.rawValue
    }
}
