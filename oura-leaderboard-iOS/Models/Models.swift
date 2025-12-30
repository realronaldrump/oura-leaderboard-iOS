import Foundation

// MARK: - User Profile

struct UserProfile: Codable, Identifiable, Equatable, Sendable {
    let id: String
    var age: Int?
    var weight: Double?
    var height: Double?
    var biologicalSex: String?
    var email: String?
    var token: String
    var lastUpdated: String?
    var firstName: String?
    var lastName: String?
    
    enum CodingKeys: String, CodingKey {
        case id, age, weight, height, email, token, lastUpdated, firstName, lastName
        case biologicalSex = "biological_sex"
    }
    
    var displayName: String {
        if let firstName = firstName, !firstName.isEmpty {
            return firstName
        }
        return email?.components(separatedBy: "@").first ?? "User"
    }
}

// MARK: - Sleep Data

struct SleepContributors: Codable, Sendable {
    var deepSleep: Int?
    var efficiency: Int?
    var latency: Int?
    var remSleep: Int?
    var restfulness: Int?
    var timing: Int?
    var totalSleep: Int?
    
    enum CodingKeys: String, CodingKey {
        case efficiency, latency, restfulness, timing
        case deepSleep = "deep_sleep"
        case remSleep = "rem_sleep"
        case totalSleep = "total_sleep"
    }
}

struct DailySleep: Codable, Identifiable, Sendable {
    let id: String
    let day: String
    var score: Int?
    var timestamp: String?
    var contributors: SleepContributors
}

struct SampleModel: Codable, Sendable {
    let interval: Int
    let items: [Int]
    let timestamp: String
}

struct SleepSession: Codable, Identifiable, Sendable {
    let id: String
    let day: String
    var averageBreath: Double?
    var averageHeartRate: Double?
    var averageHrv: Int?
    var awakeTime: Int?
    var bedtimeEnd: String?
    var bedtimeStart: String?
    var deepSleepDuration: Int?
    var efficiency: Int?
    var latency: Int?
    var lightSleepDuration: Int?
    var lowBatteryAlert: Bool?
    var lowestHeartRate: Int?
    var movement30Sec: String?
    var period: Int?
    var readinessScoreDelta: Int?
    var remSleepDuration: Int?
    var restlessPeriods: Int?
    var sleepPhase5Min: String?
    var sleepScoreDelta: Int?
    var timeInBed: Int?
    var totalSleepDuration: Int?
    var type: String?
    var heartRate: SampleModel?
    var hrv: SampleModel?
    
    enum CodingKeys: String, CodingKey {
        case id, day, efficiency, latency, period, type, hrv
        case averageBreath = "average_breath"
        case averageHeartRate = "average_heart_rate"
        case averageHrv = "average_hrv"
        case awakeTime = "awake_time"
        case bedtimeEnd = "bedtime_end"
        case bedtimeStart = "bedtime_start"
        case deepSleepDuration = "deep_sleep_duration"
        case lightSleepDuration = "light_sleep_duration"
        case lowBatteryAlert = "low_battery_alert"
        case lowestHeartRate = "lowest_heart_rate"
        case movement30Sec = "movement_30_sec"
        case readinessScoreDelta = "readiness_score_delta"
        case remSleepDuration = "rem_sleep_duration"
        case restlessPeriods = "restless_periods"
        case sleepPhase5Min = "sleep_phase_5_min"
        case sleepScoreDelta = "sleep_score_delta"
        case timeInBed = "time_in_bed"
        case totalSleepDuration = "total_sleep_duration"
        case heartRate = "heart_rate"
    }
}

// MARK: - Activity Data

struct ActivityContributors: Codable, Sendable {
    var meetDailyTargets: Int?
    var moveEveryHour: Int?
    var recoveryTime: Int?
    var stayActive: Int?
    var trainingFrequency: Int?
    var trainingVolume: Int?
    
