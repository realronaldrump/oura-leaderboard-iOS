import SwiftUI
import Combine

// MARK: - Enhanced App State with Better Performance

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
    
    // MARK: - Data Cache with Proper Date Alignment
    // Actor-based cache for thread-safe persistence operations
    private let dataCache = DataCache()
    // Local mirror for synchronous view access (updated after cache operations)
    private var localCache: [String: ProfileData] = [:]
    
    // MARK: - Loading States
    var loadingStates: [String: LoadingState] = [:] // Per-profile loading states
    var globalLoadingState = LoadingState()
    
    // MARK: - UI State
    var authStatus: AuthStatus = .unauthenticated
    var viewMode: ViewMode = .daily
    var selectedDate = Date() // Using actual Date instead of index
    var errorMessage: String?
    var lastSyncAt: Date?
    var syncMessage: String?
    
    // MARK: - All-Time Stats Storage
    var allTimeStats: [String: DailyStats] = [:]
    
    // MARK: - Computed Loading Properties
    var isLoading: Bool {
        globalLoadingState.isLoading
    }
    
    var isSyncing: Bool {
        loadingStates.values.contains { $0.isLoading }
    }
    
    // MARK: - Daily Stats (computed from local cache mirror)
    var dailyStats: [String: DailyStats] {
        var result: [String: DailyStats] = [:]
        for profile in profiles {
            if let data = localCache[profile.id] {
                result[profile.id] = data.toDailyStats()
            }
        }
        return result
    }
    
    // MARK: - AI State
    var aiBriefing: String?
    var isGeneratingBriefing = false
    
    // MARK: - Services
    private let localStorage = LocalProfileStorage.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        // Load saved profile ID
        activeProfileId = UserDefaults.standard.string(forKey: "active_profile_id")
        
        // Load profiles from local storage
        profiles = localStorage.profiles
        
        // Setup data refresh timer
        setupAutoRefresh()
        
        // Load cached data from disk for instant UI (async)
        Task {
            await loadCachedDataFromDisk()
        }
    }
    
    /// Load all profile data from disk cache for instant UI on app launch
    private func loadCachedDataFromDisk() async {
        for profile in profiles {
            await dataCache.loadFromDisk(for: profile.id)
            // Update local mirror for synchronous view access
            if let data = await dataCache.getData(for: profile.id) {
                localCache[profile.id] = data
            }
        }
    }
    
    // MARK: - Data Access with Proper Date Alignment
    
    var activeStats: ProfileData? {
        guard let id = activeProfileId else { return nil }
        return localCache[id]
    }
    
    var currentDateKey: String {
        // Use static formatter instead of creating new instance
        Formatters.dayKeyString(from: selectedDate)
    }
    
    var currentDayData: DayData? {
        activeStats?.getDayData(for: currentDateKey)
    }
    
    var currentSleep: DailySleep? {
        currentDayData?.sleep
    }
    
    var currentReadiness: DailyReadiness? {
        currentDayData?.readiness
    }
    
    var currentActivity: DailyActivity? {
        currentDayData?.activity
    }
    
    var currentSession: SleepSession? {
        currentDayData?.session
    }
    
    var currentSpo2: DailySpO2? {
        currentDayData?.spo2
    }
    
    var currentHeartRate: [HeartRate] {
        currentDayData?.heartRate ?? []
    }

    var activeHeartRate: [HeartRate] {
        currentHeartRate
    }
    
    // MARK: - Authentication
    
    func login() async {
        authStatus = .loading
        errorMessage = nil
        
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
        globalLoadingState.isLoading = true
        globalLoadingState.message = "Adding profile..."
        defer { globalLoadingState.isLoading = false }
        
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
        
        // Fetch initial data in background
        await loadDataForProfile(profile, forceRefresh: true)
    }
    
    // MARK: - Optimized Data Loading
    
    func loadDataForProfile(_ profile: UserProfile, forceRefresh: Bool = false) async {
        let profileId = profile.id
        
        // Check if we already have recent data
        if !forceRefresh, let lastSync = await dataCache.getLastSync(for: profileId),
           Date().timeIntervalSince(lastSync) < 300 { // 5 minutes
            return
        }
        
        // Update loading state
        loadingStates[profileId] = LoadingState(isLoading: true, message: "Syncing data...")
        
        // Sequential loading with small delays to prevent API rate limiting (429 errors)
        // This is especially important when multiple profiles are being synced
        await loadDailyData(for: profile)
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms delay
        
        await loadHeartRateData(for: profile)
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms delay
        
        await loadSpo2Data(for: profile)
        
        // Update local cache mirror for synchronous view access
        if let data = await dataCache.getData(for: profileId) {
            localCache[profileId] = data
        }
        
        // Persist to disk for offline access and instant UI on next launch
        await dataCache.saveToDisk(for: profileId)
        await dataCache.setLastSync(for: profileId, date: Date())
        
        loadingStates[profileId] = LoadingState(isLoading: false)
        lastSyncAt = Date()
    }
    
    private func loadDailyData(for profile: UserProfile) async {
        do {
            async let sleepData = OuraAPIService.shared.getDailySleep(token: profile.token)
            async let readinessData = OuraAPIService.shared.getDailyReadiness(token: profile.token)
            async let activityData = OuraAPIService.shared.getDailyActivity(token: profile.token)
            async let sessionData = OuraAPIService.shared.getSleepSessions(token: profile.token)
            
            let (sleep, readiness, activity, sessions) = await (
                try sleepData,
                try readinessData,
                try activityData,
                try sessionData
            )
            
            await dataCache.updateDailyData(
                for: profile.id,
                sleep: sleep,
                readiness: readiness,
                activity: activity,
                sessions: sessions
            )
        } catch {
            print("Failed to load daily data: \(error)")
            errorMessage = "Failed to sync daily data"
        }
    }
    
    private func loadHeartRateData(for profile: UserProfile) async {
        do {
            let heartRate = try await OuraAPIService.shared.getHeartRate(token: profile.token)
            await dataCache.updateHeartRateData(for: profile.id, heartRate: heartRate)
        } catch {
            print("Failed to load heart rate data: \(error)")
        }
    }
    
    private func loadSpo2Data(for profile: UserProfile) async {
        do {
            let spo2 = try await OuraAPIService.shared.getDailySpO2(token: profile.token)
            await dataCache.updateSpo2Data(for: profile.id, spo2: spo2)
        } catch {
            print("Failed to load SpO2 data: \(error)")
        }
    }
    
    // MARK: - Profile Management
    
    func removeProfile(id: String) {
        localStorage.deleteProfile(id: id)
        profiles = localStorage.profiles
        localCache.removeValue(forKey: id)
        Task {
            await dataCache.removeData(for: id)
            await PersistenceService.shared.deleteProfileData(for: id)
        }
        
        if activeProfileId == id {
            activeProfileId = profiles.first?.id
        }
    }
    
    func switchProfile(_ id: String) {
        activeProfileId = id
        selectedDate = Date()
        
        // Load data if not cached
        if let profile = profiles.first(where: { $0.id == id }) {
            Task {
                await loadDataForProfile(profile)
            }
        }
    }
    
    // MARK: - Date Navigation
    
    var availableDates: [Date] {
        guard let stats = activeStats else { return [] }
        return stats.availableDates.sorted(by: >)
    }
    
    var canGoBack: Bool {
        guard let currentIndex = availableDates.firstIndex(where: { 
            Calendar.current.isDate($0, inSameDayAs: selectedDate)
        }) else { return false }
        return currentIndex < availableDates.count - 1
    }
    
    var canGoForward: Bool {
        guard let currentIndex = availableDates.firstIndex(where: { 
            Calendar.current.isDate($0, inSameDayAs: selectedDate)
        }) else { return false }
        return currentIndex > 0
    }
    
    func goToPreviousDay() {
        guard canGoBack,
              let currentIndex = availableDates.firstIndex(where: { 
                  Calendar.current.isDate($0, inSameDayAs: selectedDate)
              }) else { return }
        
        selectedDate = availableDates[currentIndex + 1]
        provideHapticFeedback(.selection)
    }
    
    func goToNextDay() {
        guard canGoForward,
              let currentIndex = availableDates.firstIndex(where: { 
                  Calendar.current.isDate($0, inSameDayAs: selectedDate)
              }) else { return }
        
        selectedDate = availableDates[currentIndex - 1]
        provideHapticFeedback(.selection)
    }
    
    func goToToday() {
        selectedDate = Date()
        provideHapticFeedback(.selection)
    }
    
    // MARK: - Refresh
    
    func refreshActiveProfile() async {
        guard let profile = activeProfile else { return }
        await loadDataForProfile(profile, forceRefresh: true)
    }
    
    func refreshAllProfiles() async {
        await withTaskGroup(of: Void.self) { group in
            for profile in profiles {
                group.addTask { [weak self] in
                    await self?.loadDataForProfile(profile, forceRefresh: true)
                }
            }
        }
    }
    
    func loadAllProfilesData() async {
        await refreshAllProfiles()
    }
    
    // MARK: - All-Time Stats Loading
    
    func loadAllTimeStats(for profile: UserProfile) async {
        do {
            // Fetch extended history (e.g., all available data)
            async let sleepData = OuraAPIService.shared.getDailySleep(token: profile.token, days: 365)
            async let readinessData = OuraAPIService.shared.getDailyReadiness(token: profile.token, days: 365)
            async let activityData = OuraAPIService.shared.getDailyActivity(token: profile.token, days: 365)
            async let sessionData = OuraAPIService.shared.getSleepSessions(token: profile.token, days: 365)
            
            let (sleep, readiness, activity, sessions) = await (
                try sleepData,
                try readinessData,
                try activityData,
                try sessionData
            )
            
            let stats = DailyStats(
                sleep: sleep,
                readiness: readiness,
                activity: activity,
                session: sessions,
                spo2: [],
                stress: [],
                resilience: []
            )
            
            allTimeStats[profile.id] = stats
        } catch {
            print("Failed to load all-time stats: \(error)")
        }
    }
    
    // MARK: - Logout
    
    func logout() {
        // Remove active profile and clear data
        if let activeId = activeProfileId {
            removeProfile(id: activeId)
        }
        authStatus = .unauthenticated
    }
    
    // MARK: - Auto Refresh
    
    private func setupAutoRefresh() {
        Timer.publish(every: 300, on: .main, in: .common) // Every 5 minutes
            .autoconnect()
            .sink { [weak self] _ in
                Task { [weak self] in
                    await self?.refreshActiveProfile()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Leaderboard
    
    var leaderboardData: [LeaderboardEntry] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        // Use static formatter instead of creating new instance
        let todayKey = Formatters.dayKeyString(from: today)
        
        return profiles.compactMap { profile -> LeaderboardEntry? in
            // Use localCache for synchronous view access
            guard let data = localCache[profile.id],
                  let dayData = data.getDayData(for: todayKey) else { return nil }
            
            let sScore = dayData.sleep?.score ?? 0
            let rScore = dayData.readiness?.score ?? 0
            let aScore = dayData.activity?.score ?? 0
            
            return LeaderboardEntry(
                id: profile.id,
                name: profile.displayName,
                readiness: rScore,
                sleep: sScore,
                activity: aScore,
                average: (sScore + rScore + aScore) / 3,
                isCurrentUser: profile.id == activeProfileId,
                steps: dayData.activity?.steps,
                activeCalories: dayData.activity?.activeCalories,
                sleepDuration: dayData.session?.totalSleepDuration,
                averageHrv: dayData.session?.averageHrv,
                restingHeartRate: dayData.session?.lowestHeartRate
            )
        }.sorted { $0.average > $1.average }
    }
    
    // MARK: - AI Insights
    
    func generateAIBriefing() async {
        guard profiles.count >= 2 else { return }
        
        isGeneratingBriefing = true
        defer { isGeneratingBriefing = false }
        
        let p1 = profiles[0]
        let p2 = profiles[1]
        
        // Use localCache for synchronous access
        guard let data1 = localCache[p1.id],
              let data2 = localCache[p2.id],
              let day1 = data1.getDayData(for: currentDateKey),
              let day2 = data2.getDayData(for: currentDateKey) else { return }
        
        do {
            let briefing = try await AIService.shared.generateBriefing(
                statsA: (day1.sleep, day1.readiness, day1.activity),
                statsB: (day2.sleep, day2.readiness, day2.activity),
                nameA: p1.displayName,
                nameB: p2.displayName
            )
            aiBriefing = briefing
        } catch {
            print("Failed to generate AI briefing: \(error)")
            aiBriefing = "Failed to generate briefing. Please try again."
        }
    }
    
    // MARK: - Stats Access
    
    func getDailyStats(for profileId: String) -> DailyStats? {
        // Use localCache for synchronous access
        localCache[profileId]?.toDailyStats()
    }
    
    // MARK: - Haptic Feedback
    
    func provideHapticFeedback(_ style: HapticStyle) {
        let impactFeedback: (UIImpactFeedbackGenerator.FeedbackStyle) -> Void = { impactStyle in
            let generator = UIImpactFeedbackGenerator(style: impactStyle)
            generator.prepare()
            generator.impactOccurred()
        }
        
        switch style {
        case .selection:
            let generator = UISelectionFeedbackGenerator()
            generator.prepare()
            generator.selectionChanged()
        case .success:
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.success)
        case .warning:
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.warning)
        case .error:
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.error)
        case .light:
            impactFeedback(.light)
        case .medium:
            impactFeedback(.medium)
        case .heavy:
            impactFeedback(.heavy)
        case .soft:
            impactFeedback(.soft)
        case .rigid:
            impactFeedback(.rigid)
        }
    }
}

