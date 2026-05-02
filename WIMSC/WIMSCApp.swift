import SwiftUI
import SwiftData
import SCData

@main
struct WIMSCApp: App {
    private let container: ModelContainer
    private let sharedModelContext: ModelContext
    @State private var syncEngine: SyncEngine
    @State private var teslaAuth = TeslaAuthService()
    @State private var liveStore = LiveAvailabilityStore()

    @MainActor
    init() {
        do {
            let c = try ModelContainerFactory.makeContainer()
            container = c
            let ctx = ModelContext(c)
            sharedModelContext = ctx
            syncEngine = SyncEngine(
                superchargeClient: SuperchargeInfoClient(),
                teslaClient: TeslaFindUsClient(),
                modelContext: ctx
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            AppRootView(
                container: container,
                sharedModelContext: sharedModelContext,
                syncEngine: syncEngine,
                teslaAuth: teslaAuth,
                liveStore: liveStore
            )
        }
    }
}

// MARK: - Root view wrapper

private struct AppRootView: View {
    let container: ModelContainer
    let sharedModelContext: ModelContext
    let syncEngine: SyncEngine
    let teslaAuth: TeslaAuthService
    let liveStore: LiveAvailabilityStore

    var body: some View {
        ContentView()
            .modelContainer(container)
            .modifier(TeslaEnvironmentModifier(teslaAuth: teslaAuth, liveStore: liveStore))
            .task {
                BundledDataLoader.seedIfNeeded(into: sharedModelContext)
                if syncEngine.needsSync {
                    await syncEngine.syncAll()
                }
            }
    }
}

// MARK: - Tesla environment modifier
// Using a ViewModifier lets the compiler type-check each .environment call independently.
// @MainActor ensures TeslaAuthService (also @MainActor) is safely captured in @Sendable closures.

@MainActor
private struct TeslaEnvironmentModifier: ViewModifier {
    let teslaAuth: TeslaAuthService
    let liveStore: LiveAvailabilityStore

    func body(content: Content) -> some View {
        content
            .environment(\.teslaIsSignedIn, teslaAuth.isSignedIn)
            .environment(\.teslaIsLoading, teslaAuth.isLoading)
            .environment(\.teslaErrorMessage, teslaAuth.errorMessage)
            .environment(\.teslaSignIn, makeSignIn())
            .environment(\.teslaSignOut, makeSignOut())
            .environment(\.teslaTokenProvider, makeTokenProvider())
            .environment(\.liveAvailability, teslaAuth.isSignedIn ? liveStore : nil)
    }

    private func makeSignIn() -> @Sendable () async -> Void {
        let auth = teslaAuth
        return { await auth.signIn() }
    }

    private func makeSignOut() -> @Sendable () async -> Void {
        let auth = teslaAuth
        return { await auth.signOut() }
    }

    private func makeTokenProvider() -> (@Sendable () async throws -> String)? {
        guard teslaAuth.isSignedIn else { return nil }
        let auth = teslaAuth
        return { try await auth.validAccessToken() }
    }
}
