//
//  EnhancedHabitEngine.swift
//  Habital
//
//  Created by Elias Osarumwense on 29.10.25.
//

import Foundation
import CoreData

// MARK: - Enhanced Configuration with Personalization
struct EnhancedHabitAutomationConfig {
    var timeZone: TimeZone = .current
    var dayStartHour: Int = 4 // 4 AM to avoid midnight artifacts
    var analysisEnd: Date = Date()
    
    // Base habit strength model parameters (based on Lally et al., 2010)
    var habitGrowthRate: Double = 0.08      // k: Growth rate during streaks
    var habitDecayRate: Double = 0.03       // λ: Decay rate during gaps
    var residualMemoryFactor: Double = 0.15 // Minimum retained strength (15% of peak)
    var maxHabitStrength: Double = 1.0      // Maximum achievable strength
    
    // Intensity adjustment parameters
    var intensityPenaltyPerLevel: Double = 0.1
    
    // Soft drift for non-scheduled periods
    var softDriftRate: Double = 0.002       // λ_soft for non-scheduled gaps
    
    // Partial credit parameters
    var partialCreditEnabled: Bool = true
    var quantityLookbackDays: Int = 7      // Days to look back for quantity targets
    var durationLookbackDays: Int = 7      // Days to look back for duration targets
    
    // Context consistency parameters
    var contextConsistencyWindow: Int = 21  // Days to look back for context patterns
    var contextConsistencyBonus: Double = 0.2 // Max bonus from consistent context
    
    // Long break handling
    var longBreakThreshold: Int = 21       // Days to consider a "long break"
    var longBreakDecayRate: Double = 0.25  // Special decay rate for long breaks
    
    // Rolling average window for personalization signals
    var personalizationWindow: Int = 14    // Scheduled instances to consider
    
    // Category-based priors (will be populated from HabitCategory)
    var categoryPriors: [String: Double] = [
        "Health": 0.06,
        "Fitness": 0.05,
        "Productivity": 0.08,
        "Learning": 0.07,
        "Mindfulness": 0.09,
        "Social": 0.08,
        "Finance": 0.06,
        "Creativity": 0.07,
        "Nutrition": 0.08,
        "Sleep": 0.09,
        "Work": 0.06,
        "Personal": 0.08
    ]
    
    // Intensity-adjusted growth rate with clamping
    func adjustedGrowthRate(for intensityLevel: Int64) -> Double {
        let raw = habitGrowthRate * (1.0 - Double(max(0, intensityLevel - 1)) * intensityPenaltyPerLevel)
        return max(raw, 0.005) // floor at 0.005
    }
    
    // Intensity-adjusted decay rate with clamping
    func adjustedDecayRate(for intensityLevel: Int64) -> Double {
        let raw = habitDecayRate * (1.0 + Double(max(0, intensityLevel - 1)) * intensityPenaltyPerLevel * 0.5)
        return min(max(raw, 0.001), 0.25) // clamp between 0.001 and 0.25
    }
}

// MARK: - Enhanced Bad Habit Parameters
private struct EnhancedBadHabitParams {
    let k_ext: Double        // Extinction: control growth when avoided
    let lambda_reinst: Double// Reinstatement: control drop on lapse
    let floor_min: Double    // Minimal residual control floor
    let softDrift: Double    // Tiny drift per non-scheduled day
}

private func enhancedBadParams(for level: Int) -> EnhancedBadHabitParams {
    switch max(1, min(4, level)) {
    case 1: return .init(k_ext: 0.09,  lambda_reinst: 0.06, floor_min: 0.25, softDrift: 0.002)
    case 2: return .init(k_ext: 0.07,  lambda_reinst: 0.08, floor_min: 0.20, softDrift: 0.002)
    case 3: return .init(k_ext: 0.05,  lambda_reinst: 0.10, floor_min: 0.15, softDrift: 0.003)
    default:return .init(k_ext: 0.035, lambda_reinst: 0.12, floor_min: 0.10, softDrift: 0.003)
    }
}

// MARK: - Partial Credit Support
struct PartialCredit {
    let progressPercentage: Double
    let quantity: Double
    let duration: Double
    let targetQuantity: Double
    let targetDuration: Double
    let weight: Double // Final computed weight [0,1]
}

