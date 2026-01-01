import Foundation

// MARK: - Persistence Service
// Actor-based service for persisting health data to JSON files in the Documents directory.
// This enables instant UI loading on app launch and offline viewing of previously synced data.

actor PersistenceService {
    static let shared = PersistenceService()
    
    private let fileManager = FileManager.default
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    
    private var cacheDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("OuraCache", isDirectory: true)
    }
    
    private init() {
        encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        decoder = JSONDecoder()
        
        // Ensure cache directory exists
        Task {
            await ensureCacheDirectoryExists()
        }
    }
    
    // MARK: - Directory Management
    
    private func ensureCacheDirectoryExists() {
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
    }
    
    private func profileDataURL(for profileId: String) -> URL {
        cacheDirectory.appendingPathComponent("profile_\(profileId).json")
    }
    
    private func lastSyncURL(for profileId: String) -> URL {
        cacheDirectory.appendingPathComponent("lastsync_\(profileId).txt")
    }
    
    // MARK: - Profile Data Persistence
    
    func saveProfileData(_ data: CodableProfileData, for profileId: String) async throws {
        ensureCacheDirectoryExists()
        let url = profileDataURL(for: profileId)
        let jsonData = try encoder.encode(data)
        try jsonData.write(to: url, options: .atomic)
    }
    
    func loadProfileData(for profileId: String) async -> CodableProfileData? {
        let url = profileDataURL(for: profileId)
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        
        do {
            let data = try Data(contentsOf: url)
            return try decoder.decode(CodableProfileData.self, from: data)
        } catch {
            print("Failed to load cached profile data: \(error)")
            return nil
        }
    }
    
    // MARK: - Last Sync Date
    
    func getLastSyncDate(for profileId: String) async -> Date? {
        let url = lastSyncURL(for: profileId)
        guard let string = try? String(contentsOf: url, encoding: .utf8),
              let timestamp = TimeInterval(string) else { return nil }
        return Date(timeIntervalSince1970: timestamp)
    }
    
    func setLastSyncDate(_ date: Date, for profileId: String) async {
        ensureCacheDirectoryExists()
        let url = lastSyncURL(for: profileId)
        let timestamp = String(date.timeIntervalSince1970)
        try? timestamp.write(to: url, atomically: true, encoding: .utf8)
    }
    
    // MARK: - Cleanup
    
    func deleteProfileData(for profileId: String) async {
        let dataURL = profileDataURL(for: profileId)
        let syncURL = lastSyncURL(for: profileId)
        try? fileManager.removeItem(at: dataURL)
        try? fileManager.removeItem(at: syncURL)
    }
    
    func clearAllCache() async {
        try? fileManager.removeItem(at: cacheDirectory)
        ensureCacheDirectoryExists()
    }
}

// MARK: - Codable Profile Data Structures

/// Codable wrapper for ProfileData to enable JSON persistence
struct CodableProfileData: Codable {
    var dayDataMap: [String: CodableDayData]
    var lastSyncDate: Date?
    
    init(dayDataMap: [String: CodableDayData] = [:], lastSyncDate: Date? = nil) {
        self.dayDataMap = dayDataMap
        self.lastSyncDate = lastSyncDate
    }
}

/// Codable wrapper for DayData
struct CodableDayData: Codable {
    var sleep: DailySleep?
    var readiness: DailyReadiness?
    var activity: DailyActivity?
    var session: SleepSession?
    var spo2: DailySpO2?
    var heartRate: [HeartRate]
    
    init(sleep: DailySleep? = nil, readiness: DailyReadiness? = nil, 
         activity: DailyActivity? = nil, session: SleepSession? = nil,
         spo2: DailySpO2? = nil, heartRate: [HeartRate] = []) {
        self.sleep = sleep
        self.readiness = readiness
        self.activity = activity
        self.session = session
        self.spo2 = spo2
        self.heartRate = heartRate
    }
}
