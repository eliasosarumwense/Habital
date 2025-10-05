//
//  HabitHelper.swift
//  Habital
//
//  Created by Elias Osarumwense on 06.04.25.
//
import SwiftUI
import CoreData
import Combine

extension Habit {
    // Find the most recent completion before a specific date
    func findMostRecentCompletion(before date: Date) -> Completion? {
        guard let completions = self.completion as? Set<Completion>,
              !completions.isEmpty else {
            return nil
        }
        
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        let normalizedDate = calendar.startOfDay(for: date)
        
        guard let repeatPattern = HabitUtilities.getEffectiveRepeatPattern(for: self, on: normalizedDate) else {
            // No pattern found, use default behavior for single repeat
            //return self.findDefaultMostRecentCompletion(before: date)
            return nil
        }

        // Check if multiple repetitions per day
        if repeatPattern.repeatsPerDay > 1 {
            return self.findMostRecentCompletedCompletion(before: date, repeatPattern: repeatPattern)
        }
        else {
            
            // Filter completions that occurred before the given date
            let validCompletions = completions.compactMap { completion -> (Completion, Date)? in
                guard let completionDate = completion.date,
                      completion.completed,
                      calendar.startOfDay(for: completionDate) < normalizedDate else {
                    return nil
                }
                return (completion, completionDate)
            }
            
            // If no valid completions, return nil
            if validCompletions.isEmpty {
                return nil
            }
            
            // Find and return the completion with the most recent date
            let mostRecent = validCompletions.max { pair1, pair2 in
                return pair1.1 < pair2.1
            }
            
            return mostRecent?.0
        }
    }
}

extension Habit {
    // Find the most recent completed completion before a specific date where the completion's day has exactly `repeatsPerDay` completions
    /*
    func findMostRecentCompletedCompletion(before date: Date) -> Completion? {
        guard let completions = self.completion as? Set<Completion>,
              !completions.isEmpty else {
            return nil
        }
        
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        let normalizedDate = calendar.startOfDay(for: date)
        
        // Get repeats required for this pattern
        guard let repeatPattern = HabitUtilities.getEffectiveRepeatPattern(for: self, on: normalizedDate),
              repeatPattern.repeatsPerDay > 1 else {
            // If repeatsPerDay is 1 or pattern not found, fallback to standard logic
            return self.findMostRecentCompletion(before: date)
        }
        
        let repeatsRequired = Int(repeatPattern.repeatsPerDay)
        let effectiveFromDate = calendar.startOfDay(for: repeatPattern.effectiveFrom ?? .distantPast)
        
        // Group all completions by date
        var completionsByDate: [Date: [Completion]] = [:]
        
        for completion in completions {
            guard let completionDate = completion.date,
                  completion.completed else { continue }
            
            let normalizedCompDate = calendar.startOfDay(for: completionDate)
            
            // Skip if date is on or after our search date or before effective date
            if normalizedCompDate >= normalizedDate || normalizedCompDate < effectiveFromDate {
                continue
            }
            
            if completionsByDate[normalizedCompDate] == nil {
                completionsByDate[normalizedCompDate] = []
            }
            completionsByDate[normalizedCompDate]?.append(completion)
        }
        
        // Find dates that have enough completions to consider the habit completed
        let validDates = completionsByDate.keys.filter { dateKey in
            let completionsForDay = completionsByDate[dateKey]?.count ?? 0
            
            // For bad habits: completed means fewer completions than required
            if self.isBadHabit {
                return completionsForDay < repeatsRequired
            }
            // For good habits: completed means met or exceeded required completions
            else {
                return completionsForDay >= repeatsRequired
            }
        }
        
        // Find the most recent date with valid completions
        guard let mostRecentValidDate = validDates.max() else {
            return nil
        }
        
        // Get completions for the most recent valid date
        guard let completionsForMostRecentDate = completionsByDate[mostRecentValidDate] else {
            return nil
        }
        
        // Return the most recent completion from that date
        return completionsForMostRecentDate.max { a, b in
            (a.date ?? .distantPast) < (b.date ?? .distantPast)
        }
    }
     */
    func findMostRecentCompletedCompletion(before date: Date, repeatPattern: RepeatPattern) -> Completion? {
        guard let completions = self.completion as? Set<Completion>,
              !completions.isEmpty else {
            return nil
        }
        
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        let normalizedDate = calendar.startOfDay(for: date)
        
        // Get repeats required for this pattern
        if repeatPattern.repeatsPerDay <= 1 {
                // If repeatsPerDay is 1, fallback to standard logic
                return self.findMostRecentCompletion(before: date)
            }
        
        let effectiveFromDate = calendar.startOfDay(for: repeatPattern.effectiveFrom ?? .distantPast)
        
        // Collect dates to check
        var datesToCheck: [Date] = []
        var currentDate = effectiveFromDate
        
        // Generate all dates between effectiveFrom and the day before our search date
        while currentDate < normalizedDate {
            datesToCheck.append(currentDate)
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDay
        }
        
        // Sort dates in reverse chronological order (most recent first)
        datesToCheck.sort(by: >)
        
        // Find the most recent date on which the habit was completed
        for checkDate in datesToCheck {
            if self.isCompleted(on: checkDate) {
                // For this date, find the most recent completion
                let dayCompletions = completions.filter { completion in
                    guard let compDate = completion.date else { return false }
                    return calendar.isDate(compDate, inSameDayAs: checkDate) && completion.completed
                }
                
                // Return the most recent completion from that date
                return dayCompletions.max { a, b in
                    (a.date ?? .distantPast) < (b.date ?? .distantPast)
                }
            }
        }
        
        return nil
    }
}

