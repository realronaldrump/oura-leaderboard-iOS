import SwiftUI
import Combine

// MARK: - App State

@MainActor
@Observable
class AppState {
    // MARK: - Profile Management
    var profiles: [UserProfile] = []
    var activeProfileId: String? {
        didSet {
            if let id = activeProfileId {
                UserDefaults.standard.set(id, forKey: "active_profile_id")
            } else {
                UserDefaults.standard.removeObject(forKey: "active_profile_id")
            }
        }
    }
    
    var activeProfile: UserProfile? {
        profiles.first { $0.id == activeProfileId }
    }
    
    // MARK: - Data Cache
    var dailyStats: [String: DailyStats] = [:]  // Keyed by profile ID
    var allTimeStats: [String: DailyStats] = [:]  // Keyed by profile ID
    var heartRateData: [String: [HeartRate]] = [:]  // Keyed by profile ID
    
    // MARK: - UI State
    var isLoading = false
    var authStatus: AuthStatus = .unauthenticated
    var viewMode: ViewMode = .daily
    var selectedDateIndex = 0
    var errorMessage: String?
    
    // MARK: - AI State
    var aiBriefing: String?
    var isGeneratingBriefing = false
    
    // MARK: - Services
    private let localStorage = LocalProfileStorage.shared
    
    // MARK: - Initialization
    
    init() {
        // Load saved profile ID
        activeProfileId = UserDefaults.standard.string(forKey: "active_profile_id")
        
        // Load profiles from local storage
        profiles = localStorage.profiles
        
        // Try to initialize Firebase (optional)
        // FirebaseService.shared.initialize()
    }
    
    // MARK: - Authentication
    
    func login() async {
        authStatus = .loading
        
        do {
            let token = try await AuthService.shared.authenticate()
            try await addProfile(token: token)
            authStatus = .authenticated
        } catch {
            if case AuthError.cancelled = error {
                authStatus = .unauthenticated
            } else {
                errorMessage = error.localizedDescription
                authStatus = .unauthenticated
            }
        }
    }
    
    func addProfile(token: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Fetch personal info from Oura
        var profile = try await OuraAPIService.shared.getPersonalInfo(token: token)
        
        // Check if profile with same email already exists
        if let existingProfile = profiles.first(where: { $0.email == profile.email }) {
            profile = UserProfile(
                id: existingProfile.id,
                age: profile.age,
                weight: profile.weight,
                height: profile.height,
                biologicalSex: profile.biologicalSex,
                email: profile.email,
                token: token,
                lastUpdated: ISO8601DateFormatter().string(from: Date()),
                firstName: existingProfile.firstName,
                lastName: existingProfile.lastName
            )
        }
        
        // Save to local storage
        localStorage.addProfile(profile)
        profiles = localStorage.profiles
        
        // Set as active profile
        activeProfileId = profile.id
        
        // Fetch initial data
        await loadDataForProfile(profile)
    }
    
    func removeProfile(id: String) {
        localStorage.deleteProfile(id: id)
        profiles = localStorage.profiles
        
        // Clear data cache
        dailyStats.removeValue(forKey: id)
        allTimeStats.removeValue(forKey: id)
        heartRateData.removeValue(forKey: id)
        
        // Clear active profile if it was the one removed
        if activeProfileId == id {
            activeProfileId = profiles.first?.id
        }
    }
    
    func switchProfile(_ id: String) {
        activeProfileId = id
        selectedDateIndex = 0
        
        // Load data if not cached
        if let profile = profiles.first(where: { $0.id == id }) {
            Task {
                await loadDataForProfile(profile)
            }
        }
    }
    
    func logout() {
        activeProfileId = nil
        authStatus = .unauthenticated
    }
    
    // MARK: - Data Loading
    
    func loadDataForProfile(_ profile: UserProfile) async {
        await loadDailyStats(for: profile)
        await loadHeartRate(for: profile)
    }
    
