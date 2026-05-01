import Foundation
import CoreLocation
import SCData

/// Applies filter criteria and sorting to an array of Supercharger sites.
public enum SuperchargerFilter {
    
    /// Returns a filtered and sorted copy of `sites` according to `criteria` and `sortBy`.
    /// - Parameters:
    ///   - sites: The full list of sites to filter.
    ///   - criteria: Filtering rules to apply.
    ///   - sortBy: Sort order for the result.
    ///   - userLocation: The user's current location, used for distance-based sorting.
    /// - Returns: Filtered and sorted array.
    public static func apply(
        _ sites: [Supercharger],
        criteria: FilterCriteria,
        sortBy: SortOrder,
        userLocation: CLLocation?
    ) -> [Supercharger] {
        var result = sites.filter { matches($0, criteria: criteria) }
        result = sort(result, by: sortBy, userLocation: userLocation)
        return result
    }
    
    // MARK: - Private
    
    private static func matches(_ site: Supercharger, criteria: FilterCriteria) -> Bool {
        // Status filter
        if !criteria.statuses.isEmpty, !criteria.statuses.contains(site.status) {
            return false
        }
        // Generation filter
        if !criteria.generations.isEmpty, !criteria.generations.contains(site.generation) {
            return false
        }
        // Kilowatts filter
        if let minKw = criteria.minimumKilowatts, site.maxKilowatts < minKw {
            return false
        }
        // Country filter
        if !criteria.countries.isEmpty, !criteria.countries.contains(site.country) {
            return false
        }
        // Amenities filter: site must have ALL required amenities
        if !criteria.amenities.isEmpty {
            let siteAmenitySet = Set(site.amenities)
            if !criteria.amenities.isSubset(of: siteAmenitySet) {
                return false
            }
        }
        // Plug type filter: site must support AT LEAST ONE required plug type
        if !criteria.plugTypes.isEmpty {
            let sitePlugSet = Set(site.plugTypes)
            if criteria.plugTypes.isDisjoint(with: sitePlugSet) {
                return false
            }
        }
        // Favourites filter
        if criteria.favouritesOnly, !site.isFavourite {
            return false
        }
        return true
    }
    
    private static func sort(
        _ sites: [Supercharger],
        by order: SortOrder,
        userLocation: CLLocation?
    ) -> [Supercharger] {
        switch order {
        case .distance:
            guard let userLoc = userLocation else {
                // No location available: fall back to name sort
                return sites.sorted { $0.name < $1.name }
            }
            return sites.sorted {
                let locA = CLLocation(latitude: $0.latitude, longitude: $0.longitude)
                let locB = CLLocation(latitude: $1.latitude, longitude: $1.longitude)
                return locA.distance(from: userLoc) < locB.distance(from: userLoc)
            }
        case .name:
            return sites.sorted { $0.name < $1.name }
        case .stallCount:
            return sites.sorted { $0.stallCount > $1.stallCount }
        case .maxKilowatts:
            return sites.sorted { $0.maxKilowatts > $1.maxKilowatts }
        case .recentlyVerified:
            return sites.sorted {
                let dateA = $0.lastVerifiedDate ?? .distantPast
                let dateB = $1.lastVerifiedDate ?? .distantPast
                return dateA > dateB
            }
        }
    }
}
