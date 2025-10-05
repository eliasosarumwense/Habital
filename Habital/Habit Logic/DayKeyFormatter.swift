//
//  DayKeyFormatter.swift
//  Habital
//
//  Created by Elias Osarumwense on 22.08.25.
//

import Foundation

enum DayKeyFormatter {
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = .current
        return f
    }()
    
    private static let calendar: Calendar = {
        var cal = Calendar.current
        cal.timeZone = .current
        return cal
    }()
    
    /// Generate a stable key for any date in the user's local timezone
    static func localKey(from date: Date, tz: TimeZone = .current) -> String {
        var cal = calendar
        cal.timeZone = tz
        
        // Normalize to start of day in the given timezone
        let components = cal.dateComponents([.year, .month, .day], from: date)
        guard let normalized = cal.date(from: components) else {
            // Fallback - should never happen
            formatter.timeZone = tz
            return formatter.string(from: date)
        }
        
        formatter.timeZone = tz
        return formatter.string(from: normalized)
    }
    
    /// Generate keys for a date range
    static func keysForRange(from startDate: Date, to endDate: Date, tz: TimeZone = .current) -> [String] {
        var cal = calendar
        cal.timeZone = tz
        
        var keys: [String] = []
        var currentDate = cal.startOfDay(for: startDate)
        let endDay = cal.startOfDay(for: endDate)
        
        while currentDate <= endDay {
            keys.append(localKey(from: currentDate, tz: tz))
            guard let nextDate = cal.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }
        
        return keys
    }
    
    /// Generate keys for the last N days
    static func keysForLastDays(_ days: Int, from date: Date = Date(), tz: TimeZone = .current) -> [String] {
        var cal = calendar
        cal.timeZone = tz
        
        guard let startDate = cal.date(byAdding: .day, value: -(days - 1), to: date) else {
            return [localKey(from: date, tz: tz)]
        }
        
        return keysForRange(from: startDate, to: date, tz: tz)
    }
}
