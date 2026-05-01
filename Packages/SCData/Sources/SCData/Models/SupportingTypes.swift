import Foundation

/// Status of a Supercharger site.
public enum SiteStatus: String, Codable, CaseIterable, Hashable {
    case open, construction, closed, permit, plan
}

/// Hardware generation of the charger.
public enum ChargerGeneration: String, Codable, CaseIterable, Hashable {
    case v2, v3, v4, unknown

    public var maxKilowatts: Int {
        switch self {
        case .v2: return 150
        case .v3: return 250
        case .v4: return 325
        case .unknown: return 0
        }
    }
}

/// Plug type supported at the site.
public enum PlugType: String, Codable, CaseIterable, Hashable {
    case nacs, ccs2, type2, chademo
}

/// On-site amenity.
public enum Amenity: String, Codable, CaseIterable, Hashable {
    case restrooms, food, coffee, wifi, shops, coveredParking, pullThrough, lounge
}

/// Where the site data originated.
public enum DataSource: String, Codable {
    case superchargeInfo, teslaFindUs, openChargeMap
}

/// Pricing information embedded in a Supercharger record.
public struct PricingInfo: Codable {
    public var perKwh: Double?
    public var idleFee: Double?
    public var currency: String
    public var congestionFee: Double?
    public var peakHours: String?
    public var notes: String?

    public init(perKwh: Double? = nil, idleFee: Double? = nil, currency: String, congestionFee: Double? = nil, peakHours: String? = nil, notes: String? = nil) {
        self.perKwh = perKwh
        self.idleFee = idleFee
        self.currency = currency
        self.congestionFee = congestionFee
        self.peakHours = peakHours
        self.notes = notes
    }
}

/// A community-contributed note about a site. Stored inline as Codable data.
public struct CommunityNote: Codable {
    public var id: String
    public var body: String
    public var postedAt: Date
    public var source: String

    public init(id: String, body: String, postedAt: Date, source: String) {
        self.id = id
        self.body = body
        self.postedAt = postedAt
        self.source = source
    }
}

/// Source of a visit record.
public enum VisitSource: String, Codable {
    case manual, teslaFleetAPI
}

/// Issue type for a stall report.
public enum StallIssue: String, Codable {
    case broken, degraded, occupied, ok
}

/// Tesla vehicle model.
public enum TeslaModel: String, Codable, CaseIterable {
    case model3, modelY, modelS, modelX, cybertruck, semi
}
