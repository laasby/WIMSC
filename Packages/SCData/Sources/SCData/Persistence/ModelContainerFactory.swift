import Foundation
import SwiftData

/// Factory for creating SwiftData ModelContainer instances.
public enum ModelContainerFactory {
    /// All model types managed by the app.
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
    
    /// Creates the appropriate ModelContainer using a CloudSyncManager.
    public static func makeContainer(syncManager: CloudSyncManager) throws -> ModelContainer {
        return try syncManager.makeContainer()
    }

    /// Creates the persistent ModelContainer for production use.
    public static func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try ModelContainer(for: schema, configurations: [config])
    }
    
    /// Creates an in-memory ModelContainer for tests and SwiftUI previews.
    public static func makeInMemoryContainer() throws -> ModelContainer {
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }
}