extension Habit {
    func calculateOverdueDays(on date: Date) -> Int? {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        let normalizedDate = calendar.startOfDay(for: date)
        
        // Get the effective repeat pattern for this date
        guard let repeatPattern = HabitUtilities.getEffectiveRepeatPattern(for: self, on: date),
              repeatPattern.followUp else {
            return nil
        }
        
        // Find most recent completion before the date
        let mostRecentCompletion = self.findMostRecentCompletion(before: date)
        
        // Find the earliest missed scheduled date
        var earliestMissedDate: Date? = nil
        
        // CASE 1: Daily Goal
        if let dailyGoal = repeatPattern.dailyGoal {
            // Every day pattern
            if dailyGoal.everyDay {
                if let mostRecentCompletion = mostRecentCompletion,
                   let completionDate = mostRecentCompletion.date {
                    
                    let completionDateNormalized = calendar.startOfDay(for: completionDate)
                    let nextDay = calendar.date(byAdding: .day, value: 1, to: completionDateNormalized)
                    
                    if let nextDay = nextDay, nextDay < normalizedDate {
                        earliestMissedDate = nextDay
                    }
                } else if let startDate = self.startDate {
                    let startDateNormalized = calendar.startOfDay(for: startDate)
                    
                    if startDateNormalized < normalizedDate {
                        earliestMissedDate = startDateNormalized
                    }
                }
            }
            
            // Days interval pattern
            else if dailyGoal.daysInterval > 0 {
                let daysInterval = max(1, Int(dailyGoal.daysInterval))
                
                if let mostRecentCompletion = mostRecentCompletion,
                   let completionDate = mostRecentCompletion.date {
                    
                    let completionDateNormalized = calendar.startOfDay(for: completionDate)
                    
                    // Calculate the next scheduled date after completion
                    guard let nextScheduledDate = calendar.date(byAdding: .day, value: daysInterval, to: completionDateNormalized) else {
                        return nil
                    }
                    
                    // If next scheduled date is past, it's the earliest missed date
                    if nextScheduledDate < normalizedDate {
                        earliestMissedDate = nextScheduledDate
                    }
                } else if let startDate = self.startDate {
                    let startDateNormalized = calendar.startOfDay(for: startDate)
                    
                    // If start date is in the future, there's no missed date
                    if startDateNormalized >= normalizedDate {
                        return nil
                    }
                    
                    // Check if the start date itself is an active day for the habit
                    if HabitUtilities.isHabitActive(habit: self, on: startDateNormalized) {
                        earliestMissedDate = startDateNormalized
                    } else {
                        // If start date isn't active, find the first active date
                        var currentDate = startDateNormalized
                        
                        // Look ahead for the first active date
                        while currentDate < normalizedDate {
                            if HabitUtilities.isHabitActive(habit: self, on: currentDate) {
                                earliestMissedDate = currentDate
                                break
                            }
                            
                            // Move to next day
                            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                                break
                            }
                            currentDate = nextDay
                        }
                    }
                }
            }
            
            // Specific days pattern
            else if let specificDays = dailyGoal.specificDays as? [Bool], specificDays.count >= 7 {
                // Determine how many weeks are in the pattern
                let weekCount = specificDays.count / 7
                let effectiveFromDate = repeatPattern.effectiveFrom ?? self.startDate ?? Date()
                
                // Search for earliest missed day
                var currentDate: Date
                
                if let mostRecentCompletion = mostRecentCompletion,
                   let completionDate = mostRecentCompletion.date {
                    currentDate = calendar.date(byAdding: .day, value: 1, to: completionDate) ?? date
                } else if let startDate = self.startDate {
                    currentDate = startDate
                } else {
                    return nil
                }
                
                while currentDate < normalizedDate {
                    // Get days since effectiveFrom to determine which week we're in
                    let effectiveFromDay = calendar.startOfDay(for: effectiveFromDate)
                    let daysSinceEffective = calendar.dateComponents([.day], from: effectiveFromDay, to: currentDate).day ?? 0
                    
                    // Calculate which week in the cycle we're in
                    let weekInCycle = (daysSinceEffective / 7) % weekCount
                    
                    // Get the day of week
                    let dayOfWeek = calendar.component(.weekday, from: currentDate)
                    let adjustedIndex = (dayOfWeek + 5) % 7
                    
                    // Calculate the actual index in the specificDays array
                    let actualIndex = (weekInCycle * 7) + adjustedIndex
                    
                    // Check if this specific day is scheduled
                    if actualIndex >= 0 && actualIndex < specificDays.count && specificDays[actualIndex] {
                        // Check if this day was completed
                        let isCompleted = self.isCompleted(on: currentDate)
                        
                        if !isCompleted {
                            earliestMissedDate = currentDate
                            break
                        }
                    }
                    
                    // Move to next day
                    if let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDate) {
                        currentDate = nextDay
                    } else {
                        break
                    }
                }
            }
        }
        
        // CASE 2: Weekly Goal
        else if let weeklyGoal = repeatPattern.weeklyGoal, let specificDays = weeklyGoal.specificDays as? [Bool], specificDays.count == 7 {
            let effectiveFromDate = repeatPattern.effectiveFrom ?? self.startDate ?? Date()
            
            // Search for earliest missed day
            var currentDate: Date
            
            if let mostRecentCompletion = mostRecentCompletion,
               let completionDate = mostRecentCompletion.date {
                currentDate = calendar.date(byAdding: .day, value: 1, to: completionDate) ?? date
            } else if let startDate = self.startDate {
                currentDate = startDate
            } else {
                return nil
            }
            
            while currentDate < normalizedDate {
                // Check if this date is in an active week
                let isActiveWeek = weeklyGoal.everyWeek ||
                                  HabitUtilities.isActiveWeek(date: currentDate,
                                                            effectiveFrom: effectiveFromDate,
                                                            weekInterval: weeklyGoal.weekInterval)
                
                if isActiveWeek {
                    // Check if this day of week is selected
                    let dayOfWeek = calendar.component(.weekday, from: currentDate)
                    let adjustedIndex = (dayOfWeek + 5) % 7
                    
                    if adjustedIndex >= 0 && adjustedIndex < specificDays.count && specificDays[adjustedIndex] {
                        // Check if this day was completed
                        let isCompleted = self.isCompleted(on: currentDate)
                        
                        if !isCompleted {
                            earliestMissedDate = currentDate
                            break
                        }
                    }
                }
                
                // Move to next day
                if let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDate) {
                    currentDate = nextDay
                } else {
                    break
                }
            }
        }
        
        // CASE 3: Monthly Goal
        else if let monthlyGoal = repeatPattern.monthlyGoal, let specificDays = monthlyGoal.specificDays as? [Bool], specificDays.count == 31 {
            let effectiveFromDate = repeatPattern.effectiveFrom ?? self.startDate ?? Date()
            
            // Search for earliest missed day
            var currentDate: Date
            
            if let mostRecentCompletion = mostRecentCompletion,
               let completionDate = mostRecentCompletion.date {
                currentDate = calendar.date(byAdding: .day, value: 1, to: completionDate) ?? date
            } else if let startDate = self.startDate {
                currentDate = startDate
            } else {
                return nil
            }
            
            while currentDate < normalizedDate {
                // Check if this date is in an active month
                let isActiveMonth = monthlyGoal.everyMonth ||
                                   HabitUtilities.isActiveMonth(date: currentDate,
                                                              effectiveFrom: effectiveFromDate,
                                                              monthInterval: monthlyGoal.monthInterval)
                
                if isActiveMonth {
                    // Check if this day of month is selected
                    let dayOfMonth = calendar.component(.day, from: currentDate)
                    
                    if dayOfMonth <= specificDays.count && specificDays[dayOfMonth - 1] {
                        // Check if this day was completed
                        let isCompleted = self.isCompleted(on: currentDate)
                        
                        if !isCompleted {
                            earliestMissedDate = currentDate
                            break
                        }
                    }
                    // Special case: Check if this is the last day of a month with fewer than 31 days
                    let range = calendar.range(of: .day, in: .month, for: currentDate)
                    let lastDay = range?.count ?? 31
                    
                    if dayOfMonth == lastDay && lastDay < 31 {
                        // Check if any later days are selected
                        var hasLaterDaySelected = false
                        for day in lastDay..<31 {
                            if specificDays[day] {
                                hasLaterDaySelected = true
                                break
                            }
                        }
                        
                        if hasLaterDaySelected {
                            // Check if this day was completed
                            let isCompleted = self.isCompleted(on: currentDate)
                            
                            if !isCompleted {
                                earliestMissedDate = currentDate
                                break
                            }
                        }
                    }
                }
                
                // Move to next day
                if let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDate) {
                    currentDate = nextDay
                } else {
                    break
                }
            }
        }
        if let earliestMissedDate = earliestMissedDate {
            // Special handling for habits without previous completions
            if mostRecentCompletion == nil {
                // If we're on the first overdue day, show 1 overdue day
                if calendar.isDate(earliestMissedDate, inSameDayAs: normalizedDate) {
                    return 1
                }
                
                // Get components between dates
                let components = calendar.dateComponents([.day], from: earliestMissedDate, to: normalizedDate)
                
                // For specific patterns (weekly, monthly) we need to add +1 to count the first day
                if let dailyGoal = repeatPattern.dailyGoal, !dailyGoal.everyDay && dailyGoal.daysInterval == 0,
                   let specificDays = dailyGoal.specificDays as? [Bool], specificDays.count >= 7 {
                    // For specific days pattern in daily goal
                    return (components.day ?? 0) + 1
                } else if repeatPattern.weeklyGoal != nil || repeatPattern.monthlyGoal != nil {
                    // For weekly or monthly goals
                    return (components.day ?? 0) + 1
                } else {
                    // For daily interval, calculation is already correct
                    return components.day ?? 0
                }
            } else {
                // Normal calculation for habits with previous completions
                let components = calendar.dateComponents([.day], from: earliestMissedDate, to: normalizedDate)
                return components.day ?? 0
            }
        }
        
        // Calculate overdue days if we found an earliest missed date
        /*
        if let earliestMissedDate = earliestMissedDate {
            // Spezielle Behandlung für Habits ohne bisherige Completions
            if mostRecentCompletion == nil {
                // Wenn wir am ersten überfälligen Tag sind, zeige 1 überfälligen Tag
                if calendar.isDate(earliestMissedDate, inSameDayAs: normalizedDate) {
                    return 1
                }
                
                // Bei Habits ohne bisherige Completions zählen wir ab dem ersten verpassten Tag
                let components = calendar.dateComponents([.day], from: earliestMissedDate, to: normalizedDate)
                return (components.day ?? 0) + 1 // +1 um den ersten Tag mitzuzählen
            } else {
                // Normale Berechnung für Habits mit bisherigen Completions
                let components = calendar.dateComponents([.day], from: earliestMissedDate, to: normalizedDate)
                return (components.day ?? 0)
            }
        }
         */
        
        
        return nil
    }
}

