//
//  OldHabitEngine.swift
//  Habital
//
//  Created by Elias Osarumwense on 29.10.25.
//


//
//  HabitAutomationEngine.swift
//  Habital
//
//  Created by Elias Osarumwense on 15.08.25.
//  Enhanced with scientific habit strength model and bad-habit handling
//

import Foundation
import CoreData

// MARK: - Configuration
struct HabitAutomationConfig {
    var timeZone: TimeZone = .current
    var dayStartHour: Int = 4 // 4 AM to avoid midnight artifacts
    var analysisEnd: Date = Date()
    
    // Habit strength model parameters (based on Lally et al., 2010)
    var habitGrowthRate: Double = 0.08      // k: Growth rate during streaks
    var habitDecayRate: Double = 0.03       // λ: Decay rate during gaps
    var residualMemoryFactor: Double = 0.15 // Minimum retained strength (15% of peak)
    var maxHabitStrength: Double = 1.0      // Maximum achievable strength
    
    // Intensity adjustment parameters
    var intensityPenaltyPerLevel: Double = 0.1
    
    // Soft drift for non-scheduled periods
    var softDriftRate: Double = 0.002       // λ_soft for non-scheduled gaps
}

// MARK: - Bad Habit Parameters
private struct BadHabitParams {
    let k_ext: Double        // Extinction: control growth when avoided (per scheduled opportunity)
    let lambda_reinst: Double// Reinstatement: control drop on lapse (per scheduled opportunity)
    let floor_min: Double    // Minimal residual control floor (baseline)
    let softDrift: Double    // Tiny drift per non-scheduled day (context instability)
}

private func badParams(for level: Int) -> BadHabitParams {
    switch max(1, min(4, level)) {
    case 1: return .init(k_ext: 0.09,  lambda_reinst: 0.06, floor_min: 0.25, softDrift: 0.002)
    case 2: return .init(k_ext: 0.07,  lambda_reinst: 0.08, floor_min: 0.20, softDrift: 0.002)
    case 3: return .init(k_ext: 0.05,  lambda_reinst: 0.10, floor_min: 0.15, softDrift: 0.003)
    default:return .init(k_ext: 0.035, lambda_reinst: 0.12, floor_min: 0.10, softDrift: 0.003)
    }
}

// MARK: - Calendar Extension for Custom Day Boundary
private extension Calendar {
    func startOfCustomDay(_ date: Date, tz: TimeZone, startHour: Int) -> Date {
        var cal = self
        cal.timeZone = tz
        let shifted = cal.date(byAdding: .hour, value: -startHour, to: date)!
        let sod = cal.startOfDay(for: shifted)
        return cal.date(byAdding: .hour, value: startHour, to: sod)!
    }
}

// MARK: - Utility Functions
@inline(__always)
private func clamp(_ x: Double, _ lo: Double = 0, _ hi: Double = 1) -> Double {
    min(hi, max(lo, x))
}

// MARK: - Intensity Mapping Helpers (1=light … 4=extreme)
@inline(__always) 
private func I_g(_ L: Int) -> Double { pow(0.88, Double(L-1)) }           // growth ↓ with intensity

@inline(__always) 
private func I_d(_ L: Int) -> Double { 1.0 + 0.12*Double(L-1) }           // decay ↑ with intensity

@inline(__always) 
private func I_sd(_ L: Int) -> Double { 1.0 + 0.10*Double(L-1) }          // soft drift ↑ with intensity

@inline(__always) 
private func I_rho(_ L: Int) -> Double { [0.20, 0.17, 0.15, 0.12][max(0, min(3, L-1))] }  // residual memory floor

@inline(__always) 
private func I_alpha(_ L: Int) -> Double { [0.0025,0.002,0.0015,0.001][max(0, min(3, L-1))] } // experience floor slope

@inline(__always) 
private func I_m1(_ L: Int) -> Double { [0.40,0.50,0.60,0.70][max(0, min(3, L-1))] }      // lighter first miss

// Exact growth for n consecutive completed scheduled instances
@inline(__always)
private func grow(from h0: Double, toward hMax: Double, k: Double, n: Int) -> Double {
    let n = max(0, n)
    return hMax - (hMax - h0) * exp(-k * Double(n))
}

// Exact decay for n consecutive missed scheduled instances with floor
@inline(__always)
private func decay(from h0: Double, lambda: Double, n: Int, floor: Double) -> Double {
    let n = max(0, n)
    let h = h0 * exp(-lambda * Double(n))
    return max(floor, h)
}

// Bad habit specific functions
@inline(__always)
private func avoidanceGrowth(C: Double, k_ext: Double) -> Double {
    // C_next = 1 - (1 - C) * exp(-k_ext)
    return clamp(1.0 - (1.0 - C) * exp(-k_ext), 0, 1)
}

@inline(__always)
private func lapseReinstatement(C: Double, lambda: Double, floor: Double) -> Double {
    // C_next = max(floor, C * exp(-lambda))
    return clamp(max(floor, C * exp(-lambda)), floor, 1.0)
}