    enum CodingKeys: String, CodingKey {
        case meetDailyTargets = "meet_daily_targets"
        case moveEveryHour = "move_every_hour"
        case recoveryTime = "recovery_time"
        case stayActive = "stay_active"
        case trainingFrequency = "training_frequency"
        case trainingVolume = "training_volume"
    }
}

struct DailyActivity: Codable, Identifiable, Sendable {
    let id: String
    let day: String
    var class5Min: String?
    var score: Int?
    var activeCalories: Int
    var averageMetMinutes: Double?
    var contributors: ActivityContributors
    var equivalentWalkingDistance: Int?
    var highActivityMetMinutes: Int?
    var highActivityTime: Int?
    var inactivityAlerts: Int?
    var lowActivityMetMinutes: Int?
    var lowActivityTime: Int?
    var mediumActivityMetMinutes: Int?
    var mediumActivityTime: Int?
    var metersToTarget: Int?
    var nonWearTime: Int?
    var restingTime: Int?
    var sedentaryMetMinutes: Int?
    var sedentaryTime: Int?
    var steps: Int
    var targetCalories: Int
    var targetMeters: Int?
    var totalCalories: Int
    var timestamp: String?
    
    enum CodingKeys: String, CodingKey {
        case id, day, score, contributors, steps, timestamp
        case class5Min = "class_5_min"
        case activeCalories = "active_calories"
        case averageMetMinutes = "average_met_minutes"
        case equivalentWalkingDistance = "equivalent_walking_distance"
        case highActivityMetMinutes = "high_activity_met_minutes"
        case highActivityTime = "high_activity_time"
        case inactivityAlerts = "inactivity_alerts"
        case lowActivityMetMinutes = "low_activity_met_minutes"
        case lowActivityTime = "low_activity_time"
        case mediumActivityMetMinutes = "medium_activity_met_minutes"
        case mediumActivityTime = "medium_activity_time"
        case metersToTarget = "meters_to_target"
        case nonWearTime = "non_wear_time"
        case restingTime = "resting_time"
        case sedentaryMetMinutes = "sedentary_met_minutes"
        case sedentaryTime = "sedentary_time"
        case targetCalories = "target_calories"
        case targetMeters = "target_meters"
        case totalCalories = "total_calories"
    }
}

// MARK: - Readiness Data

struct ReadinessContributors: Codable, Sendable {
    var activityBalance: Int?
    var bodyTemperature: Int?
    var hrvBalance: Int?
    var previousDayActivity: Int?
    var previousNight: Int?
    var recoveryIndex: Int?
    var restingHeartRate: Int?
    var sleepBalance: Int?
    
    enum CodingKeys: String, CodingKey {
        case activityBalance = "activity_balance"
        case bodyTemperature = "body_temperature"
        case hrvBalance = "hrv_balance"
        case previousDayActivity = "previous_day_activity"
        case previousNight = "previous_night"
        case recoveryIndex = "recovery_index"
        case restingHeartRate = "resting_heart_rate"
        case sleepBalance = "sleep_balance"
    }
}

struct DailyReadiness: Codable, Identifiable, Sendable {
    let id: String
    let day: String
    var score: Int?
    var temperatureDeviation: Double?
    var temperatureTrendDeviation: Double?
    var timestamp: String?
    var contributors: ReadinessContributors
    
    enum CodingKeys: String, CodingKey {
        case id, day, score, timestamp, contributors
        case temperatureDeviation = "temperature_deviation"
        case temperatureTrendDeviation = "temperature_trend_deviation"
    }
}

// MARK: - Heart Rate

struct HeartRate: Codable, Identifiable, Sendable {
    var id: String { "\(timestamp)-\(bpm)" }
    let bpm: Int
    let source: String
    let timestamp: String
}

// MARK: - SpO2 Data

struct Spo2Percentage: Codable, Sendable {
    var average: Double?
}

