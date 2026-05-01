import Foundation
import SCData

/// Centralised localisation helper.
/// Usage: L10n.string("tab.map")  or  L10n.string("list.empty.title")
public enum L10n {
    /// Returns the localised string for the given key from the main bundle.
    public static func string(_ key: String, comment: String = "") -> String {
        NSLocalizedString(key, bundle: .main, comment: comment)
    }
}

// MARK: - Localised display names for domain enums

public extension SiteStatus {
    var localizedName: String {
        switch self {
        case .open:         return L10n.string("status.open")
        case .construction: return L10n.string("status.construction")
        case .closed:       return L10n.string("status.closed")
        case .permit:       return L10n.string("status.permit")
        case .plan:         return L10n.string("status.plan")
        }
    }
}

public extension ChargerGeneration {
    var localizedName: String {
        switch self {
        case .v2:      return L10n.string("generation.v2")
        case .v3:      return L10n.string("generation.v3")
        case .v4:      return L10n.string("generation.v4")
        case .unknown: return L10n.string("generation.unknown")
        }
    }
}

public extension Amenity {
    var localizedName: String {
        switch self {
        case .restrooms:      return L10n.string("amenity.restrooms")
        case .food:           return L10n.string("amenity.food")
        case .coffee:         return L10n.string("amenity.coffee")
        case .wifi:           return L10n.string("amenity.wifi")
        case .shops:          return L10n.string("amenity.shops")
        case .coveredParking: return L10n.string("amenity.coveredParking")
        case .pullThrough:    return L10n.string("amenity.pullThrough")
        case .lounge:         return L10n.string("amenity.lounge")
        }
    }
}

public extension PlugType {
    var localizedName: String {
        switch self {
        case .nacs:    return L10n.string("plug.nacs")
        case .ccs2:    return L10n.string("plug.ccs2")
        case .type2:   return L10n.string("plug.type2")
        case .chademo: return L10n.string("plug.chademo")
        }
    }
}
