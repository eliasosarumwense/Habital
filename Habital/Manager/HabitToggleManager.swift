//
//  HabitToggleManager.swift
//  Habital
//
//  Created by Elias Osarumwense on 08.08.25.
//

import SwiftUI
import CoreData
import Combine

class HabitToggleManager: ObservableObject {
    let viewContext: NSManagedObjectContext
    let calendar = Calendar.current
    
    // 🔄 Published property that triggers view updates when habits are toggled
    @Published var completionVersion = UUID()
    
    init(context: NSManagedObjectContext) {
        self.viewContext = context
    }
    
    
    // MARK: - Main Toggle Function with Smart Streak Updates
    @MainActor func toggleCompletion(for habit: Habit, on date: Date, dataManager: AnyObject? = nil, tracksTime: Bool = false, minutes: Int? = nil, quantity: Int? = nil) {
        // Only normalize if not tracking time
        let dateToUse = tracksTime ? date : calendar.startOfDay(for: date)
        let normalizedDateForCalc = calendar.startOfDay(for: dateToUse)  // Always use normalized for calculations
        
        // Cache repeatsPerDay using normalized date for calculations
        let repeatsPerDay = HabitUtilities.getRepeatsPerDay(for: habit, on: normalizedDateForCalc)
        
        // Cache before state using normalized date
        let wasCompletedBefore = isHabitCompletedForDate(habit, on: normalizedDateForCalc)
        
        let trackingType = getTrackingType(for: habit)
            
            switch trackingType {
            case .repetitions:
                // Existing logic for repetitions
                let repeatsPerDay = HabitUtilities.getRepeatsPerDay(for: habit, on: date)
                if repeatsPerDay > 1 {
                    toggleMultiRepeatCompletion(for: habit, on: date, repeatsPerDay: repeatsPerDay)
                } else {
                    toggleSingleCompletion(for: habit, on: date, tracksTime: tracksTime)
                }
                
            case .duration:
                // Use provided minutes or toggle to target/0
                let minutesToUse: Int
                if let providedMinutes = minutes {
                    minutesToUse = providedMinutes
                } else {
                    let currentDuration = getDurationCompleted(for: habit, on: date)
                    let targetDuration = getTargetDuration(for: habit)
                    minutesToUse = (currentDuration >= targetDuration) ? 0 : targetDuration
                }
                toggleDurationCompletion(for: habit, on: date, minutes: minutesToUse, tracksTime: tracksTime)
                
            case .quantity:
                // Use provided quantity or toggle to target/0
                let quantityToUse: Int
                if let providedQuantity = quantity {
                    quantityToUse = providedQuantity
                } else {
                    let currentQuantity = getQuantityCompleted(for: habit, on: date)
                    let targetQuantity = getTargetQuantity(for: habit)
                    quantityToUse = (currentQuantity >= targetQuantity) ? 0 : targetQuantity
                }
                toggleQuantityCompletion(for: habit, on: date, quantity: quantityToUse, tracksTime: tracksTime)
            }
        
        // Get the completion state after toggle using normalized date
        let isCompletedAfter = isHabitCompletedForDate(habit, on: normalizedDateForCalc)
        
        // 🔄 Trigger view updates by changing the published property
        completionVersion = UUID()
        
        // Smart cache invalidation using normalized date
        invalidateCacheForIntervalHabit(habit: habit, completionDate: normalizedDateForCalc)

        // Specific notification for habit toggle (for stats and other views)
        NotificationCenter.default.post(
            name: NSNotification.Name("HabitToggled"),
            object: nil,  // Don't use object - it causes all listeners to update
            userInfo: [
                "habitID": habit.id!,  // Add specific ID
                "date": date,
                "wasCompleted": wasCompletedBefore,
                "isCompleted": isCompletedAfter
            ]
        )
        
        // SMART STREAK UPDATE: Calculate streaks only for this habit and check if it affects best streaks
        Task {
            let streakData = await calculateStreakDataForHabit(habit, on: date)
            
            await MainActor.run {
                // Post efficient streak update notification with the calculated data
                NotificationCenter.default.post(
                    name: NSNotification.Name("StreakUpdatedEfficient"),
                    object: habit,
                    userInfo: [
                        "date": date,
                        "streakData": streakData,
                        "shouldUpdateGlobalStats": true
                    ]
                )
            }
        }
        //HabitUtilities.clearHabitActivityCache()
    }
    
    private func saveContext() {
            do {
                try viewContext.save()
            } catch {
                print("Error saving context: \(error)")
                viewContext.rollback()
            }
        }
    
