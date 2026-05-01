import Foundation
import SwiftData

/// Loads the bundled seed data on first launch to provide immediate content before the first remote sync.
public enum BundledDataLoader {
    private static let seededKey = "SCData.bundledDataSeeded"
    
    /// Inserts the bundled Supercharger seed data into the context if not already done.
    /// Call this once at app startup before showing any UI.
    public static func seedIfNeeded(into context: ModelContext) {
        guard !UserDefaults.standard.bool(forKey: seededKey) else { return }
        do {
            let sites = try loadBundledSites()
            for site in sites {
                context.insert(site)
            }
            try context.save()
            UserDefaults.standard.set(true, forKey: seededKey)
        } catch {
            // Non-fatal: the app can still function; a remote sync will populate data
        }
    }
    
    private static func loadBundledSites() throws -> [Supercharger] {
        guard let url = Bundle.module.url(forResource: "bundled_superchargers", withExtension: "json") else {
            // The resource must be bundled; this is a build-time configuration error.
            assertionFailure("bundled_superchargers.json not found in bundle")
            return []
        }
        let data = try Data(contentsOf: url)
        let entries = try JSONDecoder().decode([BundledSuperchargerEntry].self, from: data)
        return entries.map { $0.toModel() }
    }
}

// MARK: - Codable seed schema

private struct BundledSuperchargerEntry: Decodable {
    let id: String
    let name: String
    let status: String
    let latitude: Double
    let longitude: Double
    let streetAddress: String
    let city: String
    let state: String
    let country: String
    let postalCode: String
    let stallCount: Int
    let generation: String
    let maxKilowatts: Int
    let hasMagicDock: Bool?
    let plugTypes: [String]?
    let is24Hours: Bool?
    let hasRestrictedHours: Bool?
    let openingHours: String?
    let amenities: [String]?
    let hasPullThrough: Bool?
    let dataSource: String
    
    func toModel() -> Supercharger {
        let siteStatus: SiteStatus
        switch status.uppercased() {
        case "OPEN": siteStatus = .open
        case "CONSTRUCTION": siteStatus = .construction
        case "CLOSED": siteStatus = .closed
        case "PERMIT": siteStatus = .permit
        case "PLAN": siteStatus = .plan
        default: siteStatus = .open
        }
        
        let gen: ChargerGeneration
        switch generation.lowercased() {
        case "v2": gen = .v2
        case "v3": gen = .v3
        case "v4": gen = .v4
        default: gen = .unknown
        }
        
        let plugs: [PlugType] = (plugTypes ?? []).compactMap {
            switch $0.lowercased() {
            case "nacs": return .nacs
            case "ccs2": return .ccs2
            case "type2": return .type2
            case "chademo": return .chademo
            default: return nil
            }
        }
        
        let siteAmenities: [Amenity] = (amenities ?? []).compactMap {
            switch $0.lowercased() {
            case "restrooms": return .restrooms
            case "food": return .food
            case "coffee": return .coffee
            case "wifi": return .wifi
            case "shops": return .shops
            case "coveredparking": return .coveredParking
            case "pullthrough": return .pullThrough
            case "lounge": return .lounge
            default: return nil
            }
        }
        
        let ds: DataSource
        switch dataSource.lowercased() {
        case "superchargeinfo": ds = .superchargeInfo
        case "teslafindus": ds = .teslaFindUs
        case "openchargesmap": ds = .openChargeMap
        default: ds = .superchargeInfo
        }
        
        return Supercharger(
            id: id,
            name: name,
            latitude: latitude,
            longitude: longitude,
            streetAddress: streetAddress,
            city: city,
            state: state,
            country: country,
            postalCode: postalCode,
            status: siteStatus,
            stallCount: stallCount,
            generation: gen,
            maxKilowatts: maxKilowatts,
            hasMagicDock: hasMagicDock ?? false,
            plugTypes: plugs,
            is24Hours: is24Hours ?? true,
            hasRestrictedHours: hasRestrictedHours ?? false,
            openingHours: openingHours,
            amenities: siteAmenities,
            hasPullThrough: hasPullThrough ?? false,
            dataSource: ds,
            lastSyncedAt: .distantPast
        )
    }
}
