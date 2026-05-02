import Foundation
import SCData

/// Criteria for filtering a list of Supercharger sites.
public struct FilterCriteria: Equatable {
    /// Restrict to specific charger generations. Empty means all generations.
    public var generations: Set<ChargerGeneration>
    /// Minimum power output in kilowatts. Nil means no minimum.
    public var minimumKilowatts: Int?
    /// Restrict to specific site statuses. Empty means show all open sites.
    public var statuses: Set<SiteStatus>
    /// Restrict to specific countries (ISO 3166-1 alpha-2). Empty means all countries.
    public var countries: Set<String>
    /// Site must have ALL of these amenities.
    public var amenities: Set<Amenity>
    /// Site must support AT LEAST ONE of these plug types.
    public var plugTypes: Set<PlugType>
    /// When true, only show favourited sites.
    public var favouritesOnly: Bool
    
    public init(
        generations: Set<ChargerGeneration> = [],
        minimumKilowatts: Int? = nil,
        statuses: Set<SiteStatus> = [.open, .construction],
        countries: Set<String> = [],
        amenities: Set<Amenity> = [],
        plugTypes: Set<PlugType> = [],
        favouritesOnly: Bool = false
    ) {
        self.generations = generations
        self.minimumKilowatts = minimumKilowatts
        self.statuses = statuses
        self.countries = countries
        self.amenities = amenities
        self.plugTypes = plugTypes
        self.favouritesOnly = favouritesOnly
    }
    
    /// Default filter: open and under-construction sites, no other restrictions.
    public static let `default` = FilterCriteria(
        generations: [],
        minimumKilowatts: nil,
        statuses: [.open, .construction],
        countries: [],
        amenities: [],
        plugTypes: [],
        favouritesOnly: false
    )
}
