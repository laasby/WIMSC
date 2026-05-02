import SwiftUI
import SwiftData
import SCData

@main
struct WIMSCApp: App {
    private let container: ModelContainer
    private let sharedModelContext: ModelContext
    @State private var syncEngine: SyncEngine

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
                .task {
                    BundledDataLoader.seedIfNeeded(into: sharedModelContext)
                    if syncEngine.needsSync {
                        await syncEngine.syncAll()
                    }
                }
        }
    }
}
