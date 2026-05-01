import SwiftUI
import SwiftData
import SCData

public struct SettingsView: View {
    @Environment(CloudSyncManager.self) private var cloudSyncManager
    @Environment(\.modelContext) private var modelContext
    @Environment(\.teslaIsAuthenticated) private var teslaIsAuthenticated
    @Environment(\.teslaSignIn) private var teslaSignIn
    @Environment(\.teslaSignOut) private var teslaSignOut
    @State private var showSyncRestartAlert = false
    @State private var tibberToken: String = ""
    @State private var homeChargerKw: Double = 11
    @State private var homeZone: NOPriceZone = .no1

    public init() {}

    public var body: some View {
        NavigationStack {
            Form {
                Section("Vehicles") {
                    NavigationLink("Manage vehicles") {
                        VehicleListView(modelContext: modelContext)
                    }
                }

                Section("Tesla Account") {
                    if teslaIsAuthenticated {
                        HStack {
                            Label("Connected", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Spacer()
                            Button("Disconnect", role: .destructive) {
                                teslaSignOut()
                            }
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Connect your Tesla account for real-time stall availability on the map and in station details.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Button {
                                Task { await teslaSignIn() }
                            } label: {
                                Label("Sign in with Tesla", systemImage: "bolt.car.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                        }
                        .padding(.vertical, 4)
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
                    Toggle("iCloud Sync", isOn: Binding(
                        get: { cloudSyncManager.isSyncEnabled },
                        set: { newValue in
                            cloudSyncManager.setSyncEnabled(newValue)
                            showSyncRestartAlert = true
                        }
                    ))
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
        .alert("Restart Required", isPresented: $showSyncRestartAlert) {
            Button("OK") {}
        } message: {
            Text("iCloud sync changes take effect after restarting the app.")
        }
    }
}