// MARK: - Personalization Signals
struct PersonalizationSignals {
    let perceivedDifficulty: Double    // 1-5, averaged
    let selfEfficacy: Double           // 1-5, averaged  
    let moodImpact: Double             // -1 to +1, averaged
    let contextConsistency: Double     // 0-1, consistency score
    let sampleSize: Int                // Number of data points
    
    static let `default` = PersonalizationSignals(
        perceivedDifficulty: 3.0,
        selfEfficacy: 3.0,
        moodImpact: 0.0,
        contextConsistency: 0.5,
        sampleSize: 0
    )
}

// MARK: - Context Analysis
struct ContextTuple: Hashable {
    let dayKey: String
    let timeBin: TimeBin
}

enum TimeBin: String, CaseIterable {
    case morning = "morning"     // 4-12
    case afternoon = "afternoon" // 12-17
    case evening = "evening"     // 17-21
    case night = "night"         // 21-4
    
    static func from(date: Date, timeZone: TimeZone = .current) -> TimeBin {
        var calendar = Calendar.current
        calendar.timeZone = timeZone
        let hour = calendar.component(.hour, from: date)
        
        switch hour {
        case 4..<12: return .morning
        case 12..<17: return .afternoon
        case 17..<21: return .evening
        default: return .night
        }
    }
}

// MARK: - Enhanced Predictions with Uncertainty
struct EnhancedHabitPredictions {
    let oneWeekAutomation: ConfidenceInterval
    let twoWeekAutomation: ConfidenceInterval
    let oneMonthAutomation: ConfidenceInterval
    let estimatedDaysTo95Percent: Int?
    let estimatedDaysTo100Percent: Int?
    let estimatedCompletionsTo95Percent: Int?
    let estimatedCompletionsTo100Percent: Int?
    let trend: CompletionTrend
    let guidanceMessage: String
    let trendFactor: Double
    let repeatPatternDescription: String
    let uncertaintyNote: String
}

struct ConfidenceInterval {
    let low: Double
    let mid: Double
    let high: Double
    
    var range: String {
        if abs(high - low) < 5 {
            return String(format: "%.0f%%", mid)
        } else {
            return String(format: "%.0f-%.0f%%", low, high)
        }
    }
}

// MARK: - Enhanced History Analysis
struct EnhancedHabitHistoryAnalysis {
    let strengthHistory: [HabitStrengthPoint]
    let currentStrength: Double
    let peakStrength: Double
    let totalStreakDays: Int
    let totalGapDays: Int
    let longestStreak: Int
    let currentStreak: Int
    let bestStreakEver: Int
    let averageStreakLength: Double
    let recoveryPotential: Double
    let experienceFloor: Double
    let personalizationSignals: PersonalizationSignals
    let partialCreditHistory: [PartialCredit] // Last 21 days
    let trendSignal: Double // EMA-based trend
}

// MARK: - Enhanced Insight
struct EnhancedHabitAutomationInsight {
    let habitId: UUID
    let habitName: String
    let analysisDate: Date
    
    // Core automation metrics
    let automationPercentage: Double
    let currentStreak: Int
    let bestStreakEver: Int
    let expectedCompletions: Int
    let actualCompletions: Int
    
    // Component breakdown for debugging
    let rawCompletionRate: Double
    let streakMultiplier: Double
    let intensityWeight: Double
    let timeFactor: Double
    
    // Enhanced features
    let partialCreditScore: Double      // Average weight from partial completions
    let personalizationBonus: Double   // Boost from personal signals
    let contextConsistencyScore: Double // 0-1 score for context stability
    let categoryPrior: Double           // Category-based prior strength
    
    // History analysis
    let historyAnalysis: EnhancedHabitHistoryAnalysis?
    
    // Predictive insights with uncertainty
    let predictions: EnhancedHabitPredictions?
}

// MARK: - Enhanced Calendar Extension
private extension Calendar {
    func startOfCustomDay(_ date: Date, tz: TimeZone, startHour: Int) -> Date {
        var cal = self
        cal.timeZone = tz
        let shifted = cal.date(byAdding: .hour, value: -startHour, to: date)!
        let sod = cal.startOfDay(for: shifted)
        return cal.date(byAdding: .hour, value: startHour, to: sod)!
    }
    
