import Foundation
import AuthenticationServices
import Combine
import CryptoKit

// MARK: - Auth Service

@MainActor
class AuthService: NSObject, ObservableObject {
    static let shared = AuthService()
    
    private var webAuthSession: ASWebAuthenticationSession?
    private var authContinuation: CheckedContinuation<String, Error>?
    private var codeVerifier: String?
    private var oauthState: String?
    
    private override init() {
        super.init()
    }
    
    // MARK: - OAuth Flow
    
    func authenticate() async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            self.authContinuation = continuation

            let verifier = Self.makeCodeVerifier()
            let challenge = Self.makeCodeChallenge(from: verifier)
            let state = Self.makeState()
            self.codeVerifier = verifier
            self.oauthState = state

            let authURL = OuraConfig.authorizationURL(codeChallenge: challenge, state: state)
            let callbackScheme = OuraConfig.redirectScheme
            
            webAuthSession = ASWebAuthenticationSession(
                url: authURL,
                callbackURLScheme: callbackScheme
            ) { [weak self] callbackURL, error in
                guard let self = self else { return }
                
                if let error = error {
                    if let authError = error as? ASWebAuthenticationSessionError,
                       authError.code == .canceledLogin {
                        self.finishAuth(.failure(AuthError.cancelled))
                    } else {
                        self.finishAuth(.failure(AuthError.authFailed(error)))
                    }
                    return
                }
                
                guard let callbackURL = callbackURL else {
                    self.finishAuth(.failure(AuthError.noCallbackURL))
                    return
                }

                if let oauthError = self.extractOAuthError(from: callbackURL) {
                    self.finishAuth(.failure(AuthError.oauthError(oauthError.code, oauthError.description)))
                    return
                }

                guard let code = self.extractAuthorizationCode(from: callbackURL) else {
                    self.finishAuth(.failure(AuthError.noAuthorizationCode))
                    return
                }

                if let expectedState = self.oauthState {
                    guard let returnedState = self.extractState(from: callbackURL),
                          returnedState == expectedState else {
                        self.finishAuth(.failure(AuthError.invalidState))
                        return
                    }
                }

                Task { [weak self] in
                    guard let self = self else { return }
                    do {
                        let token = try await self.exchangeCodeForToken(code)
                        await self.finishAuth(.success(token))
                    } catch {
                        await self.finishAuth(.failure(AuthError.authFailed(error)))
                    }
                }
            }
            
            webAuthSession?.presentationContextProvider = self
            webAuthSession?.prefersEphemeralWebBrowserSession = false
            
            DispatchQueue.main.async {
                self.webAuthSession?.start()
            }
        }
    }
    
    // MARK: - Token Extraction
    
    private func extractAuthorizationCode(from url: URL) -> String? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let items = components.queryItems else { return nil }
        return items.first(where: { $0.name == "code" })?.value
    }

    private func extractState(from url: URL) -> String? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let items = components.queryItems else { return nil }
        return items.first(where: { $0.name == "state" })?.value
    }

    private func extractOAuthError(from url: URL) -> (code: String, description: String?)? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let items = components.queryItems else { return nil }

        guard let errorCode = items.first(where: { $0.name == "error" })?.value else { return nil }
        let description = items.first(where: { $0.name == "error_description" })?.value
        return (errorCode, description)
    }

    // MARK: - PKCE Helpers

    private static func makeCodeVerifier(length: Int = 64) -> String {
        let charset = Array("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
        var verifier = ""
        verifier.reserveCapacity(length)
        for _ in 0..<length {
            verifier.append(charset[Int.random(in: 0..<charset.count)])
        }
        return verifier
    }

    private static func makeCodeChallenge(from verifier: String) -> String {
        let data = Data(verifier.utf8)
        let digest = SHA256.hash(data: data)
        let base64 = Data(digest).base64EncodedString()
        return base64
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private static func makeState() -> String {
        UUID().uuidString.replacingOccurrences(of: "-", with: "")
    }

    // MARK: - Token Exchange

    private func exchangeCodeForToken(_ code: String) async throws -> String {
        guard let verifier = codeVerifier else {
            throw AuthError.missingCodeVerifier
        }

        var request = URLRequest(url: OuraConfig.tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let parameters = [
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": OuraConfig.redirectURI,
            "client_id": OuraConfig.clientID,
            "code_verifier": verifier
        ]

        request.httpBody = Self.formURLEncodedBody(parameters)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode else {
            throw AuthError.tokenExchangeFailed
        }

        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        return tokenResponse.accessToken
    }

    private static func formURLEncodedBody(_ parameters: [String: String]) -> Data {
        var components = URLComponents()
        components.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        return Data((components.percentEncodedQuery ?? "").utf8)
    }

    private func finishAuth(_ result: Result<String, Error>) {
        switch result {
        case .success(let token):
            authContinuation?.resume(returning: token)
        case .failure(let error):
            authContinuation?.resume(throwing: error)
        }
        authContinuation = nil
        codeVerifier = nil
        oauthState = nil
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding

extension AuthService: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        // Find the first active window scene
        let windowScene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive } 
            ?? UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
            
        guard let scene = windowScene else {
            // Extreme fallback if no scenes exist (unlikely in a foreground app).
            return UIWindow(frame: .zero)
        }
        
        // Return existing key window if possible
        if let keyWindow = scene.windows.first(where: { $0.isKeyWindow }) {
             return keyWindow
        }
        
        // Or any window
        if let firstWindow = scene.windows.first {
            return firstWindow
        }
        
        // Or create a new one attached to the scene (satisfying the requirement)
        return ASPresentationAnchor(windowScene: scene)
    }
}

// MARK: - Token Response

private struct TokenResponse: Decodable {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int?
    let tokenType: String?
    let scope: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
        case scope
    }
}

// MARK: - Auth Errors

enum AuthError: Error, LocalizedError {
    case cancelled
    case authFailed(Error)
    case noCallbackURL
    case noAuthorizationCode
    case oauthError(String, String?)
    case missingCodeVerifier
    case invalidState
    case tokenExchangeFailed
    
    var errorDescription: String? {
        switch self {
        case .cancelled:
            return "Authentication was cancelled"
        case .authFailed(let error):
            return "Authentication failed: \(error.localizedDescription)"
        case .noCallbackURL:
            return "No callback URL received"
        case .noAuthorizationCode:
            return "No authorization code found in callback"
        case .oauthError(let code, let description):
            if let description, !description.isEmpty {
                return "OAuth error: \(code) (\(description))"
            }
            return "OAuth error: \(code)"
        case .missingCodeVerifier:
            return "Missing code verifier for OAuth"
        case .invalidState:
            return "OAuth state did not match"
        case .tokenExchangeFailed:
            return "Failed to exchange authorization code for token"
        }
    }
}
