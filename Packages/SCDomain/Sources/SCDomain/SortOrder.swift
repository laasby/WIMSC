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
        case .distance: return NSLocalizedString("Distance", comment: "Sort by distance from user")
        case .name: return NSLocalizedString("Name", comment: "Sort alphabetically by name")
        case .stallCount: return NSLocalizedString("Stall Count", comment: "Sort by number of stalls")
        case .maxKilowatts: return NSLocalizedString("Max Power", comment: "Sort by maximum kilowatts")
        case .recentlyVerified: return NSLocalizedString("Recently Verified", comment: "Sort by last verified date")
        }
    }
}
