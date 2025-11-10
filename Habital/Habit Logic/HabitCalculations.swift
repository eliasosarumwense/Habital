//
//  HabitCalculations.swift
//  Habital
//
//  Created by Elias Osarumwense on 04.04.25.
//

import Foundation
import CoreData

/// A utility class for common habit-related functionality
public struct HabitUtilities {
    
    // Thread-safe cache with concurrent queue
    private static let cacheQueue = DispatchQueue(label: "HabitUtilities.activeCache", attributes: .concurrent)
    private static var activeCache: [String: Bool] = [:]
    private static var cacheHits: Int = 0
    private static var cacheMisses: Int = 0
    
    // MARK: - Private Constants
    private static var calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Europe/Berlin") ?? .current
        // Set ISO week configuration if needed
        cal.firstWeekday = 2 // Monday
        cal.minimumDaysInFirstWeek = 4
        return cal
    }()
    
    // MARK: - Cache Management
    
    public static func clearHabitActivityCache() {
        cacheQueue.async(flags: .barrier) {
            activeCache = [:]
            #if DEBUG
            print("Cache cleared. Hits: \(cacheHits), Misses: \(cacheMisses)")
            #endif
            cacheHits = 0
            cacheMisses = 0
        }
    }

    public static func clearCacheKey(_ key: String) {
        cacheQueue.async(flags: .barrier) {
            activeCache.removeValue(forKey: key)
        }
    }
    
    // Improved cache key generation using objectID and day integer
    private static func cacheKeyForHabit(_ habit: Habit, date: Date) -> String {
        let cal = Self.calendar
        let dayInt = Int(cal.startOfDay(for: date).timeIntervalSince1970 / 86_400)
        let id = habit.objectID.uriRepresentation().absoluteString
        return "\(id)#\(dayInt)"
    }
    
    // MARK: - Private Helper Methods
    
    /// Build a set of completed dayKeys for a habit (thread-safe version)
    private static func getCompletedDayKeys(for habit: Habit) -> Set<String> {
        // Note: Caller must ensure this is called on the correct Core Data queue
        guard let completions = habit.completion as? Set<Completion> else { return [] }
        return Set(completions.compactMap { $0.completed ? $0.dayKey : nil })
    }
    /*
    /// Check if a habit is completed on a specific date using dayKey
    private static func isHabitCompleted(habit: Habit, on date: Date, completedDayKeys: Set<String>) -> Bool {
        let dayKey = DayKeyFormatter.localKey(from: date)
        return completedDayKeys.contains(dayKey)
    }
    */
    static func getTrackingType(for habit: Habit) -> HabitTrackingType {
            guard let pattern = habit.repeatPattern?.allObjects.first as? RepeatPattern,
                  let trackingTypeString = pattern.trackingType,
                  let trackingType = HabitTrackingType(rawValue: trackingTypeString) else {
                // Default to repetitions for legacy habits
                return .repetitions
            }
            return trackingType
        }
        
        // Check if habit is completed with enhanced logic
        static func isHabitCompleted(for habit: Habit, on date: Date) -> Bool {
            return habit.isCompleted(on: date)
        }
        
        // Get completion progress as a percentage (0.0 to 1.0)
        static func getCompletionProgress(for habit: Habit, on date: Date) -> Double {
            guard let pattern = habit.repeatPattern?.allObjects.first as? RepeatPattern else {
                // Fallback to repetitions logic
                let required = Double(getRepeatsPerDay(for: habit, on: date))
                let completed = Double(getCompletedRepeatsCount(for: habit, on: date))
                return required > 0 ? min(1.0, completed / required) : 0
            }
            
            let trackingType = getTrackingType(for: habit)
            
            switch trackingType {
            case .repetitions:
                let required = Double(getRepeatsPerDay(for: habit, on: date))
                let completed = Double(getCompletedRepeatsCount(for: habit, on: date))
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
        
        // Get repeats per day for a habit on a specific date
        static func getRepeatsPerDay(for habit: Habit, on date: Date) -> Int {
            return habit.currentRepeatsPerDay(on: date)
        }
        
        // Get completed repeats count for a habit on a specific date
        static func getCompletedRepeatsCount(for habit: Habit, on date: Date) -> Int {
            return habit.completedCount(on: date)
        }
        
        // Get duration completed for a specific date
        static func getDurationCompleted(for habit: Habit, on date: Date) -> Int {
            guard let completions = habit.completion as? Set<Completion> else { return 0 }
            
            let key = DayKeyFormatter.localKey(from: date)
            
            // Sum up all duration entries for the day
            return completions.filter { c in
                c.dayKey == key
            }.reduce(0) { $0 + Int($1.duration) }
        }
        
        // Get quantity completed for a specific date
        static func getQuantityCompleted(for habit: Habit, on date: Date) -> Int {
            guard let completions = habit.completion as? Set<Completion> else { return 0 }
            
            let key = DayKeyFormatter.localKey(from: date)
            
            // Sum up all quantity entries for the day
            return completions.filter { c in
                c.dayKey == key
            }.reduce(0) { $0 + Int($1.quantity) }
        }
        
        // Get target duration for a habit
        static func getTargetDuration(for habit: Habit) -> Int {
            guard let pattern = habit.repeatPattern?.allObjects.first as? RepeatPattern else {
                return 30 // Default 30 minutes
            }
            return Int(pattern.duration)
        }
        
        // Get target quantity for a habit
        static func getTargetQuantity(for habit: Habit) -> Int {
            guard let pattern = habit.repeatPattern?.allObjects.first as? RepeatPattern else {
                return 1 // Default 1 unit
            }
            return Int(pattern.targetQuantity)
        }
        
        // Get quantity unit for a habit
        static func getQuantityUnit(for habit: Habit) -> String {
            guard let pattern = habit.repeatPattern?.allObjects.first as? RepeatPattern,
                  let unit = pattern.quantityUnit else {
                return "items" // Default unit
            }
            return unit
        }
        
        // Format completion status text based on tracking type
        static func getCompletionStatusText(for habit: Habit, on date: Date) -> String {
            let trackingType = getTrackingType(for: habit)
            
            switch trackingType {
            case .repetitions:
                let completed = getCompletedRepeatsCount(for: habit, on: date)
                let required = getRepeatsPerDay(for: habit, on: date)
                return "\(completed)/\(required)"
                
            case .duration:
                let completed = getDurationCompleted(for: habit, on: date)
                let target = getTargetDuration(for: habit)
                return formatDuration(completed) + "/" + formatDuration(target)
                
            case .quantity:
                let completed = getQuantityCompleted(for: habit, on: date)
                let target = getTargetQuantity(for: habit)
                let unit = getQuantityUnit(for: habit)
                return "\(completed)/\(target) \(unit)"
            }
        }
        
        // Helper to format duration
        private static func formatDuration(_ minutes: Int) -> String {
            if minutes < 60 {
                return "\(minutes)m"
            } else {
                let hours = minutes / 60
                let mins = minutes % 60
                return mins > 0 ? "\(hours)h\(mins)m" : "\(hours)h"
            }
        }
    // MARK: - Public Methods
    
    /// Get the effective repeat pattern for a habit on a specific date
    public static func getEffectiveRepeatPattern(for habit: Habit, on date: Date) -> RepeatPattern? {
        guard let repeatPatterns = habit.repeatPattern as? Set<RepeatPattern>,
              !repeatPatterns.isEmpty else {
            return nil
        }
        
        let cal = Self.calendar
        let normalizedDate = cal.startOfDay(for: date)
        
        guard let startDate = habit.startDate,
              normalizedDate >= cal.startOfDay(for: startDate) else {
            return nil
        }
        
        let patternsWithDates = repeatPatterns.compactMap { pattern -> (RepeatPattern, Date)? in
            guard let effectiveFrom = pattern.effectiveFrom else { return nil }
            return (pattern, cal.startOfDay(for: effectiveFrom))
        }
        
        let validPatterns = patternsWithDates.filter { (_, effectiveDate) in
            effectiveDate <= normalizedDate
        }
        
        if !validPatterns.isEmpty {
            let sortedPatterns = validPatterns.sorted { (a, b) in
                a.1 > b.1
            }
            return sortedPatterns.first?.0
        }
        
        if normalizedDate >= cal.startOfDay(for: startDate) {
            if !patternsWithDates.isEmpty {
                let oldestPattern = patternsWithDates.min { a, b in
                    a.1 < b.1
                }
                return oldestPattern?.0
            } else {
                return repeatPatterns.first
            }
        }
        
        return nil
    }
    
    /// Determines if a date falls in an active week based on the effective date and week interval
    public static func isActiveWeek(date: Date, effectiveFrom: Date, weekInterval: Int16) -> Bool {
        if weekInterval <= 1 {
            return true
        }
        
        let cal = Self.calendar
        
        var effectiveWeekComponents = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: effectiveFrom)
        effectiveWeekComponents.weekday = 2
        
        guard let effectiveWeek = cal.date(from: effectiveWeekComponents) else {
            return false
        }
        
        var checkWeekComponents = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        checkWeekComponents.weekday = 2
        
        guard let checkWeek = cal.date(from: checkWeekComponents) else {
            return false
        }
        
        let weekComponent = cal.dateComponents([.weekOfYear], from: effectiveWeek, to: checkWeek)
        guard let weeksBetween = weekComponent.weekOfYear else {
            return false
        }
        
        return weeksBetween % Int(weekInterval) == 0
    }
    
    /// Determines if a date falls in an active month based on the effective date and month interval
    public static func isActiveMonth(date: Date, effectiveFrom: Date, monthInterval: Int16) -> Bool {
        if monthInterval <= 1 {
            return true
        }
        
        let cal = Self.calendar
        
        let effectiveComponents = cal.dateComponents([.year, .month], from: effectiveFrom)
        let dateComponents = cal.dateComponents([.year, .month], from: date)
        
        guard let effectiveYear = effectiveComponents.year, let effectiveMonth = effectiveComponents.month,
              let checkYear = dateComponents.year, let checkMonth = dateComponents.month else {
            return false
        }
        
        let monthsBetween = (checkYear - effectiveYear) * 12 + (checkMonth - effectiveMonth)
        
        return monthsBetween % Int(monthInterval) == 0
    }
    
    /// Helper method to check if habit would be active regularly (ignoring followUp)
    static func isHabitRegularlyActive(habit: Habit, on date: Date, repeatPattern: RepeatPattern) -> Bool {
        let cal = Self.calendar
        let normalizedDate = cal.startOfDay(for: date)
        
        guard let startDate = habit.startDate else { return false }
        let effectiveFromDate = repeatPattern.effectiveFrom ?? startDate
        let effectiveDay = cal.startOfDay(for: effectiveFromDate)
        
        if normalizedDate < effectiveDay {
            return false
        }
        
        // Daily Goal
        if let dailyGoal = repeatPattern.dailyGoal {
            if dailyGoal.everyDay {
                return true
            }
            
            if let specificDays = dailyGoal.specificDays as? [Bool], specificDays.count >= 7 {
                let weekCount = specificDays.count / 7
                guard weekCount > 0 else { return false }
                
                guard let daysSinceEffective = cal.dateComponents([.day], from: effectiveDay, to: normalizedDate).day else {
                    return false
                }
                
                let weekInCycle = ((daysSinceEffective / 7) % weekCount + weekCount) % weekCount
                let dayOfWeek = cal.component(.weekday, from: normalizedDate)
                let adjustedIndex = (dayOfWeek + 5) % 7
                let actualIndex = (weekInCycle * 7) + adjustedIndex
                
                return actualIndex < specificDays.count && specificDays[actualIndex]
            }
            
            if dailyGoal.daysInterval > 0 {
                let daysInterval = max(1, Int(dailyGoal.daysInterval))
                
                guard let daysSinceEffective = cal.dateComponents([.day], from: effectiveDay, to: normalizedDate).day else {
                    return false
                }
                
                if !repeatPattern.followUp {
                    return daysSinceEffective >= 0 && daysSinceEffective % daysInterval == 0
                }
            }
        }
        
        // Weekly Goal
        if let weeklyGoal = repeatPattern.weeklyGoal {
            guard let specificDays = weeklyGoal.specificDays as? [Bool], specificDays.count == 7 else {
                return false
            }
            
            let dayOfWeek = cal.component(.weekday, from: normalizedDate)
            let adjustedIndex = (dayOfWeek + 5) % 7
            
            guard adjustedIndex < specificDays.count else {
                return false
            }
            
            if !specificDays[adjustedIndex] {
                return false
            }
            
            if weeklyGoal.everyWeek {
                return true
            }
            
            if weeklyGoal.weekInterval > 0 {
                return isActiveWeek(date: normalizedDate,
                                    effectiveFrom: effectiveFromDate,
                                    weekInterval: weeklyGoal.weekInterval)
            }
        }
        
        // Monthly Goal
        if let monthlyGoal = repeatPattern.monthlyGoal {
            guard let specificDays = monthlyGoal.specificDays as? [Bool], specificDays.count == 31 else {
                return false
            }
            
            let dayOfMonth = cal.component(.day, from: normalizedDate)
            let daysInMonth = cal.range(of: .day, in: .month, for: normalizedDate)?.count ?? 30
            
            let isMonthActive = monthlyGoal.everyMonth ||
                isActiveMonth(date: normalizedDate,
                              effectiveFrom: effectiveFromDate,
                              monthInterval: monthlyGoal.monthInterval)
            
            if !isMonthActive {
                return false
            }
            
            if dayOfMonth <= 31 && specificDays[dayOfMonth - 1] {
                return true
            }
            
            if dayOfMonth == daysInMonth && daysInMonth < 31 {
                for day in daysInMonth..<31 {
                    if specificDays[day] {
                        return true
                    }
                }
            }
        }
        
        return false
    }

    /// Thread-safe version of isHabitActive
    public static func isHabitActive(habit: Habit, on date: Date) -> Bool {
        let cacheKey = cacheKeyForHabit(habit, date: date)
        
        // Thread-safe cache read
        if let cachedResult: Bool = cacheQueue.sync(execute: { activeCache[cacheKey] }) {
            cacheQueue.async(flags: .barrier) { cacheHits &+= 1 }
            return cachedResult
        } else {
            cacheQueue.async(flags: .barrier) { cacheMisses &+= 1 }
        }
        
        let result = calculateIsHabitActive(habit: habit, on: date)
        
        // Thread-safe cache write
        cacheQueue.async(flags: .barrier) {
            activeCache[cacheKey] = result
        }
        
        return result
    }
        
    private static func calculateIsHabitActive(habit: Habit, on date: Date) -> Bool {
        let cal = Self.calendar
        guard let startDate = habit.startDate else { return false }
        let normalizedStartDate = cal.startOfDay(for: startDate)
        let normalizedSelectedDate = cal.startOfDay(for: date)
        
        if normalizedStartDate > normalizedSelectedDate {
            return false
        }
        
        guard let repeatPattern = getEffectiveRepeatPattern(for: habit, on: date) else {
            return false
        }
        
        let isRegularlyActive = isHabitRegularlyActive(habit: habit, on: date, repeatPattern: repeatPattern)
        
        if isRegularlyActive {
            return true
        }
        
        if repeatPattern.followUp {
            return isActiveForFollowUp(habit: habit, on: date, repeatPattern: repeatPattern)
        }
        
        return false
    }
    
    /// Check if followUp makes habit active on the selected date
    static func isActiveForFollowUp(habit: Habit, on date: Date, repeatPattern: RepeatPattern) -> Bool {
        if !repeatPattern.followUp {
            return false
        }
        
        let cal = Self.calendar  // Local calendar reference
        let normalizedDate = cal.startOfDay(for: date)
        let today = cal.startOfDay(for: Date())
        
        let completedDayKeys = getCompletedDayKeys(for: habit)
        
        let dayKey = DayKeyFormatter.localKey(from: normalizedDate)
        if completedDayKeys.contains(dayKey) {
            return true
        }
        
        if normalizedDate > today,
           let dailyGoal = repeatPattern.dailyGoal,
           dailyGoal.daysInterval > 0 {
            
            let todayKey = DayKeyFormatter.localKey(from: today)
            let todayCompleted = completedDayKeys.contains(todayKey)

            if todayCompleted {
                let daysInterval = Int(dailyGoal.daysInterval)
                guard let daysSinceToday = cal.dateComponents([.day], from: today, to: normalizedDate).day else {
                    return false
                }
                return daysSinceToday % daysInterval == 0
            }
            
            let daysInterval = Int(dailyGoal.daysInterval)
            let isOverdueToday = isHabitActive(habit: habit, on: today)
            
            if isOverdueToday {
                guard let daysSinceToday = cal.dateComponents([.day], from: today, to: normalizedDate).day else {
                    return false
                }
                return daysSinceToday % daysInterval == 0
            } else if let completions = habit.completion as? Set<Completion>, !completions.isEmpty {
                let completedEntries = completions.filter { $0.completed }
                if let mostRecentCompletion = completedEntries.max(by: {
                    ($0.date ?? .distantPast) < ($1.date ?? .distantPast)
                }),
                let lastCompletedDate = mostRecentCompletion.date {
                    
                    let normalizedLastCompleted = cal.startOfDay(for: lastCompletedDate)
                    var nextDueDate = cal.date(byAdding: .day, value: daysInterval, to: normalizedLastCompleted) ?? today
                    
                    while nextDueDate < normalizedDate {
                        nextDueDate = cal.date(byAdding: .day, value: daysInterval, to: nextDueDate) ?? nextDueDate
                    }
                    
                    return cal.isDate(nextDueDate, inSameDayAs: normalizedDate)
                }
            }
            
            let referenceDate = cal.startOfDay(for: repeatPattern.effectiveFrom ?? habit.startDate ?? Date())
            guard referenceDate <= normalizedDate else {
                return false
            }
            
            let daysSinceReference = cal.dateComponents([.day], from: referenceDate, to: normalizedDate).day ?? 0
            return daysSinceReference % daysInterval == 0
        }
        
        if normalizedDate > today {
            return false
        }
        
        // CASE 1: Daily Goal
        if let dailyGoal = repeatPattern.dailyGoal {
            if dailyGoal.everyDay {
                return false
            }
            
            if dailyGoal.daysInterval > 0 {
                if let mostRecentCompletion = habit.findMostRecentCompletion(before: normalizedDate),
                   let completionDate = mostRecentCompletion.date {

                    let completionDateNormalized = cal.startOfDay(for: completionDate)
                    let daysInterval = Int(dailyGoal.daysInterval)
                    
                    guard let nextDueDate = cal.date(byAdding: .day, value: daysInterval, to: completionDateNormalized) else {
                        return false
                    }
                    
                    let nextDueDateNormalized = cal.startOfDay(for: nextDueDate)

                    if normalizedDate < nextDueDateNormalized {
                        return false
                    }
                    
                    var currentDate = nextDueDateNormalized
                    while currentDate <= normalizedDate {
                        let currentDayKey = DayKeyFormatter.localKey(from: currentDate)
                        if completedDayKeys.contains(currentDayKey) {
                            return false
                        }
                        guard let nextDay = cal.date(byAdding: .day, value: 1, to: currentDate) else { break }
                        currentDate = nextDay
                    }
                    
                    return true
                }
                else {
                    let startDate = repeatPattern.effectiveFrom ?? habit.startDate ?? Date()
                    let effectiveDay = cal.startOfDay(for: startDate)
                    
                    if effectiveDay > normalizedDate {
                        return false
                    }
                    
                    let daysInterval = Int(dailyGoal.daysInterval)
                    let daysSinceEffective = cal.dateComponents([.day], from: effectiveDay, to: normalizedDate).day ?? 0
                    
                    if repeatPattern.followUp && normalizedDate <= today {
                        if normalizedDate >= effectiveDay {
                            let firstDueDate = effectiveDay
                            if normalizedDate >= firstDueDate {
                                return true
                            }
                        }
                    }
                    
                    return daysSinceEffective % daysInterval == 0
                }
            }
            else if let specificDays = dailyGoal.specificDays as? [Bool], specificDays.count >= 7 {
                let weekCount = specificDays.count / 7
                guard weekCount > 0 else { return false }
                
                if let mostRecentCompletion = habit.findMostRecentCompletion(before: date),
                   let completionDate = mostRecentCompletion.date {
                    
                    let completionDateNormalized = cal.startOfDay(for: completionDate)
                    var currentDate = cal.date(byAdding: .day, value: 1, to: completionDateNormalized) ?? normalizedDate
                    currentDate = cal.startOfDay(for: currentDate)
                    
                    while currentDate < normalizedDate {
                        let effectiveFromDate = repeatPattern.effectiveFrom ?? habit.startDate ?? Date()
                        let effectiveFromDay = cal.startOfDay(for: effectiveFromDate)
                        let daysSinceEffective = cal.dateComponents([.day], from: effectiveFromDay, to: currentDate).day ?? 0
                        
                        let weekInCycle = ((daysSinceEffective / 7) % weekCount + weekCount) % weekCount
                        let dayOfWeek = cal.component(.weekday, from: currentDate)
                        let adjustedIndex = (dayOfWeek + 5) % 7
                        let actualIndex = (weekInCycle * 7) + adjustedIndex
                        
                        if actualIndex >= 0 && actualIndex < specificDays.count && specificDays[actualIndex] {
                            let currentDayKey = DayKeyFormatter.localKey(from: currentDate)
                            if !completedDayKeys.contains(currentDayKey) {
                                return true
                            }
                        }
                        
                        guard let nextDay = cal.date(byAdding: .day, value: 1, to: currentDate) else { break }
                        currentDate = cal.startOfDay(for: nextDay)
                    }
                    
                    return false
                }
                else if let startDate = habit.startDate {
                    let startDateNormalized = cal.startOfDay(for: startDate)
                    
                    if startDateNormalized > normalizedDate {
                        return false
                    }
                    
                    var currentDate = startDateNormalized
                    
                    while currentDate < normalizedDate {
                        let effectiveFromDate = repeatPattern.effectiveFrom ?? habit.startDate ?? Date()
                        let effectiveFromDay = cal.startOfDay(for: effectiveFromDate)
                        let daysSinceEffective = cal.dateComponents([.day], from: effectiveFromDay, to: currentDate).day ?? 0
                        
                        let weekInCycle = ((daysSinceEffective / 7) % weekCount + weekCount) % weekCount
                        let dayOfWeek = cal.component(.weekday, from: currentDate)
                        let adjustedIndex = (dayOfWeek + 5) % 7
                        let actualIndex = (weekInCycle * 7) + adjustedIndex
                        
                        if actualIndex >= 0 && actualIndex < specificDays.count && specificDays[actualIndex] {
                            if currentDate < startDateNormalized {
                                continue
                            }
                            
                            let currentDayKey = DayKeyFormatter.localKey(from: currentDate)
                            if !completedDayKeys.contains(currentDayKey) {
                                return true
                            }
                        }
                        
                        guard let nextDay = cal.date(byAdding: .day, value: 1, to: currentDate) else { break }
                        currentDate = cal.startOfDay(for: nextDay)
                    }
                    
                    return false
                }
            }
        }
        
        // CASE 2: Weekly Goal
        if let weeklyGoal = repeatPattern.weeklyGoal, let specificDays = weeklyGoal.specificDays as? [Bool], specificDays.count == 7 {
            let effectiveFromDate = repeatPattern.effectiveFrom ?? habit.startDate ?? Date()
            let effectiveFromDay = cal.startOfDay(for: effectiveFromDate)
            
            if let mostRecentCompletion = habit.findMostRecentCompletion(before: date),
               let completionDate = mostRecentCompletion.date {
                
                let completionDateNormalized = cal.startOfDay(for: completionDate)
                var currentDate = cal.date(byAdding: .day, value: 1, to: completionDateNormalized) ?? normalizedDate
                currentDate = cal.startOfDay(for: currentDate)
                
                while currentDate < normalizedDate {
                    let isActiveWeek = weeklyGoal.everyWeek ||
                        isActiveWeek(date: currentDate,
                                    effectiveFrom: effectiveFromDay,
                                    weekInterval: weeklyGoal.weekInterval)
                    
                    if isActiveWeek {
                        let dayOfWeek = cal.component(.weekday, from: currentDate)
                        let adjustedIndex = (dayOfWeek + 5) % 7
                        
                        if adjustedIndex >= 0 && adjustedIndex < specificDays.count && specificDays[adjustedIndex] {
                            let currentDayKey = DayKeyFormatter.localKey(from: currentDate)
                            if !completedDayKeys.contains(currentDayKey) {
                                return true
                            }
                        }
                    }
                    
                    guard let nextDay = cal.date(byAdding: .day, value: 1, to: currentDate) else { break }
                    currentDate = cal.startOfDay(for: nextDay)
                }
                
                return false
            }
            else if let startDate = habit.startDate {
                let effectiveFromDay = cal.startOfDay(for: repeatPattern.effectiveFrom ?? startDate)
                let startDateNormalized = cal.startOfDay(for: startDate)
                
                if effectiveFromDay > normalizedDate {
                    return false
                }
                
                var currentDate = max(effectiveFromDay, startDateNormalized)
                
                while currentDate <= normalizedDate {
                    let isActiveWeek = weeklyGoal.everyWeek ||
                        isActiveWeek(date: currentDate,
                                    effectiveFrom: effectiveFromDay,
                                    weekInterval: weeklyGoal.weekInterval)
                    
                    if isActiveWeek {
                        let dayOfWeek = cal.component(.weekday, from: currentDate)
                        let adjustedIndex = (dayOfWeek + 5) % 7
                        
                        if adjustedIndex < specificDays.count && specificDays[adjustedIndex] {
                            let currentDayKey = DayKeyFormatter.localKey(from: currentDate)
                            if !completedDayKeys.contains(currentDayKey) {
                                return true
                            }
                        }
                    }
                    
                    guard let nextDay = cal.date(byAdding: .day, value: 1, to: currentDate) else {
                        break
                    }
                    currentDate = cal.startOfDay(for: nextDay)
                }
                
                return false
            }
        }
        
        // CASE 3: Monthly Goal
        else if let monthlyGoal = repeatPattern.monthlyGoal, let specificDays = monthlyGoal.specificDays as? [Bool], specificDays.count == 31 {
            let effectiveFromDate = repeatPattern.effectiveFrom ?? habit.startDate ?? Date()
            let effectiveFromDay = cal.startOfDay(for: effectiveFromDate)
            
            if let mostRecentCompletion = habit.findMostRecentCompletion(before: date),
               let completionDate = mostRecentCompletion.date {
                
                let completionDateNormalized = cal.startOfDay(for: completionDate)
                var currentDate = cal.date(byAdding: .day, value: 1, to: completionDateNormalized) ?? normalizedDate
                currentDate = cal.startOfDay(for: currentDate)
                
                while currentDate < normalizedDate {
                    let isActiveMonth = monthlyGoal.everyMonth ||
                                       isActiveMonth(date: currentDate,
                                                  effectiveFrom: effectiveFromDay,
                                                  monthInterval: monthlyGoal.monthInterval)
                    
                    if isActiveMonth {
                        let dayOfMonth = cal.component(.day, from: currentDate)
                        
                        if dayOfMonth <= specificDays.count && specificDays[dayOfMonth - 1] {
                            let currentDayKey = DayKeyFormatter.localKey(from: currentDate)
                            if !completedDayKeys.contains(currentDayKey) {
                                return true
                            }
                        }
                        
                        let range = cal.range(of: .day, in: .month, for: currentDate)
                        let lastDay = range?.count ?? 31
                        
                        if dayOfMonth == lastDay && lastDay < 31 {
                            var hasLaterDaySelected = false
                            for day in lastDay..<31 {
                                if specificDays[day] {
                                    hasLaterDaySelected = true
                                    break
                                }
                            }
                            
                            if hasLaterDaySelected {
                                let currentDayKey = DayKeyFormatter.localKey(from: currentDate)
                                if !completedDayKeys.contains(currentDayKey) {
                                    return true
                                }
                            }
                        }
                    }
                    
                    guard let nextDay = cal.date(byAdding: .day, value: 1, to: currentDate) else { break }
                    currentDate = cal.startOfDay(for: nextDay)
                }
                
                return false
            }
            else if let startDate = habit.startDate {
                let startDateNormalized = cal.startOfDay(for: startDate)
                
                if startDateNormalized > normalizedDate {
                    return false
                }
                
                var currentDate = startDateNormalized
                
                while currentDate < normalizedDate {
                    let isActiveMonth = monthlyGoal.everyMonth ||
                                       isActiveMonth(date: currentDate,
                                                  effectiveFrom: effectiveFromDay,
                                                  monthInterval: monthlyGoal.monthInterval)
                    
                    if isActiveMonth {
                        let dayOfMonth = cal.component(.day, from: currentDate)
                        
                        if dayOfMonth <= specificDays.count && specificDays[dayOfMonth - 1] {
                            if currentDate < startDateNormalized {
                                continue
                            }
                            
                            let currentDayKey = DayKeyFormatter.localKey(from: currentDate)
                            if !completedDayKeys.contains(currentDayKey) {
                                return true
                            }
                        }
                        
                        let range = cal.range(of: .day, in: .month, for: currentDate)
                        let lastDay = range?.count ?? 31
                        
                        if dayOfMonth == lastDay && lastDay < 31 {
                            var hasLaterDaySelected = false
                            for day in lastDay..<31 {
                                if specificDays[day] {
                                    hasLaterDaySelected = true
                                    break
                                }
                            }
                            
                            if hasLaterDaySelected {
                                if currentDate < startDateNormalized {
                                    continue
                                }
                                
                                let currentDayKey = DayKeyFormatter.localKey(from: currentDate)
                                if !completedDayKeys.contains(currentDayKey) {
                                    return true
                                }
                            }
                        }
                    }
                    
                    guard let nextDay = cal.date(byAdding: .day, value: 1, to: currentDate) else { break }
                    currentDate = cal.startOfDay(for: nextDay)
                }
                
                return false
            }
        }
        
        return false
    }
    
    /// For backward compatibility
    public static func isHabitActive(on date: Date, startDate: Date, repeatPattern: Habit) -> Bool {
        return isHabitActive(habit: repeatPattern, on: date)
    }
    
    /// Calculate the percentage of completed habits for a specific date
    public static func calculateHabitCompletionPercentage(for date: Date, habits: [Habit]) -> Double {
        let cal = Self.calendar
        let startOfDay = cal.startOfDay(for: date)
        
        let activeHabits = habits.filter { habit in
            return isHabitActive(habit: habit, on: date)
        }
        
        if activeHabits.isEmpty {
            return 0.0
        }

        let dayKey = DayKeyFormatter.localKey(from: date)
        let completedHabits = activeHabits.filter { habit in
            let completedDayKeys = getCompletedDayKeys(for: habit)
            return completedDayKeys.contains(dayKey)
        }
        
        return Double(completedHabits.count) / Double(activeHabits.count)
    }
    
    
    public static func getNextOccurrenceText(for habit: Habit, selectedDate: Date) -> String {
        // 1) Use the same calendar & time zone everywhere
        let cal = Self.calendar
        let referenceDate = cal.startOfDay(for: selectedDate)
        let today = cal.startOfDay(for: Date())
        
        // Get the effective repeat pattern for the date
        guard let startDate = habit.startDate,
              let repeatPattern = getEffectiveRepeatPattern(for: habit, on: selectedDate) else {
            return "Not scheduled"
        }
        
        // 3) Early exits and guards
        guard !habit.isArchived else { return "Not scheduled" }
        
        let startSOD = cal.startOfDay(for: startDate)
        if referenceDate < startSOD {
            return formatDate(startDate, referenceDate: referenceDate)
        }
        
        let effectiveDay = cal.startOfDay(for: repeatPattern.effectiveFrom ?? startDate)
        
        // 2) One formatter, reused (avoid allocating 3 DF objects per call)
        func formatDate(_ date: Date, referenceDate: Date) -> String {
            let df = DateFormatter()
            df.locale = Locale.autoupdatingCurrent
            
            let diff = cal.dateComponents([.day], from: referenceDate, to: date).day ?? 0
            switch diff {
            case  0:  return "Today"
            case  1:  return "Tomorrow"
            case -1:  return "Yesterday"
            case  2...7:
                df.dateFormat = "EEEE"; return df.string(from: date)
            case (-7)...(-2):
                df.dateFormat = "EEEE"; return "Last " + df.string(from: date)
            default:
                df.dateFormat = "dd. MMMM"; return df.string(from: date)
            }
        }
        
        // Daily Goal
        if let dailyGoal = repeatPattern.dailyGoal {
            // Every day pattern
            if dailyGoal.everyDay {
                if startDate > referenceDate {
                    return formatDate(startDate, referenceDate: referenceDate)
                } else {
                    if cal.startOfDay(for: referenceDate) >= cal.startOfDay(for: startDate) {
                        return "Today"
                    } else {
                        if let tomorrow = cal.date(byAdding: .day, value: 1, to: referenceDate) {
                            return formatDate(tomorrow, referenceDate: referenceDate)
                        }
                    }
                }
            }
            
            // 5) Daily "specificDays" (multi-week): compute the next active day directly
            if let specific = dailyGoal.specificDays as? [Bool], specific.count >= 7 {
                let weeks = specific.count / 7
                for offset in 0..<(weeks * 7) {
                    guard let d = cal.date(byAdding: .day, value: offset, to: referenceDate) else { break }
                    if d < startSOD { continue }
                    if isHabitRegularlyActive(habit: habit, on: d, repeatPattern: repeatPattern) {
                        return formatDate(d, referenceDate: referenceDate)
                    }
                }
            }
            
            // 4) Daily: jump with math, not loops
            if dailyGoal.daysInterval > 0 {
                if repeatPattern.followUp {
                    if let mostRecentCompletion = habit.findMostRecentCompletion(before: selectedDate),
                       let completionDate = mostRecentCompletion.date {
                        
                        let completionDateNormalized = cal.startOfDay(for: completionDate)
                        let daysInterval = Int(dailyGoal.daysInterval)
                        
                        let k = max(0, cal.dateComponents([.day], from: completionDateNormalized, to: referenceDate).day ?? 0)
                        let steps = (k + daysInterval - 1) / daysInterval        // ceil
                        guard let nextDue = cal.date(byAdding: .day, value: steps * daysInterval, to: completionDateNormalized) else {
                            return "Not scheduled"
                        }
                        if cal.isDate(nextDue, inSameDayAs: referenceDate) { return "Today" }
                        return formatDate(nextDue, referenceDate: referenceDate)
                    } else {
                        // No previous completion, use regular interval from effectiveFrom date
                        let daysSinceEffective = cal.dateComponents([.day], from: effectiveDay, to: referenceDate).day ?? 0
                        let daysInterval = Int(dailyGoal.daysInterval)
                        
                        if daysSinceEffective % daysInterval == 0 {
                            return "Today"
                        }
                        
                        let daysRemaining = daysInterval - (daysSinceEffective % daysInterval)
                        if let nextDate = cal.date(byAdding: .day, value: daysRemaining, to: referenceDate) {
                            return formatDate(nextDate, referenceDate: referenceDate)
                        }
                    }
                } else {
                    // Regular interval logic (not followUp) - already uses modulo—good
                    if effectiveDay > referenceDate {
                        return formatDate(effectiveDay, referenceDate: referenceDate)
                    }
                    
                    let daysSinceEffective = cal.dateComponents([.day], from: effectiveDay, to: referenceDate).day ?? 0
                    let daysInterval = Int(dailyGoal.daysInterval)
                    
                    if daysSinceEffective % daysInterval == 0 {
                        return "Today"
                    }
                    
                    let daysRemaining = daysInterval - (daysSinceEffective % daysInterval)
                    if let nextDate = cal.date(byAdding: .day, value: daysRemaining, to: referenceDate) {
                        return formatDate(nextDate, referenceDate: referenceDate)
                    }
                }
            }
        }
        
        // 6) Weekly: fix "every X weeks" correctness and avoid scanning
        if let weekly = repeatPattern.weeklyGoal, let days = weekly.specificDays as? [Bool], days.count == 7 {
            // Is this week active?
            let isWeekActive = weekly.everyWeek || Self.isActiveWeek(date: referenceDate,
                                                                     effectiveFrom: effectiveDay,
                                                                     weekInterval: weekly.weekInterval)

            // If active week: find the next selected weekday in this week
            if isWeekActive {
                for add in 0..<7 {
                    guard let d = cal.date(byAdding: .day, value: add, to: referenceDate) else { break }
                    if d < startSOD { continue }
                    let idx = (cal.component(.weekday, from: d) + 5) % 7      // Mon=0
                    if days[idx] { return formatDate(d, referenceDate: referenceDate) }
                    // stop when week changes
                    if cal.component(.weekOfYear, from: d) != cal.component(.weekOfYear, from: referenceDate) { break }
                }
            }

            // Not in an active week → jump to next active week start using modulo math
            if weekly.weekInterval > 1 && !weekly.everyWeek {
                var a = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: effectiveDay); a.weekday = 2
                var b = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: referenceDate); b.weekday = 2
                guard let eff = cal.date(from: a), let ref = cal.date(from: b) else { return "Not scheduled" }
                if ref < eff { return formatDate(eff, referenceDate: referenceDate) } // before baseline

                let weeksBetween = cal.dateComponents([.weekOfYear], from: eff, to: ref).weekOfYear ?? 0
                let interval = Int(weekly.weekInterval)
                let deltaWeeks = (interval - (weeksBetween % interval)) % interval
                guard let nextActiveWeekStart = cal.date(byAdding: .weekOfYear, value: deltaWeeks, to: ref) else {
                    return "Not scheduled"
                }

                // First selected day in that active week
                for dayOffset in 0..<7 {
                    guard let d = cal.date(byAdding: .day, value: dayOffset, to: nextActiveWeekStart) else { continue }
                    if d < startSOD { continue }
                    let idx = (cal.component(.weekday, from: d) + 5) % 7
                    if days[idx] { return formatDate(d, referenceDate: referenceDate) }
                }
            } else {
                // every week
                for add in 1...14 {                                   // bounded 2 weeks
                    guard let d = cal.date(byAdding: .day, value: add, to: referenceDate) else { break }
                    if d < startSOD { continue }
                    let idx = (cal.component(.weekday, from: d) + 5) % 7
                    if days[idx] { return formatDate(d, referenceDate: referenceDate) }
                }
            }
        }
        
        // 7) Monthly: jump month-wise with modulo, avoid the 24-month loop
        if let monthly = repeatPattern.monthlyGoal, let days = monthly.specificDays as? [Bool], days.count == 31 {

            func firstDayInMonth(from base: Date) -> Date? {
                var comp = cal.dateComponents([.year, .month], from: base)
                comp.day = 1
                return cal.date(from: comp)
            }

            // Is current month active?
            let thisMonthActive = monthly.everyMonth || Self.isActiveMonth(date: referenceDate,
                                                                           effectiveFrom: effectiveDay,
                                                                           monthInterval: monthly.monthInterval)

            // Try remaining days of this month
            if thisMonthActive {
                let dom  = cal.component(.day, from: referenceDate)
                let daysInMonth = cal.range(of: .day, in: .month, for: referenceDate)?.count ?? 30

                // next selected future day this month
                for day in (dom+1)...daysInMonth {
                    if day <= days.count, days[day-1] {
                        var c = cal.dateComponents([.year, .month], from: referenceDate); c.day = day
                        let d = cal.date(from: c)!
                        if d >= startSOD { return formatDate(d, referenceDate: referenceDate) }
                    }
                }
                // last-day fallback if any selected day > daysInMonth
                if (daysInMonth..<31).contains(where: { days[$0] }) {
                    var c = cal.dateComponents([.year, .month], from: referenceDate); c.day = daysInMonth
                    let d = cal.date(from: c)!
                    if d > referenceDate, d >= startSOD { return formatDate(d, referenceDate: referenceDate) }
                }
            }

            // Jump to next active month with modulo (no loop of 24)
            let a = cal.dateComponents([.year, .month], from: effectiveDay)
            let b = cal.dateComponents([.year, .month], from: referenceDate)
            guard let ey = a.year, let em = a.month, let cy = b.year, let cm = b.month else { return "Not scheduled" }
            let diff = (cy - ey) * 12 + (cm - em)
            let interval = max(1, Int(monthly.monthInterval))

            let monthsToNextActive: Int = {
                if diff < 0 { return 0 }                                        // before baseline → go to baseline month
                let r = diff % interval
                return r == 0 ? interval : (interval - r)
            }()

            // month start
            guard let nextActiveMonthDate = cal.date(byAdding: .month, value: monthsToNextActive, to: referenceDate),
                  let nextActiveMonthStart = firstDayInMonth(from: nextActiveMonthDate) else {
                return "Not scheduled"
            }
            let daysInNext = cal.range(of: .day, in: .month, for: nextActiveMonthStart)?.count ?? 30

            // pick first existing selected day, else last-day fallback
            for day in 1...min(daysInNext, 31) {
                if days[day-1] {
                    var c = cal.dateComponents([.year, .month], from: nextActiveMonthStart); c.day = day
                    guard let d = cal.date(from: c) else { continue }
                    if d >= startSOD { return formatDate(d, referenceDate: referenceDate) }
                }
            }
            if (daysInNext..<31).contains(where: { days[$0] }) {
                var c = cal.dateComponents([.year, .month], from: nextActiveMonthStart); c.day = daysInNext
                guard let d = cal.date(from: c) else { return "Not scheduled" }
                if d >= startSOD { return formatDate(d, referenceDate: referenceDate) }
            }
        }
        
        // 8) Consistent fallthrough
        return "Not scheduled"
    }
    }