    /// DST-safe date iteration with nil protection
    func safeNextDay(after date: Date) -> Date? {
        return self.date(byAdding: .day, value: 1, to: date)
    }
}

// MARK: - Enhanced Utility Functions
@inline(__always)
private func clamp(_ x: Double, _ lo: Double = 0, _ hi: Double = 1) -> Double {
    min(hi, max(lo, x))
}

// Enhanced growth with partial credit weight
@inline(__always)
private func weightedGrow(from h0: Double, toward hMax: Double, k: Double, weight: Double) -> Double {
    let weightedIncrement = weight * (hMax - h0) * (1 - exp(-k))
    return h0 + weightedIncrement
}

// Enhanced avoidance growth with partial credit
@inline(__always)
private func weightedAvoidanceGrowth(C: Double, k_ext: Double, weight: Double) -> Double {
    let increment = weight * (1.0 - C) * (1.0 - exp(-k_ext))
    return clamp(C + increment, 0, 1)
}

// Humane decay with skipped day protection
@inline(__always)
private func humaneDecay(from h0: Double, lambda: Double, n: Int, floor: Double, isSkipped: Bool) -> Double {
    if isSkipped {
        // Very gentle drift for intentionally skipped days
        let softDecay = h0 * exp(-0.25 * lambda * Double(n))
        return max(floor, softDecay)
    } else {
        // Normal decay for actual misses
        let normalDecay = h0 * exp(-lambda * Double(n))
        return max(floor, normalDecay)
    }
}

// Long break handling
@inline(__always)
private func applyLongBreakDecay(strength: Double, restDays: Int, lambda: Double, floor: Double) -> Double {
    let decay = strength * exp(-lambda * Double(restDays) * 0.25)
    return max(floor, decay)
}

// MARK: - Enhanced Main Analytics Engine
class EnhancedHabitAutomationEngine {
    private let config: EnhancedHabitAutomationConfig
    private let context: NSManagedObjectContext
    
    init(config: EnhancedHabitAutomationConfig = EnhancedHabitAutomationConfig(), context: NSManagedObjectContext) {
        self.config = config
        self.context = context
    }
    
    // MARK: - Public API
    func calculateAutomationPercentage(habit: Habit) -> EnhancedHabitAutomationInsight {
        // Step 1: Build complete enhanced habit history with partial credit
        let historyAnalysis = analyzeEnhancedHabitHistory(habit: habit)
        
        // Step 2: Current automation is the current strength as percentage
        let automationPercentage = min(100.0, historyAnalysis.currentStrength * 100.0)
        
        // Step 3: Get completion metrics using unified source of truth
        let (expectedCompletions, actualCompletions) = scheduledStats(
            habit: habit,
            from: habit.startDate ?? Date(),
            to: config.analysisEnd
        )
        
        let rawCompletionRate = expectedCompletions > 0 ? Double(actualCompletions) / Double(expectedCompletions) : 0
        
        // Step 4: Calculate enhanced metrics
        let intensityWeight = clamp(
            1.0 - (config.intensityPenaltyPerLevel * Double(max(0, habit.intensityLevel - 1))),
            0.2,
            1.0
        )
        
        let partialCreditScore = historyAnalysis.partialCreditHistory.isEmpty ? 1.0 :
            historyAnalysis.partialCreditHistory.map(\.weight).reduce(0, +) / Double(historyAnalysis.partialCreditHistory.count)
        
        let personalizationBonus = calculatePersonalizationBonus(signals: historyAnalysis.personalizationSignals)
        
        let categoryPrior = getCategoryPrior(habit: habit)
        
        // Step 5: Generate enhanced predictions
        let predictions = calculateEnhancedPredictions(
            habit: habit,
            historyAnalysis: historyAnalysis
        )
        
        return EnhancedHabitAutomationInsight(
            habitId: habit.id ?? UUID(),
            habitName: habit.name ?? "Unnamed Habit",
            analysisDate: config.analysisEnd,
            automationPercentage: automationPercentage,
            currentStreak: historyAnalysis.currentStreak,
            bestStreakEver: historyAnalysis.bestStreakEver,
            expectedCompletions: expectedCompletions,
            actualCompletions: actualCompletions,
            rawCompletionRate: rawCompletionRate,
            streakMultiplier: 1.0,
            intensityWeight: intensityWeight,
            timeFactor: historyAnalysis.currentStrength,
            partialCreditScore: partialCreditScore,
            personalizationBonus: personalizationBonus,
            contextConsistencyScore: historyAnalysis.personalizationSignals.contextConsistency,
            categoryPrior: categoryPrior,
            historyAnalysis: historyAnalysis,
            predictions: predictions
        )
    }
    
