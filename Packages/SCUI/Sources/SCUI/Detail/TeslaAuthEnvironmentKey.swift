import SwiftUI

// MARK: - isAuthenticated

private struct TeslaIsAuthenticatedKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

// MARK: - signIn

private struct TeslaSignInKey: EnvironmentKey {
    static let defaultValue: @Sendable () async -> Void = {}
}

// MARK: - signOut

private struct TeslaSignOutKey: EnvironmentKey {
    static let defaultValue: @Sendable () -> Void = {}
}

public extension EnvironmentValues {
    var teslaIsAuthenticated: Bool {
        get { self[TeslaIsAuthenticatedKey.self] }
        set { self[TeslaIsAuthenticatedKey.self] = newValue }
    }

    var teslaSignIn: @Sendable () async -> Void {
        get { self[TeslaSignInKey.self] }
        set { self[TeslaSignInKey.self] = newValue }
    }

    var teslaSignOut: @Sendable () -> Void {
        get { self[TeslaSignOutKey.self] }
        set { self[TeslaSignOutKey.self] = newValue }
    }
}
