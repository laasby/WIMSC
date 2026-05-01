import Foundation

// MARK: - DTOs

/// Data Transfer Object matching the supercharge.info allSites JSON shape.
public struct SuperchargerDTO: Decodable {
    public let id: Int
    public let locationId: String?
    public let name: String
    public let status: String?
    public let address: AddressDTO?
    public let gps: GpsDTO?
    public let stallCount: Int?
    public let powerKilowatt: Int?
    public let open24Hr: Bool?
    public let amenities: String?
    public let accessNotes: String?
    public let plugType: String?

    public struct AddressDTO: Decodable {
        public let street: String?
        public let city: String?
        public let state: String?
        public let zip: String?
        public let country: String?
    }

    public struct GpsDTO: Decodable {
        public let lat: Double?
        public let lng: Double?
    }

    /// Converts this DTO into a SwiftData Supercharger model.
    public func toDomain() -> Supercharger {
        let siteId = locationId ?? "site-\(id)"
        
        let siteStatus: SiteStatus
        switch status?.uppercased() {
        case "OPEN": siteStatus = .open
        case "CONSTRUCTION": siteStatus = .construction
        case "CLOSED": siteStatus = .closed
        case "PERMIT": siteStatus = .permit
        case "PLAN": siteStatus = .plan
        default: siteStatus = .closed
        }
        
        let kw = powerKilowatt ?? 0
        let generation: ChargerGeneration
        if kw >= 300 { generation = .v4 }
        else if kw >= 200 { generation = .v3 }
        else if kw > 0 { generation = .v2 }
        else { generation = .unknown }
        
        let plugs: [PlugType]
        switch plugType?.uppercased() {
        case "NACS": plugs = [.nacs]
        case "CCS", "CCS2": plugs = [.ccs2]
        case "TYPE2": plugs = [.type2]
        case "CHADEMO": plugs = [.chademo]
        case "NACS,CCS": plugs = [.nacs, .ccs2]
        default: plugs = [.nacs]
        }
        
        var siteAmenities: [Amenity] = []
        if let amenityStr = amenities?.lowercased() {
            if amenityStr.contains("restroom") || amenityStr.contains("bathroom") { siteAmenities.append(.restrooms) }
            if amenityStr.contains("food") || amenityStr.contains("restaurant") { siteAmenities.append(.food) }
            if amenityStr.contains("coffee") || amenityStr.contains("café") || amenityStr.contains("cafe") { siteAmenities.append(.coffee) }
            if amenityStr.contains("wifi") || amenityStr.contains("wi-fi") { siteAmenities.append(.wifi) }
            if amenityStr.contains("shop") || amenityStr.contains("mall") || amenityStr.contains("retail") { siteAmenities.append(.shops) }
            if amenityStr.contains("covered") { siteAmenities.append(.coveredParking) }
            if amenityStr.contains("pull") { siteAmenities.append(.pullThrough) }
            if amenityStr.contains("lounge") { siteAmenities.append(.lounge) }
        }
        
        let gatedAccess = accessNotes?.isEmpty == false
        let lat = gps?.lat ?? 0
        let lng = gps?.lng ?? 0
        let street = address?.street ?? ""
        let cityStr = address?.city ?? ""
        let stateStr = address?.state ?? ""
        let countryStr = address?.country ?? ""
        let zip = address?.zip ?? ""
        let stalls = stallCount ?? 0
        let is24 = open24Hr ?? false
        let pullThrough = siteAmenities.contains(.pullThrough)
        
        return Supercharger(
            id: siteId,
            name: name,
            latitude: lat,
            longitude: lng,
            streetAddress: street,
            city: cityStr,
            state: stateStr,
            country: countryStr,
            postalCode: zip,
            status: siteStatus,
            stallCount: stalls,
            generation: generation,
            maxKilowatts: kw,
            plugTypes: plugs,
            is24Hours: is24,
            hasGatedAccess: gatedAccess,
            gatedAccessNotes: accessNotes,
            amenities: siteAmenities,
            hasPullThrough: pullThrough,
            dataSource: .superchargeInfo,
            lastSyncedAt: .now
        )
    }
}

/// Extended detail DTO returned by the supercharge.info details endpoint.
public struct SuperchargerDetailDTO: Decodable {
    public let id: Int
    public let locationId: String?
    public let name: String
    public let status: String?
    public let address: SuperchargerDTO.AddressDTO?
    public let gps: SuperchargerDTO.GpsDTO?
    public let stallCount: Int?
    public let powerKilowatt: Int?
    public let open24Hr: Bool?
    public let amenities: String?
    public let accessNotes: String?
    public let plugType: String?
    public let openDate: String?
    public let pricingInfo: String?
}

// MARK: - Client

/// Client for fetching Supercharger site data from supercharge.info.
public struct SuperchargeInfoClient {
    public let session: URLSession
    
    public init(session: URLSession = .shared) {
        self.session = session
    }
    
    /// Fetches all known Supercharger sites.
    public func fetchAllSites() async throws -> [SuperchargerDTO] {
        guard let url = URL(string: "https://supercharge.info/service/supercharger/allSites") else {
            // This URL is a compile-time constant; a nil here is a programmer error.
            preconditionFailure("Invalid hardcoded URL for supercharge.info allSites")
        }
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("WIMSC/1.0", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, http.statusCode == 429 {
            // Rate limited — wait and retry once
            try await Task.sleep(nanoseconds: 2_000_000_000)
            let (retryData, _) = try await session.data(for: request)
            return try JSONDecoder().decode([SuperchargerDTO].self, from: retryData)
        }
        return try JSONDecoder().decode([SuperchargerDTO].self, from: data)
    }
    
    /// Fetches detailed information for a single Supercharger site.
    public func fetchSiteDetails(id: String) async throws -> SuperchargerDetailDTO {
        guard let url = URL(string: "https://supercharge.info/service/supercharger/details?siteId=\(id)") else {
            preconditionFailure("Invalid URL constructed for siteId: \(id)")
        }
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("WIMSC/1.0", forHTTPHeaderField: "User-Agent")
        // Polite delay to avoid hammering the API
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1s
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(SuperchargerDetailDTO.self, from: data)
    }
}