struct DailySpO2: Codable, Identifiable, Sendable {
    let id: String
    let day: String
    var spo2Percentage: Spo2Percentage?
    var breathingDisturbanceIndex: Double?
    
    enum CodingKeys: String, CodingKey {
        case id, day
        case spo2Percentage = "spo2_percentage"
        case breathingDisturbanceIndex = "breathing_disturbance_index"
    }
}

// MARK: - Stress Data

struct DailyStress: Codable, Identifiable, Sendable {
    let id: String
    let day: String
    var stressHigh: Int?
    var recoveryHigh: Int?
    var daySummary: String?
    
    enum CodingKeys: String, CodingKey {
        case id, day
        case stressHigh = "stress_high"
        case recoveryHigh = "recovery_high"
        case daySummary = "day_summary"
    }
}

// MARK: - Resilience Data

struct ResilienceContributors: Codable, Sendable {
    var sleepRecovery: Int?
    var daytimeRecovery: Int?
    var stress: Int?
    
    enum CodingKeys: String, CodingKey {
        case stress
        case sleepRecovery = "sleep_recovery"
        case daytimeRecovery = "daytime_recovery"
    }
}

struct DailyResilience: Codable, Identifiable, Sendable {
    let id: String
    let day: String
    var level: String?
    var contributors: ResilienceContributors?
}

// MARK: - Workout Data

struct Workout: Codable, Identifiable, Sendable {
    let id: String
    let activity: String
    var calories: Double?
    let day: String
    var distance: Double?
    let endDatetime: String
    let startDatetime: String
    var intensity: String?
    var label: String?
    var source: String?
    
    enum CodingKeys: String, CodingKey {
        case id, activity, calories, day, distance, intensity, label, source
        case endDatetime = "end_datetime"
        case startDatetime = "start_datetime"
    }
}

// MARK: - Leaderboard Entry

struct LeaderboardEntry: Identifiable, Sendable {
    let id: String
    let name: String
    let readiness: Int
    let sleep: Int
    let activity: Int
    let average: Int
    let isCurrentUser: Bool
    var avatar: String?
    var steps: Int?
    var activeCalories: Int?
    var sleepDuration: Int?
    var averageHrv: Int?
    var restingHeartRate: Int?
}

// MARK: - Daily Stats Aggregate

struct DailyStats: Sendable {
    var sleep: [DailySleep]
    var readiness: [DailyReadiness]
    var activity: [DailyActivity]
    var session: [SleepSession]
    var spo2: [DailySpO2]
    var stress: [DailyStress]
    var resilience: [DailyResilience]
    
    static var empty: DailyStats {
        DailyStats(
            sleep: [],
            readiness: [],
            activity: [],
            session: [],
            spo2: [],
            stress: [],
            resilience: []
        )
    }
}

// MARK: - Auth Status

enum AuthStatus {
    case loading
    case authenticated
    case unauthenticated
}

// MARK: - API Response Wrappers

struct OuraDataResponse<T: Codable>: Codable {
    let data: [T]
    let nextToken: String?
    
    enum CodingKeys: String, CodingKey {
        case data
        case nextToken = "next_token"
    }
}

// MARK: - Utility Functions

func formatDuration(_ seconds: Int?) -> String {
    guard let seconds = seconds else { return "--" }
    let hours = seconds / 3600
    let minutes = (seconds % 3600) / 60
    if hours > 0 {
        return "\(hours)h \(minutes)m"
    }
    return "\(minutes)m"
}

func formatTime(_ isoString: String?) -> String {
    guard let isoString = isoString else { return "--" }
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    
    // Try with fractional seconds first, then without
    var date = formatter.date(from: isoString)
    if date == nil {
        formatter.formatOptions = [.withInternetDateTime]
        date = formatter.date(from: isoString)
    }
    
    guard let parsedDate = date else { return "--" }
    
    let displayFormatter = DateFormatter()
    displayFormatter.dateFormat = "h:mm a"
    return displayFormatter.string(from: parsedDate)
}
