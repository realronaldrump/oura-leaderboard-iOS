import Foundation

// MARK: - AI Service for Health Insights

actor AIService {
    static let shared = AIService()
    
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent"
    
    private init() {}
    
    // MARK: - Generate Comparative Briefing
    
    func generateBriefing(
        statsA: (sleep: DailySleep?, readiness: DailyReadiness?, activity: DailyActivity?),
        statsB: (sleep: DailySleep?, readiness: DailyReadiness?, activity: DailyActivity?),
        nameA: String,
        nameB: String
    ) async throws -> String {
        let apiKey = AIConfig.geminiAPIKey
        
        guard !apiKey.isEmpty else {
            return "AI Briefing unavailable: API Key missing."
        }
        
        let prompt = buildPrompt(statsA: statsA, statsB: statsB, nameA: nameA, nameB: nameB)
        
        return try await callGeminiAPI(prompt: prompt, apiKey: apiKey)
    }
    
    // MARK: - Build Prompt
    
    private func buildPrompt(
        statsA: (sleep: DailySleep?, readiness: DailyReadiness?, activity: DailyActivity?),
        statsB: (sleep: DailySleep?, readiness: DailyReadiness?, activity: DailyActivity?),
        nameA: String,
        nameB: String
    ) -> String {
        let statsAJson = formatStats(statsA)
        let statsBJson = formatStats(statsB)
        
        return """
        Analyze the Oura ring health data for \(nameA) and \(nameB) (always use these names, NOT emails).

        \(nameA)'s data: \(statsAJson)
        \(nameB)'s data: \(statsBJson)
        
        Provide a concise health comparison using the following markdown structure:

        ## Today's Winner
        Who had better overall metrics today and why (1-2 sentences).

        ## \(nameA)'s Insights
        - Key strength from their data
        - One area to focus on

        ## \(nameB)'s Insights  
        - Key strength from their data
        - One area to focus on

        ## Recommendations
        Brief, actionable suggestions for both based on their energy levels and recovery status.

        Keep the tone friendly and supportive. Be specific and reference actual numbers from their data.
        """
    }
    
    private func formatStats(_ stats: (sleep: DailySleep?, readiness: DailyReadiness?, activity: DailyActivity?)) -> String {
        var result: [String: Any] = [:]
        
        if let sleep = stats.sleep {
            result["sleep_score"] = sleep.score ?? 0
            result["sleep_contributors"] = [
                "deep_sleep": sleep.contributors.deepSleep ?? 0,
                "efficiency": sleep.contributors.efficiency ?? 0,
                "rem_sleep": sleep.contributors.remSleep ?? 0,
                "total_sleep": sleep.contributors.totalSleep ?? 0
            ]
        }
        
        if let readiness = stats.readiness {
            result["readiness_score"] = readiness.score ?? 0
            result["readiness_contributors"] = [
                "hrv_balance": readiness.contributors.hrvBalance ?? 0,
                "resting_heart_rate": readiness.contributors.restingHeartRate ?? 0,
                "recovery_index": readiness.contributors.recoveryIndex ?? 0,
                "sleep_balance": readiness.contributors.sleepBalance ?? 0
            ]
        }
        
        if let activity = stats.activity {
            result["activity_score"] = activity.score ?? 0
            result["steps"] = activity.steps
            result["active_calories"] = activity.activeCalories
        }
        
        if let data = try? JSONSerialization.data(withJSONObject: result),
           let json = String(data: data, encoding: .utf8) {
            return json
        }
        
        return "{}"
    }
    
    // MARK: - Gemini API Call
    
    private func callGeminiAPI(prompt: String, apiKey: String) async throws -> String {
        var components = URLComponents(string: baseURL)!
        components.queryItems = [URLQueryItem(name: "key", value: apiKey)]
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.7,
                "maxOutputTokens": 1024
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode else {
            throw AIError.requestFailed
        }
        
        // Parse response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            throw AIError.parseError
        }
        
        return text
    }
}

// MARK: - AI Errors

enum AIError: Error, LocalizedError {
    case noAPIKey
    case requestFailed
    case parseError
    
    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "Gemini API key not configured"
        case .requestFailed:
            return "Failed to get response from AI"
        case .parseError:
            return "Failed to parse AI response"
        }
    }
}