// MARK: - Haptic Style

enum HapticStyle {
    case light
    case medium
    case heavy
    case soft
    case rigid
    case selection
    case success
    case warning
    case error
}

// MARK: - Loading State

struct LoadingState {
    var isLoading = false
    var message: String?
    var progress: Double?
}

// MARK: - Data Cache (Actor for thread safety)

private actor DataCache {
    private var cache: [String: ProfileData] = [:]
    private var lastSync: [String: Date] = [:]
    
    func getData(for profileId: String) -> ProfileData? {
        cache[profileId]
    }
    
    func updateDailyData(for profileId: String, sleep: [DailySleep], readiness: [DailyReadiness], 
                        activity: [DailyActivity], sessions: [SleepSession]) {
        if cache[profileId] == nil {
            cache[profileId] = ProfileData()
        }
        cache[profileId]?.updateDailyData(sleep: sleep, readiness: readiness, 
                                         activity: activity, sessions: sessions)
    }
    
    func updateHeartRateData(for profileId: String, heartRate: [HeartRate]) {
        if cache[profileId] == nil {
            cache[profileId] = ProfileData()
        }
        cache[profileId]?.updateHeartRateData(heartRate: heartRate)
    }
    
    func updateSpo2Data(for profileId: String, spo2: [DailySpO2]) {
        if cache[profileId] == nil {
            cache[profileId] = ProfileData()
        }
        cache[profileId]?.updateSpo2Data(spo2: spo2)
    }
    
    func removeData(for profileId: String) {
        cache.removeValue(forKey: profileId)
        lastSync.removeValue(forKey: profileId)
    }
    
    func getLastSync(for profileId: String) -> Date? {
        lastSync[profileId]
    }
    
    func setLastSync(for profileId: String, date: Date) {
        lastSync[profileId] = date
    }
    
    // MARK: - Persistence Integration
    
    /// Load cached data from disk for a profile
    func loadFromDisk(for profileId: String) async {
        guard let codableData = await PersistenceService.shared.loadProfileData(for: profileId) else {
            return
        }
        
        // Convert CodableProfileData to ProfileData
        var profileData = ProfileData()
        for (dayKey, codableDay) in codableData.dayDataMap {
            var dayData = DayData()
            dayData.sleep = codableDay.sleep
            dayData.readiness = codableDay.readiness
            dayData.activity = codableDay.activity
            dayData.session = codableDay.session
            dayData.spo2 = codableDay.spo2
            dayData.heartRate = codableDay.heartRate
            profileData.setDayData(dayData, for: dayKey)
        }
        
        cache[profileId] = profileData
        lastSync[profileId] = codableData.lastSyncDate
    }
    
    /// Save current cache to disk for a profile
    func saveToDisk(for profileId: String) async {
        guard let profileData = cache[profileId] else { return }
        
        let codableData = profileData.toCodableProfileData(lastSync: lastSync[profileId])
        
        do {
            try await PersistenceService.shared.saveProfileData(codableData, for: profileId)
        } catch {
            print("Failed to persist profile data: \(error)")
        }
    }
}

    // MARK: - Profile Data has been moved to Models.swift to avoid MainActor isolation issues


