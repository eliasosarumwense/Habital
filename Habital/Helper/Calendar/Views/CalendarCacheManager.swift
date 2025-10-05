//
//  CalendarCacheManager.swift
//  Habital
//
//  Created by Elias Osarumwense on 02.05.25.
//

import SwiftUI

//
//  CalendarCacheManager.swift
//  Habital
//
//  Created by Elias Osarumwense on 02.05.25.
//


class CalendarCacheManager: ObservableObject {
    @Published var visibleDates: [Date] = []
    // Removed activityCache - now using HabitUtilities cache directly
    @Published var completionCache: [String: [TimeInterval: Bool]] = [:]
    
    func updateVisibleDates(calendarType: WeekTimelineView.CalendarType,
                           selectedDate: Date,
                           weekOffset: Int,
                           forceRefresh: Bool = false) {
        let calendar = Calendar.current
        
        switch calendarType {
        case .week:
            let currentWeekStart = getStartOfWeek(for: weekOffset)
            let newVisibleDates = (0..<7).map { day in
                calendar.date(byAdding: .day, value: day, to: currentWeekStart)!
            }
            
            // Clear cache and force update when returning to current week
            if weekOffset == 0 || forceRefresh {
                visibleDates = newVisibleDates
                if weekOffset == 0 {
                    clearCompletionCacheForDates(newVisibleDates)
                }
            } else if visibleDates != newVisibleDates {
                visibleDates = newVisibleDates
            }
            
        case .month:
            let components = calendar.dateComponents([.year, .month], from: selectedDate)
            guard let startOfMonth = calendar.date(from: components),
                  let range = calendar.range(of: .day, in: .month, for: startOfMonth) else { return }
            
            let newVisibleDates = range.compactMap { day -> Date? in
                var dateComponents = DateComponents()
                dateComponents.year = components.year
                dateComponents.month = components.month
                dateComponents.day = day
                return calendar.date(from: dateComponents)
            }
            
            // Clear cache and force update when returning to current month
            let isCurrentMonth = calendar.isDate(selectedDate, equalTo: Date(), toGranularity: .month)
            if isCurrentMonth || forceRefresh {
                visibleDates = newVisibleDates
                if isCurrentMonth {
                    clearCompletionCacheForDates(newVisibleDates)
                }
            } else if visibleDates != newVisibleDates {
                visibleDates = newVisibleDates
            }
        }
    }

    // MARK: - Add this simple helper function
    private func clearCompletionCacheForDates(_ dates: [Date]) {
        let calendar = Calendar.current
        let dateKeys = dates.map { calendar.startOfDay(for: $0).timeIntervalSince1970 }
        
        for habitID in completionCache.keys {
            for dateKey in dateKeys {
                completionCache[habitID]?.removeValue(forKey: dateKey)
            }
        }
    }

    
    // Helper function to get start of week
    private func getStartOfWeek(for weekOffset: Int) -> Date {
        let calendar = Calendar.current
        let currentDate = Date()
        
        // Get current week's Monday
        var comps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: currentDate)
        comps.weekday = 2 // Monday
        guard let startOfCurrentWeek = calendar.date(from: comps) else { return currentDate }
        
        // Add the week offset
        return calendar.date(byAdding: .weekOfYear, value: weekOffset, to: startOfCurrentWeek) ?? currentDate
    }
    
    // Simplified - now delegates to HabitUtilities cache
    func isHabitActive(_ habit: Habit, on date: Date) -> Bool {
        // Just delegate to HabitUtilities - it already has efficient caching
        return HabitUtilities.isHabitActive(habit: habit, on: date)
    }
    
    // Check if habit is completed for a date (keeps its own cache since this is calendar-specific)
    func isHabitCompleted(_ habit: Habit, on date: Date) -> Bool {
        guard let habitID = habit.id?.uuidString else {
            return isCompletedCheck(habit, on: date)
        }
        
        let calendar = Calendar.current
        let normalizedDate = calendar.startOfDay(for: date)
        let dateKey = normalizedDate.timeIntervalSince1970
        
        // Check cache first
        if let cachedValue = completionCache[habitID]?[dateKey] {
            return cachedValue
        }
        
        // If not in cache, calculate
        let isCompleted = isCompletedCheck(habit, on: date)
        
        // Store in cache
        if completionCache[habitID] == nil {
            completionCache[habitID] = [:]
        }
        completionCache[habitID]?[dateKey] = isCompleted
        
        return isCompleted
    }
    
    // Implementation of the completion check
    private func isCompletedCheck(_ habit: Habit, on date: Date) -> Bool {
        guard let completions = habit.completion as? Set<Completion> else {
            return false
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        return completions.contains { completion in
            guard let completionDate = completion.date else { return false }
            return calendar.isDate(completionDate, inSameDayAs: startOfDay) && completion.completed
        }
    }
    
    // Updated invalidation - only handles completion cache now
    func invalidateCacheForHabit(_ habit: Habit) {
        guard let habitID = habit.id?.uuidString else { return }
        // Only handle completion cache, HabitUtilities handles its own activity cache
        completionCache.removeValue(forKey: habitID)
        
        // Optional: Clear HabitUtilities cache for this specific habit
        // You may want to add a more targeted method to HabitUtilities for this
        HabitUtilities.clearHabitActivityCache() // This clears all, but you could make it more targeted
    }
    
    // Updated invalidation for dates
    func invalidateCacheForDate(_ date: Date) {
        let calendar = Calendar.current
        let normalizedDate = calendar.startOfDay(for: date)
        let dateKey = normalizedDate.timeIntervalSince1970
        
        // Remove from completion cache only
        for habitID in completionCache.keys {
            completionCache[habitID]?.removeValue(forKey: dateKey)
        }
        
        // HabitUtilities handles its own cache invalidation
        // You might want to call a more targeted clear method here if available
    }
    
    // Updated preload - delegates activity caching to HabitUtilities
    func preloadData(habits: [Habit], dates: [Date]) {
        for habit in habits {
            for date in dates {
                // This will populate HabitUtilities cache for activity
                _ = isHabitActive(habit, on: date)
                // This will populate our completion cache
                _ = isHabitCompleted(habit, on: date)
            }
        }
    }
    
    func preloadLastMonths(_ months: Int, habits: [Habit]) {
        let calendar = Calendar.current
        let today = Date()
        let startDate = calendar.date(byAdding: .month, value: -months, to: today) ?? today
        
        var dates: [Date] = []
        var currentDate = calendar.startOfDay(for: startDate)
        let finalDate = calendar.startOfDay(for: today)
        
        while currentDate <= finalDate {
            dates.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? finalDate
        }
        
        preloadData(habits: habits, dates: dates)
    }
}