    func toggleDurationCompletion(for habit: Habit, on date: Date, minutes: Int, tracksTime: Bool = false) {
        let normalizedDate = tracksTime ? date : calendar.startOfDay(for: date)
            let dayKey = DayKeyFormatter.localKey(from: date)
            
            // Track if we're removing a skip
            let isRemovingSkip = findSkippedCompletion(for: habit, on: normalizedDate) != nil
            
            // Remove any skip completion first
            if let skippedCompletion = findSkippedCompletion(for: habit, on: normalizedDate) {
                viewContext.delete(skippedCompletion)
            }
            
            // If minutes is 0, delete all completions for this date
            if minutes == 0 {
                let completedCount = getCompletedCompletionsCount(for: habit, on: normalizedDate)
                let removedCount = clearAllCompletionsOptimized(for: habit, on: normalizedDate)
                
                // Only decrement by completed completions that were actually counted
                if completedCount > 0 && !isRemovingSkip {
                    habit.totalCompletions = max(0, habit.totalCompletions - Int32(completedCount))
                    print("📉 Decremented totalCompletions by \(completedCount) when deleting duration completion")
                }
                
                // Update habit's last completion date if needed
                habit.lastCompletionDate = habit.findMostRecentCompletion(before: date)?.date
                
                do {
                    try viewContext.save()
                    //HabitUtilities.clearHabitActivityCache()
                    print("✅ Duration completion deleted for habit '\(habit.name ?? "Unknown")' - Total completions: \(habit.totalCompletions)")
                } catch {
                    print("❌ Failed to delete duration completion: \(error)")
                    viewContext.rollback()
                }
                
                return
            }
        
        // Find or create completion for this date
        let completion: Completion
        let isNewCompletion: Bool
        if let existingCompletion = findCompletion(for: habit, on: normalizedDate) {
            completion = existingCompletion
            isNewCompletion = false
        } else {
            completion = Completion(context: viewContext)
            completion.date = normalizedDate
            completion.dayKey = dayKey
            habit.addToCompletion(completion)
            isNewCompletion = true
        }
        
        // Track previous state
        let wasCompleted = completion.completed
        let previousMinutes = Int(completion.duration)
        
        // Update duration values
        completion.duration = Int16(minutes)
        completion.tracksTime = tracksTime
        completion.loggedAt = Date()
        
        // Get target duration
        let targetDuration = getTargetDuration(for: habit)
        
        // Update completion status
        completion.completed = minutes >= targetDuration
        completion.progressPercentage = min(1.0, Double(minutes) / Double(targetDuration))
        
        // Update total completions ONLY when completion status actually changes
        if wasCompleted != completion.completed && !isRemovingSkip {
                if completion.completed {
                    habit.totalCompletions += 1
                    print("📈 Incremented totalCompletions when duration reached target")
                } else {
                    habit.totalCompletions = max(0, habit.totalCompletions - 1)
                    print("📉 Decremented totalCompletions when duration fell below target")
                }
            }
        
        // Update habit's last completion date
        if completion.completed && normalizedDate > (habit.lastCompletionDate ?? Date.distantPast) {
            habit.lastCompletionDate = normalizedDate
        }
        
        // Save changes
        do {
            try viewContext.save()
            //HabitUtilities.clearHabitActivityCache()
            print("✅ Duration updated: \(previousMinutes)min → \(minutes)min (target: \(targetDuration)min) - Total completions: \(habit.totalCompletions)")
        } catch {
            print("❌ Failed to update duration: \(error)")
            viewContext.rollback()
        }
        
    }

    func toggleQuantityCompletion(for habit: Habit, on date: Date, quantity: Int, tracksTime: Bool = false) {
        let normalizedDate = tracksTime ? date : calendar.startOfDay(for: date)
            let dayKey = DayKeyFormatter.localKey(from: date)
            
            // Track if we're removing a skip
            let isRemovingSkip = findSkippedCompletion(for: habit, on: normalizedDate) != nil
            
            // Remove any skip completion first
            if let skippedCompletion = findSkippedCompletion(for: habit, on: normalizedDate) {
                viewContext.delete(skippedCompletion)
            }
            
            // If quantity is 0, delete all completions for this date
            if quantity == 0 {
                let completedCount = getCompletedCompletionsCount(for: habit, on: normalizedDate)
                let removedCount = clearAllCompletionsOptimized(for: habit, on: normalizedDate)
                
                // Only decrement by completed completions that were actually counted
                if completedCount > 0 && !isRemovingSkip {
                    habit.totalCompletions = max(0, habit.totalCompletions - Int32(completedCount))
                    print("📉 Decremented totalCompletions by \(completedCount) when deleting quantity completion")
                }
                
                // Update habit's last completion date if needed
                habit.lastCompletionDate = habit.findMostRecentCompletion(before: date)?.date
                
                do {
                    try viewContext.save()
                    //HabitUtilities.clearHabitActivityCache()
                    print("✅ Quantity completion deleted for habit '\(habit.name ?? "Unknown")' - Total completions: \(habit.totalCompletions)")
                } catch {
                    print("❌ Failed to delete quantity completion: \(error)")
                    viewContext.rollback()
                }
                return
            }
        
        // Find or create completion for this date
        let completion: Completion
        let isNewCompletion: Bool
        if let existingCompletion = findCompletion(for: habit, on: normalizedDate) {
            completion = existingCompletion
            isNewCompletion = false
        } else {
            completion = Completion(context: viewContext)
            completion.date = normalizedDate
            completion.dayKey = dayKey
            habit.addToCompletion(completion)
            isNewCompletion = true
        }
        
        // Track previous state
        let wasCompleted = completion.completed
        let previousQuantity = Int(completion.quantity)
        
        // Update quantity values
        completion.quantity = Int32(quantity)
        completion.tracksTime = tracksTime
        completion.loggedAt = Date()
        
        // Get target quantity
        let targetQuantity = getTargetQuantity(for: habit)
        
        // Update completion status
        completion.completed = quantity >= targetQuantity
        completion.progressPercentage = min(1.0, Double(quantity) / Double(targetQuantity))
        
        // Update total completions ONLY when completion status actually changes
        if wasCompleted != completion.completed && !isRemovingSkip {
                if completion.completed {
                    habit.totalCompletions += 1
                    print("📈 Incremented totalCompletions when quantity reached target")
                } else {
                    habit.totalCompletions = max(0, habit.totalCompletions - 1)
                    print("📉 Decremented totalCompletions when quantity fell below target")
                }
            }
        
        // Update habit's last completion date
        if completion.completed && normalizedDate > (habit.lastCompletionDate ?? Date.distantPast) {
            habit.lastCompletionDate = normalizedDate
        }
        
        // Save changes
        do {
            try viewContext.save()
            //HabitUtilities.clearHabitActivityCache()
            print("✅ Quantity updated: \(previousQuantity) → \(quantity) (target: \(targetQuantity)) - Total completions: \(habit.totalCompletions)")
        } catch {
            print("❌ Failed to update quantity: \(error)")
            viewContext.rollback()
        }
        
    }
    
