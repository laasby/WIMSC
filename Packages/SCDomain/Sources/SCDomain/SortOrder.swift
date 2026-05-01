import Foundation

/// The field and direction by which to sort Supercharger results.
public enum SortOrder: String, CaseIterable, Identifiable {
    case distance
    case name
    case stallCount
    case maxKilowatts
    case recentlyVerified
    
    public var id: String { rawValue }
    
    /// A user-facing localised label for this sort order.
    public var localizedName: String {
        switch self {
        case .distance:         return L10n.string("sort.distance")
        case .name:             return L10n.string("sort.name")
        case .stallCount:       return L10n.string("sort.stallCount")
        case .maxKilowatts:     return L10n.string("sort.maxKilowatts")
        case .recentlyVerified: return L10n.string("sort.recentlyVerified")
        }
    }
}
