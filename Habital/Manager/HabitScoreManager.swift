//
//  HabitScoreManager.swift
//  Habital
//
//  Created by Elias Osarumwense on 12.08.25.
//  Optimized with research-backed scoring algorithm
//

import Foundation
import CoreData

/// Manages habit score calculations based on 30-day completion rates and streak bonuses
/// Uses research-backed approach: 66-day average formation time, rolling 30-day window assessment
class HabitScoreManager {
    
    // MARK: - Public Interface
    
    /// Calculate habit score (0-100) based on last 30 days of performance
    /// Algorithm: 80% base score (completion ratio) + 20% streak bonus
    /// - Parameters:
    ///   - habit: The habit to calculate score for
    ///   - today: Current date (defaults to Date())
    /// - Returns: Score from 0-100
    static func calculateHabitScore(for habit: Habit, today: Date = Date()) -> Int {
        
        // 1. Define the 30-day rolling window
        let windowInfo = calculateWindow(startDate: habit.startDate, today: today)
        
        // Get effective repeat pattern for the window
        guard let repeatPattern = getEffectiveRepeatPattern(for: habit, in: windowInfo) else {
            return 0
        }
        
        // 2. Calculate expected count in window using HabitUtilities.isHabitActive
        let expectedCount = calculateExpectedCount(
            habit: habit,
            windowStart: windowInfo.windowStart,
            windowEnd: windowInfo.windowEnd
        )
        
        // Early exit: no expectations means no measurable progress
        guard expectedCount > 0 else {
            return 0
        }
        
        // 3. Calculate actual completed count (only on scheduled days)
        let actualCount = calculateActualCount(
            habit: habit,
            windowStart: windowInfo.windowStart,
            windowEnd: windowInfo.windowEnd
        )
        
        // 4. Base score: completion consistency (max 80 points)
        let baseScore = calculateBaseScore(actualCount: actualCount, expectedCount: expectedCount)
        
        // 5. Streak bonus: recent momentum (max 20 points) - using habit.calculateStreak
        let streakBonus = calculateStreakBonus(
            habit: habit,
            expectedCount: expectedCount,
            today: today
        )
        
        // 6. Final score (0-100, rounded)
        let finalScore = min(100, max(0, Int(round(baseScore + streakBonus))))
        
        return finalScore
    }
    
    /// Get detailed breakdown of habit score calculation for analytics/debugging
    static func getScoreBreakdown(for habit: Habit, today: Date = Date()) -> HabitScoreBreakdown {
        let windowInfo = calculateWindow(startDate: habit.startDate, today: today)
        
        guard let repeatPattern = getEffectiveRepeatPattern(for: habit, in: windowInfo) else {
            return HabitScoreBreakdown(
                totalScore: 0,
                baseScore: 0,
                streakBonus: 0,
                expectedCount: 0,
                actualCount: 0,
                completionRatio: 0,
                currentStreakDays: 0,
                windowDays: windowInfo.windowDays,
                streakRatio: 0
            )
        }
        
        let expectedCount = calculateExpectedCount(
            habit: habit,
            windowStart: windowInfo.windowStart,
            windowEnd: windowInfo.windowEnd
        )
        
        let actualCount = calculateActualCount(
            habit: habit,
            windowStart: windowInfo.windowStart,
            windowEnd: windowInfo.windowEnd
        )
        
        let baseScore = calculateBaseScore(actualCount: actualCount, expectedCount: expectedCount)
        let streakInfo = calculateStreakInfo(habit: habit, expectedCount: expectedCount, today: today)
        
        let completionRatio = expectedCount > 0 ? Double(actualCount) / Double(expectedCount) : 0
        let totalScore = min(100, max(0, Int(round(baseScore + streakInfo.bonus))))
        
        return HabitScoreBreakdown(
            totalScore: totalScore,
            baseScore: Int(round(baseScore)),
            streakBonus: Int(round(streakInfo.bonus)),
            expectedCount: expectedCount,
            actualCount: actualCount,
            completionRatio: completionRatio,
            currentStreakDays: streakInfo.days,
            windowDays: windowInfo.windowDays,
            streakRatio: streakInfo.ratio
        )
    }
}