    private func getCompletedCompletionsCount(for habit: Habit, on date: Date) -> Int {
        let dayKey = DayKeyFormatter.localKey(from: date)
        
        let request = NSFetchRequest<Completion>(entityName: "Completion")
        request.predicate = NSPredicate(
            format: "dayKey == %@ AND habit == %@ AND completed == YES",
            dayKey, habit
        )
        
        do {
            let count = try viewContext.count(for: request)
            return count
        } catch {
            print("Error counting completed completions: \(error)")
            return 0
        }
    }
        
        // MARK: - Helper Methods for Getting Current Values
        func getDurationCompleted(for habit: Habit, on date: Date) -> Int {
            let normalizedDate = calendar.startOfDay(for: date)
            
            if let completion = findCompletion(for: habit, on: normalizedDate) {
                return Int(completion.duration)
            }
            return 0
        }
        
        func getQuantityCompleted(for habit: Habit, on date: Date) -> Int {
            let normalizedDate = calendar.startOfDay(for: date)
            
            if let completion = findCompletion(for: habit, on: normalizedDate) {
                return Int(completion.quantity)
            }
            return 0
        }
        
        // Helper to get target duration for a habit
        private func getTargetDuration(for habit: Habit) -> Int {
            guard let pattern = habit.repeatPattern?.allObjects.first as? RepeatPattern else {
                return 30 // Default 30 minutes
            }
            return Int(pattern.duration)
        }
        
        // Helper to get target quantity for a habit
        private func getTargetQuantity(for habit: Habit) -> Int {
            guard let pattern = habit.repeatPattern?.allObjects.first as? RepeatPattern else {
                return 1 // Default 1 unit
            }
            return Int(pattern.targetQuantity)
        }
        
        private func getTrackingType(for habit: Habit) -> HabitTrackingType {
            guard let pattern = habit.repeatPattern?.allObjects.first as? RepeatPattern,
                  let typeString = pattern.trackingType,
                  let type = HabitTrackingType(rawValue: typeString) else {
                return .repetitions
            }
            return type
        }
    
    // MARK: - Smart Streak Calculation for Single Habit
    