/*
extension Habit {
    // Calculate the streak for this habit up to a specific date
    func calculateStreak(upTo referenceDate: Date) -> Int {
        let calendar = Calendar.current
        let referenceDay = calendar.startOfDay(for: referenceDate)
        
        guard let completions = completion as? Set<Completion>,
              let startDate = self.startDate else {
            return 0
        }
        
        // If the habit hasn't started yet on the reference date, return 0
        if calendar.startOfDay(for: startDate) > referenceDay {
            return 0
        }
        
        // Convert completions to a dictionary for faster lookup
        var completionDict: [Date: Bool] = [:]
        for completion in completions {
            if let date = completion.date, completion.completed,
               // Only include completions up to the reference date
               date <= referenceDay {
                completionDict[calendar.startOfDay(for: date)] = true
            }
        }
        
        // If there are no completions up to the reference date, return 0
        if completionDict.isEmpty {
            return 0
        }
        
        // Get all dates where the habit should be active, from start date to reference date
        var activeDates: [Date] = []
        var currentDate = calendar.startOfDay(for: startDate)
        
        // Collect all active dates from start to reference date
        while currentDate <= referenceDay {
            // Use the centralized HabitUtilities function
            if HabitUtilities.isHabitActive(habit: self, on: currentDate) {
                activeDates.append(currentDate)
            }
            
            if let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) {
                currentDate = nextDate
            } else {
                break
            }
        }
        
        // If no active dates found, return 0
        if activeDates.isEmpty {
            return 0
        }
        
        // Sort active dates in descending order (most recent first)
        activeDates.sort(by: >)
        
        // Start counting streak from most recent active date
        var streak = 0
        var shouldBeActive = true
        
        for activeDate in activeDates {
            // If the streak should be active
            if shouldBeActive {
                // Check if the habit was completed on this date
                if completionDict[activeDate] == true {
                    streak += 1
                } else {
                    // If the reference date is active but not completed yet, don't break streak
                    // but only if the reference date is today (we don't want to be lenient for past dates)
                    let isReferenceToday = calendar.isDate(referenceDay, inSameDayAs: Date())
                    
                    if calendar.isDate(activeDate, inSameDayAs: referenceDay) && isReferenceToday {
                        // Reference date is today and not completed yet, don't count it
                    } else {
                        // A previous active date was missed, streak breaks
                        shouldBeActive = false
                    }
                }
            }
        }
        
        return streak
    }
}
*/
/*
extension Habit {
    func calculateStreak(upTo referenceDate: Date) -> Int {
        let calendar = Calendar.current
        let referenceDay = calendar.startOfDay(for: referenceDate)
        
        guard let startDate = self.startDate else {
            return 0
        }
        
        // If the habit hasn't started yet on the reference date, return 0
        if calendar.startOfDay(for: startDate) > referenceDay {
            return 0
        }
        
        // Optimization: For everyday habits without follow-up, we can use a faster approach
        if let repeatPattern = HabitUtilities.getEffectiveRepeatPattern(for: self, on: referenceDay),
           let dailyGoal = repeatPattern.dailyGoal,
           dailyGoal.everyDay && !repeatPattern.followUp {
            return calculateEverydayHabitStreak(upTo: referenceDate)
        }
        
        // For other patterns, use a limited date range for efficiency
        // Start from max(startDate, referenceDay - 60 days) to avoid checking unnecessary dates
        let oldestDateToCheck = calendar.date(byAdding: .day, value: -60, to: referenceDay) ?? startDate
        let effectiveStartDate = max(calendar.startOfDay(for: startDate), calendar.startOfDay(for: oldestDateToCheck))
        
        // Get active dates only within the limited range
        var activeDates: [Date] = []
        var currentDate = effectiveStartDate
        
        // Collect active dates within the limited range
        while currentDate <= referenceDay {
            if HabitUtilities.isHabitActive(habit: self, on: currentDate) {
                activeDates.append(currentDate)
            }
            
            if let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) {
                currentDate = nextDate
            } else {
                break
            }
        }
        
        // If no active dates found, return 0
        if activeDates.isEmpty {
            return 0
        }
        
        // Sort active dates in descending order (most recent first)
        activeDates.sort(by: >)
        
        // Start counting streak from most recent active date
        var streak = 0
        var shouldBeActive = true
        
        for activeDate in activeDates {
            // Skip if we've already broken the streak
            if !shouldBeActive {
                break
            }
            
            // Use the isCompleted method to determine completion status
            let isCompleted = self.isCompleted(on: activeDate)
            
            // Different logic for bad habits vs good habits
            if self.isBadHabit {
                // For bad habits: If "isCompleted" is true it means the user successfully avoided the habit
                // so we increment the streak
                if isCompleted {
                    streak += 1
                } else {
                    // If not "completed" (meaning the bad habit was done), streak breaks
                    shouldBeActive = false
                }
            } else {
                // For good habits: completed means the streak continues
                if isCompleted {
                    streak += 1
                } else {
                    // Special handling for today's date
                    let isReferenceToday = calendar.isDate(referenceDay, inSameDayAs: Date())
                    
                    if calendar.isDate(activeDate, inSameDayAs: referenceDay) && isReferenceToday {
                        // Today's date and not completed yet - don't break streak
                        streak += 1 // Still count today for streak
                    } else {
                        // Past date was missed - streak breaks
                        shouldBeActive = false
                    }
                }
            }
        }
        
        return streak
    }
    
    // Fast path for everyday habits
    private func calculateEverydayHabitStreak(upTo referenceDate: Date) -> Int {
        let calendar = Calendar.current
        let referenceDay = calendar.startOfDay(for: referenceDate)
        let today = calendar.startOfDay(for: Date())
        
        // For everyday habits, we just need to find the most recent missed day
        var streak = 0
        var currentDate = referenceDay
        
        // Only check back up to 100 days maximum for efficiency
        let maxDaysToCheck = 100
        
        for _ in 0..<maxDaysToCheck {
            let isToday = calendar.isDate(currentDate, inSameDayAs: today)
            
            // Different logic for bad habits vs good habits
            if self.isBadHabit {
                // For bad habits, the streak continues if they successfully AVOID the habit
                // which is when isCompleted returns TRUE for bad habits
                let didComplete = self.isCompleted(on: currentDate)
                
                if isToday {
                    // For today, assume they'll avoid the habit and add to streak
                    streak += 1
                }
                else if didComplete {
                    // Successfully avoided the bad habit, increment streak
                    streak += 1
                } else {
                    // Bad habit was done - streak breaks
                    break
                }
            } else {
                // For good habits, the streak continues if they DO the habit
                let didComplete = self.isCompleted(on: currentDate)
                
                if isToday {
                    // For today, assume they'll complete later
                    streak += 1
                }
                // For other days, check completion
                else if didComplete {
                    // Good habit was done
                    streak += 1
                } else {
                    // Good habit was missed - streak breaks
                    break
                }
            }
            
            // Move to previous day
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                break
            }
            
            // Don't go earlier than start date
            if let startDate = self.startDate, previousDay < calendar.startOfDay(for: startDate) {
                break
            }
            
            currentDate = previousDay
        }
        
        return streak
    }
}
 */
