import SwiftUI
import SCData

public struct SettingsView: View {
    @Environment(\.teslaIsAuthenticated) private var teslaIsAuthenticated
    @Environment(\.teslaSignIn) private var teslaSignIn
    @Environment(\.teslaSignOut) private var teslaSignOut

    private let appVersion: String = {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }()

    public init() {}

    public var body: some View {
        NavigationStack {
            Form {
                Section("Tesla Account") {
                    if teslaIsAuthenticated {
                        HStack {
                            Label("Connected", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Spacer()
                            Button("Disconnect", role: .destructive) {
                                Task { await teslaSignOut() }
                            }
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Connect your Tesla account for real-time stall availability.")
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

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(appVersion)
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Data")
                        Spacer()
                        Text("supercharge.info")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Weather")
                        Spacer()
                        Text("MET Norway")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
