import SwiftUI

public struct SettingsView: View {
    private let appVersion: String = {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }()

    @Environment(\.teslaIsSignedIn) private var isSignedIn
    @Environment(\.teslaIsLoading) private var isLoading
    @Environment(\.teslaErrorMessage) private var errorMessage
    @Environment(\.teslaSignIn) private var signIn
    @Environment(\.teslaSignOut) private var signOut

    public init() {}

    public var body: some View {
        NavigationStack {
            Form {
                teslaSection
                aboutSection
            }
            .navigationTitle("Settings")
        }
    }

    // MARK: - Tesla account section

    private var teslaSection: some View {
        Section {
            if isSignedIn {
                HStack {
                    Label("Connected", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Spacer()
                    Button("Sign Out", role: .destructive) {
                        Task { await signOut?() }
                    }
                }
                Text("Live stall availability is active.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Connect your Tesla account to see live stall availability on the map and in detail views.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Button {
                        Task { await signIn?() }
                    } label: {
                        if isLoading {
                            HStack {
                                ProgressView()
                                Text("Signing in…")
                            }
                            .frame(maxWidth: .infinity)
                        } else {
                            Label("Sign in with Tesla", systemImage: "bolt.fill")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isLoading)
                }
                .padding(.vertical, 4)

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        } header: {
            Text("Tesla Account")
        } footer: {
            if !isSignedIn {
                Text("Requires a Tesla account and a registered app at developer.tesla.com.")
            }
        }
    }

    // MARK: - About section

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text(appVersion).foregroundStyle(.secondary)
            }
            HStack {
                Text("Data")
                Spacer()
                Text("supercharge.info").foregroundStyle(.secondary)
            }
            HStack {
                Text("Weather")
                Spacer()
                Text("MET Norway").foregroundStyle(.secondary)
            }
        }
    }
}
