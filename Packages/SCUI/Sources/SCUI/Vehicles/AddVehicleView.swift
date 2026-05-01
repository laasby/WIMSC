import SwiftUI
import SwiftData
import SCData
import SCDomain

public struct AddVehicleView: View {
    private let modelContext: ModelContext
    public var onSave: () -> Void

    @State private var name: String = ""
    @State private var selectedModel: TeslaModel = .model3
    @State private var batteryKwh: Double = 75
    @State private var efficiencyWhKm: Double = 155
    @State private var wheelSize: Int = 18
    @State private var minArrivalSoc: Int = 10
    @State private var isDefault: Bool = false

    public init(modelContext: ModelContext, onSave: @escaping () -> Void) {
        self.modelContext = modelContext
        self.onSave = onSave
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. KALM3", text: $name)
                        .autocorrectionDisabled()
                }

                Section("Model") {
                    Picker("Tesla model", selection: $selectedModel) {
                        ForEach(TeslaModel.allCases, id: \.self) { m in
                            Text(VehicleSpecs.spec(for: m)?.displayName ?? m.rawValue).tag(m)
                        }
                    }
                    .onChange(of: selectedModel) { _, model in
                        if let spec = VehicleSpecs.spec(for: model) {
                            batteryKwh = spec.batteryCapacityKwh
                            efficiencyWhKm = spec.defaultEfficiencyWhPerKm
                            wheelSize = spec.defaultWheelSizeInches
                        }
                    }
                }

                Section("Battery & Efficiency") {
                    HStack {
                        Text("Battery capacity (kWh)")
                        Spacer()
                        TextField("75", value: $batteryKwh, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                    }
                    HStack {
                        Text("Efficiency (Wh/km)")
                        Spacer()
                        TextField("155", value: $efficiencyWhKm, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                    }
                    HStack {
                        Text("Wheel size (inches)")
                        Spacer()
                        Stepper("\(wheelSize)\"", value: $wheelSize, in: 16...24)
                    }
                }

                Section("Preferences") {
                    HStack {
                        Text("Min arrival SoC (%)")
                        Spacer()
                        Stepper("\(minArrivalSoc)%", value: $minArrivalSoc, in: 5...30, step: 5)
                    }
                    Toggle("Set as default vehicle", isOn: $isDefault)
                }
            }
            .navigationTitle("Add Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onSave() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let service = VehicleService(modelContext: modelContext)
        try? service.addVehicle(
            name: name.trimmingCharacters(in: .whitespaces),
            model: selectedModel,
            batteryCapacityKwh: batteryKwh,
            efficiencyWhPerKm: efficiencyWhKm,
            wheelSizeInches: wheelSize,
            preferredMinArrivalSoc: minArrivalSoc
        )
        if isDefault {
            try? service.load()
            if let v = service.vehicles.last {
                try? service.setDefault(v)
            }
        }
        onSave()
    }
}