/*
extension Habit {
    func calculateStreak(upTo referenceDate: Date) -> Int {
        let calendar = Calendar.current
        let referenceDay = calendar.startOfDay(for: referenceDate)
        let todayDate = calendar.startOfDay(for: Date())
        
        guard let startDate = self.startDate else {
            return 0
        }
        
        // If the habit hasn't started yet on the reference date, return 0
        if calendar.startOfDay(for: startDate) > referenceDay {
            return 0
        }
        
        // Optimization: For everyday habits without follow-up, we can use a faster approach
        if let repeatPattern = HabitUtilities.getEffectiveRepeatPattern(for: self, on: referenceDay),
           let dailyGoal = repeatPattern.dailyGoal,
           dailyGoal.everyDay && !repeatPattern.followUp {
            return calculateEverydayHabitStreak(upTo: referenceDate)
        }
        
        // For other patterns, use a limited date range for efficiency
        // Start from max(startDate, referenceDay - 60 days) to avoid checking unnecessary dates
        let oldestDateToCheck = calendar.date(byAdding: .day, value: -60, to: referenceDay) ?? startDate
        let effectiveStartDate = max(calendar.startOfDay(for: startDate), calendar.startOfDay(for: oldestDateToCheck))
        
        // Get active dates only within the limited range
        var activeDates: [Date] = []
        var currentDate = effectiveStartDate
        
        // Collect active dates within the limited range
        while currentDate <= referenceDay {
            if HabitUtilities.isHabitActive(habit: self, on: currentDate) {
                activeDates.append(currentDate)
            }
            
            if let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) {
                currentDate = nextDate
            } else {
                break
            }
        }
        
        // If no active dates found, return 0
        if activeDates.isEmpty {
            return 0
        }
        
        // Sort active dates in descending order (most recent first)
        activeDates.sort(by: >)
        
        // Start counting streak from most recent active date
        var streak = 0
        var shouldBeActive = true
        
        for activeDate in activeDates {
            // Skip if we've already broken the streak
            if !shouldBeActive {
                break
            }
            
            // Check if this is today
            let isToday = calendar.isDate(activeDate, inSameDayAs: todayDate)
            
            // If this is today and not the reference date, skip it for now
            // This handles the case where we're calculating a streak for a past date
            if isToday && !calendar.isDate(activeDate, inSameDayAs: referenceDay) {
                continue
            }
            
            // Use the isCompleted method to determine completion status
            let isCompleted = self.isCompleted(on: activeDate)
            
            // Different logic for bad habits vs good habits
            if self.isBadHabit {
                // For bad habits: isCompleted is true when habit was successfully avoided
                if isCompleted {
                    streak += 1
                } else {
                    // If the bad habit was done, streak breaks
                    shouldBeActive = false
                }
            } else {
                // For good habits: completed means the streak continues
                if isCompleted {
                    streak += 1
                } else {
                    // If the current date is today and it's not completed,
                    // don't increment streak but don't break it either
                    if isToday && calendar.isDate(activeDate, inSameDayAs: referenceDay) {
                        // Do nothing - we don't count today but we don't break the streak
                    } else {
                        // Past date was missed - streak breaks
                        shouldBeActive = false
                    }
                }
            }
        }
        
        return streak
    }
    
    // Fast path for everyday habits
    private func calculateEverydayHabitStreak(upTo referenceDate: Date) -> Int {
        let calendar = Calendar.current
        let referenceDay = calendar.startOfDay(for: referenceDate)
        let todayDate = calendar.startOfDay(for: Date())
        
        // If the reference date is today, we need to handle it specially
        let isReferenceToday = calendar.isDate(referenceDay, inSameDayAs: todayDate)
        
        // For everyday habits, we just need to find the most recent missed day
        var streak = 0
        var currentDate = referenceDay
        
        // Only check back up to 100 days maximum for efficiency
        let maxDaysToCheck = 150
        
        // If reference date is today and habit is not completed yet,
        // start checking from yesterday instead
        if isReferenceToday && !self.isCompleted(on: todayDate) {
            if let yesterday = calendar.date(byAdding: .day, value: -1, to: todayDate) {
                currentDate = yesterday
            }
        }
        
        for _ in 0..<maxDaysToCheck {
            // If we've gone before the start date, stop
            if let startDate = self.startDate, currentDate < calendar.startOfDay(for: startDate) {
                break
            }
            
            // Use the isCompleted method to determine completion status
            let isCompleted = self.isCompleted(on: currentDate)
            
            // Different logic for bad habits vs good habits
            if self.isBadHabit {
                // For bad habits: isCompleted is true when habit was successfully avoided
                if isCompleted {
                    streak += 1
                } else {
                    // If the bad habit was done, streak breaks
                    break
                }
            } else {
                // For good habits: completed means the streak continues
                if isCompleted {
                    streak += 1
                } else {
                    // Good habit was missed - streak breaks
                    break
                }
            }
            
            // Move to previous day
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                break
            }
            
            currentDate = previousDay
        }
        
        return streak
    }
}
 */
