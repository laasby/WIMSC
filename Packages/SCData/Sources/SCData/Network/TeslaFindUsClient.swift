import Foundation

/// DTO matching the Tesla cua-api site list JSON shape.
public struct TeslaFindUsSiteDTO: Decodable {
    public let title: String?
    public let nid: String?
    public let address: String?
    public let city: String?
    public let province_state: String?
    public let zip: String?
    public let country: String?
    public let latitude: String?
    public let longitude: String?
    public let chargers: String?
    public let open_soon: String?
    public let sales: String?
    public let service: String?
    public let body: String?
}

/// Client for fetching Tesla's public Supercharger site list.
public struct TeslaFindUsClient {
    public let session: URLSession
    
    public init(session: URLSession = .shared) {
        self.session = session
    }
    
    /// Fetches Tesla's public site list. Returns nil if the endpoint is unavailable.
    public func fetchSites() async throws -> [TeslaFindUsSiteDTO]? {
        guard let url = URL(string: "https://www.tesla.com/cua-api/tesla-site-list?lang=en_US&types=supercharger") else {
            preconditionFailure("Invalid hardcoded URL for Tesla site list")
        }
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("WIMSC/1.0", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 15
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                return nil
            }
            // Tesla returns either a JSON array directly or a wrapped object
            if let array = try? JSONDecoder().decode([TeslaFindUsSiteDTO].self, from: data) {
                return array
            }
            // Try wrapped format: { "result": [...] }
            struct Wrapped: Decodable { let result: [TeslaFindUsSiteDTO] }
            if let wrapped = try? JSONDecoder().decode(Wrapped.self, from: data) {
                return wrapped.result
            }
            return nil
        } catch {
            // Graceful degradation: Tesla's endpoint may be unavailable
            return nil
        }
    }
}
