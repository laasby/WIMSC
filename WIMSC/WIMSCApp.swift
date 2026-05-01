import SwiftUI
import SwiftData
import SCData

@main
struct WIMSCApp: App {
    private let container: ModelContainer
    @State private var syncEngine: SyncEngine
    @State private var cloudSyncManager = CloudSyncManager()
    @State private var teslaAuthService = TeslaAuthService()
    @State private var liveAvailabilityStore = LiveAvailabilityStore()

    @MainActor
    init() {
        let mgr = CloudSyncManager()
        do {
            let c = try ModelContainerFactory.makeContainer(syncManager: mgr)
            container = c
            syncEngine = SyncEngine(
                superchargeClient: SuperchargeInfoClient(),
                teslaClient: TeslaFindUsClient(),
                modelContext: ModelContext(c)
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        _cloudSyncManager = State(wrappedValue: mgr)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
                .environment(cloudSyncManager)
                .environment(liveAvailabilityStore)
                .environment(\.teslaIsAuthenticated, teslaAuthService.isAuthenticated)
                .environment(\.teslaSignIn) {
                    await teslaAuthService.signIn()
                    if teslaAuthService.isAuthenticated {
                        liveAvailabilityStore.tokenProvider = { [weak teslaAuthService] in
                            guard let svc = teslaAuthService else { throw TeslaAuthError.notAuthenticated }
                            return try await svc.refreshIfNeeded()
                        }
                    }
                }
                .environment(\.teslaSignOut) {
                    teslaAuthService.signOut()
                    liveAvailabilityStore.tokenProvider = nil
                    liveAvailabilityStore.availability = [:]
                }
                .task {
                    BundledDataLoader.seedIfNeeded(into: ModelContext(container))
                    if syncEngine.needsSync {
                        await syncEngine.syncAll()
                    }
                    // Wire token provider if already authenticated from keychain
                    if teslaAuthService.isAuthenticated {
                        liveAvailabilityStore.tokenProvider = { [weak teslaAuthService] in
                            guard let svc = teslaAuthService else { throw TeslaAuthError.notAuthenticated }
                            return try await svc.refreshIfNeeded()
                        }
                    }
                }
        }
    }
}