extension Color {
    // Convert UIColor archived data back to Color
    init?(data: Data?) {
        guard let data = data,
              let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data)
        else {
            return nil
        }
        self.init(uiColor)
    }
}
/*

extension Habit {
    func isCompleted(on date: Date) -> Bool {
        guard let completions = self.completion as? Set<Completion> else {
            return false
        }
        
        let repeatsRequired = currentRepeatsPerDay(on: date)
        let key = DayKeyFormatter.localKey(from: date)
        
        // ✅ Use dayKey instead of scanning with Calendar
        let completedCount = completions.filter { c in
            c.completed && c.dayKey == key
        }.count
        
        if self.isBadHabit {
            // Bad habit: success = fewer than required (often 0)
            return completedCount < repeatsRequired
        } else {
            // Good habit: success = met or exceeded required
            return completedCount >= repeatsRequired
        }
    }
    
    func completedCount(on date: Date) -> Int {
        guard let completions = self.completion as? Set<Completion> else {
            return 0
        }
        
        let key = DayKeyFormatter.localKey(from: date)
        return completions.filter { c in
            c.completed && c.dayKey == key
        }.count
    }
    
    func currentRepeatsPerDay(on date: Date) -> Int {
        guard Thread.isMainThread else {
            return DispatchQueue.main.sync {
                return self.currentRepeatsPerDay(on: date)
            }
        }
        
        guard !self.isFault && !self.isDeleted else { return 1 }
        guard let set = self.repeatPattern, set.count > 0 else { return 1 }
        
        let patterns = Array(set).compactMap { $0 as? RepeatPattern }
        guard !patterns.isEmpty else { return 1 }
        
        let calendar = Calendar.current
        let normalized = calendar.startOfDay(for: date)
        
        let activePatterns = patterns.compactMap { p -> (RepeatPattern, Date)? in
            guard !p.isFault && !p.isDeleted, let ef = p.effectiveFrom else { return nil }
            let efd = calendar.startOfDay(for: ef)
            return efd <= normalized ? (p, efd) : nil
        }
        
        guard let mostRecent = activePatterns.max(by: { $0.1 < $1.1 })?.0 else { return 1 }
        guard !mostRecent.isFault && !mostRecent.isDeleted else { return 1 }
        
        return Int(mostRecent.repeatsPerDay)
    }
    
    static func getCompletionProgress(for habit: Habit, on date: Date) -> Double {
            guard let pattern = habit.repeatPattern?.allObjects.first as? RepeatPattern,
                  let trackingType = pattern.trackingType,
                  let type = HabitTrackingType(rawValue: trackingType) else {
                // Fallback to repetitions logic
                let required = Double(HabitUtilities.getRepeatsPerDay(for: habit, on: date))
                let completed = Double(HabitUtilities.getCompletedRepeatsCount(for: habit, on: date))
                return required > 0 ? min(1.0, completed / required) : 0
            }
            
            switch type {
            case .repetitions:
                let required = Double(HabitUtilities.getRepeatsPerDay(for: habit, on: date))
                let completed = Double(HabitUtilities.getCompletedRepeatsCount(for: habit, on: date))
                return required > 0 ? min(1.0, completed / required) : 0
                
            case .duration:
                let target = Double(pattern.duration)
                let completed = Double(getDurationCompleted(for: habit, on: date))
                return target > 0 ? min(1.0, completed / target) : 0
                
            case .quantity:
                let target = Double(pattern.targetQuantity)
                let completed = Double(getQuantityCompleted(for: habit, on: date))
                return target > 0 ? min(1.0, completed / target) : 0
            }
        }
        
        // Helper methods
        static func getDurationCompleted(for habit: Habit, on date: Date) -> Int {
            let calendar = Calendar.current
            let normalizedDate = calendar.startOfDay(for: date)
            
            guard let completions = habit.completion as? Set<Completion> else { return 0 }
            
            let dayCompletions = completions.filter { completion in
                guard let completionDate = completion.date else { return false }
                return calendar.isDate(completionDate, inSameDayAs: normalizedDate)
            }
            
            // Sum up all duration entries for the day
            return dayCompletions.reduce(0) { $0 + Int($1.duration) }
        }
        
        static func getQuantityCompleted(for habit: Habit, on date: Date) -> Int {
            let calendar = Calendar.current
            let normalizedDate = calendar.startOfDay(for: date)
            
            guard let completions = habit.completion as? Set<Completion> else { return 0 }
            
            let dayCompletions = completions.filter { completion in
                guard let completionDate = completion.date else { return false }
                return calendar.isDate(completionDate, inSameDayAs: normalizedDate)
            }
            
            // Sum up all quantity entries for the day
            return dayCompletions.reduce(0) { $0 + Int($1.quantity) }
        }
}
*/
extension Habit {
    func isCompleted(on date: Date) -> Bool {
        guard let completions = self.completion as? Set<Completion> else {
            return false
        }
        
        let repeatsRequired = currentRepeatsPerDay(on: date)
        let key = DayKeyFormatter.localKey(from: date)
        
        // Check if we have a tracking type specified
        if let pattern = self.repeatPattern?.allObjects.first as? RepeatPattern,
           let trackingTypeString = pattern.trackingType,
           let trackingType = HabitTrackingType(rawValue: trackingTypeString) {
            
            switch trackingType {
            case .repetitions:
                // Count completed instances for the specified date
                let completedCount = completions.filter { c in
                    c.completed && c.dayKey == key
                }.count
                
                // For bad habits: success = fewer than required (often 0)
                if self.isBadHabit {
                    return completedCount < repeatsRequired
                } else {
                    // Good habit: success = met or exceeded required
                    return completedCount >= repeatsRequired
                }
                
            case .duration:
                // Get target duration and completed duration
                let targetMinutes = Int(pattern.duration)
                let completedMinutes = getDurationCompleted(on: date)
                
                // For duration habits, completion means reaching the target time
                return completedMinutes >= targetMinutes
                
            case .quantity:
                // Get target quantity and completed quantity
                let targetQuantity = Int(pattern.targetQuantity)
                let completedQuantity = getQuantityCompleted(on: date)
                
                // For quantity habits, completion means reaching the target amount
                return completedQuantity >= targetQuantity
            }
            
        } else {
            // Fallback to original repetition-based logic for legacy habits
            let completedCount = completions.filter { c in
                c.completed && c.dayKey == key
            }.count
            
            if self.isBadHabit {
                // Bad habit: success = fewer than required (often 0)
                return completedCount < repeatsRequired
            } else {
                // Good habit: success = met or exceeded required
                return completedCount >= repeatsRequired
            }
        }
    }
    func completedCount(on date: Date) -> Int {
        guard let completions = self.completion as? Set<Completion> else {
            return 0
        }
        
        let key = DayKeyFormatter.localKey(from: date)
        return completions.filter { c in
            c.completed && c.dayKey == key
        }.count
    }
    
