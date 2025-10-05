// MARK: - Optimized Streak Manager

import CoreData
import Foundation
import SwiftUI
import Combine

class StreakManager {
    private let context: NSManagedObjectContext
    private let calendar = Calendar.current
    
    // OPTIMIZATION: In-memory cache for recent calculations
    private static var memoryCache: [String: (data: StreakData, timestamp: Date)] = [:]
    private static let cacheValidDuration: TimeInterval = 30 // 30 seconds
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    // MARK: - Main streak calculation
    
    func getCurrentStreak(for habit: Habit) async throws -> StreakData {
        // Check memory cache first
        if let cached = checkMemoryCache(for: habit) {
            return cached
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                do {
                    // Validate habit
                    guard !habit.isFault && !habit.isDeleted && habit.id != nil else {
                        continuation.resume(returning: StreakData.empty())
                        return
                    }
                    
                    // Calculate streak data with best tracking
                    let streakData = self.calculateStreakDataOptimized(for: habit)
                    
                    // Cache the result
                    self.cacheInMemory(streakData, for: habit)
                    
                    continuation.resume(returning: streakData)
                    
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func forceRecalculateStreak(for habit: Habit) async throws -> StreakData {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                do {
                    // Validate habit
                    guard !habit.isFault && !habit.isDeleted && habit.id != nil else {
                        continuation.resume(returning: StreakData.empty())
                        return
                    }
                    
                    // Force recalculate and cache
                    let streakData = self.calculateStreakDataOptimized(for: habit)
                    self.cacheInMemory(streakData, for: habit)
                    
                    continuation.resume(returning: streakData)
                    
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Core calculation method with best streak tracking
    
    private func calculateStreakDataOptimized(for habit: Habit) -> StreakData {
        let today = calendar.startOfDay(for: Date())
        
        // Use the habit's optimized streak calculations
        let currentStreak = habit.calculateStreak(upTo: today)
        let longestStreak = habit.calculateLongestStreak()
        
        // 🆕 FIXED: bestStreakEver should ALWAYS equal longestStreak (they're the same thing)
        let currentBestStreak = Int(habit.bestStreakEver)
        if longestStreak != currentBestStreak {
            habit.bestStreakEver = Int32(longestStreak)
            
            do {
                try context.save()
                let changeDirection = longestStreak > currentBestStreak ? "increased" : "decreased"
                print("🔄 Best streak \(changeDirection) for '\(habit.name ?? "Unknown")': \(currentBestStreak) → \(longestStreak)")
            } catch {
                print("❌ Failed to save updated best streak: \(error)")
            }
        }
        
        // Find last active date efficiently
        let lastActiveDate = findLastCompletedDateOptimized(for: habit)
        
        return StreakData(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            bestStreakEver: Int(habit.bestStreakEver), // This always equals longestStreak now
            startDate: habit.startDate ?? Date(),
            lastActiveDate: lastActiveDate,
            isActive: currentStreak > 0
        )
    }
    
    // MARK: - Fast last completed date finding
    private func findLastCompletedDateOptimized(for habit: Habit) -> Date? {
        guard let completions = habit.completion as? Set<Completion> else { return nil }
        
        return completions
            .compactMap { completion -> Date? in
                guard let date = completion.date, completion.completed else { return nil }
                return calendar.startOfDay(for: date)
            }
            .max()
    }
    
    // MARK: - Memory caching system
    
    private func checkMemoryCache(for habit: Habit) -> StreakData? {
        guard let habitId = habit.id?.uuidString else { return nil }
        
        if let cached = Self.memoryCache[habitId] {
            if Date().timeIntervalSince(cached.timestamp) < Self.cacheValidDuration {
                return cached.data
            } else {
                Self.memoryCache.removeValue(forKey: habitId)
            }
        }
        
        return nil
    }
    
    private func cacheInMemory(_ streakData: StreakData, for habit: Habit) {
        guard let habitId = habit.id?.uuidString else { return }
        
        Self.memoryCache[habitId] = (data: streakData, timestamp: Date())
        
        // Cleanup old cache entries
        cleanupExpiredCache()
    }
    
    private func cleanupExpiredCache() {
        let now = Date()
        
        Self.memoryCache = Self.memoryCache.filter { _, value in
            now.timeIntervalSince(value.timestamp) < Self.cacheValidDuration
        }
    }
    
    // MARK: - Update method with safe best streak tracking
    
    func updateStreakAfterToggle(habit: Habit, date: Date) async throws {
        guard let habitId = habit.id?.uuidString else { return }
        
        // Remove from memory cache to force recalculation on next access
        Self.memoryCache.removeValue(forKey: habitId)
        
        // 🆕 SAFE: Update best streak using background context
        await updateBestStreakSafely(for: habit)
    }
    
    // MARK: - Safe Best Streak Update (Fixed)
    
    private func updateBestStreakSafely(for habit: Habit) async {
        guard let habitID = habit.id else { return }
        
        // Create a background context for safe CoreData access
        let backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        backgroundContext.parent = context
        
        // Use performAndWait for synchronous execution on the background context's queue
        await withCheckedContinuation { continuation in
            backgroundContext.perform {
                do {
                    // Fetch the habit in the background context
                    let fetchRequest: NSFetchRequest<Habit> = Habit.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "id == %@", habitID as CVarArg)
                    
                    guard let backgroundHabit = try backgroundContext.fetch(fetchRequest).first else {
                        print("❌ Could not find habit in background context")
                        continuation.resume()
                        return
                    }
                    
                    // Calculate longest streak safely in background context
                    let newLongestStreak = backgroundHabit.calculateLongestStreak()
                    let previousBestStreak = Int(backgroundHabit.bestStreakEver)
                    
                    // Update only if different
                    if newLongestStreak != previousBestStreak {
                        backgroundHabit.bestStreakEver = Int32(newLongestStreak)
                        
                        // Save background context
                        try backgroundContext.save()
                        
                        // Save parent context on main thread
                        DispatchQueue.main.async {
                            do {
                                try self.context.save()
                                
                                // Post notification
                                NotificationCenter.default.post(
                                    name: NSNotification.Name("BestStreakChanged"),
                                    object: habit,
                                    userInfo: [
                                        "newBestStreak": newLongestStreak,
                                        "previousBest": previousBestStreak
                                    ]
                                )
                                
                                let direction = newLongestStreak > previousBestStreak ? "increased" : "decreased"
                                print("🔄 Best streak \(direction): '\(habit.name ?? "Unknown")': \(previousBestStreak) → \(newLongestStreak)")
                            } catch {
                                print("❌ Failed to save best streak on main context: \(error)")
                            }
                            continuation.resume()
                        }
                    } else {
                        continuation.resume()
                    }
                    
                } catch {
                    print("❌ Failed to update best streak safely: \(error)")
                    continuation.resume()
                }
            }
        }
    }
    
    // MARK: - Utility methods
    
    func invalidateCache(for habit: Habit) async throws {
        guard let habitId = habit.id?.uuidString else { return }
        Self.memoryCache.removeValue(forKey: habitId)
    }
    
    func invalidateAllStreakCaches() async throws {
        Self.memoryCache.removeAll()
    }
    
    func preloadStreaksForHabits(_ habits: [Habit]) async throws {
        // Skip preloading for performance
        print("StreakManager: Skipping preload for optimal performance")
    }
    
    // MARK: - Best streak utilities
    
    func getBestStreakForHabit(_ habit: Habit) -> Int {
        return Int(habit.bestStreakEver)
    }
}

// MARK: - StreakData Model

struct StreakData {
    let currentStreak: Int
    let longestStreak: Int
    let bestStreakEver: Int
    let startDate: Date
    let lastActiveDate: Date?
    let isActive: Bool
    
    var isStreakContinuable: Bool {
        guard let lastDate = lastActiveDate else { return true }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let daysSinceLastCompletion = calendar.dateComponents([.day], from: lastDate, to: today).day ?? 0
        
        return daysSinceLastCompletion <= 1
    }
    
    static func empty() -> StreakData {
        return StreakData(
            currentStreak: 0,
            longestStreak: 0,
            bestStreakEver: 0,
            startDate: Date(),
            lastActiveDate: nil,
            isActive: false
        )
    }
}