extension HabitUtilities {
    
    /// Calculates an intelligent completion score based on recent activity in the last 30 days
    /// Higher scores indicate more recent and consistent completion patterns
    static func calculateRecentCompletionScore(for habit: Habit, referenceDate: Date = Date()) -> Double {
        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: referenceDate) ?? referenceDate
        
        guard let completions = habit.completion as? Set<Completion> else {
            return 0.0
        }
        
        // Filter completions to last 30 days
        let recentCompletions = completions.filter { completion in
            guard let completionDate = completion.date, completion.completed else { return false }
            return completionDate >= thirtyDaysAgo && completionDate <= referenceDate
        }.sorted { ($0.date ?? Date.distantPast) > ($1.date ?? Date.distantPast) }
        
        if recentCompletions.isEmpty {
            return 0.0
        }
        
        var score: Double = 0.0
        let totalPossibleDays = 30.0
        
        // Component 1: Recency Bonus (40% of score)
        // Most recent completion gets higher weight
        if let mostRecentCompletion = recentCompletions.first,
           let mostRecentDate = mostRecentCompletion.date {
            let daysSinceLastCompletion = calendar.dateComponents([.day],
                                                                from: mostRecentDate,
                                                                to: referenceDate).day ?? 30
            let recencyScore = max(0, (30.0 - Double(daysSinceLastCompletion)) / 30.0)
            score += recencyScore * 0.4
        }
        
