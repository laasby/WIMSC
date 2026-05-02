import Foundation
import AuthenticationServices
import CommonCrypto
import UIKit
import Observation

/// Manages Tesla OAuth PKCE sign-in and token lifecycle.
///
/// Register your app at https://developer.tesla.com to obtain a client_id,
/// then set `TeslaAuthService.clientID` before shipping.
@Observable
@MainActor
public final class TeslaAuthService: NSObject {

    // MARK: - Configuration

    /// Your Tesla Fleet API client_id from https://developer.tesla.com
    nonisolated static let clientID = "YOUR_CLIENT_ID"
    nonisolated static let redirectURI = "wimsc://auth/callback"
    nonisolated static let authURL = URL(string: "https://auth.tesla.com/oauth2/v3/authorize")!
    nonisolated static let tokenURL = URL(string: "https://auth.tesla.com/oauth2/v3/token")!
    nonisolated static let scopes = "openid offline_access"

    // MARK: - Observable state

    public var isSignedIn: Bool = false
    public var isLoading: Bool = false
    public var errorMessage: String?

    // MARK: - Init

    override public init() {
        super.init()
        isSignedIn = KeychainHelper.read(key: .refreshToken) != nil
    }

    // MARK: - Public API

    /// Returns a valid access token, refreshing via the refresh token if needed.
    public func validAccessToken() async throws -> String {
        if let token = KeychainHelper.read(key: .accessToken),
           let expiresStr = KeychainHelper.read(key: .expiresAt),
           let expires = Double(expiresStr),
           Date(timeIntervalSince1970: expires) > Date().addingTimeInterval(60) {
            return token
        }
        guard let refresh = KeychainHelper.read(key: .refreshToken) else {
            throw TeslaAuthError.notSignedIn
        }
        return try await performRefresh(refreshToken: refresh)
    }

    /// Starts the PKCE OAuth flow in an in-app browser.
    public func signIn() async {
        guard Self.clientID != "YOUR_CLIENT_ID" else {
            errorMessage = "Tesla Client ID not configured. See developer.tesla.com."
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let (verifier, challenge) = generatePKCE()
            let state = UUID().uuidString

            var comps = URLComponents(url: Self.authURL, resolvingAgainstBaseURL: false)!
            comps.queryItems = [
                .init(name: "client_id",             value: Self.clientID),
                .init(name: "redirect_uri",          value: Self.redirectURI),
                .init(name: "response_type",         value: "code"),
                .init(name: "scope",                 value: Self.scopes),
                .init(name: "code_challenge",        value: challenge),
                .init(name: "code_challenge_method", value: "S256"),
                .init(name: "state",                 value: state),
            ]

            let callbackURL: URL = try await withCheckedThrowingContinuation { continuation in
                let session = ASWebAuthenticationSession(
                    url: comps.url!,
                    callbackURLScheme: "wimsc"
                ) { url, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else if let url {
                        continuation.resume(returning: url)
                    } else {
                        continuation.resume(throwing: TeslaAuthError.noCallback)
                    }
                }
                session.presentationContextProvider = KeyWindowPresenter.shared
                session.prefersEphemeralWebBrowserSession = false
                session.start()
            }

            guard let callbackComps = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
                  let code = callbackComps.queryItems?.first(where: { $0.name == "code" })?.value
            else {
                throw TeslaAuthError.noAuthCode
            }

            try await exchangeCode(code, codeVerifier: verifier)
            isSignedIn = true

        } catch ASWebAuthenticationSessionError.canceledLogin {
            // User cancelled — not an error
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func signOut() {
        KeychainHelper.delete(key: .accessToken)
        KeychainHelper.delete(key: .refreshToken)
        KeychainHelper.delete(key: .expiresAt)
        isSignedIn = false
    }

    // MARK: - Token exchange

    private func exchangeCode(_ code: String, codeVerifier: String) async throws {
        let body = [
            "grant_type=authorization_code",
            "client_id=\(Self.clientID)",
            "code=\(code)",
            "redirect_uri=\(Self.redirectURI)",
            "code_verifier=\(codeVerifier)",
        ].joined(separator: "&")
        let data = try await postForm(url: Self.tokenURL, body: body)
        try storeTokens(from: data)
    }

    @discardableResult
    private func performRefresh(refreshToken: String) async throws -> String {
        let body = [
            "grant_type=refresh_token",
            "client_id=\(Self.clientID)",
            "refresh_token=\(refreshToken)",
        ].joined(separator: "&")
        let data = try await postForm(url: Self.tokenURL, body: body)
        try storeTokens(from: data)
        guard let token = KeychainHelper.read(key: .accessToken) else {
            throw TeslaAuthError.tokenParseFailed
        }
        return token
    }

    private func postForm(url: URL, body: String) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = body.data(using: .utf8)
        request.timeoutInterval = 15
        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw TeslaAuthError.httpError(http.statusCode)
        }
        return data
    }

