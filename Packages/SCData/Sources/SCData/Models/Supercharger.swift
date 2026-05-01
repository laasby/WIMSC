import Foundation
import SwiftData

/// A Tesla Supercharger site with full metadata.
@Model
public final class Supercharger {
    /// Site identifier from supercharge.info, e.g. "US-CA-0001".
    public var id: String
    public var name: String
    public var latitude: Double
    public var longitude: Double
    public var streetAddress: String
    public var city: String
    public var state: String
    /// ISO 3166-1 alpha-2 country code.
    public var country: String
    public var postalCode: String
    public var status: SiteStatus
    public var stallCount: Int
    public var generation: ChargerGeneration
    public var maxKilowatts: Int
    public var hasMagicDock: Bool
    public var plugTypes: [PlugType]
    public var is24Hours: Bool
    public var hasRestrictedHours: Bool
    public var openingHours: String?
    public var hasGatedAccess: Bool
    public var gatedAccessNotes: String?
    public var pricing: PricingInfo?
    public var amenities: [Amenity]
    public var hasPullThrough: Bool
    @Relationship(deleteRule: .cascade)
    public var photos: [SitePhoto]
    /// Community notes stored as Codable embedded values.
    public var communityNotes: [CommunityNote]
    public var lastVerifiedDate: Date?
    public var dataSource: DataSource
    public var openedDate: Date?
    /// Whether the user has marked this site as a favourite.
    public var isFavourite: Bool
    /// Free-form user notes.
    public var userNotes: String?
    public var lastSyncedAt: Date

    public init(
        id: String,
        name: String,
        latitude: Double,
        longitude: Double,
        streetAddress: String,
        city: String,
        state: String,
        country: String,
        postalCode: String,
        status: SiteStatus,
        stallCount: Int,
        generation: ChargerGeneration,
        maxKilowatts: Int,
        hasMagicDock: Bool = false,
        plugTypes: [PlugType] = [],
        is24Hours: Bool = true,
        hasRestrictedHours: Bool = false,
        openingHours: String? = nil,
        hasGatedAccess: Bool = false,
        gatedAccessNotes: String? = nil,
        pricing: PricingInfo? = nil,
        amenities: [Amenity] = [],
        hasPullThrough: Bool = false,
        photos: [SitePhoto] = [],
        communityNotes: [CommunityNote] = [],
        lastVerifiedDate: Date? = nil,
        dataSource: DataSource,
        openedDate: Date? = nil,
        isFavourite: Bool = false,
        userNotes: String? = nil,
        lastSyncedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.streetAddress = streetAddress
        self.city = city
        self.state = state
        self.country = country
        self.postalCode = postalCode
        self.status = status
        self.stallCount = stallCount
        self.generation = generation
        self.maxKilowatts = maxKilowatts
        self.hasMagicDock = hasMagicDock
        self.plugTypes = plugTypes
        self.is24Hours = is24Hours
        self.hasRestrictedHours = hasRestrictedHours
        self.openingHours = openingHours
        self.hasGatedAccess = hasGatedAccess
        self.gatedAccessNotes = gatedAccessNotes
        self.pricing = pricing
        self.amenities = amenities
        self.hasPullThrough = hasPullThrough
        self.photos = photos
        self.communityNotes = communityNotes
        self.lastVerifiedDate = lastVerifiedDate
        self.dataSource = dataSource
        self.openedDate = openedDate
        self.isFavourite = isFavourite
        self.userNotes = userNotes
        self.lastSyncedAt = lastSyncedAt
    }
}