    private func calculateStreakDataForHabit(_ habit: Habit, on date: Date) async -> StreakData {
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                let calendar = Calendar.current
                let today = calendar.startOfDay(for: Date())
                let toggleDate = calendar.startOfDay(for: date)
                
                // Always calculate current streak (this is already optimized & fast)
                let currentStreak = habit.calculateStreak(upTo: today) // Always use TODAY for current
                
                // Get stored best streak
                let storedBest = Int(habit.bestStreakEver)
                
                // Determine if we need full recalculation
                let needsFullRecalculation =
                    currentStreak >= storedBest ||  // At or exceeding record
                    toggleDate < today               // Editing past (could affect historical streaks)
                
                let longestStreak: Int
                let lastActiveDate: Date?
                
                if needsFullRecalculation {
                    // Full recalculation needed
                    longestStreak = habit.calculateLongestStreak()
                    
                    // Update stored best if changed
                    if longestStreak != storedBest {
                        habit.bestStreakEver = Int32(longestStreak)
                        
                        // Batch save with other potential changes
                        if self.viewContext.hasChanges {
                            do {
                                try self.viewContext.save()
                                let changeType = longestStreak > storedBest ? "📈 NEW RECORD" : "📉 Updated"
                                print("\(changeType): '\(habit.name ?? "Unknown")' best streak: \(storedBest) → \(longestStreak)")
                            } catch {
                                print("❌ Failed to save best streak: \(error)")
                            }
                        }
                    }
                    
                    // Calculate last active date only when needed
                    lastActiveDate = habit.lastCompletionDate
                } else {
                    // Use cached values - no expensive calculations
                    longestStreak = storedBest
                    
                    // Optimize: Only calculate lastActiveDate if current streak is active
                    lastActiveDate = currentStreak > 0 ? habit.lastCompletionDate : nil
                }
                
                let streakData = StreakData(
                    currentStreak: currentStreak,
                    longestStreak: longestStreak,
                    bestStreakEver: longestStreak, // Always equals longestStreak
                    startDate: habit.startDate ?? Date(),
                    lastActiveDate: lastActiveDate,
                    isActive: currentStreak > 0
                )
                
                continuation.resume(returning: streakData)
            }
        }
    }
    
    private func toggleSingleCompletion(for habit: Habit, on date: Date, tracksTime: Bool = false) {
        let targetDate = date
        let normalizedDate = calendar.startOfDay(for: date)
        let dayKey = DayKeyFormatter.localKey(from: date)
        
        // Track if we're removing a skip
        let isRemovingSkip = findSkippedCompletion(for: habit, on: normalizedDate) != nil
        
        // Check for and delete any skipped completion first
        if let skippedCompletion = findSkippedCompletion(for: habit, on: normalizedDate) {
            viewContext.delete(skippedCompletion)
            print("🗑️ Removed skip completion for '\(habit.name ?? "Unknown")'")
        }
        
        // Find existing completion (excluding skipped ones we just deleted)
        if let existingCompletion = findCompletion(for: habit, on: date) {
            if existingCompletion.completed {
                // Remove completion entirely
                viewContext.delete(existingCompletion)
                habit.totalCompletions = max(0, habit.totalCompletions - 1)
                print("📉 Decremented totalCompletions: removed completed habit")
            } else {
                // Mark as completed - but only increment if not coming from a skip
                existingCompletion.completed = true
                existingCompletion.loggedAt = Date()
                existingCompletion.tracksTime = tracksTime
                existingCompletion.dayKey = dayKey
                if !isRemovingSkip {
                    habit.totalCompletions += 1
                    print("📈 Incremented totalCompletions: marked existing as completed")
                } else {
                    print("⚖️ No totalCompletions change: converting from skip to completed")
                }
            }
        } else {
            // Create new completion - but only increment if not coming from a skip
            let newCompletion = Completion(context: viewContext)
            newCompletion.completed = true
            newCompletion.date = targetDate
            newCompletion.loggedAt = Date()
            newCompletion.tracksTime = tracksTime
            newCompletion.dayKey = dayKey
            habit.addToCompletion(newCompletion)
            
            if !isRemovingSkip {
                habit.totalCompletions += 1
                print("📈 Incremented totalCompletions: created new completion")
            } else {
                print("⚖️ No totalCompletions change: converting from skip to completed")
            }
            
            if calendar.startOfDay(for: targetDate) > (habit.lastCompletionDate ?? Date.distantPast) {
                habit.lastCompletionDate = calendar.startOfDay(for: targetDate)
            }
        }
        
        do {
            try viewContext.save()
            HabitUtilities.clearHabitActivityCache()
            print("✅ Updated habit '\(habit.name ?? "Unknown")' - Total completions: \(habit.totalCompletions)")
        } catch {
            print("❌ Error updating habit: \(error)")
            viewContext.rollback()
        }
    }

    private func toggleMultiRepeatCompletion(for habit: Habit, on date: Date, repeatsPerDay: Int, tracksTime: Bool = false) {
        let normalizedDate = calendar.startOfDay(for: date)
        let dayKey = DayKeyFormatter.localKey(from: date)
        
        // Track if we're removing a skip
        let isRemovingSkip = findSkippedCompletion(for: habit, on: normalizedDate) != nil
        
        // Check for and delete any skipped completion first
        if let skippedCompletion = findSkippedCompletion(for: habit, on: normalizedDate) {
            viewContext.delete(skippedCompletion)
            print("🗑️ Removed skip completion for '\(habit.name ?? "Unknown")'")
        }
        
        // Get current completions AFTER potentially removing skip
        let currentCompletions = HabitUtilities.getCompletedRepeatsCount(for: habit, on: normalizedDate)
        
        // Handle the different scenarios
        if isRemovingSkip {
            // When removing a skip, just remove it - don't add any completion
            print("⚖️ Removed skip completion for multi-repeat habit")
            
        } else if currentCompletions >= repeatsPerDay {
            // At max completions, clear all
            let completedCount = getCompletedCompletionsCount(for: habit, on: normalizedDate)
            let removedCount = clearAllCompletionsOptimized(for: habit, on: normalizedDate)
            
            // Decrement by completed completions that were actually counted
            if completedCount > 0 {
                habit.totalCompletions = max(0, habit.totalCompletions - Int32(completedCount))
                print("📉 Decremented totalCompletions by \(completedCount) when clearing multi-repeat completions")
            }
            
            // Update habit's last completion date if needed
            habit.lastCompletionDate = habit.findMostRecentCompletion(before: date)?.date
            
        } else {
            // Add one more completion (incremental behavior for multi-repeat)
            let newCompletion = Completion(context: viewContext)
            newCompletion.date = date
            newCompletion.completed = true
            newCompletion.loggedAt = Date()
            newCompletion.tracksTime = tracksTime
            newCompletion.dayKey = dayKey
            habit.addToCompletion(newCompletion)
            
            // Increment totalCompletions for new completion
            habit.totalCompletions += 1
            print("📈 Incremented totalCompletions: added multi-repeat completion")
            
            // Update lastCompletionDate if needed
            if normalizedDate > (habit.lastCompletionDate ?? Date.distantPast) {
                habit.lastCompletionDate = normalizedDate
            }
        }
        
        do {
            try viewContext.save()
            HabitUtilities.clearHabitActivityCache()
            print("✅ Updated multi-repeat habit '\(habit.name ?? "Unknown")' - Total completions: \(habit.totalCompletions)")
        } catch {
            print("❌ Error updating multi-repeat completion: \(error)")
            viewContext.rollback()
        }
    }
    
    private func hasSkippedCompletion(for habit: Habit, on date: Date) -> Bool {
            let dayKey = DayKeyFormatter.localKey(from: date)  // ✅ Generate dayKey from date
            
            let request = NSFetchRequest<Completion>(entityName: "Completion")
            request.predicate = NSPredicate(
                format: "dayKey == %@ AND habit == %@ AND skipped == YES",
                dayKey, habit
            )
            request.fetchLimit = 1
            
            do {
                let count = try viewContext.count(for: request)
                return count > 0
            } catch {
                print("Error checking for skipped completion: \(error)")
                return false
            }
        }
        
        // MARK: - Fixed: findSkippedCompletion with dayKey
        private func findSkippedCompletion(for habit: Habit, on date: Date) -> Completion? {
            let dayKey = DayKeyFormatter.localKey(from: date)  // ✅ Generate dayKey from date
            
            let request = NSFetchRequest<Completion>(entityName: "Completion")
            request.predicate = NSPredicate(
                format: "dayKey == %@ AND habit == %@ AND skipped == YES",
                dayKey, habit
            )
            request.fetchLimit = 1
            
            do {
                let completions = try viewContext.fetch(request)
                return completions.first
            } catch {
                print("Error finding skipped completion: \(error)")
                return nil
            }
        }
    
    func skipHabit(for habit: Habit, on date: Date) {
        let normalizedDate = calendar.startOfDay(for: date)
        let dayKey = DayKeyFormatter.localKey(from: date)
        
        // Get current completion state BEFORE making changes
        let wasCompleted = isHabitCompletedForDate(habit, on: normalizedDate)
        
        // Count how many completed completions exist for this date
        let completedCompletionsCount = getCompletedCompletionsCount(for: habit, on: normalizedDate)
        
        // Remove any existing completions for this date (both completed and uncompleted)
        let removedCount = clearAllCompletionsOptimized(for: habit, on: normalizedDate)
        
        // Adjust total completions ONLY by the number of completed completions that were removed
        if completedCompletionsCount > 0 {
            habit.totalCompletions = max(0, habit.totalCompletions - Int32(completedCompletionsCount))
            print("📉 Decremented totalCompletions by \(completedCompletionsCount) when skipping")
        }
        
        // Create a skipped completion
        let skippedCompletion = Completion(context: viewContext)
        skippedCompletion.date = normalizedDate
        skippedCompletion.completed = false
        skippedCompletion.skipped = true
        skippedCompletion.dayKey = dayKey
        skippedCompletion.loggedAt = Date()
        habit.addToCompletion(skippedCompletion)
        
        // Save changes
        do {
            try viewContext.save()
            HabitUtilities.clearHabitActivityCache()
            print("✅ Habit '\(habit.name ?? "Unknown")' skipped for \(dayKey) - Total completions: \(habit.totalCompletions)")
            
            // 🔄 Trigger view updates
            completionVersion = UUID()
        } catch {
            print("❌ Failed to skip habit: \(error)")
            viewContext.rollback()
        }
    }
        
        // NEW METHOD: Unskip a habit by removing the skip completion
    func unskipHabit(for habit: Habit, on date: Date) {
        let normalizedDate = calendar.startOfDay(for: date)
        let dayKey = DayKeyFormatter.localKey(from: date)
        
        // Find and remove the skipped completion
        if let skippedCompletion = findSkippedCompletion(for: habit, on: normalizedDate) {
            viewContext.delete(skippedCompletion)
            
            // Note: We don't adjust totalCompletions here because skipped completions
            // were never counted in totalCompletions in the first place
            
            // Save changes
            do {
                try viewContext.save()
                HabitUtilities.clearHabitActivityCache()
                print("✅ Habit '\(habit.name ?? "Unknown")' unskipped for \(dayKey)")
                
                // 🔄 Trigger view updates
                completionVersion = UUID()
            } catch {
                print("❌ Failed to unskip habit: \(error)")
                viewContext.rollback()
            }
        }
    }
    
    // MARK: - Safe Best Streak Update (Called separately, not during toggle)
    private static let bestStreakQueue = DispatchQueue(label: "bestStreak.serial", qos: .utility)
    /// Safely update best streak for a habit using a background context
    func updateBestStreakSafely(for habit: Habit) {
            guard let habitID = habit.id,
                  let habitName = habit.name else { return }
            
            // 🔧 FIXED: Use serial queue to prevent concurrent calculations
            Self.bestStreakQueue.async {
                // Create a background context for safe CoreData access
                let backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
                backgroundContext.parent = self.viewContext
                
                backgroundContext.performAndWait {
                    do {
                        // Fetch the habit in the background context
                        let fetchRequest: NSFetchRequest<Habit> = Habit.fetchRequest()
                        fetchRequest.predicate = NSPredicate(format: "id == %@", habitID as CVarArg)
                        
                        guard let backgroundHabit = try backgroundContext.fetch(fetchRequest).first else {
                            print("❌ Could not find habit in background context")
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
                            DispatchQueue.main.sync {
                                do {
                                    try self.viewContext.save()
                                    
                                    // 🔧 FIXED: Get fresh habit from main context for notification
                                    let mainFetchRequest: NSFetchRequest<Habit> = Habit.fetchRequest()
                                    mainFetchRequest.predicate = NSPredicate(format: "id == %@", habitID as CVarArg)
                                    
                                    if let mainHabit = try? self.viewContext.fetch(mainFetchRequest).first {
                                        NotificationCenter.default.post(
                                            name: NSNotification.Name("BestStreakChanged"),
                                            object: mainHabit,
                                            userInfo: [
                                                "newBestStreak": newLongestStreak,
                                                "previousBest": previousBestStreak
                                            ]
                                        )
                                    }
                                    
                                    let direction = newLongestStreak > previousBestStreak ? "increased" : "decreased"
                                    print("🔄 Best streak \(direction): '\(habitName)': \(previousBestStreak) → \(newLongestStreak)")
                                    
                                } catch {
                                    print("❌ Failed to save best streak update on main context: \(error)")
                                }
                            }
                        }
                        
                    } catch {
                        print("❌ Failed to update best streak safely: \(error)")
                    }
                }
            }
        }
    
    // MARK: - 🆕 UPDATED: Delete all completions with Total Completions
    func deleteAllCompletions(for habit: Habit, on date: Date) {
        let normalizedDate = calendar.startOfDay(for: date)
        let nextDay = calendar.date(byAdding: .day, value: 1, to: normalizedDate)!
        
        // Fetch all completions for this habit on the specified date
        let request: NSFetchRequest<Completion> = Completion.fetchRequest()
        request.predicate = NSPredicate(
            format: "habit == %@ AND date >= %@ AND date < %@",
            habit,
            normalizedDate as NSDate,
            nextDay as NSDate
        )
        
        do {
            let completions = try viewContext.fetch(request)
            let deletedCount = completions.count
            
            // Delete all found completions
            for completion in completions {
                viewContext.delete(completion)
            }
            
            // 🆕 DECREMENT total completions by deleted count
            habit.totalCompletions = max(0, habit.totalCompletions - Int32(deletedCount))
            
            // Update habit's last completion date if needed
            if !completions.isEmpty {
                // Find the most recent completion before this date
                habit.lastCompletionDate = habit.findMostRecentCompletion(before: date)?.date
            }
            
            try viewContext.save()
            HabitUtilities.clearHabitActivityCache()
            print("✅ Deleted \(deletedCount) completions for '\(habit.name ?? "Unknown")' - Total completions: \(habit.totalCompletions)")
            
            // 🔄 Trigger view updates
            completionVersion = UUID()
        } catch {
            print("Failed to delete completions: \(error)")
        }
    }
    
    // MARK: - 🆕 UPDATED: More efficient completion clearing with Total Completions
    @discardableResult
    func clearAllCompletionsOptimized(for habit: Habit, on normalizedDate: Date) -> Int {
        let dayKey = DayKeyFormatter.localKey(from: normalizedDate)
        
        let request = NSFetchRequest<Completion>(entityName: "Completion")
        request.predicate = NSPredicate(
            format: "dayKey == %@ AND habit == %@",
            dayKey, habit
        )
        
        do {
            let completions = try viewContext.fetch(request)
            let totalCount = completions.count
            let completedCount = completions.filter { $0.completed }.count
            
            for completion in completions {
                viewContext.delete(completion)
            }
            
            print("🗑️ Cleared \(totalCount) completions (\(completedCount) were completed) for habit '\(habit.name ?? "Unknown")' on \(dayKey)")
            return completedCount  // Return only the count that should affect totalCompletions
        } catch {
            print("Error clearing completions: \(error)")
            return 0
        }
    }
    
    private func findCompletion(for habit: Habit, on date: Date) -> Completion? {
        guard let completions = habit.completion as? Set<Completion> else {
            return nil
        }
        
        // For finding existing completions, compare by day since users might want
        // to toggle completions for the same day but different times
        let targetDay = calendar.startOfDay(for: date)
        
        return completions.first { completion in
            guard let completionDate = completion.date else { return false }
            let completionDay = calendar.startOfDay(for: completionDate)
            return calendar.isDate(completionDay, inSameDayAs: targetDay)
        }
    }
    /// Check if habit is completed for a specific date
    func isHabitCompletedForDate(_ habit: Habit, on date: Date) -> Bool {
        return habit.isCompleted(on: date)
    }
    
    /// Get completed repeats count for multi-repeat habits
    func getCompletedRepeatsCount(for habit: Habit, on date: Date) -> Int {
        return HabitUtilities.getCompletedRepeatsCount(for: habit, on: date)
    }
    
    // MARK: - Cache Management
    
    /// Smart cache invalidation for interval habits
    private func invalidateCacheForIntervalHabit(habit: Habit, completionDate: Date) {
        guard let habitID = habit.id?.uuidString else { return }
        
        // Get the repeat pattern
        guard let repeatPatterns = habit.repeatPattern as? Set<RepeatPattern>,
              let currentPattern = repeatPatterns.first,
              let dailyGoal = currentPattern.dailyGoal else {
            return // No pattern, no invalidation needed
        }
        
        let daysInterval = Int(dailyGoal.daysInterval)
        let isFollowupHabit = currentPattern.followUp
        
        // OPTIMIZATION 1: Only process followup habits with intervals > 1
        guard isFollowupHabit && daysInterval > 1 else {
            return // Skip daily habits and regular interval habits
        }
        
        // OPTIMIZATION 2: Only clear future dates (no past dates)
        let normalizedDate = calendar.startOfDay(for: completionDate)
        
        // Clear current completion day
        let currentDateKey = normalizedDate.timeIntervalSince1970
        HabitUtilities.clearCacheKey("\(habitID)-\(currentDateKey)")
        
        // Clear future dates - conservative range
        let maxFutureDays = min(daysInterval * 2, 14) // Cap at 2 intervals or 14 days max
        
        for dayOffset in 1...maxFutureDays {
            if let futureDate = calendar.date(byAdding: .day, value: dayOffset, to: completionDate) {
                let futureDateKey = calendar.startOfDay(for: futureDate).timeIntervalSince1970
                HabitUtilities.clearCacheKey("\(habitID)-\(futureDateKey)")
            }
        }
        
        // Clear general activity cache (lightweight)
        HabitUtilities.clearHabitActivityCache()
    }
    
    // MARK: - Rest of existing methods
    
    // MARK: - 🆕 UPDATED: Force complete a habit with Total Completions
    func forceCompleteHabit(_ habit: Habit, on date: Date) {
            let dayOfDate = calendar.startOfDay(for: date)
            let repeatsPerDay = HabitUtilities.getRepeatsPerDay(for: habit, on: dayOfDate)
            let currentCompletions = HabitUtilities.getCompletedRepeatsCount(for: habit, on: dayOfDate)
            
            // Add completions until we reach the target
            for _ in currentCompletions..<repeatsPerDay {
                let newCompletion = Completion(context: viewContext)
                // NEW: Use exact timestamp
                newCompletion.date = date
                newCompletion.completed = true
                // NEW: Track when it was logged
                newCompletion.loggedAt = Date()
                habit.addToCompletion(newCompletion)
                
                // INCREMENT total completions
                habit.totalCompletions += 1
            }
            
            // Update lastCompletionDate if needed
            if dayOfDate > (habit.lastCompletionDate ?? Date.distantPast) {
                habit.lastCompletionDate = dayOfDate
            }
            
            // Save changes
            do {
                try viewContext.save()
                HabitUtilities.clearHabitActivityCache()
                print("✅ Force completed habit '\(habit.name ?? "Unknown")' - Total completions: \(habit.totalCompletions)")
                
                // 🔄 Trigger view updates
                completionVersion = UUID()
            } catch {
                print("Error forcing habit completion: \(error)")
                viewContext.rollback()
            }
        }
    
    // MARK: - 🆕 UPDATED: Add a single completion with Total Completions
    func addSingleCompletion(for habit: Habit, on date: Date, tracksTime: Bool = false) -> Int {
        let normalizedDate = calendar.startOfDay(for: date)
                let dayKey = DayKeyFormatter.localKey(from: date)  // ✅ Generate dayKey
                let repeatsPerDay = HabitUtilities.getRepeatsPerDay(for: habit, on: normalizedDate)
                let currentCompletions = HabitUtilities.getCompletedRepeatsCount(for: habit, on: normalizedDate)
                
                if currentCompletions < repeatsPerDay {
                    // Create a new completion
                    let newCompletion = Completion(context: viewContext)
                    newCompletion.date = date
                    newCompletion.completed = true
                    newCompletion.loggedAt = Date()
                    newCompletion.tracksTime = tracksTime
                    newCompletion.dayKey = dayKey  // ✅ Set dayKey
                    habit.addToCompletion(newCompletion)
                    
                    // INCREMENT total completions
                    habit.totalCompletions += 1
                    
                    // Update lastCompletionDate if needed
                    if normalizedDate > (habit.lastCompletionDate ?? Date.distantPast) {
                        habit.lastCompletionDate = normalizedDate
                    }
                    
                    // Save
                    do {
                        try viewContext.save()
                        HabitUtilities.clearHabitActivityCache()
                        print("✅ Added completion with dayKey: \(dayKey)")
                        
                        // 🔄 Trigger view updates
                        completionVersion = UUID()
                        
                        return currentCompletions + 1
                    } catch {
                        print("Error adding completion: \(error)")
                        viewContext.rollback()
                        return currentCompletions
                    }
                }
                
                return currentCompletions
        }
    
    // MARK: - Remove a single completion
    func removeSingleCompletion(for habit: Habit, on date: Date) -> Int {
        let normalizedDate = calendar.startOfDay(for: date)
        let dayKey = DayKeyFormatter.localKey(from: date)
        let currentCompletions = HabitUtilities.getCompletedRepeatsCount(for: habit, on: normalizedDate)
        
        if currentCompletions > 0 {
            // Find and remove the most recent completion for this date
            let request = NSFetchRequest<Completion>(entityName: "Completion")
            request.predicate = NSPredicate(
                format: "dayKey == %@ AND habit == %@ AND completed == YES",
                dayKey, habit
            )
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Completion.loggedAt, ascending: false)]
            request.fetchLimit = 1
            
            do {
                let completions = try viewContext.fetch(request)
                if let completionToRemove = completions.first {
                    viewContext.delete(completionToRemove)
                    
                    // Decrement total completions
                    habit.totalCompletions = max(0, habit.totalCompletions - 1)
                    
                    // Update lastCompletionDate if needed
                    if currentCompletions == 1 {
                        // This was the last completion for the day, find previous completion date
                        habit.lastCompletionDate = habit.findMostRecentCompletion(before: date)?.date
                    }
                    
                    // Save
                    try viewContext.save()
                    HabitUtilities.clearHabitActivityCache()
                    print("✅ Removed completion with dayKey: \(dayKey)")
                    
                    // 🔄 Trigger view updates
                    completionVersion = UUID()
                    
                    return currentCompletions - 1
                }
            } catch {
                print("Error removing completion: \(error)")
                viewContext.rollback()
            }
        }
        
        return currentCompletions
    }
    
    /// Check if habit has reached its completion target for the day
    func hasReachedCompletionTarget(for habit: Habit, on date: Date) -> Bool {
            let dayOfDate = calendar.startOfDay(for: date)
            let repeatsPerDay = HabitUtilities.getRepeatsPerDay(for: habit, on: dayOfDate)
            let currentCompletions = HabitUtilities.getCompletedRepeatsCount(for: habit, on: dayOfDate)
            
            return currentCompletions >= repeatsPerDay
        }
    
    // MARK: - Convenience Functions
    
    /// Convenience method for simple toggle without data manager
    @MainActor func toggleCompletion(for habit: Habit, on date: Date = Date()) {
        toggleCompletion(for: habit, on: date, dataManager: nil as AnyObject?)
    }
    
    /// Check if today is completed
    func isTodayCompleted(_ habit: Habit) -> Bool {
        return isHabitCompletedForDate(habit, on: Date())
    }
    
    /// Toggle today's completion
    @MainActor func toggleTodayCompletion(for habit: Habit) {
        toggleCompletion(for: habit, on: Date())
    }
}