// MARK: - Bad Habit Floor Calculation
private func badHabitFloor(
    params: BadHabitParams,
    totalAvoidedScheduledDays: Int,
    peakControl: Double,
    residualMemoryFactor: Double
) -> Double {
    // For bad habits, experience floor only applies when you've actually avoided the habit
    // When nothing has been avoided yet, use the baseline floor_min appropriate for intensity level
    if totalAvoidedScheduledDays > 0 {
        let experienceFloor = min(0.50, 0.05 + 0.002 * Double(totalAvoidedScheduledDays))
        return max(params.floor_min, experienceFloor, peakControl * residualMemoryFactor)
    } else {
        // No avoidance experience yet - use baseline floor for this intensity level
        return max(params.floor_min, peakControl * residualMemoryFactor)
    }
}

// MARK: - Habit History Tracking
struct HabitStrengthPoint {
    let date: Date
    let strength: Double
    let isStreak: Bool // true = in streak, false = in gap
    let streakLength: Int // Current streak length at this point
}

struct HabitHistoryAnalysis {
    let strengthHistory: [HabitStrengthPoint]
    let currentStrength: Double
    let peakStrength: Double
    let totalStreakDays: Int
    let totalGapDays: Int
    let longestStreak: Int // From habit.calculateLongestStreak()
    let currentStreak: Int  // From habit.calculateStreak()
    let bestStreakEver: Int // From habit.bestStreakEver Core Data attribute
    let averageStreakLength: Double
    let recoveryPotential: Double // How much strength can be quickly recovered
    let experienceFloor: Double // Experience-based minimum strength
}

// MARK: - Data Models
struct HabitAutomationInsight {
    let habitId: UUID
    let habitName: String
    let analysisDate: Date
    
    // Core automation metrics
    let automationPercentage: Double        // 0.0 - 100.0
    let currentStreak: Int                  // From Core Data via habit.calculateStreak()
    let bestStreakEver: Int                 // From Core Data habit.bestStreakEver
    let expectedCompletions: Int
    let actualCompletions: Int
    
    // Component breakdown for debugging
    let rawCompletionRate: Double
    let streakMultiplier: Double
    let intensityWeight: Double
    let timeFactor: Double
    
    // History analysis
    let historyAnalysis: HabitHistoryAnalysis?
    
    // Predictive insights
    let predictions: HabitPredictions?
}

// MARK: - Predictive Models
struct HabitPredictions {
    let oneWeekAutomation: Double
    let twoWeekAutomation: Double
    let oneMonthAutomation: Double
    let estimatedDaysTo95Percent: Int?
    let estimatedDaysTo100Percent: Int?
    let estimatedCompletionsTo95Percent: Int?
    let estimatedCompletionsTo100Percent: Int?
    let trend: CompletionTrend
    let guidanceMessage: String
    let trendFactor: Double // Growth rate per day
    let repeatPatternDescription: String
}

enum CompletionTrend {
    case improving
    case stable
    case declining
    
    var color: String {
        switch self {
        case .improving: return "green"
        case .stable: return "blue"
        case .declining: return "orange"
        }
    }
    
    var icon: String {
        switch self {
        case .improving: return "arrow.up.right.circle.fill"
        case .stable: return "equal.circle.fill"
        case .declining: return "arrow.down.right.circle.fill"
        }
    }
}

// MARK: - Main Analytics Engine
class HabitAutomationEngine {
    private let config: HabitAutomationConfig
    private let context: NSManagedObjectContext
    
    init(config: HabitAutomationConfig = HabitAutomationConfig(), context: NSManagedObjectContext) {
        self.config = config
        self.context = context
    }
    
    // MARK: - Public API
    func calculateAutomationPercentage(habit: Habit) -> HabitAutomationInsight {
        // Step 1: Build complete habit history and calculate strength
        let historyAnalysis = analyzeFullHabitHistory(habit: habit)
        
        // Step 2: Current automation is the current strength as percentage
        let automationPercentage = min(100.0, historyAnalysis.currentStrength * 100.0)
        
        // Step 3: Get completion metrics using unified source of truth
        let (expectedCompletions, actualCompletions) = scheduledStats(
            habit: habit,
            from: habit.startDate ?? Date(),
            to: config.analysisEnd
        )
        
        let rawCompletionRate = expectedCompletions > 0 ? Double(actualCompletions) / Double(expectedCompletions) : 0
        
        // Step 4: Calculate intensity weight with clamping
        let intensityWeight = clamp(
            1.0 - (config.intensityPenaltyPerLevel * Double(max(0, habit.intensityLevel - 1))),
            0.2,
            1.0
        )
        
        // Step 5: Generate predictions based on history
        let predictions = calculateHistoryAwarePredictions(
            habit: habit,
            historyAnalysis: historyAnalysis
        )
        
        // Return comprehensive insight using Core Data values
        return HabitAutomationInsight(
            habitId: habit.id ?? UUID(),
            habitName: habit.name ?? "Unnamed Habit",
            analysisDate: config.analysisEnd,
            automationPercentage: automationPercentage,
            currentStreak: historyAnalysis.currentStreak,
            bestStreakEver: historyAnalysis.bestStreakEver,
            expectedCompletions: expectedCompletions,
            actualCompletions: actualCompletions,
            rawCompletionRate: rawCompletionRate,
            streakMultiplier: 1.0, // Now incorporated into strength calculation
            intensityWeight: intensityWeight,
            timeFactor: historyAnalysis.currentStrength, // Strength itself represents time factor
            historyAnalysis: historyAnalysis,
            predictions: predictions
        )
    }
    
