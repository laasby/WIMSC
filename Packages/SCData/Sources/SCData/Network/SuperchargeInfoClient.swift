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
    public let otherEVs: Bool?
    /// stalls dict e.g. {"v4": 16} — used for generation detection
    public let stalls: [String: Int]?
    /// plugs dict e.g. {"ccs2": 16, "nacs": 4}
    public let plugs: [String: Int]?

    public struct AddressDTO: Decodable {
        public let street: String?
        public let city: String?
        public let state: String?
        public let zip: String?
        public let country: String?
    }

    public struct GpsDTO: Decodable {
        public let latitude: Double?
        public let longitude: Double?
        // Legacy field aliases (some endpoints use lat/lng)
        public let lat: Double?
        public let lng: Double?

        public var resolvedLat: Double? { latitude ?? lat }
        public var resolvedLng: Double? { longitude ?? lng }
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
        if let stalls = stalls {
            if stalls["v4"] != nil { generation = .v4 }
            else if stalls["v3"] != nil { generation = .v3 }
            else if stalls["v2"] != nil { generation = .v2 }
            else if kw >= 300 { generation = .v4 }
            else if kw >= 200 { generation = .v3 }
            else if kw > 0 { generation = .v2 }
            else { generation = .unknown }
        } else if kw >= 300 { generation = .v4 }
        else if kw >= 200 { generation = .v3 }
        else if kw > 0 { generation = .v2 }
        else { generation = .unknown }
        
        let resolvedPlugs: [PlugType]
        if let plugsDict = plugs, !plugsDict.isEmpty {
            var types: [PlugType] = []
            if plugsDict["nacs"] != nil { types.append(.nacs) }
            if plugsDict["ccs2"] != nil { types.append(.ccs2) }
            if plugsDict["type2"] != nil { types.append(.type2) }
            if plugsDict["chademo"] != nil { types.append(.chademo) }
            resolvedPlugs = types.isEmpty ? [.nacs] : types
        } else {
            switch plugType?.uppercased() {
            case "NACS": resolvedPlugs = [.nacs]
            case "CCS", "CCS2": resolvedPlugs = [.ccs2]
            case "TYPE2": resolvedPlugs = [.type2]
            case "CHADEMO": resolvedPlugs = [.chademo]
            case "NACS,CCS": resolvedPlugs = [.nacs, .ccs2]
            default: resolvedPlugs = [.nacs]
            }
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
        let lat = gps?.resolvedLat ?? 0
        let lng = gps?.resolvedLng ?? 0
        let street = address?.street ?? ""
        let cityStr = address?.city ?? ""
        let stateStr = address?.state ?? ""
        let countryStr = Self.normalizeCountry(address?.country)
        let zip = address?.zip ?? ""
        let stallsCount = stallCount ?? 0
        let is24 = open24Hr ?? true
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
            stallCount: stallsCount,
            generation: generation,
            maxKilowatts: kw,
            plugTypes: resolvedPlugs,
            is24Hours: is24,
            hasGatedAccess: gatedAccess,
            gatedAccessNotes: accessNotes,
            amenities: siteAmenities,
            hasPullThrough: pullThrough,
            dataSource: .superchargeInfo,
            lastSyncedAt: .now
        )
    }

    // Maps full country names returned by supercharge.info to ISO 3166-1 alpha-2 codes
    private static func normalizeCountry(_ name: String?) -> String {
        guard let name else { return "" }
        let map: [String: String] = [
            "Norway": "NO", "Sweden": "SE", "Denmark": "DK", "Finland": "FI",
            "Germany": "DE", "France": "FR", "Netherlands": "NL", "Belgium": "BE",
            "Austria": "AT", "Switzerland": "CH", "Spain": "ES", "Portugal": "PT",
            "Italy": "IT", "United Kingdom": "GB", "Ireland": "IE", "Poland": "PL",
            "Czech Republic": "CZ", "Slovakia": "SK", "Hungary": "HU", "Romania": "RO",
            "United States": "US", "Canada": "CA", "Mexico": "MX",
            "Australia": "AU", "New Zealand": "NZ", "Japan": "JP",
            "China": "CN", "South Korea": "KR", "Hong Kong": "HK",
            "Brazil": "BR", "Chile": "CL", "Argentina": "AR"
        ]
        return map[name] ?? name
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
        guard let url = URL(string: "https://supercharge.info/service/supercharge/allSites") else {
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
        guard let url = URL(string: "https://supercharge.info/service/supercharge/details?siteId=\(id)") else {
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
