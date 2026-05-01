import SwiftUI
import SwiftData
import SCData

public struct SettingsView: View {
    @State private var tibberToken: String = ""
    @State private var homeChargerKw: Double = 11
    @State private var homeZone: NOPriceZone = .no1
    @State private var iCloudSyncEnabled: Bool = false

    public init() {}

    public var body: some View {
        NavigationStack {
            Form {
                Section("Vehicles") {
                    NavigationLink("Manage vehicles") {
                        Text("Vehicle management coming soon")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Home Charging") {
                    HStack {
                        Text("Charger power (kW)")
                        Spacer()
                        TextField("11", value: $homeChargerKw, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                    }
                    Picker("Price zone", selection: $homeZone) {
                        ForEach(NOPriceZone.allCases) { zone in
                            Text(zone.displayName).tag(zone)
                        }
                    }
                    SecureField("Tibber API token (optional)", text: $tibberToken)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section("Privacy & Sync") {
                    Toggle("iCloud Sync", isOn: $iCloudSyncEnabled)
                    NavigationLink("Your Data") {
                        YourDataView()
                    }
                }

                Section {
                    NavigationLink("Data Sources & Credits") {
                        CreditsView()
                    }
                }

                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
