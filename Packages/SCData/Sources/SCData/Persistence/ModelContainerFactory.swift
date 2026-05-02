import Foundation
import SwiftData

public enum ModelContainerFactory {
    private static var schema: Schema {
        Schema([
            Supercharger.self,
            SitePhoto.self,
            VisitRecord.self,
            StallReport.self,
            UserVehicle.self,
            StallAvailability.self,
        ])
    }

    public static func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // Schema changed and SwiftData can't auto-migrate.
            // Destroy the stale store and start fresh.
            // TODO: Replace with a versioned MigrationPlan before App Store release.
            destroyStore(at: config.url)
            return try ModelContainer(for: schema, configurations: [config])
        }
    }

    public static func makeInMemoryContainer() throws -> ModelContainer {
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }

    // MARK: - Private

    private static func destroyStore(at url: URL) {
        let fm = FileManager.default
        for suffix in ["", "-shm", "-wal"] {
            let file = URL(fileURLWithPath: url.path + suffix)
            try? fm.removeItem(at: file)
        }
    }
}
