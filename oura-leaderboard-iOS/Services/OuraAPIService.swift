import Foundation

// MARK: - Oura API Service

final class OuraAPIService: Sendable {
    static let shared = OuraAPIService()
    
    private init() {}
    
    // MARK: - Date Helpers
    
    private func getDateRange(daysBack: Int = 30) -> (start: String, end: String) {
        let today = Date()
        // Calendar is thread-safe
        guard let pastDate = Calendar.current.date(byAdding: .day, value: -daysBack, to: today) else {
            // Fallback if calculation fails, though unlikely
            return ("", "")
        }
        
        // Use static formatter to avoid expensive allocations
        return (Formatters.dayKeyString(from: pastDate), Formatters.dayKeyString(from: today))
    }
    
    private func getDateRange(start: String, end: String? = nil) -> (start: String, end: String) {
        // Use static formatter to avoid expensive allocations
        let endDate = end ?? Formatters.dayKeyString(from: Date())
        return (start, endDate)
    }
    
    // MARK: - HTTP Helpers
    
    private func makeRequest<T: Codable>(
        endpoint: APIConfig.Endpoint,
        token: String,
        queryItems: [URLQueryItem] = []
    ) async throws -> T {
        let baseURL = APIConfig.baseURL
        // Ensure valid URL construction
        guard var components = URLComponents(string: baseURL + endpoint.path) else {
            throw OuraAPIError.networkError(NSError(domain: "InvalidURL", code: -1, userInfo: nil))
        }
        
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        
        guard let url = components.url else {
            throw OuraAPIError.networkError(NSError(domain: "InvalidURL", code: -1, userInfo: nil))
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OuraAPIError.invalidResponse
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            throw OuraAPIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
    
    private func fetchDataArray<T: Codable>(
        endpoint: APIConfig.Endpoint,
        token: String,
        startDate: String? = nil,
        endDate: String? = nil,
        useDatetime: Bool = false,
        useDateFilter: Bool = true
    ) async throws -> [T] {
        var allData: [T] = []
        var nextToken: String? = nil
        
        // Calculate date range if needed
        var start = ""
        var end = ""
        
        if useDateFilter {
            if let startDate = startDate {
                let range = getDateRange(start: startDate, end: endDate)
                start = range.start
                end = range.end
            } else {
                let daysBack = AppConstants.defaultDataRangeDays
                let range = getDateRange(daysBack: daysBack)
                start = range.start
                end = range.end
            }
        }
        
        // Paginate through all results
        repeat {
            var queryItems: [URLQueryItem] = []
            
            if useDateFilter {
                if useDatetime {
                    queryItems = [
                        URLQueryItem(name: "start_datetime", value: "\(start)T00:00:00"),
                        URLQueryItem(name: "end_datetime", value: "\(end)T23:59:59")
                    ]
                } else {
                    queryItems = [
                        URLQueryItem(name: "start_date", value: start),
                        URLQueryItem(name: "end_date", value: end)
                    ]
                }
            }
            
            // Add pagination token if we have one
            if let token = nextToken {
                queryItems.append(URLQueryItem(name: "next_token", value: token))
            }
            
            let response: OuraDataResponse<T> = try await makeRequest(
                endpoint: endpoint,
                token: token,
                queryItems: queryItems
            )
            
            allData.append(contentsOf: response.data)
            nextToken = response.nextToken
            
            // Safety: break if API returns empty data with a nextToken (known API quirk)
            // This prevents potential infinite loops
            if response.data.isEmpty && nextToken != nil {
                print("Warning: Empty data with nextToken - breaking pagination loop")
                break
            }
        } while nextToken != nil
        
        return allData
    }
    
    // MARK: - API Methods
    
    func getPersonalInfo(token: String) async throws -> UserProfile {
        let baseURL = APIConfig.baseURL
        guard let components = URLComponents(string: baseURL + APIConfig.Endpoint.personalInfo.path),
              let url = components.url else {
            throw OuraAPIError.networkError(NSError(domain: "InvalidURL", code: -1))
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode else {
            throw OuraAPIError.invalidResponse
        }
        
        // Decode partial data and add token
        struct PersonalInfoResponse: Codable {
            var id: String?
            var age: Int?
            var weight: Double?
            var height: Double?
            var biologicalSex: String?
            var email: String?
            
            enum CodingKeys: String, CodingKey {
                case id, age, weight, height, email
                case biologicalSex = "biological_sex"
            }
        }
        
        let decoder = JSONDecoder()
        let info = try decoder.decode(PersonalInfoResponse.self, from: data)
        
        return UserProfile(
            id: info.id ?? UUID().uuidString,
            age: info.age,
            weight: info.weight,
            height: info.height,
            biologicalSex: info.biologicalSex,
            email: info.email,
            token: token,
            lastUpdated: Formatters.iso8601.string(from: Date())
        )
    }
    
    func getDailySleep(token: String, start: String? = nil, end: String? = nil) async throws -> [DailySleep] {
        try await fetchDataArray(endpoint: .dailySleep, token: token, startDate: start, endDate: end)
    }
    
    func getSleepSessions(token: String, start: String? = nil, end: String? = nil) async throws -> [SleepSession] {
        try await fetchDataArray(endpoint: .sleep, token: token, startDate: start, endDate: end)
    }
    
    func getDailyReadiness(token: String, start: String? = nil, end: String? = nil) async throws -> [DailyReadiness] {
        try await fetchDataArray(endpoint: .dailyReadiness, token: token, startDate: start, endDate: end)
    }
    
    func getDailyActivity(token: String, start: String? = nil, end: String? = nil) async throws -> [DailyActivity] {
        try await fetchDataArray(endpoint: .dailyActivity, token: token, startDate: start, endDate: end)
    }
    
    // Convenience overloads with days parameter
    func getDailySleep(token: String, days: Int) async throws -> [DailySleep] {
        let (start, end) = getDateRange(daysBack: days)
        return try await fetchDataArray(endpoint: .dailySleep, token: token, startDate: start, endDate: end)
    }
    
    func getSleepSessions(token: String, days: Int) async throws -> [SleepSession] {
        let (start, end) = getDateRange(daysBack: days)
        return try await fetchDataArray(endpoint: .sleep, token: token, startDate: start, endDate: end)
    }
    
    func getDailyReadiness(token: String, days: Int) async throws -> [DailyReadiness] {
        let (start, end) = getDateRange(daysBack: days)
        return try await fetchDataArray(endpoint: .dailyReadiness, token: token, startDate: start, endDate: end)
    }
    
    func getDailyActivity(token: String, days: Int) async throws -> [DailyActivity] {
        let (start, end) = getDateRange(daysBack: days)
        return try await fetchDataArray(endpoint: .dailyActivity, token: token, startDate: start, endDate: end)
    }
    
    func getHeartRate(token: String) async throws -> [HeartRate] {
        let daysBack = AppConstants.heartRateDataRangeDays
        let (start, end) = getDateRange(daysBack: daysBack)
        return try await fetchDataArray(
            endpoint: .heartrate,
            token: token,
            startDate: start,
            endDate: end,
            useDatetime: true
        )
    }
    
    func getDailySpO2(token: String, start: String? = nil, end: String? = nil) async throws -> [DailySpO2] {
        try await fetchDataArray(endpoint: .dailySpo2, token: token, startDate: start, endDate: end)
    }
    
    func getDailyStress(token: String, start: String? = nil, end: String? = nil) async throws -> [DailyStress] {
        do {
            return try await fetchDataArray(endpoint: .dailyStress, token: token, startDate: start, endDate: end)
        } catch {
            print("Stress data not available: \(error)")
            return []
        }
    }
    
    func getDailyResilience(token: String, start: String? = nil, end: String? = nil) async throws -> [DailyResilience] {
        do {
            return try await fetchDataArray(endpoint: .dailyResilience, token: token, startDate: start, endDate: end)
        } catch {
            print("Resilience data not available: \(error)")
            return []
        }
    }
    
    func getWorkouts(token: String, start: String? = nil, end: String? = nil) async throws -> [Workout] {
        try await fetchDataArray(endpoint: .workout, token: token, startDate: start, endDate: end)
    }
    
    // MARK: - New API Methods (Full Coverage)
    
    /// Fetch user-created tags for tracking symptoms, supplements, meals, etc.
    func getTags(token: String, start: String? = nil, end: String? = nil) async throws -> [Tag] {
        do {
            return try await fetchDataArray(endpoint: .tag, token: token, startDate: start, endDate: end)
        } catch {
            print("Tags data not available: \(error)")
            return []
        }
    }
    
    /// Fetch enhanced tags with more context
    func getEnhancedTags(token: String, start: String? = nil, end: String? = nil) async throws -> [EnhancedTag] {
        do {
            return try await fetchDataArray(endpoint: .enhancedTag, token: token, startDate: start, endDate: end)
        } catch {
            print("Enhanced tags data not available: \(error)")
            return []
        }
    }
    
    /// Fetch meditation and relaxation sessions
    func getSessions(token: String, start: String? = nil, end: String? = nil) async throws -> [Session] {
        do {
            return try await fetchDataArray(endpoint: .session, token: token, startDate: start, endDate: end)
        } catch {
            print("Sessions data not available: \(error)")
            return []
        }
    }
    
    /// Fetch recommended sleep time windows
    func getSleepTime(token: String, start: String? = nil, end: String? = nil) async throws -> [SleepTime] {
        do {
            return try await fetchDataArray(endpoint: .sleepTime, token: token, startDate: start, endDate: end)
        } catch {
            print("Sleep time data not available: \(error)")
            return []
        }
    }
    
    /// Fetch rest mode periods for recovery tracking
    func getRestModePeriods(token: String, start: String? = nil, end: String? = nil) async throws -> [RestModePeriod] {
        do {
            return try await fetchDataArray(endpoint: .restModePeriod, token: token, startDate: start, endDate: end)
        } catch {
            print("Rest mode data not available: \(error)")
            return []
        }
    }
    
    /// Fetch ring configuration - no date filter needed
    func getRingConfiguration(token: String) async throws -> [RingConfiguration] {
        do {
            return try await fetchDataArray(endpoint: .ringConfiguration, token: token, useDateFilter: false)
        } catch {
            print("Ring configuration not available: \(error)")
            return []
        }
    }
    
    /// Fetch daily cardiovascular age estimates
    func getCardiovascularAge(token: String, start: String? = nil, end: String? = nil) async throws -> [CardiovascularAge] {
        do {
            return try await fetchDataArray(endpoint: .dailyCardiovascularAge, token: token, startDate: start, endDate: end)
        } catch {
            print("Cardiovascular age data not available: \(error)")
            return []
        }
    }
    
    /// Fetch VO2 max estimates for cardiorespiratory fitness
    func getVO2Max(token: String, start: String? = nil, end: String? = nil) async throws -> [VO2Max] {
        do {
            return try await fetchDataArray(endpoint: .vo2Max, token: token, startDate: start, endDate: end)
        } catch {
            print("VO2 max data not available: \(error)")
            return []
        }
    }
    
    // MARK: - Aggregate Fetch
    
    func fetchDailyStats(token: String, start: String? = nil, end: String? = nil) async throws -> DailyStats {
        async let sleepData = getDailySleep(token: token, start: start, end: end)
        async let readinessData = getDailyReadiness(token: token, start: start, end: end)
        async let activityData = getDailyActivity(token: token, start: start, end: end)
        async let sessionData = getSleepSessions(token: token, start: start, end: end)
        async let spo2Data = getDailySpO2(token: token, start: start, end: end)
        async let stressData = getDailyStress(token: token, start: start, end: end)
        async let resilienceData = getDailyResilience(token: token, start: start, end: end)
        
        let (sleep, readiness, activity, session, spo2, stress, resilience) = try await (
            sleepData, readinessData, activityData, sessionData, spo2Data, stressData, resilienceData
        )
        
        return DailyStats(
            sleep: sleep.sorted { $0.day > $1.day },
            readiness: readiness.sorted { $0.day > $1.day },
            activity: activity.sorted { $0.day > $1.day },
            session: session.sorted { $0.day > $1.day },
            spo2: spo2.sorted { $0.day > $1.day },
            stress: stress.sorted { $0.day > $1.day },
            resilience: resilience.sorted { $0.day > $1.day }
        )
    }
}

// MARK: - Errors

enum OuraAPIError: Error, LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError(Error)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
