//
//  Calendar+Extensions.swift
//  Habital
//
//  Created for fixing WeekTimelineView issues
//

import Foundation

extension Calendar {
    /// Returns the nearest Monday to the given date (going backward if necessary)
    static func nearestMonday(from date: Date) -> Date {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        
        // In Calendar, weekday 1 = Sunday, 2 = Monday, etc.
        let daysToSubtract: Int
        switch weekday {
        case 1: // Sunday
            daysToSubtract = 6
        case 2: // Monday
            daysToSubtract = 0
        case 3: // Tuesday
            daysToSubtract = 1
        case 4: // Wednesday
            daysToSubtract = 2
        case 5: // Thursday
            daysToSubtract = 3
        case 6: // Friday
            daysToSubtract = 4
        case 7: // Saturday
            daysToSubtract = 5
        default:
            daysToSubtract = 0
        }
        
        return calendar.date(byAdding: .day, value: -daysToSubtract, to: calendar.startOfDay(for: date)) ?? date
    }
    
    /// Returns the current week (Monday to Sunday) starting from the given Monday
    static func currentWeek(from monday: Date) -> [Date] {
        let calendar = Calendar.current
        var dates: [Date] = []
        
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: i, to: monday) {
                dates.append(date)
            }
        }
        
        return dates
    }
    
    /// Returns the previous week (7 days before the first day of the given date's week)
    static func previousWeek(from date: Date) -> [Date] {
        let calendar = Calendar.current
        let monday = nearestMonday(from: date)
        
        guard let previousMonday = calendar.date(byAdding: .weekOfYear, value: -1, to: monday) else {
            return []
        }
        
        return currentWeek(from: previousMonday)
    }
    
    /// Returns the next week (7 days after the last day of the given date's week)
    static func nextWeek(from date: Date) -> [Date] {
        let calendar = Calendar.current
        let monday = nearestMonday(from: date)
        
        guard let nextMonday = calendar.date(byAdding: .weekOfYear, value: 1, to: monday) else {
            return []
        }
        
        return currentWeek(from: nextMonday)
    }
    
    /// Returns a formatted string for month and year
    static func monthAndYear(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    /// Returns a formatted string for week and year
    static func weekAndYear(from date: Date) -> String {
        let calendar = Calendar.current
        let weekOfYear = calendar.component(.weekOfYear, from: date)
        let year = calendar.component(.year, from: date)
        return "W\(weekOfYear)-\(year)"
    }
    
    /// Checks if two dates are in the same month
    static func isSameMonth(_ date1: Date, _ date2: Date) -> Bool {
        let calendar = Calendar.current
        let components1 = calendar.dateComponents([.year, .month], from: date1)
        let components2 = calendar.dateComponents([.year, .month], from: date2)
        
        return components1.year == components2.year && components1.month == components2.month
    }
}