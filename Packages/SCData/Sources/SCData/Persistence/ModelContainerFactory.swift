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
        return try ModelContainer(for: schema, configurations: [config])
    }

    public static func makeInMemoryContainer() throws -> ModelContainer {
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }
}