    func loadDailyStats(for profile: UserProfile) async {
        guard dailyStats[profile.id] == nil else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let stats = try await OuraAPIService.shared.fetchDailyStats(token: profile.token)
            dailyStats[profile.id] = stats
        } catch {
            print("Failed to load daily stats: \(error)")
            errorMessage = error.localizedDescription
        }
    }
    
    func loadAllTimeStats(for profile: UserProfile) async {
        guard allTimeStats[profile.id] == nil else { return }
        
        do {
            let stats = try await OuraAPIService.shared.fetchDailyStats(
                token: profile.token,
                start: AppConstants.allTimeStartDate
            )
            allTimeStats[profile.id] = stats
        } catch {
            print("Failed to load all-time stats: \(error)")
        }
    }
    
    func loadHeartRate(for profile: UserProfile) async {
        guard heartRateData[profile.id] == nil else { return }
        
        do {
            let hrData = try await OuraAPIService.shared.getHeartRate(token: profile.token)
            heartRateData[profile.id] = hrData
        } catch {
            print("Failed to load heart rate: \(error)")
        }
    }
    
    func loadAllProfilesData() async {
        for profile in profiles {
            await loadDataForProfile(profile)
        }
    }
    
    // MARK: - Leaderboard
    
    var leaderboardData: [LeaderboardEntry] {
        profiles.compactMap { profile -> LeaderboardEntry? in
            guard let stats = dailyStats[profile.id] else { return nil }
            
            let lastSleep = stats.sleep.first
            let lastReadiness = stats.readiness.first
            let lastActivity = stats.activity.first
            let lastSession = stats.session.first
            
            let sScore = lastSleep?.score ?? 0
            let rScore = lastReadiness?.score ?? 0
            let aScore = lastActivity?.score ?? 0
            
            return LeaderboardEntry(
                id: profile.id,
                name: profile.displayName,
                readiness: rScore,
                sleep: sScore,
                activity: aScore,
                average: (sScore + rScore + aScore) / 3,
                isCurrentUser: profile.id == activeProfileId,
                steps: lastActivity?.steps,
                activeCalories: lastActivity?.activeCalories,
                sleepDuration: lastSession?.totalSleepDuration,
                averageHrv: lastSession?.averageHrv,
                restingHeartRate: lastSession?.lowestHeartRate
            )
        }.sorted { $0.average > $1.average }
    }
    
    // MARK: - Current Data Helpers
    
    var activeStats: DailyStats? {
        guard let id = activeProfileId else { return nil }
        return dailyStats[id]
    }
    
    var currentSleep: DailySleep? {
        activeStats?.sleep[safe: selectedDateIndex]
    }
    
    var currentReadiness: DailyReadiness? {
        activeStats?.readiness[safe: selectedDateIndex]
    }
    
    var currentActivity: DailyActivity? {
        activeStats?.activity[safe: selectedDateIndex]
    }
    
    var currentSession: SleepSession? {
        guard let day = currentSleep?.day else { return nil }
        return activeStats?.session.first { $0.day == day } ?? activeStats?.session[safe: selectedDateIndex]
    }
    
    var currentSpo2: DailySpO2? {
        guard let day = currentSleep?.day else { return nil }
        return activeStats?.spo2.first { $0.day == day }
    }
    
    var activeHeartRate: [HeartRate] {
        guard let id = activeProfileId else { return [] }
        return heartRateData[id] ?? []
    }
    
    // MARK: - AI Insights
    
    func generateAIBriefing() async {
        guard profiles.count >= 2 else { return }
        
        isGeneratingBriefing = true
        defer { isGeneratingBriefing = false }
        
        let p1 = profiles[0]
        let p2 = profiles[1]
        let stats1 = dailyStats[p1.id]
        let stats2 = dailyStats[p2.id]
        
        guard stats1 != nil, stats2 != nil else { return }
        
        do {
            let briefing = try await AIService.shared.generateBriefing(
                statsA: (stats1?.sleep.first, stats1?.readiness.first, stats1?.activity.first),
                statsB: (stats2?.sleep.first, stats2?.readiness.first, stats2?.activity.first),
                nameA: p1.displayName,
                nameB: p2.displayName
            )
            aiBriefing = briefing
        } catch {
            print("Failed to generate AI briefing: \(error)")
            aiBriefing = "Failed to generate briefing. Please try again."
        }
    }
    
    // MARK: - Date Navigation
    
    var canGoBack: Bool {
        guard let stats = activeStats else { return false }
        return selectedDateIndex < stats.sleep.count - 1
    }
    
    var canGoForward: Bool {
        selectedDateIndex > 0
    }
    
    func goToPreviousDay() {
        if canGoBack {
            selectedDateIndex += 1
        }
    }
    
    func goToNextDay() {
        if canGoForward {
            selectedDateIndex -= 1
        }
    }
}

// MARK: - View Mode

enum ViewMode: String, CaseIterable {
    case daily = "Daily"
    case versus = "Versus"
    case history = "History"
}

// MARK: - Collection Extension

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
