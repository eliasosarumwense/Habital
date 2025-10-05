
import SwiftUI
import Combine

class SharedLevelData: ObservableObject {
    @Published var levelData = UserLevelData(totalXP: 0)
    
    static let shared = SharedLevelData()
    
    private init() {}
    
    func addXPForHabitCompletion(habit: Habit, isCompleted: Bool, isUncompleting: Bool = false, onDate: Date = Date()) {
        // Calculate streak based on the specific date, not always today
        let streak = habit.calculateStreak(upTo: onDate)
        let baseXP = UserLevelData.BASE_XP_PER_COMPLETION
        
        // Get the multiplier based on streak at that time
        let streakMultiplier = calculateXPMultiplier(for: streak)
        
        // Get intensity multiplier based on habit's intensity level
        let intensityMultiplier = calculateIntensityMultiplier(for: habit.intensityLevel)
        
        // Combined multiplier (streak × intensity)
        let totalMultiplier = streakMultiplier * intensityMultiplier
        
        if habit.isBadHabit {
            if isUncompleting {
                // Uncompleting a bad habit - remove the penalty that was applied when it was marked complete
                // We need to ADD 100 XP because the penalty was -100 XP
                levelData.addXP(100, habit: habit, isReversing: true)
            } else if isCompleted {
                // Completing a bad habit (marking it as broken) means -100 XP penalty
                // Apply intensity multiplier to the penalty as well
                let penalty = -100 * Int(intensityMultiplier)
                levelData.addXP(penalty, habit: habit)
            }
        } else { // Good habit
            if isUncompleting {
                // Uncompleting a good habit means removing the XP that was awarded
                let xpToDeduct = -Int(Double(baseXP) * totalMultiplier)
                levelData.addXP(xpToDeduct, habit: habit, isReversing: true)
            } else if isCompleted {
                // Completing a good habit means awarding XP with both streak and intensity multipliers
                let xpEarned = Int(Double(baseXP) * totalMultiplier)
                levelData.addXP(xpEarned, habit: habit)
            }
        }
    }

    // Add a new helper function to calculate intensity multiplier
    private func calculateIntensityMultiplier(for intensityLevel: Int16) -> Double {
        switch intensityLevel {
        case 1: // Light
            return 1.0
        case 2: // Moderate
            return 1.5
        case 3: // High
            return 2.0
        case 4: // Extreme
            return 3.0
        default:
            return 1.0 // Default to Light if unknown
        }
    }

    // Helper function to calculate multiplier
    private func calculateXPMultiplier(for streak: Int) -> Double {
        if streak >= 100 {
            return 10.0
        } else if streak >= 50 {
            return 5.0
        } else if streak >= 40 {
            return 4.0
        } else if streak >= 30 {
            return 3.0
        } else if streak >= 20 {
            return 2.0
        } else if streak >= 10 {
            return 1.5
        } else {
            return 1.0
        }
    }
    
    func cleanupDuplicateBadHabitEntries() {
        // Get today's date normalized
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Filter out any duplicate entries for bad habits completed today
        let filteredGains = levelData.recentXPGains.enumerated().filter { (index, gain) in
            // Keep the entry if it's:
            // 1. Not a bad habit, OR
            // 2. Not from today, OR
            // 3. Is the first occurrence of this bad habit for today
            if gain.habit.isBadHabit && calendar.isDate(gain.date, inSameDayAs: today) {
                // Check if this is the first occurrence of this bad habit today
                let earlierEntry = levelData.recentXPGains.prefix(index).contains { earlier in
                    return earlier.habit.id == gain.habit.id &&
                           calendar.isDate(earlier.date, inSameDayAs: today)
                }
                return !earlierEntry
            }
            return true
        }.map { $0.element }
        
        // Update the filtered list
        levelData.recentXPGains = filteredGains
    }
    
    func cleanupAndResetXP(from habits: [Habit]) {
        print("DEBUG: Cleaning up and resetting XP from scratch")
        
        // This will clear all XP and recalculate from all habit completions
        recalculateAllXP(from: habits)
        
        // You could also manually inspect/fix bad habit completions here if needed
        print("DEBUG: Final XP after reset: \(levelData.totalXP)")
    }
    
    func recalculateAllXP(from habits: [Habit]) {
        // Reset XP to 0
        levelData = UserLevelData(totalXP: 0)
        
        var totalXP = 0
        
        for habit in habits {
            guard let completions = habit.completion as? Set<Completion>,
                  !completions.isEmpty else { continue }
            
            // Process each completion
            for completion in completions {
                guard let completionDate = completion.date, completion.completed else { continue }
                
                // Get the streak at the time of completion
                let streak = habit.calculateStreak(upTo: completionDate)
                
                // Calculate streak multiplier
                let streakMultiplier = calculateXPMultiplier(for: streak)
                
                // Calculate intensity multiplier
                let intensityMultiplier = calculateIntensityMultiplier(for: habit.intensityLevel)
                
                // Combined multiplier
                let totalMultiplier = streakMultiplier * intensityMultiplier
                
                // Calculate XP for this completion
                let baseXP = UserLevelData.BASE_XP_PER_COMPLETION
                
                // For bad habits, apply a penalty of -100 XP when "completed" (i.e., broken)
                let xpEarned: Int
                if habit.isBadHabit {
                    // Apply intensity multiplier to the penalty as well
                    xpEarned = -100 * Int(intensityMultiplier)
                } else {
                    xpEarned = Int(Double(baseXP) * totalMultiplier)
                }
                
                totalXP += xpEarned
            }
        }
        
        // Update the level data without animation
        levelData.totalXP = max(0, totalXP) // Ensure XP doesn't go below 0
        levelData.updateCalculations()
    }
}

