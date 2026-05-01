import Foundation
import AuthenticationServices
import Security
import CryptoKit
import SwiftUI

@Observable
@MainActor
public final class TeslaAuthService: NSObject {
    static let clientId = "YOUR_TESLA_CLIENT_ID"
    static let redirectUri = "com.laasby.wimsc://tesla-auth"
    static let scopes = "openid offline_access vehicle_device_data vehicle_charging_cmds"
    static let authURL = "https://auth.tesla.com/oauth2/v3/authorize"
    static let tokenURL = "https://auth.tesla.com/oauth2/v3/token"

    public var isAuthenticated: Bool = false
    public var isLoading: Bool = false
    public var errorMessage: String? = nil

    private var accessToken: String?
    private var refreshToken: String?
    private var tokenExpiry: Date?

    // PKCE
    private var codeVerifier: String?

    // Keychain keys
    private let accessTokenKey = "com.laasby.wimsc.tesla.accessToken"
    private let refreshTokenKey = "com.laasby.wimsc.tesla.refreshToken"
    private let expiryKey = "com.laasby.wimsc.tesla.tokenExpiry"

    public override init() {
        super.init()
        loadFromKeychain()
    }

    public func signIn() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let verifier = generateCodeVerifier()
        codeVerifier = verifier
        let challenge = generateCodeChallenge(from: verifier)

        var components = URLComponents(string: Self.authURL)!
        components.queryItems = [
            .init(name: "response_type", value: "code"),
            .init(name: "client_id", value: Self.clientId),
            .init(name: "redirect_uri", value: Self.redirectUri),
            .init(name: "scope", value: Self.scopes),
            .init(name: "code_challenge", value: challenge),
            .init(name: "code_challenge_method", value: "S256"),
        ]

        guard let authURL = components.url else {
            errorMessage = "Failed to build auth URL"
            return
        }

        do {
            let callbackURL = try await withCheckedThrowingContinuation { (cont: CheckedContinuation<URL, Error>) in
                let session = ASWebAuthenticationSession(
                    url: authURL,
                    callbackURLScheme: "com.laasby.wimsc"
                ) { url, error in
                    if let error = error {
                        cont.resume(throwing: error)
                    } else if let url = url {
                        cont.resume(returning: url)
                    } else {
                        cont.resume(throwing: URLError(.badServerResponse))
                    }
                }
                session.presentationContextProvider = self
                session.prefersEphemeralWebBrowserSession = false
                session.start()
            }
            let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)
            guard let code = components?.queryItems?.first(where: { $0.name == "code" })?.value else {
                errorMessage = "No authorization code received"
                return
            }
            try await exchangeCode(code)
        } catch ASWebAuthenticationSessionError.canceledLogin {
            // user cancelled — silently ignore
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func signOut() {
        accessToken = nil
        refreshToken = nil
        tokenExpiry = nil
        isAuthenticated = false
        deleteFromKeychain()
    }

    public func refreshIfNeeded() async throws -> String {
        if let token = accessToken, let expiry = tokenExpiry, expiry > Date().addingTimeInterval(60) {
            return token
        }
        guard let rt = refreshToken else {
            throw TeslaAuthError.notAuthenticated
        }
        try await performTokenRefresh(refreshToken: rt)
        guard let token = accessToken else { throw TeslaAuthError.notAuthenticated }
        return token
    }

    // MARK: - Private

    private func exchangeCode(_ code: String) async throws {
        var request = URLRequest(url: URL(string: Self.tokenURL)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        guard let verifier = codeVerifier else { throw TeslaAuthError.missingCodeVerifier }
        let body = [
            "grant_type": "authorization_code",
            "client_id": Self.clientId,
            "redirect_uri": Self.redirectUri,
            "code": code,
            "code_verifier": verifier,
        ].map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
         .joined(separator: "&")
        request.httpBody = body.data(using: .utf8)
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(TokenResponse.self, from: data)
        storeTokens(response)
    }

    private func performTokenRefresh(refreshToken rt: String) async throws {
        var request = URLRequest(url: URL(string: Self.tokenURL)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let body = [
            "grant_type": "refresh_token",
            "client_id": Self.clientId,
            "refresh_token": rt,
        ].map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
         .joined(separator: "&")
        request.httpBody = body.data(using: .utf8)
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(TokenResponse.self, from: data)
        storeTokens(response)
    }

    private func storeTokens(_ response: TokenResponse) {
        accessToken = response.accessToken
        if let rt = response.refreshToken { refreshToken = rt }
        tokenExpiry = Date().addingTimeInterval(Double(response.expiresIn))
        isAuthenticated = true
        saveToKeychain()
    }

    // MARK: - PKCE helpers

    private func generateCodeVerifier() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private func generateCodeChallenge(from verifier: String) -> String {
        let data = Data(verifier.utf8)
        let digest = SHA256.hash(data: data)
        return Data(digest).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    // MARK: - Keychain

    private func saveToKeychain() {
        if let token = accessToken { save(string: token, forKey: accessTokenKey) }
        if let rt = refreshToken { save(string: rt, forKey: refreshTokenKey) }
        if let expiry = tokenExpiry { save(string: String(expiry.timeIntervalSince1970), forKey: expiryKey) }
    }

    private func loadFromKeychain() {
        accessToken = load(forKey: accessTokenKey)
        refreshToken = load(forKey: refreshTokenKey)
        if let expiryStr = load(forKey: expiryKey), let interval = Double(expiryStr) {
            tokenExpiry = Date(timeIntervalSince1970: interval)
        }
        isAuthenticated = accessToken != nil
    }

    private func deleteFromKeychain() {
        [accessTokenKey, refreshTokenKey, expiryKey].forEach { key in
            let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                         kSecAttrAccount as String: key]
            SecItemDelete(query as CFDictionary)
        }
    }

    private func save(string: String, forKey key: String) {
        let data = Data(string.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    private func load(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    // MARK: - Token models

    private struct TokenResponse: Decodable {
        let accessToken: String
        let refreshToken: String?
        let expiresIn: Int
        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case refreshToken = "refresh_token"
            case expiresIn = "expires_in"
        }
    }
}

enum TeslaAuthError: Error {
    case notAuthenticated
    case missingCodeVerifier
}

extension TeslaAuthService: ASWebAuthenticationPresentationContextProviding {
    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}