        // Component 2: Completion Frequency (35% of score)
        let completionCount = Double(recentCompletions.count)
        let frequencyScore = min(1.0, completionCount / totalPossibleDays)
        score += frequencyScore * 0.35
        
        // Component 3: Consistency Pattern (25% of score)
        // Reward habits completed more consistently throughout the period
        let consistencyScore = calculateConsistencyScore(completions: recentCompletions,
                                                       thirtyDaysAgo: thirtyDaysAgo,
                                                       referenceDate: referenceDate)
        score += consistencyScore * 0.25
        
        return score
    }
    
    /// Calculates how consistently a habit was completed across the 30-day period
    private static func calculateConsistencyScore(completions: [Completion],
                                                thirtyDaysAgo: Date,
                                                referenceDate: Date) -> Double {
        let calendar = Calendar.current
        
        // Divide 30 days into 6 periods of 5 days each
        let periodsWithCompletions = (0..<6).map { periodIndex in
            let periodStart = calendar.date(byAdding: .day, value: periodIndex * 5, to: thirtyDaysAgo) ?? thirtyDaysAgo
            let periodEnd = calendar.date(byAdding: .day, value: (periodIndex + 1) * 5 - 1, to: thirtyDaysAgo) ?? referenceDate
            
            return completions.contains { completion in
                guard let completionDate = completion.date else { return false }
                return completionDate >= periodStart && completionDate <= periodEnd
            }
        }
        
        let periodsWithActivity = periodsWithCompletions.filter { $0 }.count
        return Double(periodsWithActivity) / 6.0
    }
}
