import Foundation

// MARK: - Centralized Formatters
// Static DateFormatter instances to eliminate repeated expensive allocations.
// DateFormatters are expensive to create - these singletons are thread-safe
// and reused throughout the app.

enum Formatters {
    
    // MARK: - ISO8601 Formatters
    
    /// ISO8601 formatter with fractional seconds support
    static let iso8601Full: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    /// ISO8601 formatter without fractional seconds
    static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
    
    // MARK: - Day Key Formatter
    
    /// Formats dates as "yyyy-MM-dd" for dictionary keys and API queries
    static let dayKey: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    // MARK: - Display Formatters
    
    /// Formats time as "h:mm a" (e.g., "11:30 PM")
    static let displayTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()
    
    /// Formats date as "EEEE, MMM d" (e.g., "Monday, Jan 1")
    static let displayDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter
    }()

    /// Formats date as "MMM d, yyyy" (e.g., "Jan 1, 2026")
    static let displayDateMedium: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter
    }()

    /// Relative time formatter (e.g., "2 min ago")
    static let relativeTime: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter
    }()

    /// Decimal number formatter with grouping (e.g., "8,432").
    /// Only access from the main thread (NumberFormatter is not thread-safe).
    static let decimal: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
    
    // MARK: - Helper Methods
    
    /// Parse an ISO8601 string to Date, trying with fractional seconds first
    static func parseISO8601(_ string: String) -> Date? {
        if let date = iso8601Full.date(from: string) {
            return date
        }
        return iso8601.date(from: string)
    }
    
    /// Format a date as a day key string (yyyy-MM-dd)
    static func dayKeyString(from date: Date) -> String {
        dayKey.string(from: date)
    }
    
    /// Parse a day key string to Date
    static func date(fromDayKey string: String) -> Date? {
        dayKey.date(from: string)
    }

    /// Format an integer with grouping separators (e.g., "8,432")
    static func decimalString(from value: Int) -> String {
        decimal.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