    // MARK: - Single Source of Truth for Counting
    private func scheduledStats(habit: Habit, from start: Date, to end: Date) -> (expected: Int, actual: Int) {
        precondition(start <= end, "Start date must be before or equal to end date")
        
        let cal = Calendar.current
        var d = cal.startOfCustomDay(start, tz: config.timeZone, startHour: config.dayStartHour)
        let endBoundary = cal.startOfCustomDay(end, tz: config.timeZone, startHour: config.dayStartHour)
        
        var expected = 0
        var actual = 0
        
        // Use half-open range [start, end)
        while d < endBoundary {
            if HabitUtilities.isHabitActive(habit: habit, on: d) {
                expected += 1
                if habit.isCompleted(on: d) {
                    actual += 1
                }
            }
            d = cal.date(byAdding: .day, value: 1, to: d)!
        }
        
        return (expected, actual)
    }
    
    // MARK: - Full History Analysis with Closed-Form Calculations
    private func analyzeFullHabitHistory(habit: Habit) -> HabitHistoryAnalysis {
        guard let startDate = habit.startDate else {
            return HabitHistoryAnalysis(
                strengthHistory: [],
                currentStrength: 0,
                peakStrength: 0,
                totalStreakDays: 0,
                totalGapDays: 0,
                longestStreak: 0,
                currentStreak: 0,
                bestStreakEver: Int(habit.bestStreakEver),
                averageStreakLength: 0,
                recoveryPotential: 0,
                experienceFloor: 0.05
            )
        }
        
        let calendar = Calendar.current
        var currentDate = calendar.startOfCustomDay(startDate, tz: config.timeZone, startHour: config.dayStartHour)
        let endDate = calendar.startOfCustomDay(config.analysisEnd, tz: config.timeZone, startHour: config.dayStartHour)
        
        // For same-day creation, ensure we process at least that day
        let effectiveEndDate = currentDate == endDate ? 
            calendar.date(byAdding: .day, value: 1, to: endDate)! : endDate
        
        // Handle newly created bad habits (same-day creation with no history)
        if habit.isBadHabit && currentDate == endDate {
            let params = badParams(for: Int(habit.intensityLevel))
            let baselineStrength = params.floor_min
            
            // Return early with baseline strength for new bad habits
            return HabitHistoryAnalysis(
                strengthHistory: [HabitStrengthPoint(
                    date: currentDate,
                    strength: baselineStrength,
                    isStreak: false,
                    streakLength: 0
                )],
                currentStrength: baselineStrength,
                peakStrength: baselineStrength,
                totalStreakDays: 0,
                totalGapDays: 0,
                longestStreak: habit.calculateLongestStreak(),
                currentStreak: habit.calculateStreak(upTo: config.analysisEnd),
                bestStreakEver: Int(habit.bestStreakEver),
                averageStreakLength: 0,
                recoveryPotential: 0,
                experienceFloor: params.floor_min
            )
        }
        
        // Initialize habit strength based on type
        var habitStrength: Double
        if habit.isBadHabit {
            // Bad habits start with baseline control level, not zero
            let params = badParams(for: Int(habit.intensityLevel))
            habitStrength = params.floor_min
        } else {
            // Good habits start at zero
            habitStrength = 0.0
        }
        var peakStrength: Double = habitStrength
        var strengthHistory: [HabitStrengthPoint] = []
        
        var totalStreakDays = 0
        var totalGapDays = 0
        var streakCount = 0
        var totalStreakLengths = 0
        
        // Track state for analysis
        var nonScheduledGapDays = 0
        var isInStreak = false
        var currentStreakLength = 0
        var consecutiveMisses = 0 // Track consecutive scheduled misses for intensity adjustment
        
        let L = Int(habit.intensityLevel)
        let growthRate = clamp(config.habitGrowthRate * I_g(L), 0.005, 0.20)
        let baseDecayRate = clamp(config.habitDecayRate * I_d(L), 0.001, 0.25)
        
        // Use half-open range iteration
        while currentDate < effectiveEndDate {
            let wasScheduled = HabitUtilities.isHabitActive(habit: habit, on: currentDate)
            
            if wasScheduled {
                // Reset non-scheduled gap counter
                if nonScheduledGapDays > 3 {
                    if habit.isBadHabit {
                        // Apply soft drift for bad habits during non-scheduled periods
                        let params = badParams(for: Int(habit.intensityLevel))
                        let λ_soft_eff = params.softDrift * I_sd(L)
                        let C_floor = badHabitFloor(
                            params: params,
                            totalAvoidedScheduledDays: totalStreakDays,
                            peakControl: peakStrength,
                            residualMemoryFactor: config.residualMemoryFactor
                        )
                        habitStrength = max(C_floor, habitStrength * exp(-λ_soft_eff * Double(nonScheduledGapDays)))
                        habitStrength = clamp(habitStrength, C_floor, config.maxHabitStrength)
                    } else {
                        // Apply soft drift for good habits
                        let λ_soft_eff = config.softDriftRate * I_sd(L)
                        let rho = I_rho(L)
                        let alpha = I_alpha(L)
                        let residualFloor = rho * peakStrength
                        let experienceFloor = clamp(0.05 + alpha * Double(totalStreakDays), 0.05, 0.50)
                        let minStrength = max(residualFloor, experienceFloor)
                        habitStrength = max(minStrength, habitStrength * exp(-λ_soft_eff * Double(nonScheduledGapDays)))
                    }
                }
                nonScheduledGapDays = 0
                
                if habit.isBadHabit {
                    // BAD-HABIT PATH (control-strength C)
                    let params = badParams(for: Int(habit.intensityLevel))
                    
                    // Recompute floor using current totals & peak
                    let C_floor = badHabitFloor(
                        params: params,
                        totalAvoidedScheduledDays: totalStreakDays,
                        peakControl: peakStrength,
                        residualMemoryFactor: config.residualMemoryFactor
                    )
                    
                    let avoided = habit.isCompleted(on: currentDate) // model already inverts meaning for bad habits
                    if avoided {
                        // Success: avoided the bad habit during the window
                        let k_ext_eff = clamp(params.k_ext * I_g(L), 0.01, 0.20)
                        habitStrength = avoidanceGrowth(C: habitStrength, k_ext: k_ext_eff)
                        totalStreakDays += 1 // count days of successful avoidance (days free from bad habit)
                        currentStreakLength += 1
                        
                        // Check if we're entering a new streak
                        let wasInStreak = isInStreak
                        isInStreak = true
                        if !wasInStreak {
                            streakCount += 1
                        }
                    } else {
                        // Lapse: performed the bad habit
                        let λ_reinst_eff = clamp(params.lambda_reinst * I_d(L), 0.03, 0.25)
                        habitStrength = lapseReinstatement(C: habitStrength, lambda: λ_reinst_eff, floor: C_floor)
                        totalGapDays += 1
                        
                        if isInStreak {
                            isInStreak = false
                            totalStreakLengths += currentStreakLength
                            currentStreakLength = 0
                        }
                    }
                    
                    habitStrength = clamp(habitStrength, C_floor, config.maxHabitStrength)
                    peakStrength = max(peakStrength, habitStrength)
                    
                } else {
                    // GOOD-HABIT PATH (keep existing logic)
                    let wasCompleted = habit.isCompleted(on: currentDate)
                    
                    // Compute experience-based floor (dynamic residual floor)
                    let experienceFloor = min(0.50, 0.05 + 0.002 * Double(totalStreakDays))
                    
                    if wasCompleted {
                        // Start or continue streak
                        if !isInStreak {
                            isInStreak = true
                            currentStreakLength = 0
                            streakCount += 1
                        }
                        
                        currentStreakLength += 1
                        totalStreakDays += 1
                        consecutiveMisses = 0 // Reset consecutive misses on completion
                        
                        // Apply growth using asymptotic model with τ mapping (per-day update only)
                        habitStrength = applyAsymptoticGrowth(
                            previousStrength: habitStrength,
                            streakDay: currentStreakLength,
                            growthRate: growthRate
                        )
                        
                        // Apply safety rails
                        habitStrength = clamp(habitStrength, 0, config.maxHabitStrength)
                        peakStrength = max(peakStrength, habitStrength)
                        
                    } else {
                        // End streak if in one
                        if isInStreak {
                            isInStreak = false
                            totalStreakLengths += currentStreakLength
                            currentStreakLength = 0
                        }
                        
                        consecutiveMisses += 1
                        totalGapDays += 1
                        
                        // Apply intensity-adjusted decay with humane first miss
                        let λ_eff: Double
                        if consecutiveMisses == 1 {
                            λ_eff = clamp(baseDecayRate * I_m1(L), 0.001, 0.25)
                        } else if consecutiveMisses == 2 {
                            λ_eff = baseDecayRate
                        } else {
                            λ_eff = clamp(baseDecayRate * 1.25, 0.001, 0.25)
                        }
                        
                        // Compute floors using intensity mapping
                        let rho = I_rho(L)
                        let alpha = I_alpha(L)
                        let residualFloor = rho * peakStrength
                        let experienceFloor = clamp(0.05 + alpha * Double(totalStreakDays), 0.05, 0.50)
                        let minStrength = max(residualFloor, experienceFloor)
                        
                        habitStrength = decay(from: habitStrength, lambda: λ_eff, n: 1, floor: minStrength)
                        habitStrength = clamp(habitStrength, 0, config.maxHabitStrength)
                    }
                }
                
                // Record strength point for history
                strengthHistory.append(HabitStrengthPoint(
                    date: currentDate,
                    strength: habitStrength,
                    isStreak: isInStreak,
                    streakLength: currentStreakLength
                ))
            } else {
                // Non-scheduled day
                nonScheduledGapDays += 1
                if habit.isBadHabit && nonScheduledGapDays > 3 {
                    let params = badParams(for: Int(habit.intensityLevel))
                    let λ_soft_eff = params.softDrift * I_sd(L)
                    // Soft drift toward floor (very small effect)
                    let C_floor = badHabitFloor(
                        params: params,
                        totalAvoidedScheduledDays: totalStreakDays,
                        peakControl: peakStrength,
                        residualMemoryFactor: config.residualMemoryFactor
                    )
                    habitStrength = max(C_floor, habitStrength * exp(-λ_soft_eff * Double(nonScheduledGapDays)))
                    habitStrength = clamp(habitStrength, C_floor, config.maxHabitStrength)
                }
            }
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        
        // If we ended in a streak, add it to the total
        if isInStreak {
            totalStreakLengths += currentStreakLength
        }
        
        // Update experience floor based on total streak days using intensity mapping
        let finalExperienceFloor: Double
        if habit.isBadHabit {
            // For bad habits, use the appropriate baseline floor for intensity level
            let params = badParams(for: L)
            if totalStreakDays > 0 {
                // Once avoidance experience exists, use experience-based floor
                let experienceFloor = min(0.50, 0.05 + 0.002 * Double(totalStreakDays))
                finalExperienceFloor = max(params.floor_min, experienceFloor)
            } else {
                // No avoidance experience yet - use baseline floor for this intensity level
                finalExperienceFloor = params.floor_min
            }
        } else {
            // For good habits, use intensity-mapped experience floor
            let alpha = I_alpha(L)
            finalExperienceFloor = clamp(0.05 + alpha * Double(totalStreakDays), 0.05, 0.50)
        }
        
        let averageStreakLength = streakCount > 0 ? Double(totalStreakLengths) / Double(streakCount) : 0
        let recoveryPotential = peakStrength - habitStrength
        
        // Use Core Data attributes for streak values
        let actualCurrentStreak = habit.calculateStreak(upTo: config.analysisEnd)
        let historicalLongestStreak = habit.calculateLongestStreak()
        let bestStreakEver = Int(habit.bestStreakEver)
        
        return HabitHistoryAnalysis(
            strengthHistory: strengthHistory,
            currentStrength: habitStrength,
            peakStrength: peakStrength,
            totalStreakDays: totalStreakDays,
            totalGapDays: totalGapDays,
            longestStreak: historicalLongestStreak,
            currentStreak: actualCurrentStreak,
            bestStreakEver: bestStreakEver,
            averageStreakLength: averageStreakLength,
            recoveryPotential: recoveryPotential,
            experienceFloor: finalExperienceFloor
        )
    }
    
    // MARK: - Growth Model with Asymptotic τ Mapping
    private func dailyIncrement(current: Double, maxStrength: Double, tauDays: Double) -> Double {
        // One scheduled completion increment
        let k = max(1.0 / max(tauDays, 5.0), 0.01)
        return (maxStrength - current) * (1 - exp(-k))
    }
    
    private func applyAsymptoticGrowth(
        previousStrength: Double,
        streakDay: Int,
        growthRate: Double
    ) -> Double {
        // Map growthRate to tau (inverse relationship)
        let tau = max(5.0, 1.0 / max(growthRate, 0.005))
        let inc = dailyIncrement(current: previousStrength, maxStrength: config.maxHabitStrength, tauDays: tau)
        return clamp(previousStrength + inc, 0, config.maxHabitStrength)
    }
    
    // MARK: - History-Aware Predictions
    private func calculateHistoryAwarePredictions(
        habit: Habit,
        historyAnalysis: HabitHistoryAnalysis
    ) -> HabitPredictions {
        let L = Int(habit.intensityLevel)
        let growthRate = habit.isBadHabit ?
            clamp(badParams(for: L).k_ext * I_g(L), 0.01, 0.20) :
            clamp(config.habitGrowthRate * I_g(L), 0.005, 0.20)
        
        // Get repeat pattern description for context
        let repeatPatternDescription = getRepeatPatternDescription(for: habit)
        
        // Project future strength assuming consistent completion
        let oneWeekStrength = projectFutureStrength(
            current: historyAnalysis.currentStrength,
            daysAhead: 7,
            growthRate: growthRate,
            habit: habit
        )
        
        let twoWeekStrength = projectFutureStrength(
            current: historyAnalysis.currentStrength,
            daysAhead: 14,
            growthRate: growthRate,
            habit: habit
        )
        
        let oneMonthStrength = projectFutureStrength(
            current: historyAnalysis.currentStrength,
            daysAhead: 30,
            growthRate: growthRate,
            habit: habit
        )
        
        // Estimate days and completions to targets
        let (daysTo95, completionsTo95) = estimateDaysAndCompletionsToTarget(
            currentStrength: historyAnalysis.currentStrength,
            targetStrength: 0.95,
            growthRate: growthRate,
            habit: habit
        )
        
        let (daysTo100, completionsTo100) = estimateDaysAndCompletionsToTarget(
            currentStrength: historyAnalysis.currentStrength,
            targetStrength: 1.0,
            growthRate: growthRate,
            habit: habit
        )
        
        // Determine trend using scheduled-aware analysis
        let trend = analyzeCompletionTrend(habit: habit)
        
        // Generate guidance considering full history and repeat pattern
        let guidance = generateHistoryAwareGuidance(
            historyAnalysis: historyAnalysis,
            daysTo95: daysTo95,
            completionsTo95: completionsTo95,
            daysTo100: daysTo100,
            completionsTo100: completionsTo100,
            trend: trend,
            habit: habit,
            repeatPattern: repeatPatternDescription
        )
        
        return HabitPredictions(
            oneWeekAutomation: min(100, oneWeekStrength * 100),
            twoWeekAutomation: min(100, twoWeekStrength * 100),
            oneMonthAutomation: min(100, oneMonthStrength * 100),
            estimatedDaysTo95Percent: daysTo95,
            estimatedDaysTo100Percent: daysTo100,
            estimatedCompletionsTo95Percent: completionsTo95,
            estimatedCompletionsTo100Percent: completionsTo100,
            trend: trend,
            guidanceMessage: guidance,
            trendFactor: growthRate,
            repeatPatternDescription: repeatPatternDescription
        )
    }
    
    private func projectFutureStrength(
        current: Double,
        daysAhead: Int,
        growthRate: Double,
        habit: Habit
    ) -> Double {
        // Project using actual scheduled days, not just calendar days
        let calendar = Calendar.current
        let startDate = calendar.startOfCustomDay(config.analysisEnd, tz: config.timeZone, startHour: config.dayStartHour)
        guard let endDate = calendar.date(byAdding: .day, value: daysAhead, to: startDate) else {
            return current
        }
        
        // Count scheduled days in the projection period using unified method
        let (scheduledDays, _) = scheduledStats(habit: habit, from: startDate, to: endDate)
        
        // Apply growth for each scheduled completion
        var strength = current
        let L = Int(habit.intensityLevel)
        for _ in 0..<scheduledDays {
            if habit.isBadHabit {
                // For bad habits, use avoidance growth with intensity adjustment
                let params = badParams(for: L)
                let k_ext_eff = clamp(params.k_ext * I_g(L), 0.01, 0.20)
                strength = avoidanceGrowth(C: strength, k_ext: k_ext_eff)
            } else {
                // For good habits, use asymptotic growth (growthRate already intensity-adjusted)
                strength = applyAsymptoticGrowth(
                    previousStrength: strength,
                    streakDay: 1,
                    growthRate: growthRate
                )
            }
        }
        
        return clamp(strength, 0, config.maxHabitStrength)
    }
    
    private func estimateDaysAndCompletionsToTarget(
        currentStrength: Double,
        targetStrength: Double,
        growthRate: Double,
        habit: Habit
    ) -> (days: Int?, completions: Int?) {
        guard currentStrength < targetStrength else { return (nil, nil) }
        
        let calendar = Calendar.current
        var strength = currentStrength
        var days = 0
        var completions = 0
        var currentDate = calendar.startOfCustomDay(config.analysisEnd, tz: config.timeZone, startHour: config.dayStartHour)
        let L = Int(habit.intensityLevel)
        
        // Simulate day by day until target is reached
        while strength < targetStrength && days < 254 {
            days += 1
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            
            // Check if habit is scheduled on this day
            if HabitUtilities.isHabitActive(habit: habit, on: nextDate) {
                completions += 1
                if habit.isBadHabit {
                    // For bad habits, use avoidance growth with intensity adjustment
                    let params = badParams(for: L)
                    let k_ext_eff = clamp(params.k_ext * I_g(L), 0.01, 0.20)
                    strength = avoidanceGrowth(C: strength, k_ext: k_ext_eff)
                } else {
                    // For good habits, use asymptotic growth (growthRate already intensity-adjusted)
                    strength = applyAsymptoticGrowth(
                        previousStrength: strength,
                        streakDay: 1,
                        growthRate: growthRate
                    )
                }
            }
            
            currentDate = nextDate
        }
        
        if days >= 254 {
            return (nil, nil)
        }
        
        return (days, completions)
    }
    
    // MARK: - Trend Analysis with Scheduled-Aware Weeks
    private func analyzeCompletionTrend(habit: Habit) -> CompletionTrend {
        let cal = Calendar.current
        let today = cal.startOfCustomDay(config.analysisEnd, tz: config.timeZone, startHour: config.dayStartHour)
        let oneWeek = cal.date(byAdding: .day, value: -7, to: today)!
        let twoWeeks = cal.date(byAdding: .day, value: -14, to: today)!
        
        let recent = scheduledStats(habit: habit, from: oneWeek, to: today)
        let prior = scheduledStats(habit: habit, from: twoWeeks, to: oneWeek)
        
        let r = recent.expected > 0 ? Double(recent.actual) / Double(recent.expected) : 0
        let p = prior.expected > 0 ? Double(prior.actual) / Double(prior.expected) : 0
        
        if r > p + 0.10 { return .improving }
        if r < p - 0.10 { return .declining }
        return .stable
    }
    
    // MARK: - Helper Functions
    
    /// Get human-readable description of repeat pattern
    private func getRepeatPatternDescription(for habit: Habit) -> String {
        // Check if habit has repeat patterns
        guard let repeatPatterns = habit.repeatPattern as? Set<RepeatPattern>,
              let pattern = repeatPatterns.first else {
            return "daily"
        }
        
        // Check for daily goal
        if let dailyGoal = pattern.dailyGoal {
            if dailyGoal.everyDay {
                return "daily"
            } else if dailyGoal.daysInterval > 0 {
                let interval = Int(dailyGoal.daysInterval)
                if interval == 1 {
                    return "daily"
                } else if interval == 7 {
                    return "weekly"
                } else if interval == 14 {
                    return "bi-weekly"
                } else {
                    return "every \(interval) days"
                }
            } else if let specificDays = dailyGoal.specificDays as? Set<String>, !specificDays.isEmpty {
                let dayCount = specificDays.count
                if dayCount == 7 {
                    return "daily"
                } else if dayCount == 1 {
                    return "weekly"
                } else {
                    return "\(dayCount) times per week"
                }
            }
        }
        
        // Check for weekly goal
        if let weeklyGoal = pattern.weeklyGoal {
            if weeklyGoal.everyWeek {
                return "weekly"
            } else if weeklyGoal.weekInterval > 0 {
                let interval = Int(weeklyGoal.weekInterval)
                if interval == 1 {
                    return "weekly"
                } else if interval == 2 {
                    return "bi-weekly"
                } else {
                    return "every \(interval) weeks"
                }
            }
        }
        
        // Check for monthly goal
        if let monthlyGoal = pattern.monthlyGoal {
            if monthlyGoal.everyMonth {
                return "monthly"
            } else if monthlyGoal.monthInterval > 0 {
                let interval = Int(monthlyGoal.monthInterval)
                if interval == 1 {
                    return "monthly"
                } else {
                    return "every \(interval) months"
                }
            }
        }
        
        // Default fallback
        return "scheduled"
    }
    
    private func generateHistoryAwareGuidance(
        historyAnalysis: HabitHistoryAnalysis,
        daysTo95: Int?,
        completionsTo95: Int?,
        daysTo100: Int?,
        completionsTo100: Int?,
        trend: CompletionTrend,
        habit: Habit,
        repeatPattern: String
    ) -> String {
        let currentPercent = Int(historyAnalysis.currentStrength * 100)
        let bestStreakEver = historyAnalysis.bestStreakEver
        
        // Special messages for bad habits
        if habit.isBadHabit {
            return generateBadHabitGuidance(
                currentAutomation: Double(currentPercent),
                currentStreak: historyAnalysis.currentStreak,
                trend: trend,
                bestStreakEver: bestStreakEver,
                recoveryPotential: historyAnalysis.recoveryPotential,
                repeatPattern: repeatPattern
            )
        }
        
        // Recovery from past best streak
        if historyAnalysis.currentStreak < bestStreakEver && bestStreakEver > 0 {
            if historyAnalysis.recoveryPotential > 0.3 {
                return "Your best streak was \(bestStreakEver) days! Great news: your brain remembers. With your \(repeatPattern) schedule, consistency will help you recover faster."
            } else if historyAnalysis.recoveryPotential > 0.1 {
                return "Rebuilding from \(currentPercent)% (best ever: \(bestStreakEver) days). Muscle memory is on your side with this \(repeatPattern) habit!"
            }
        }
        
        // Personal best achievement
        if historyAnalysis.currentStreak == bestStreakEver && bestStreakEver > 0 {
            return "🎉 Personal best! \(bestStreakEver) days with your \(repeatPattern) habit. You're in uncharted territory!"
        }
        
        // Near or at peak performance with completion-based predictions
        if historyAnalysis.currentStrength >= 0.95 {
            if let completions = completionsTo100, completions <= 30 {
                return "Outstanding! Just \(completions) more \(repeatPattern) completions for full automation!"
            } else if let completions = completionsTo95, completions <= 20 {
                return "Nearly automatic! Only \(completions) \(repeatPattern) sessions to reach 95% automation."
            }
            return "This \(repeatPattern) habit is becoming second nature. You're in the automation zone!"
        }
        
        // Strong current streak with pattern context
        if historyAnalysis.currentStreak > 21 {
            let streakProgress = bestStreakEver > 0 ? " (\(historyAnalysis.currentStreak)/\(bestStreakEver) best)" : ""
            return "Your \(historyAnalysis.currentStreak)-day streak\(streakProgress) on this \(repeatPattern) habit shows incredible dedication!"
        } else if historyAnalysis.currentStreak > 14 {
            return "Great \(historyAnalysis.currentStreak)-day streak! Your \(repeatPattern) routine is solidifying."
        } else if historyAnalysis.currentStreak > 7 {
            return "One week strong with your \(repeatPattern) schedule! Each completion strengthens the pathway."
        }
        
        // Progress-based messages with completions context
        if currentPercent >= 66 {
            if trend == .improving {
                if let completions = completionsTo95 {
                    return "At \(currentPercent)% and improving! About \(completions) more \(repeatPattern) completions to near-automation."
                }
                return "Strong \(currentPercent)% automation on your \(repeatPattern) habit. Keep the momentum!"
            }
            return "Solid \(currentPercent)% automation. Stay consistent with your \(repeatPattern) schedule."
        } else if currentPercent >= 40 {
            if trend == .improving {
                return "Building momentum at \(currentPercent)%! Your brain is adapting to this \(repeatPattern) routine."
            } else if trend == .declining {
                return "At \(currentPercent)% but slipping. Focus on your next \(repeatPattern) session to regain momentum."
            }
            return "Good \(currentPercent)% progress. Prioritize your \(repeatPattern) completions this week."
        } else {
            // Low automation with pattern encouragement
            if bestStreakEver > 7 {
                return "You've done \(bestStreakEver) days of \(repeatPattern) before—you can build back up!"
            } else if trend == .improving {
                return "Growing from \(currentPercent)%. Every \(repeatPattern) completion counts in these early stages!"
            }
            return "At \(currentPercent)% with your \(repeatPattern) habit. Focus on just the next scheduled day."
        }
    }
    
    private func generateBadHabitGuidance(
        currentAutomation: Double,
        currentStreak: Int,
        trend: CompletionTrend,
        bestStreakEver: Int,
        recoveryPotential: Double,
        repeatPattern: String
    ) -> String {
        let currentPercent = Int(currentAutomation)
        
        // Personal best for avoiding bad habit
        if currentStreak == bestStreakEver && bestStreakEver > 0 {
            return "🎉 Personal best! \(bestStreakEver) days free from this \(repeatPattern) habit. You're breaking new ground!"
        }
        
        // High automation (successfully avoiding)
        if currentPercent >= 80 {
            if currentStreak > 30 {
                let bestProgress = bestStreakEver > 0 ? " (best: \(bestStreakEver))" : ""
                return "Incredible! \(currentStreak) days\(bestProgress) free from this \(repeatPattern) habit. You've broken the cycle!"
            } else if currentStreak > 14 {
                return "Amazing \(currentStreak)-day streak avoiding this \(repeatPattern) habit. Your brain has rewired!"
            }
            return "At \(currentPercent)% control over this \(repeatPattern) habit. You've essentially broken free!"
        }
        
        // Recovery messages - comparing to personal best
        if bestStreakEver > currentStreak && bestStreakEver > 0 {
            return "You went \(bestStreakEver) days without this \(repeatPattern) habit before. Your brain remembers—you can do it again!"
        }
        
        // Moderate automation (50-79%)
        if currentPercent >= 50 {
            if trend == .improving {
                return "\(currentPercent)% in control and improving! The \(repeatPattern) urges are weakening."
            } else if currentStreak > 7 {
                let bestContext = bestStreakEver > currentStreak ? " (working toward your \(bestStreakEver)-day best)" : ""
                return "\(currentStreak) days avoiding this \(repeatPattern) habit\(bestContext)! Each day weakens its hold."
            }
            return "Halfway there at \(currentPercent)%! Stay vigilant during your typical \(repeatPattern) times."
        }
        
        // Building phase (25-49%)
        if currentPercent >= 25 {
            if currentStreak > 3 {
                let encouragement = bestStreakEver > 7 ? " You've done \(bestStreakEver) days before!" : " You're proving you can do this."
                return "\(currentStreak) days free from this \(repeatPattern) habit!\(encouragement)"
            }
            return "Building control at \(currentPercent)%. Replace this \(repeatPattern) habit with something positive."
        }
        
        // Early stages (0-24%)
        if currentStreak > 0 {
            let dayText = currentStreak == 1 ? "day" : "days"
            let bestEncouragement = bestStreakEver > 0 ? " Your record is \(bestStreakEver) days—you can get there again!" : " Take it one day at a time."
            return "\(currentStreak) \(dayText) avoiding this \(repeatPattern) habit!\(bestEncouragement)"
        }
        
        // Fresh start
        if bestStreakEver > 0 {
            return "Fresh start with this \(repeatPattern) habit. You've avoided it for \(bestStreakEver) days before—you're stronger than the urge!"
        }
        
        return "Fresh start with this \(repeatPattern) habit begins now. You're stronger than the urge!"
    }
}