    private func storeTokens(from data: Data) throws {
        struct TokenResponse: Decodable {
            let access_token: String
            let refresh_token: String?
            let expires_in: Int
        }
        let resp = try JSONDecoder().decode(TokenResponse.self, from: data)
        KeychainHelper.write(key: .accessToken, value: resp.access_token)
        if let rt = resp.refresh_token {
            KeychainHelper.write(key: .refreshToken, value: rt)
        }
        let expiresAt = Date().addingTimeInterval(Double(resp.expires_in))
        KeychainHelper.write(key: .expiresAt, value: "\(expiresAt.timeIntervalSince1970)")
    }

    // MARK: - PKCE

    private func generatePKCE() -> (verifier: String, challenge: String) {
        var bytes = [UInt8](repeating: 0, count: 64)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        let verifier = Data(bytes)
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")

        guard let verifierData = verifier.data(using: .utf8) else { return (verifier, verifier) }
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        verifierData.withUnsafeBytes { _ = CC_SHA256($0.baseAddress, CC_LONG(verifierData.count), &hash) }
        let challenge = Data(hash)
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        return (verifier, challenge)
    }
}

// MARK: - Errors

public enum TeslaAuthError: LocalizedError {
    case notSignedIn, noCallback, noAuthCode, tokenParseFailed, httpError(Int)

    public var errorDescription: String? {
        switch self {
        case .notSignedIn:      return "Not signed in to Tesla."
        case .noCallback:       return "No callback URL received from Tesla."
        case .noAuthCode:       return "Authorization code missing from callback."
        case .tokenParseFailed: return "Failed to parse token response."
        case .httpError(let c): return "Tesla auth server returned HTTP \(c)."
        }
    }
}

// MARK: - ASWebAuthenticationSession presentation

private final class KeyWindowPresenter: NSObject, ASWebAuthenticationPresentationContextProviding, @unchecked Sendable {
    static let shared = KeyWindowPresenter()

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow }) ?? UIWindow()
    }
}

// MARK: - Keychain helper

private enum KeychainKey: String {
    case accessToken  = "wimsc.tesla.access_token"
    case refreshToken = "wimsc.tesla.refresh_token"
    case expiresAt    = "wimsc.tesla.expires_at"
}

private enum KeychainHelper {
    static func read(key: KeychainKey) -> String? {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String:  true,
            kSecMatchLimit as String:  kSecMatchLimitOne,
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data,
              let str = String(data: data, encoding: .utf8)
        else { return nil }
        return str
    }

    static func write(key: KeychainKey, value: String) {
        delete(key: key)
        let attrs: [String: Any] = [
            kSecClass as String:            kSecClassGenericPassword,
            kSecAttrAccount as String:      key.rawValue,
            kSecValueData as String:        value.data(using: .utf8)!,
            kSecAttrAccessible as String:   kSecAttrAccessibleAfterFirstUnlock,
        ]
        SecItemAdd(attrs as CFDictionary, nil)
    }

    static func delete(key: KeychainKey) {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
