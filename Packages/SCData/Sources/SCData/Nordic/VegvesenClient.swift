import Foundation

/// Client for fetching Norwegian mountain pass (fjellovergang) status from Vegvesen.
public struct VegvesenClient {
    public let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    /// Fetch current status for all Norwegian mountain passes.
    /// Returns an empty array on network failure — callers should degrade gracefully.
    public func fetchMountainPasses() async -> [MountainPass] {
        guard let url = URL(string: "https://www.vegvesen.no/ws/no/vegvesen/veg/trafikkpublikasjon/rest/fjellovergang") else {
            return fallbackPasses
        }
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                return fallbackPasses
            }
            return try parsePasses(data: data)
        } catch {
            return fallbackPasses
        }
    }

    // MARK: - Parsing

    private func parsePasses(data: Data) throws -> [MountainPass] {
        // The API may return various shapes; attempt common structures defensively.
        if let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            let parsed = array.compactMap { parseSinglePass($0) }
            if !parsed.isEmpty { return parsed }
        }
        if let wrapper = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let items = wrapper["fjellovergang"] as? [[String: Any]] {
            let parsed = items.compactMap { parseSinglePass($0) }
            if !parsed.isEmpty { return parsed }
        }
        return fallbackPasses
    }

    private func parseSinglePass(_ dict: [String: Any]) -> MountainPass? {
        guard let name = dict["vegstrekning"] as? String ?? dict["name"] as? String else { return nil }
        let rawStatus = (dict["status"] as? String ?? dict["tilstand"] as? String ?? "").lowercased()
        let status: PassStatus
        if rawStatus.contains("stengt") || rawStatus.contains("closed") {
            status = .closed
        } else if rawStatus.contains("kolonne") || rawStatus.contains("restrik") || rawStatus.contains("restricted") {
            status = .restricted
        } else if rawStatus.contains("åpen") || rawStatus.contains("open") {
            status = .open
        } else {
            status = .unknown
        }
        let description = dict["merknad"] as? String ?? dict["statusDescription"] as? String
        let lat = dict["latitude"] as? Double ?? dict["lat"] as? Double
        let lng = dict["longitude"] as? Double ?? dict["lon"] as? Double
        let road = dict["vegreferanse"] as? String ?? dict["roadReference"] as? String ?? ""
        return MountainPass(
            id: dict["id"] as? String ?? name,
            name: name,
            roadReference: road,
            status: status,
            statusDescription: description,
            latitude: lat,
            longitude: lng,
            lastUpdated: nil
        )
    }

    // MARK: - Fallback

    private var fallbackPasses: [MountainPass] {
        [
            MountainPass(id: "E134-haukelifjell", name: "Haukelifjell (E134)",
                         roadReference: "E134", status: .unknown,
                         latitude: 59.817, longitude: 7.208),
            MountainPass(id: "RV7-hardangervidda", name: "Hardangervidda (Rv7)",
                         roadReference: "Rv7", status: .unknown,
                         latitude: 60.317, longitude: 7.517),
            MountainPass(id: "E16-filefjell", name: "Filefjell (E16)",
                         roadReference: "E16", status: .unknown,
                         latitude: 61.133, longitude: 8.183),
            MountainPass(id: "RV15-strynefjellet", name: "Strynefjellet (Rv15)",
                         roadReference: "Rv15", status: .unknown,
                         latitude: 61.917, longitude: 7.483),
            MountainPass(id: "E136-romsdalen", name: "Romsdalen (E136)",
                         roadReference: "E136", status: .unknown,
                         latitude: 62.483, longitude: 7.733),
            MountainPass(id: "RV55-sognefjellet", name: "Sognefjellet (Rv55)",
                         roadReference: "Rv55", status: .unknown,
                         latitude: 61.583, longitude: 8.000),
            MountainPass(id: "E6-dovre", name: "Dovre (E6)",
                         roadReference: "E6", status: .unknown,
                         latitude: 62.283, longitude: 9.550),
            MountainPass(id: "E69-nordkapp", name: "Nordkapp (E69)",
                         roadReference: "E69", status: .unknown,
                         latitude: 71.167, longitude: 25.783),
        ]
    }
}

// MARK: - Models

public struct MountainPass: Identifiable, Codable {
    public var id: String
    public var name: String
    public var roadReference: String
    public var status: PassStatus
    public var statusDescription: String?
    public var latitude: Double?
    public var longitude: Double?
    public var lastUpdated: Date?

    public init(
        id: String,
        name: String,
        roadReference: String,
        status: PassStatus,
        statusDescription: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        lastUpdated: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.roadReference = roadReference
        self.status = status
        self.statusDescription = statusDescription
        self.latitude = latitude
        self.longitude = longitude
        self.lastUpdated = lastUpdated
    }
}

public enum PassStatus: String, Codable, CaseIterable {
    case open
    case restricted
    case closed
    case unknown
}
