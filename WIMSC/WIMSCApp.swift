import SwiftUI
import SwiftData
import SCData

@main
struct WIMSCApp: App {
    private let container: ModelContainer
    @State private var syncEngine: SyncEngine

    @MainActor
    init() {
        do {
            let c = try ModelContainerFactory.makeContainer()
            container = c
            _syncEngine = State(wrappedValue: SyncEngine(
                superchargeClient: SuperchargeInfoClient(),
                teslaClient: TeslaFindUsClient(),
                modelContext: ModelContext(c)
            ))
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
                .task {
                    if syncEngine.needsSync {
                        await syncEngine.syncAll()
                    }
                }
        }
    }
}
