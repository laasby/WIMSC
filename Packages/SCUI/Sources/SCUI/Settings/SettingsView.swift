import SwiftUI

public struct SettingsView: View {
    private let appVersion: String = {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }()

    public init() {}

    public var body: some View {
        NavigationStack {
            Form {
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
