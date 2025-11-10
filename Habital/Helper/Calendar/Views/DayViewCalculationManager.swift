//
//  DayViewCalculationManager.swift
//  Habital
//
//  Created by Elias Osarumwense on 30.07.25.
//

import SwiftUI
import CoreData

@MainActor
class DayViewCalculationManager: ObservableObject {
    static let shared = DayViewCalculationManager()
    
    // Cache for calculated results
    private var calculationCache: [String: DayCalculationResult] = [:]
    private var pendingCalculations: Set<String> = []
    

    
    struct DayCalculationResult {
        let hasActiveHabits: Bool
        let completionPercentage: Double
        let ringColors: [Color]
        let timestamp: Date
        
        // Cache validity (5 minutes)
        var isValid: Bool {
            Date().timeIntervalSince(timestamp) < 300
        }
    }
    
    private init() {}
    
    // MARK: - Public Interface
    func getCalculationResult(for date: Date, habits: [Habit], useCache: Bool = true) async -> DayCalculationResult? {
        let cacheKey = createCacheKey(for: date, habits: habits)
        
        // Return cached result if valid
        if useCache, let cached = calculationCache[cacheKey], cached.isValid {
            return cached
        }
        
        // Avoid duplicate calculations
        if pendingCalculations.contains(cacheKey) {
            // Wait a bit for ongoing calculation
            try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
            return calculationCache[cacheKey]
        }
        
        return await performAsyncCalculation(for: date, habits: habits, cacheKey: cacheKey)
    }
    
    // MARK: - Async Calculation
    private func performAsyncCalculation(for date: Date, habits: [Habit], cacheKey: String) async -> DayCalculationResult? {
        pendingCalculations.insert(cacheKey)
        
        return await withTaskGroup(of: DayCalculationResult?.self) { group in
            group.addTask { [weak self] in
                return await self?.calculateOnBackground(date: date, habits: habits)
            }
            
            let result = await group.next() ?? nil
            
            if let result = result {
                calculationCache[cacheKey] = result
            }
            pendingCalculations.remove(cacheKey)
            
            return result
        }
    }
    
    private func calculateOnBackground(date: Date, habits: [Habit]) async -> DayCalculationResult {
        // Perform calculations - already on appropriate executor via Swift Concurrency
        return performCalculation(date: date, habits: habits)
    }
    
    private func performCalculation(date: Date, habits: [Habit]) -> DayCalculationResult {
        let isFuture = date > Date()
        
        // Filter active habits (this is where the bottleneck was)
        let activeHabits = habits.filter { habit in
            HabitUtilities.isHabitActive(habit: habit, on: date)
        }
        
        let hasActiveHabits = !activeHabits.isEmpty
        
        if !hasActiveHabits {
            return DayCalculationResult(
                hasActiveHabits: false,
                completionPercentage: 0.0,
                ringColors: [],
                timestamp: Date()
            )
        }
        
        if isFuture {
            let ringColors = self.calculateRingColors(activeHabits: activeHabits, completedHabits: [])
            return DayCalculationResult(
                hasActiveHabits: hasActiveHabits,
                completionPercentage: 0.0,
                ringColors: ringColors,
                timestamp: Date()
            )
        }
        
        // Calculate completion (heavy operation moved to background)
        let completedHabits = activeHabits.filter { habit in
            habit.isCompleted(on: date)
        }
        
        let completionPercentage = Double(completedHabits.count) / Double(activeHabits.count)
        let ringColors = calculateRingColors(activeHabits: activeHabits, completedHabits: completedHabits)
        
        return DayCalculationResult(
            hasActiveHabits: hasActiveHabits,
            completionPercentage: completionPercentage,
            ringColors: ringColors,
            timestamp: Date()
        )
    }
    
    private func calculateRingColors(activeHabits: [Habit], completedHabits: [Habit]) -> [Color] {
        // Simplified color calculation - adjust based on your existing logic
        if completedHabits.isEmpty {
            return [Color.gray.opacity(0.3)]
        }
        
        // Extract colors from completed habits
        return completedHabits.compactMap { habit in
            if let colorData = habit.color,
               let color = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
                return Color(uiColor: color)
            }
            return Color.blue
        }
    }
    
    private func createCacheKey(for date: Date, habits: [Habit]) -> String {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        let habitIds = habits.compactMap { $0.id?.uuidString }.sorted().joined(separator: ",")
        return "\(normalizedDate.timeIntervalSince1970)-\(habitIds.hashValue)"
    }
    
    // MARK: - Cache Management
    func clearCache() {
        calculationCache.removeAll()
    }
    
    func clearExpiredCache() {
        calculationCache = calculationCache.filter { $0.value.isValid }
    }
    
    // Pre-calculate for visible range (call this during scroll)
    func preCalculateRange(startDate: Date, endDate: Date, habits: [Habit]) {
        Task {
            let calendar = Calendar.current
            var currentDate = startDate
            
            while currentDate <= endDate {
                _ = await getCalculationResult(for: currentDate, habits: habits, useCache: false)
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? endDate
            }
        }
    }
}