    func currentRepeatsPerDay(on date: Date) -> Int {
        guard Thread.isMainThread else {
            return DispatchQueue.main.sync {
                return self.currentRepeatsPerDay(on: date)
            }
        }
        
        guard !self.isFault && !self.isDeleted else { return 1 }
        guard let set = self.repeatPattern, set.count > 0 else { return 1 }
        
        let patterns = Array(set).compactMap { $0 as? RepeatPattern }
        guard !patterns.isEmpty else { return 1 }
        
        let calendar = Calendar.current
        let normalized = calendar.startOfDay(for: date)
        
        let activePatterns = patterns.compactMap { p -> (RepeatPattern, Date)? in
            guard !p.isFault && !p.isDeleted, let ef = p.effectiveFrom else { return nil }
            let efd = calendar.startOfDay(for: ef)
            return efd <= normalized ? (p, efd) : nil
        }
        
        guard let mostRecent = activePatterns.max(by: { $0.1 < $1.1 })?.0 else { return 1 }
        guard !mostRecent.isFault && !mostRecent.isDeleted else { return 1 }
        
        return Int(mostRecent.repeatsPerDay)
    }
    // Helper method to get duration completed for a specific date
    func getDurationCompleted(on date: Date) -> Int {
        guard let completions = self.completion as? Set<Completion> else {
            return 0
        }
        
        let key = DayKeyFormatter.localKey(from: date)
        
        // Sum up all duration entries for the day
        return completions.filter { c in
            c.dayKey == key
        }.reduce(0) { $0 + Int($1.duration) }
    }
    
    // Helper method to get quantity completed for a specific date
    func getQuantityCompleted(on date: Date) -> Int {
        guard let completions = self.completion as? Set<Completion> else {
            return 0
        }
        
        let key = DayKeyFormatter.localKey(from: date)
        
        // Sum up all quantity entries for the day
        return completions.filter { c in
            c.dayKey == key
        }.reduce(0) { $0 + Int($1.quantity) }
    }
}
/*
extension Habit {
    func isCompleted(on date: Date) -> Bool {
        guard let completions = self.completion as? Set<Completion> else {
            return false
        }
        
        // Get the effective repeat pattern for this date
        guard let repeatPattern = HabitUtilities.getEffectiveRepeatPattern(for: self, on: date) else {
            return false // No active pattern found
        }
        
        // Get repeats required from the active repeat pattern
        let repeatsRequired = Int(repeatPattern.repeatsPerDay)
        
        // Count completed instances for the specified date
        let completedCount = completions.filter { completion in
            guard let completionDate = completion.date else { return false }
            return Calendar.current.isDate(completionDate, inSameDayAs: date) && completion.completed
        }.count
        
        // For bad habits: completed means fewer completions than required
        // (meaning the user successfully avoided the bad habit)
        if self.isBadHabit {
            return completedCount < repeatsRequired
        }
        // For good habits: completed means met or exceeded required completions
        else {
            return completedCount >= repeatsRequired
        }
    }
}
 */
extension Habit {
    func toggleArchiveStatus(context: NSManagedObjectContext? = nil) {
        // Use the provided context or the one associated with self
        let managedContext = context ?? self.managedObjectContext!
        
        // Toggle the archived status
        self.isArchived.toggle()
        
        do {
            try managedContext.save()
        } catch {
            print("Error toggling archive status: \(error)")
            managedContext.rollback()
        }
    }
}

extension Habit {
    func moveToHabitList(_ list: HabitList?, context: NSManagedObjectContext) {
        // Remove from current list if any
        if let currentList = self.habitList {
            currentList.removeFromHabits(self)
        }
        
        // Add to new list if provided
        if let newList = list {
            self.habitList = newList
            newList.addToHabits(self)
        } else {
            self.habitList = nil
        }
        
        // Save changes
        do {
            try context.save()
            print("✅ Successfully moved habit to new list")
        } catch {
            print("❌ Failed to save context after moving habit: \(error)")
            context.rollback()
        }
    }
}
/*
extension Habit {
    func calculateLongestStreak() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        guard let startDate = self.startDate else {
            return 0
        }
        
        // If the habit hasn't started yet, return 0
        if calendar.startOfDay(for: startDate) > today {
            return 0
        }
        
        // Get all dates where the habit should be active, from start date to today
        var activeDates: [Date] = []
        var currentDate = calendar.startOfDay(for: startDate)
        
        // Collect all active dates from start to today
        while currentDate <= today {
            if HabitUtilities.isHabitActive(habit: self, on: currentDate) {
                activeDates.append(currentDate)
            }
            
            if let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) {
                currentDate = nextDate
            } else {
                break
            }
        }
        
        // If no active dates found, return 0
        if activeDates.isEmpty {
            return 0
        }
        
        // Sort active dates chronologically
        activeDates.sort()
        
        var longestStreak = 0
        var currentStreak = 0
        
        // Different logic for tracking streaks based on habit type
        if self.isBadHabit {
            // For bad habits: NOT completed means the streak continues
            for activeDate in activeDates {
                let isCompleted = self.isCompleted(on: activeDate)
                
                if !isCompleted {
                    // If not completed (avoiding the bad habit), increment streak
                    currentStreak += 1
                    longestStreak = max(longestStreak, currentStreak)
                } else {
                    // If completed (did the bad habit), reset streak
                    currentStreak = 0
                }
            }
        } else {
            // For good habits: completed means the streak continues
            for activeDate in activeDates {
                let isCompleted = self.isCompleted(on: activeDate)
                
                if isCompleted {
                    // If completed, increment streak
                    currentStreak += 1
                    longestStreak = max(longestStreak, currentStreak)
                } else {
                    // Special handling for today's date - don't break streak
                    let isToday = calendar.isDate(activeDate, inSameDayAs: today)
                    
                    if !isToday {
                        // If not completed and not today, reset streak
                        currentStreak = 0
                    }
                }
            }
        }
        
        return longestStreak
    }
}
*/
/*
extension Habit {
    func getTotalCompletionCount() -> Int {
        guard let startDate = self.startDate else {
            return 0
        }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var currentDate = calendar.startOfDay(for: startDate)
        var completedCount = 0
        
        // Loop through each day from start date to today
        while currentDate <= today {
            // Only count days where the habit should be active
            if HabitUtilities.isHabitActive(habit: self, on: currentDate) {
                // Use the isCompleted method to determine if the habit was completed on this day
                if isCompleted(on: currentDate) {
                    completedCount += 1
                }
            }
            
            // Move to next day
            if let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) {
                currentDate = nextDate
            } else {
                break
            }
        }
        
        return completedCount
    }
}
*/
enum HabitIntensity: Int16, CaseIterable, Identifiable {
    case light = 1
    case moderate = 2
    case high = 3
    case extreme = 4
    
    var id: Int16 { self.rawValue }
    
    var title: String {
        switch self {
        case .light: return "Light"
        case .moderate: return "Moderate"
        case .high: return "High"
        case .extreme: return "Extreme"
        }
    }
    
    var color: Color {
        switch self {
        case .light: return .green
        case .moderate: return .blue
        case .high: return .orange
        case .extreme: return .red
        }
    }
    
