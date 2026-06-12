import Foundation

// MARK: - OAuth Configuration

enum OuraConfig: Sendable {
    static let clientID = "92e4c379-b278-4c42-a7c0-db088b67680f"
    static let redirectScheme = "ouraleaderboard"
    static let redirectURI = "\(redirectScheme)://oauth/callback"
    static let authBaseURL = "https://cloud.ouraring.com/oauth/authorize"
    static let tokenURL = URL(string: "https://api.ouraring.com/oauth/token")!
    static let scopes = [
        "email",
        "personal",
        "daily",
        "heartrate",
        "workout",
        "session",
        "tag",
        "spo2",
        "ring_configuration",
        "stress",
        "heart_health"
    ]
    
    // Do not hardcode secrets in source; use env var or Info.plist for local dev.
    static var clientSecret: String {
        if let secret = ProcessInfo.processInfo.environment["OURA_CLIENT_SECRET"] {
            return secret
        }
        if let secret = Bundle.main.object(forInfoDictionaryKey: "OURA_CLIENT_SECRET") as? String {
            return secret
        }
        return ""
    }
    
    static func authorizationURL(codeChallenge: String, state: String) -> URL {
        var components = URLComponents(string: authBaseURL)!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: scopes.joined(separator: " ")),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "state", value: state)
        ]
        return components.url!
    }
}

// MARK: - API Configuration

enum APIConfig: Sendable {
    nonisolated static let baseURL = "https://api.ouraring.com/v2/usercollection"
    
    enum Endpoint: Sendable {
        case personalInfo
        case dailySleep
        case sleep
        case dailyReadiness
        case dailyActivity
        case heartrate
        case dailySpo2
        case dailyStress
        case dailyResilience
        case workout
        // New endpoints for full API coverage
        case tag
        case enhancedTag
        case session
        case sleepTime
        case restModePeriod
        case ringConfiguration
        case dailyCardiovascularAge
        case vo2Max
        
        nonisolated var path: String {
            switch self {
            case .personalInfo: return "/personal_info"
            case .dailySleep: return "/daily_sleep"
            case .sleep: return "/sleep"
            case .dailyReadiness: return "/daily_readiness"
            case .dailyActivity: return "/daily_activity"
            case .heartrate: return "/heartrate"
            case .dailySpo2: return "/daily_spo2"
            case .dailyStress: return "/daily_stress"
            case .dailyResilience: return "/daily_resilience"
            case .workout: return "/workout"
            case .tag: return "/tag"
            case .enhancedTag: return "/enhanced_tag"
            case .session: return "/session"
            case .sleepTime: return "/sleep_time"
            case .restModePeriod: return "/rest_mode_period"
            case .ringConfiguration: return "/ring_configuration"
            case .dailyCardiovascularAge: return "/daily_cardiovascular_age"
            case .vo2Max: return "/vO2_max"
            }
        }
    }
}

// MARK: - Firebase Configuration

enum FirebaseConfig: Sendable {
    static let profilesCollection = "profiles"
}

// MARK: - AI Configuration

enum AIConfig: Sendable {
    // Note: API key should be stored securely, not in code
    // This is a placeholder - in production, use Keychain or environment config
    static var geminiAPIKey: String {
        // Try to get from environment or Info.plist
        if let key = ProcessInfo.processInfo.environment["GEMINI_API_KEY"] {
            return key
        }
        if let key = Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String {
            return key
        }
        return ""
    }
}

// MARK: - App Constants

enum AppConstants: Sendable {
    nonisolated static let appName = "Davis Watches You Sleep"
    nonisolated static let defaultDataRangeDays = 30
    nonisolated static let allTimeStartDate = "2016-01-01"
    // 7 days of heart rate so past days in date navigation still have charts
    nonisolated static let heartRateDataRangeDays = 7
}
