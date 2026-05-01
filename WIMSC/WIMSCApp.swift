import SwiftUI
import SwiftData
import SCData

@main
struct WIMSCApp: App {
    private let container: ModelContainer
    @State private var syncEngine: SyncEngine
    @State private var cloudSyncManager = CloudSyncManager()

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
                .task {
                    BundledDataLoader.seedIfNeeded(into: ModelContext(container))
                    if syncEngine.needsSync {
                        await syncEngine.syncAll()
                    }
                }
        }
    }
}