    var description: String {
        switch self {
        case .light: return "Low effort or impact"
        case .moderate: return "Medium effort required"
        case .high: return "Significant effort or impact"
        case .extreme: return "Maximum effort required"
        }
    }
    
    var multiplier: Double {
            switch self {
            case .light:
                return 1.0
            case .moderate:
                return 1.5
            case .high:
                return 2.0
            case .extreme:
                return 3.0
            }
        }
}

extension Habit {
    
    // OPTIMIZATION: Main streak calculation using reverse chronological approach
    func calculateStreak(upTo referenceDate: Date) -> Int {
        let calendar = Calendar.current
        let referenceDay = calendar.startOfDay(for: referenceDate)
        let todayDate = calendar.startOfDay(for: Date())
        
        guard let startDate = self.startDate else { return 0 }
        
        // If habit hasn't started yet, return 0
        if calendar.startOfDay(for: startDate) > referenceDay {
            return 0
        }
        
        // OPTIMIZATION 1: Use reverse chronological scanning (start from reference date, go backwards)
        // This stops as soon as we find a missed day, avoiding unnecessary calculations
        
        // OPTIMIZATION 2: Fast path for everyday habits
        if let repeatPattern = HabitUtilities.getEffectiveRepeatPattern(for: self, on: referenceDay),
           let dailyGoal = repeatPattern.dailyGoal,
           dailyGoal.everyDay && !repeatPattern.followUp {
            return calculateEverydayStreakReverse(upTo: referenceDate)
        }
        
        // OPTIMIZATION 3: Limited lookback for complex patterns (max 90 days)
        let maxLookbackDays = 90
        let oldestDateToCheck = calendar.date(byAdding: .day, value: -maxLookbackDays, to: referenceDay) ?? startDate
        let effectiveStartDate = max(calendar.startOfDay(for: startDate), calendar.startOfDay(for: oldestDateToCheck))
        
        return calculateComplexPatternStreakReverse(
            from: referenceDay,
            to: effectiveStartDate,
            todayDate: todayDate
        )
    }
    
    // OPTIMIZATION: Fast reverse calculation for everyday habits
    private func calculateEverydayStreakReverse(upTo referenceDate: Date) -> Int {
        let calendar = Calendar.current
        let referenceDay = calendar.startOfDay(for: referenceDate)
        let todayDate = calendar.startOfDay(for: Date())
        
        // OPTIMIZATION: Pre-build completion lookup dictionary for faster access
        let completionDict = buildCompletionDictionary()
        
        var streak = 0
        var currentDate = referenceDay
        let maxDaysToCheck = 500 // Reasonable limit
        
        // Handle today specially if reference is today and not completed
        let isReferenceToday = calendar.isDate(referenceDay, inSameDayAs: todayDate)
        if isReferenceToday && !isCompletedFromDict(on: todayDate, completionDict: completionDict) {
            // Don't count today if not completed, start from yesterday
            if let yesterday = calendar.date(byAdding: .day, value: -1, to: todayDate) {
                currentDate = yesterday
            }
        }
        
        // Reverse chronological scan
        for _ in 0..<maxDaysToCheck {
            // Stop if we've gone before start date
            if let startDate = self.startDate, currentDate < calendar.startOfDay(for: startDate) {
                break
            }
            
            // Fast completion check using pre-built dictionary
            let isCompleted = isCompletedFromDict(on: currentDate, completionDict: completionDict)
            
            if self.isBadHabit {
                if isCompleted { // Successfully avoided bad habit
                    streak += 1
                } else {
                    break // Bad habit was done, streak ends
                }
            } else {
                if isCompleted { // Good habit was done
                    streak += 1
                } else {
                    break // Good habit was missed, streak ends
                }
            }
            
            // Move to previous day
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                break
            }
            currentDate = previousDay
        }
        
