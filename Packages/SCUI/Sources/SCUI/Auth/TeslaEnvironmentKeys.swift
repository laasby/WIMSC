import SwiftUI
import SCData

// MARK: - Token provider

public struct TeslaTokenProviderKey: EnvironmentKey {
    public static let defaultValue: (@Sendable () async throws -> String)? = nil
}

// MARK: - Sign-in / sign-out actions

public struct TeslaSignInKey: EnvironmentKey {
    public static let defaultValue: (@Sendable () async -> Void)? = nil
}

public struct TeslaSignOutKey: EnvironmentKey {
    public static let defaultValue: (@Sendable () async -> Void)? = nil
}

// MARK: - Auth state

public struct TeslaIsSignedInKey: EnvironmentKey {
    public static let defaultValue: Bool = false
}

public struct TeslaIsLoadingKey: EnvironmentKey {
    public static let defaultValue: Bool = false
}

public struct TeslaErrorMessageKey: EnvironmentKey {
    public static let defaultValue: String? = nil
}

// MARK: - Live availability store

public struct LiveAvailabilityStoreKey: EnvironmentKey {
    public static let defaultValue: LiveAvailabilityStore? = nil
}

// MARK: - EnvironmentValues extensions

public extension EnvironmentValues {
    var teslaTokenProvider: (@Sendable () async throws -> String)? {
        get { self[TeslaTokenProviderKey.self] }
        set { self[TeslaTokenProviderKey.self] = newValue }
    }

    var teslaSignIn: (@Sendable () async -> Void)? {
        get { self[TeslaSignInKey.self] }
        set { self[TeslaSignInKey.self] = newValue }
    }

    var teslaSignOut: (@Sendable () async -> Void)? {
        get { self[TeslaSignOutKey.self] }
        set { self[TeslaSignOutKey.self] = newValue }
    }

    var teslaIsSignedIn: Bool {
        get { self[TeslaIsSignedInKey.self] }
        set { self[TeslaIsSignedInKey.self] = newValue }
    }

    var teslaIsLoading: Bool {
        get { self[TeslaIsLoadingKey.self] }
        set { self[TeslaIsLoadingKey.self] = newValue }
    }

    var teslaErrorMessage: String? {
        get { self[TeslaErrorMessageKey.self] }
        set { self[TeslaErrorMessageKey.self] = newValue }
    }

    var liveAvailability: LiveAvailabilityStore? {
        get { self[LiveAvailabilityStoreKey.self] }
        set { self[LiveAvailabilityStoreKey.self] = newValue }
    }
}