// MARK: - Private Calculation Methods

private extension HabitScoreManager {
    
    // MARK: - Window Calculation
    
    struct WindowInfo {
        let windowStart: Date
        let windowEnd: Date
        let windowDays: Int
    }
    
    /// Calculate 30-day rolling window, respecting habit start date
    static func calculateWindow(startDate: Date?, today: Date) -> WindowInfo {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: today)
        
        // 30-day rolling window (research shows 66-day average, but 30-day provides practical snapshot)
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: todayStart) ?? todayStart
        
        // Don't evaluate before habit started
        let windowStart: Date
        if let startDate = startDate {
            let habitStartDay = calendar.startOfDay(for: startDate)
            windowStart = max(habitStartDay, thirtyDaysAgo)
        } else {
            windowStart = thirtyDaysAgo
        }
        
        let windowEnd = todayStart
        let windowDays = calendar.dateComponents([.day], from: windowStart, to: windowEnd).day ?? 0
        
        return WindowInfo(
            windowStart: windowStart,
            windowEnd: windowEnd,
            windowDays: windowDays
        )
    }
    
    // MARK: - Repeat Pattern Selection
    
    /// Get the most recent effective repeat pattern for the evaluation window
    static func getEffectiveRepeatPattern(for habit: Habit, in windowInfo: WindowInfo) -> RepeatPattern? {
        guard let repeatPatterns = habit.repeatPattern as? Set<RepeatPattern> else {
            return nil
        }
        
        // Filter patterns that are effective during our window
        let effectivePatterns = repeatPatterns.filter { pattern in
            guard let effectiveFrom = pattern.effectiveFrom else { return false }
            let effectiveStart = Calendar.current.startOfDay(for: effectiveFrom)
            return effectiveStart <= windowInfo.windowEnd
        }
        
        // Get most recent pattern that applies to our window
        return effectivePatterns.max { pattern1, pattern2 in
            let date1 = pattern1.effectiveFrom ?? Date.distantPast
            let date2 = pattern2.effectiveFrom ?? Date.distantPast
            return date1 < date2
        }
    }
    
    // MARK: - Expected Count Calculation using HabitUtilities.isHabitActive
    
    /// Calculate total expected completions in the window using HabitUtilities.isHabitActive
    static func calculateExpectedCount(habit: Habit, windowStart: Date, windowEnd: Date) -> Int {
        let calendar = Calendar.current
        var expectedCount = 0
        var currentDate = windowStart
        
        // Get repeat pattern for repeatsPerDay calculation
        guard let repeatPattern = getEffectiveRepeatPattern(for: habit, in: WindowInfo(windowStart: windowStart, windowEnd: windowEnd, windowDays: 0)) else {
            return 0
        }
        
        let repeatsPerDay = max(1, Int(repeatPattern.repeatsPerDay))
        
        // Count expected days using HabitUtilities.isHabitActive
        while currentDate <= windowEnd {
            if HabitUtilities.isHabitActive(habit: habit, on: currentDate) {
                expectedCount += repeatsPerDay
            }
            
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDate
        }
        
        return expectedCount
    }
    
    // MARK: - Actual Count Calculation using HabitUtilities.isHabitActive
    
    /// Calculate actual completions, only counting those on scheduled days
    static func calculateActualCount(habit: Habit, windowStart: Date, windowEnd: Date) -> Int {
        guard let completions = habit.completion as? Set<Completion> else {
            return 0
        }
        
        let calendar = Calendar.current
        
        // Get repeat pattern for repeatsPerDay calculation
        guard let repeatPattern = getEffectiveRepeatPattern(for: habit, in: WindowInfo(windowStart: windowStart, windowEnd: windowEnd, windowDays: 0)) else {
            return 0
        }
        
        // Filter to completed items in window
        let relevantCompletions = completions.filter { completion in
            guard let completionDate = completion.date, completion.completed else {
                return false
            }
            
            let completionDay = calendar.startOfDay(for: completionDate)
            return completionDay >= windowStart && completionDay <= windowEnd
        }
        
        // Group by date and cap at repeatsPerDay
        var completionsByDate: [Date: Int] = [:]
        for completion in relevantCompletions {
            guard let completionDate = completion.date else { continue }
            let day = calendar.startOfDay(for: completionDate)
            completionsByDate[day, default: 0] += 1
        }
        
        // Only count completions on scheduled days (prevents gaming the system)
        var actualCount = 0
        let repeatsPerDay = max(1, Int(repeatPattern.repeatsPerDay))
        
        for (date, completionCount) in completionsByDate {
            // Use HabitUtilities.isHabitActive instead of custom isExpectedDay logic
            if HabitUtilities.isHabitActive(habit: habit, on: date) {
                // Cap at expected repeats per day
                actualCount += min(completionCount, repeatsPerDay)
            }
        }
        
        return actualCount
    }
    
    // MARK: - Base Score Calculation
    
    /// Calculate base score (0-80 points) based on completion ratio
    static func calculateBaseScore(actualCount: Int, expectedCount: Int) -> Double {
        guard expectedCount > 0 else { return 0 }
        
        // Cap completion ratio at 1.0 (100% completion)
        let completionRatio = min(1.0, Double(actualCount) / Double(expectedCount))
        return completionRatio * 80.0
    }
    
    // MARK: - Streak Calculation using habit.calculateStreak
    
    struct StreakInfo {
        let days: Int
        let ratio: Double
        let bonus: Double
    }
    
    /// Calculate streak bonus (0-20 points) using habit's calculateStreak method
    /// Uses ratio relative to expected count for fair scoring across different frequencies
    static func calculateStreakBonus(habit: Habit, expectedCount: Int, today: Date) -> Double {
        let streakInfo = calculateStreakInfo(habit: habit, expectedCount: expectedCount, today: today)
        return streakInfo.bonus
    }
    
    /// Calculate detailed streak information using habit.calculateStreak
    static func calculateStreakInfo(habit: Habit, expectedCount: Int, today: Date) -> StreakInfo {
        // Use the habit's own calculateStreak method which handles all the complexity
        let streakDays = habit.calculateStreak(upTo: today)
        
        // Calculate streak ratio relative to expected count for fairness
        // For habits with few expected occurrences, this prevents unfair penalty
        let streakRatio = expectedCount > 0 ? min(1.0, Double(streakDays) / Double(expectedCount)) : 0.0
        let bonus = streakRatio * 20.0
        
        return StreakInfo(days: streakDays, ratio: streakRatio, bonus: bonus)
    }
    
    // MARK: - Helper Methods using habit.isCompleted
    
    /// Check if habit was completed on a specific date using habit.isCompleted
    static func isHabitCompleted(habit: Habit, on date: Date, repeatPattern: RepeatPattern) -> Bool {
        // Use the habit's own isCompleted method which handles all the complexity
        return habit.isCompleted(on: date)
    }
}

// MARK: - Supporting Types

/// Detailed breakdown of habit score calculation for analytics and debugging
struct HabitScoreBreakdown {
    let totalScore: Int
    let baseScore: Int
    let streakBonus: Int
    let expectedCount: Int
    let actualCount: Int
    let completionRatio: Double
    let currentStreakDays: Int
    let windowDays: Int
    let streakRatio: Double
    
    var completionPercentage: Int {
        return Int(round(completionRatio * 100))
    }
    
    var streakPercentage: Int {
        return Int(round(streakRatio * 100))
    }
    
    /// Human-readable description of the score breakdown
    var description: String {
        return """
        Habit Score: \(totalScore)/100
        ├─ Base Score: \(baseScore)/80 (\(completionPercentage)% completion)
        ├─ Streak Bonus: \(streakBonus)/20 (\(currentStreakDays) days, \(streakPercentage)% of window)
        └─ Window: \(actualCount)/\(expectedCount) completed in \(windowDays) days
        """
    }
}