        return streak
    }
    
    // OPTIMIZATION: Reverse calculation for complex patterns with smart caching
    private func calculateComplexPatternStreakReverse(from referenceDate: Date, to startDate: Date, todayDate: Date) -> Int {
        let calendar = Calendar.current
        
        // OPTIMIZATION: Pre-build completion lookup for the date range we'll check
        let completionDict = buildCompletionDictionary()
        
        // OPTIMIZATION: Pre-calculate active dates in reverse order using efficient pattern checking
        let activeDates = generateActiveDatesReverse(from: referenceDate, to: startDate)
        
        var streak = 0
        let isReferenceToday = calendar.isDate(referenceDate, inSameDayAs: todayDate)
        
        for activeDate in activeDates {
            // Handle today specially
            let isToday = calendar.isDate(activeDate, inSameDayAs: todayDate)
            if isToday && !calendar.isDate(activeDate, inSameDayAs: referenceDate) {
                continue // Skip today if not the reference date
            }
            
            let isCompleted = isCompletedFromDict(on: activeDate, completionDict: completionDict)
            
            if self.isBadHabit {
                if isCompleted {
                    streak += 1
                } else {
                    break // Streak broken
                }
            } else {
                if isCompleted {
                    streak += 1
                } else {
                    // Special handling for today
                    if isToday && calendar.isDate(activeDate, inSameDayAs: referenceDate) {
                        // Don't count today but don't break streak
                    } else {
                        break // Streak broken
                    }
                }
            }
        }
        
        return streak
    }
    
    // OPTIMIZATION: Pre-build completion dictionary for O(1) lookups
    private func buildCompletionDictionary() -> [Date: Int] {
        guard let completions = self.completion as? Set<Completion> else {
            return [:]
        }
        
        var completionDict: [Date: Int] = [:]
        let calendar = Calendar.current
        
        // Build dictionary with completion counts per day
        for completion in completions {
            guard let date = completion.date, completion.completed else { continue }
            
            let normalizedDate = calendar.startOfDay(for: date)
            completionDict[normalizedDate, default: 0] += 1
        }
        
        return completionDict
    }
    
    // OPTIMIZATION: Fast completion check using pre-built dictionary
    private func isCompletedFromDict(on date: Date, completionDict: [Date: Int]) -> Bool {
        let calendar = Calendar.current
        let normalizedDate = calendar.startOfDay(for: date)
        
        let completedCount = completionDict[normalizedDate] ?? 0
        let repeatsRequired = currentRepeatsPerDay(on: date)
        
        if self.isBadHabit {
            return completedCount < repeatsRequired
        } else {
            return completedCount >= repeatsRequired
        }
    }
    
    // OPTIMIZATION: Generate active dates in reverse order with early termination
    private func generateActiveDatesReverse(from referenceDate: Date, to startDate: Date) -> [Date] {
        let calendar = Calendar.current
        var activeDates: [Date] = []
        var currentDate = referenceDate
        let maxDaysToCheck = 90 // Reasonable limit
        
        var daysChecked = 0
        while currentDate >= startDate && daysChecked < maxDaysToCheck {
            // OPTIMIZATION: Use cached pattern checking if available
            if HabitUtilities.isHabitActive(habit: self, on: currentDate) {
                activeDates.append(currentDate)
            }
            
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                break
            }
            currentDate = previousDay
            daysChecked += 1
        }
        
        return activeDates // Already in reverse chronological order
    }
    
    // OPTIMIZATION: Longest streak calculation using sliding window approach
    func calculateLongestStreak() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        guard let startDate = self.startDate else { return 0 }
        
        if calendar.startOfDay(for: startDate) > today {
            return 0
        }
        
        // OPTIMIZATION: For everyday habits, use a much faster approach
        if let repeatPattern = HabitUtilities.getEffectiveRepeatPattern(for: self, on: today),
           let dailyGoal = repeatPattern.dailyGoal,
           dailyGoal.everyDay && !repeatPattern.followUp {
            return calculateLongestEverydayStreak()
        }
        
        // OPTIMIZATION: For complex patterns, use limited date range with sliding window
        return calculateLongestComplexStreak()
    }
    
    // OPTIMIZATION: Fast longest streak for everyday habits
    private func calculateLongestEverydayStreak() -> Int {
        let calendar = Calendar.current
        let completionDict = buildCompletionDictionary()
        
        guard let startDate = self.startDate else { return 0 }
        
        var longestStreak = 0
        var currentStreak = 0
        var currentDate = calendar.startOfDay(for: startDate)
        let today = calendar.startOfDay(for: Date())
        let maxDaysToCheck = 365 // Check max 1 year for performance
        
        var daysChecked = 0
        while currentDate <= today && daysChecked < maxDaysToCheck {
            let isCompleted = isCompletedFromDict(on: currentDate, completionDict: completionDict)
            
            if self.isBadHabit {
                if isCompleted {
                    currentStreak += 1
                    longestStreak = max(longestStreak, currentStreak)
                } else {
                    currentStreak = 0
                }
            } else {
                if isCompleted {
                    currentStreak += 1
                    longestStreak = max(longestStreak, currentStreak)
                } else {
                    // Don't break streak for today if not completed
                    let isToday = calendar.isDate(currentDate, inSameDayAs: today)
                    if !isToday {
                        currentStreak = 0
                    }
                }
            }
            
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDate
            daysChecked += 1
        }
        
        return longestStreak
    }
    
    // OPTIMIZATION: Longest streak for complex patterns with chunking
    private func calculateLongestComplexStreak() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        guard let startDate = self.startDate else { return 0 }
        
        // OPTIMIZATION: Process in chunks to avoid memory issues
        let chunkSize = 30 // Process 30 days at a time
        let completionDict = buildCompletionDictionary()
        
        var longestStreak = 0
        var currentStreak = 0
        var currentDate = calendar.startOfDay(for: startDate)
        let maxDaysToCheck = 365 // Limit to 1 year for performance
        
        var daysChecked = 0
        while currentDate <= today && daysChecked < maxDaysToCheck {
            // Process chunk of dates
            let chunkEndDate = min(
                calendar.date(byAdding: .day, value: chunkSize, to: currentDate) ?? today,
                today
            )
            
            // Get active dates for this chunk
            var chunkDate = currentDate
            while chunkDate <= chunkEndDate && daysChecked < maxDaysToCheck {
                if HabitUtilities.isHabitActive(habit: self, on: chunkDate) {
                    let isCompleted = isCompletedFromDict(on: chunkDate, completionDict: completionDict)
                    
                    if self.isBadHabit {
                        if isCompleted {
                            currentStreak += 1
                            longestStreak = max(longestStreak, currentStreak)
                        } else {
                            currentStreak = 0
                        }
                    } else {
                        if isCompleted {
                            currentStreak += 1
                            longestStreak = max(longestStreak, currentStreak)
                        } else {
                            let isToday = calendar.isDate(chunkDate, inSameDayAs: today)
                            if !isToday {
                                currentStreak = 0
                            }
                        }
                    }
                }
                
                guard let nextDate = calendar.date(byAdding: .day, value: 1, to: chunkDate) else {
                    break
                }
                chunkDate = nextDate
                daysChecked += 1
            }
            
            currentDate = chunkDate
        }
        
        return longestStreak
    }
}

extension Habit {
    
    /// Get the best streak ever as Int
    var bestStreakEverInt: Int {
        return Int(bestStreakEver)
    }
    
    /// Update best streak if the new value is higher
    func updateBestStreakIfBetter(_ newStreak: Int) {
        let currentBest = Int(bestStreakEver)
        
        if newStreak > currentBest {
            bestStreakEver = Int32(newStreak)
            
            do {
                try managedObjectContext?.save()
                print("🏆 Updated best streak for '\(name ?? "Unknown")': \(newStreak)")
            } catch {
                print("❌ Failed to save best streak update: \(error)")
            }
        }
    }
    
    /// Check if current streak is a new personal best
    func isCurrentStreakPersonalBest() -> Bool {
        let currentStreak = calculateStreak(upTo: Date())
        return currentStreak > Int(bestStreakEver)
    }
    
    /// Force recalculate and update best streak
    func recalculateBestStreak() {
        let longestStreak = calculateLongestStreak()
        bestStreakEver = Int32(longestStreak)
        
        do {
            try managedObjectContext?.save()
            print("🔄 Recalculated best streak for '\(name ?? "Unknown")': \(longestStreak)")
        } catch {
            print("❌ Failed to save recalculated best streak: \(error)")
        }
    }
}

extension Habit {
    
    /// Calculate total completed habit completions (used for migration)
    func calculateTotalCompletions() -> Int {
        guard let completions = self.completion as? Set<Completion> else {
            return 0
        }
        
        return completions.filter { $0.completed }.count
    }
    
    /// Fast access to total completions (uses cached value)
    func getTotalCompletionCount() -> Int {
        return Int(self.totalCompletions)
    }
    
    /// Update total completions when toggling (call this in toggle operations)
    func updateTotalCompletions(context: NSManagedObjectContext, increment: Bool) {
        if increment {
            self.totalCompletions += 1
        } else {
            self.totalCompletions = max(0, self.totalCompletions - 1)
        }
        
        // Save immediately to keep cache consistent
        do {
            try context.save()
        } catch {
            print("Error updating total completions: \(error)")
        }
    }
    
    /// Recalculate and sync total completions (use sparingly - for data integrity checks)
    func syncTotalCompletions(context: NSManagedObjectContext) {
        let actualTotal = calculateTotalCompletions()
        if Int32(actualTotal) != self.totalCompletions {
            print("⚠️ Total completions out of sync for \(self.name ?? "Unknown"). Expected: \(actualTotal), Found: \(self.totalCompletions)")
            self.totalCompletions = Int32(actualTotal)
            
            do {
                try context.save()
            } catch {
                print("Error syncing total completions: \(error)")
            }
        }
    }
}
extension Completion {
    
    /// Update completion with analytics data
    func updateWithAnalytics(_ data: AnalyticsData) {
        if let difficulty = data.perceivedDifficulty {
            self.perceivedDifficulty = Int32(difficulty)
        }
        
        if let efficacy = data.selfEfficacy {
            self.selfEfficacy = Int32(efficacy)
        }
        
        if let mood = data.moodImpact {
            self.moodImpact = mood
        }
        
 
        if let duration = data.duration {
            self.duration = duration
        }
        
        if let notes = data.notes {
            self.notes = notes
        }
    }
}
