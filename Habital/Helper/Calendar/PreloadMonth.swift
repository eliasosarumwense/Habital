//
//  PreloadMonth.swift
//  Habital
//
//  Created by Elias Osarumwense on 10.04.25.
//

import SwiftUI

extension View {
    func preloadMonthView(for date: Date, getFilteredHabits: @escaping (Date) -> [Habit]) {
        // Perform preloading on background thread
        DispatchQueue.global(qos: .userInitiated).async {
            // Calculate the range of dates in the month
            let calendar = Calendar.current
            let fallbackRange = 1...31
            let range = calendar.range(of: .day, in: .month, for: date) ?? Range(fallbackRange)
            
            // Create a date for each day and pre-calculate habit data
            for day in range {
                var components = calendar.dateComponents([.year, .month], from: date)
                components.day = day
                
                if let dayDate = calendar.date(from: components) {
                    // Just call getFilteredHabits to trigger any caching your implementation might have
                    _ = getFilteredHabits(dayDate)
                }
            }
        }
    }
}
