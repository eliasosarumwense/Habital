//
//  Dates.swift
//  Habital
//
//  Created by Elias Osarumwense on 01.04.25.
//
import SwiftUI

func dayName(for index: Int) -> String {
    switch index {
    case 0: return "Mo"
    case 1: return "Tu"
    case 2: return "We"
    case 3: return "Th"
    case 4: return "Fr"
    case 5: return "Sa"
    case 6: return "Su"
    default: return ""
    }
}

// Helper function for formatting date
func formatSelectedDate() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEEE, MMMM d"
    return formatter.string(from: Date())
}

func formatSelectedDateToDayOrFull(date: Date) -> String {
    let calendar = Calendar.current
    let today = Date()
    
    // Calculate the difference in days
    let daysDifference = abs(calendar.dateComponents([.day], from: today, to: date).day ?? 0)
    
    // Create date formatter
    let formatter = DateFormatter()
    
    // If date is within 6 days before or after today, use "dd. MMMM" format
    if daysDifference <= 6 {
        formatter.dateFormat = "dd. MMMM"
    } else {
        // Otherwise use day of week format
        formatter.dateFormat = "EEEE"
    }
    
    return formatter.string(from: date)
}

func shortDayName(for index: Int) -> String {
    let calendar = Calendar.current
    let date = calendar.date(from: DateComponents(year: 2024, month: 1, day: index + 1))!
    
    let formatter = DateFormatter()
    formatter.dateFormat = "EE"  // Two-letter abbreviation
    
    return formatter.string(from: date).lowercased()
}

func formatDayOfWeek(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEEE" // Full day name
    return formatter.string(from: date)
}

func formatDayAndMonth(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "d MMMM yyyy" // Day, Month, Year
    return formatter.string(from: date)
}

func formatFullDateTime(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    
    return formatter.string(from: date)
}
// Helper function to format just the date part
func formatDateOnly(_ date: Date?) -> String {
    guard let date = date else { return "Unknown date" }
    
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    
    return formatter.string(from: date)
}

// Helper function to format just the time part
func formatTimeOnly(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .none
    formatter.timeStyle = .short
    
    return formatter.string(from: date)
}


// MARK: - Helper Methods
// Format date with specific style
func formatDate(_ date: Date?) -> String {
    guard let date = date else { return "Not set" }
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter.string(from: date)
}



func formattedDate(for date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter.string(from: date)
}