    // MARK: - Enhanced Single Source of Truth for Counting
    private func scheduledStats(habit: Habit, from start: Date, to end: Date) -> (expected: Int, actual: Int) {
        precondition(start <= end, "Start date must be before or equal to end date")
        
        let cal = Calendar.current
        var d = cal.startOfCustomDay(start, tz: config.timeZone, startHour: config.dayStartHour)
        let endBoundary = cal.startOfCustomDay(end, tz: config.timeZone, startHour: config.dayStartHour)
        
        var expected = 0
        var actual = 0
        
        // Use half-open range [start, end) with DST protection
        while d < endBoundary {
            if HabitUtilities.isHabitActive(habit: habit, on: d) {
                expected += 1
                if habit.isCompleted(on: d) {
                    actual += 1
                }
            }
            
            // DST-safe iteration
            guard let nextDay = cal.safeNextDay(after: d) else { break }
            d = nextDay
        }
        
        return (expected, actual)
    }
    
    // MARK: - Enhanced Full History Analysis with Partial Credit
    private func analyzeEnhancedHabitHistory(habit: Habit) -> EnhancedHabitHistoryAnalysis {
        guard let startDate = habit.startDate else {
            return EnhancedHabitHistoryAnalysis(
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
                experienceFloor: 0.05,
                personalizationSignals: .default,
                partialCreditHistory: [],
                trendSignal: 0.0
            )
        }
        
        let calendar = Calendar.current
        var currentDate = calendar.startOfCustomDay(startDate, tz: config.timeZone, startHour: config.dayStartHour)
        let endDate = calendar.startOfCustomDay(config.analysisEnd, tz: config.timeZone, startHour: config.dayStartHour)
        
        // Pre-compute signals and targets for efficiency
        let personalizationSignals = computePersonalizationSignals(habit: habit)
        let (quantityTargets, durationTargets) = precomputeTargets(habit: habit)
        
        // Initialize state
        var habitStrength: Double = 0.0
        var peakStrength: Double = 0.0
        var strengthHistory: [HabitStrengthPoint] = []
        var partialCreditHistory: [PartialCredit] = []
        
        var totalStreakDays = 0
        var totalGapDays = 0
        var streakCount = 0
        var totalStreakLengths = 0
        
        // Track state for analysis
        var nonScheduledGapDays = 0
        var isInStreak = false
        var currentStreakLength = 0
        var consecutiveMisses = 0
        
        // EMA trend tracking
        var ema: Double = 0.0
        var emaInitialized = false
        let emaBeta = 0.85
        
        // Compute frequency and personalized rates
        let frequencyPerWeek = computeFrequencyPerWeek(habit: habit)
        let softScale = 7.0 / max(1.0, frequencyPerWeek)
        
        let (totalScheduled, totalCompleted) = scheduledStats(habit: habit, from: startDate, to: endDate)
        let (baseGrowthRate, baseDecayRate) = getPersonalizedRates(
            habit: habit,
            signals: personalizationSignals,
            totalScheduled: totalScheduled,
            totalCompleted: totalCompleted
        )
        
        // Apply long break handling if needed
        if shouldApplyLongBreakDecay(habit: habit) {
            let restDays = daysSinceLastCompletion(habit: habit)
            let experienceFloor = computeEnhancedExperienceFloor(
                totalStreakDays: 0, // Will be computed
                peakStrength: 0,    // Will be computed
                signals: personalizationSignals
            )
            habitStrength = applyLongBreakDecay(
                strength: habitStrength,
                restDays: restDays,
                lambda: baseDecayRate,
                floor: experienceFloor
            )
        }
        
        // Use half-open range iteration with DST protection
        while currentDate < endDate {
            let wasScheduled = HabitUtilities.isHabitActive(habit: habit, on: currentDate)
            
            if wasScheduled {
                // Reset non-scheduled gap counter
                if nonScheduledGapDays > 3 {
                    habitStrength = applySoftDrift(
                        habit: habit,
                        strength: habitStrength,
                        driftDays: nonScheduledGapDays,
                        softScale: softScale,
                        totalStreakDays: totalStreakDays,
                        peakStrength: peakStrength,
                        signals: personalizationSignals
                    )
                }
                nonScheduledGapDays = 0
                
                // Compute partial credit for this day
                let partialCredit = computePartialCredit(
                    habit: habit,
                    date: currentDate,
                    quantityTargets: quantityTargets,
                    durationTargets: durationTargets
                )
                
                // Store partial credit history (keep last 21 days)
                partialCreditHistory.append(partialCredit)
                if partialCreditHistory.count > 21 {
                    partialCreditHistory.removeFirst()
                }
                
                // Update EMA trend
                if emaInitialized {
                    ema = emaBeta * ema + (1 - emaBeta) * partialCredit.weight
                } else {
                    ema = partialCredit.weight
                    emaInitialized = true
                }
                
                if habit.isBadHabit {
                    // Enhanced bad habit processing with partial credit
                    let success = habit.isCompleted(on: currentDate)
                    processEnhancedBadHabit(
                        success: success,
                        partialCredit: partialCredit,
                        currentDate: currentDate,
                        habit: habit,
                        habitStrength: &habitStrength,
                        peakStrength: &peakStrength,
                        isInStreak: &isInStreak,
                        currentStreakLength: &currentStreakLength,
                        consecutiveMisses: &consecutiveMisses,
                        totalStreakDays: &totalStreakDays,
                        totalGapDays: &totalGapDays,
                        totalStreakLengths: &totalStreakLengths,
                        streakCount: &streakCount,
                        baseGrowthRate: baseGrowthRate,
                        baseDecayRate: baseDecayRate,
                        signals: personalizationSignals
                    )
                } else {
                    // Enhanced good habit processing with partial credit
                    let wasCompleted = habit.isCompleted(on: currentDate)
                    let wasSkipped = checkIfSkipped(habit: habit, date: currentDate)
                    
                    processEnhancedGoodHabit(
                        completed: wasCompleted,
                        skipped: wasSkipped,
                        partialCredit: partialCredit,
                        currentDate: currentDate,
                        habit: habit,
                        habitStrength: &habitStrength,
                        peakStrength: &peakStrength,
                        isInStreak: &isInStreak,
                        currentStreakLength: &currentStreakLength,
                        consecutiveMisses: &consecutiveMisses,
                        totalStreakDays: &totalStreakDays,
                        totalGapDays: &totalGapDays,
                        totalStreakLengths: &totalStreakLengths,
                        streakCount: &streakCount,
                        baseGrowthRate: baseGrowthRate,
                        baseDecayRate: baseDecayRate,
                        signals: personalizationSignals
                    )
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
            }
            
            // DST-safe iteration
            guard let nextDay = calendar.safeNextDay(after: currentDate) else { break }
            currentDate = nextDay
        }
        
        // Finalize calculations
        if isInStreak {
            totalStreakLengths += currentStreakLength
        }
        
        let finalExperienceFloor = computeEnhancedExperienceFloor(
            totalStreakDays: totalStreakDays,
            peakStrength: peakStrength,
            signals: personalizationSignals
        )
        
        let averageStreakLength = streakCount > 0 ? Double(totalStreakLengths) / Double(streakCount) : 0
        let recoveryPotential = peakStrength - habitStrength
        
        // Use Core Data attributes for streak values
        let actualCurrentStreak = habit.calculateStreak(upTo: config.analysisEnd)
        let historicalLongestStreak = habit.calculateLongestStreak()
        let bestStreakEver = Int(habit.bestStreakEver)
        
        // Compute trend signal (difference from earlier EMA)
        let trendSignal = computeTrendSignal(partialCreditHistory: partialCreditHistory)
        
        return EnhancedHabitHistoryAnalysis(
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
            experienceFloor: finalExperienceFloor,
            personalizationSignals: personalizationSignals,
            partialCreditHistory: partialCreditHistory,
            trendSignal: trendSignal
        )
    }
    
    // MARK: - Continue implementation...
    // This is part 1 of the implementation. The file is getting long, so I'll continue with the helper methods.
}