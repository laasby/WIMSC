import SwiftUI
import SwiftData
import SCData

@main
struct WIMSCApp: App {
    private let container: ModelContainer
    private let sharedModelContext: ModelContext
    @State private var syncEngine: SyncEngine
    @State private var teslaAuthService = TeslaAuthService()
    @State private var liveAvailabilityStore = LiveAvailabilityStore()

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
            ContentView()
                .modelContainer(container)
                .environment(liveAvailabilityStore)
                .environment(\.teslaIsAuthenticated, teslaAuthService.isAuthenticated)
                .environment(\.teslaSignIn) { [teslaAuthService] in
                    await teslaAuthService.signIn()
                }
                .environment(\.teslaSignOut) { [teslaAuthService] in
                    await teslaAuthService.signOut()
                }
                .onChange(of: teslaAuthService.isAuthenticated) { _, isAuth in
                    if isAuth {
                        liveAvailabilityStore.tokenProvider = { [weak teslaAuthService] in
                            guard let svc = teslaAuthService else { throw TeslaAuthError.notAuthenticated }
                            return try await svc.refreshIfNeeded()
                        }
                    } else {
                        liveAvailabilityStore.tokenProvider = nil
                        liveAvailabilityStore.availability = [:]
                    }
                }
                .task {
                    BundledDataLoader.seedIfNeeded(into: sharedModelContext)
                    if syncEngine.needsSync {
                        await syncEngine.syncAll()
                    }
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
