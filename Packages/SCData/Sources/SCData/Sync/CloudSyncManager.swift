import Foundation
import SwiftData

// NOTE: CloudKit sync requires the `com.apple.developer.icloud-services` entitlement
// (value: `CloudKit`) and the `com.apple.developer.icloud-container-identifiers` entitlement
// (value: `iCloud.com.laasby.wimsc`) to be configured in your Apple Developer account and
// Xcode project's .entitlements file. The code compiles without these; sync activates only
// once the entitlement is provisioned.

/// Manages the opt-in CloudKit sync preference and provides the correct ModelContainer.
@Observable
public final class CloudSyncManager {

    // MARK: - Persistence key
    private static let syncEnabledKey = "wimsc.icloud.sync.enabled"

    public private(set) var isSyncEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isSyncEnabled, forKey: Self.syncEnabledKey)
        }
    }

    public init() {
        self.isSyncEnabled = UserDefaults.standard.bool(forKey: Self.syncEnabledKey)
    }

    // MARK: - Container factory

    /// Creates the appropriate ModelContainer based on the current sync preference.
    /// - local only when sync is disabled
    /// - CloudKit-backed when sync is enabled
    public func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            Supercharger.self,
            SitePhoto.self,
            VisitRecord.self,
            StallReport.self,
            UserVehicle.self,
        ])

        if isSyncEnabled {
            let config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .private("iCloud.com.laasby.wimsc")
            )
            return try ModelContainer(for: schema, configurations: [config])
        } else {
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            return try ModelContainer(for: schema, configurations: [config])
        }
    }

    /// Toggle sync on/off. Caller is responsible for reinitialising the container
    /// (requires app restart or scene reset — inform the user).
    public func setSyncEnabled(_ enabled: Bool) {
        isSyncEnabled = enabled
    }

    // MARK: - What syncs

    /// Human-readable description of what data syncs to iCloud.
    public static let syncedDataDescription: [(item: String, detail: String)] = [
        ("Favourite sites",   "Sites you've starred"),
        ("Personal notes",    "Notes you've added to sites"),
        ("Visit history",     "Charging sessions you've logged"),
        ("Stall reports",     "Stall issues you've filed"),
    ]

    /// Human-readable description of what does NOT sync.
    public static let localOnlyDescription: [(item: String, detail: String)] = [
        ("Supercharger database", "Downloaded fresh from supercharge.info"),
        ("Weather data",          "Fetched live — not stored long-term"),
        ("Spot prices",           "Fetched live from Tibber / hvakosterstrommen.no"),
    ]
}