extension HabitUtilities {
    /*
    static func getCompletedRepeatsCount(for habit: Habit, on date: Date) -> Int {
            guard let completions = habit.completion as? Set<Completion> else { return 0 }
            
            let calendar = Calendar.current
            let targetDay = calendar.startOfDay(for: date)
            
            return completions.filter { completion in
                guard let completionDate = completion.date, completion.completed else { return false }
                // Compare by day since completion.date now has full timestamp
                let completionDay = calendar.startOfDay(for: completionDate)
                return calendar.isDate(completionDay, inSameDayAs: targetDay)
            }.count
        }
    
    // OPTIMIZATION: Add memoization for repeatsPerDay within the same day
    private static var repeatsPerDayCache: [String: Int] = [:]
    private static let calendar = Calendar.current
    
    static func getRepeatsPerDay(for habit: Habit, on date: Date) -> Int {
        // Create cache key
        let normalizedDate = calendar.startOfDay(for: date)
        let cacheKey = "\(habit.id?.uuidString ?? "unknown")-\(normalizedDate.timeIntervalSince1970)-repeats"
        
        // Check cache first
        if let cachedValue = repeatsPerDayCache[cacheKey] {
            return cachedValue
        }
        
        // Calculate and cache
        guard let repeatPattern = getEffectiveRepeatPattern(for: habit, on: date) else {
            repeatsPerDayCache[cacheKey] = 1
            return 1
        }
        
        let result = max(1, Int(repeatPattern.repeatsPerDay))
        repeatsPerDayCache[cacheKey] = result
        return result
    }
    
    // OPTIMIZATION: Clear repeats cache when needed
    static func clearRepeatsPerDayCache() {
        repeatsPerDayCache.removeAll()
    }
     */
}
