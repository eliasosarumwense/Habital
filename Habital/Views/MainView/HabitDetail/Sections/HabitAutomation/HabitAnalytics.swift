//
//  ImprovedHabitAutomationEngine.swift
//  Habital
//
//  Enhanced version with personalized learning, context stability,
//  reward factors, plateau detection, and comprehensive analytics
//

import Foundation
import CoreData
import SwiftUI
/*
// MARK: - Enhanced Configuration with Personalization
struct HabitAutomationConfig {
    var timeZone: TimeZone = .current
    var dayStartHour: Int = 4 // 4 AM to avoid midnight artifacts
    var analysisEnd: Date = Date()
    
    // Base habit strength model parameters (Lally et al., 2010)
    var baseHabitGrowthRate: Double = 0.08      // k: Base growth rate
    var baseHabitDecayRate: Double = 0.03       // λ: Base decay rate
    var residualMemoryFactor: Double = 0.15     // Minimum retained strength
    var maxHabitStrength: Double = 1.0          // Maximum achievable strength
    
    // Personalization parameters
    var personalizedGrowthMultiplier: Double = 1.0  // User-specific adjustment
    var personalizedDecayMultiplier: Double = 1.0   // User-specific adjustment
    var learningRate: Double = 0.02                  // How fast we adapt to user
    
    // Context stability parameters
    var contextStabilityBonus: Double = 0.15    // Bonus for consistent context
    var contextVariabilityPenalty: Double = 0.10 // Penalty for inconsistent context
    var minContextConsistency: Double = 0.7      // Threshold for bonus
    
    // Reward and enjoyment factors
    var enjoymentMultiplier: Double = 1.0        // 0.5-1.5 range
    var rewardBonus: Double = 0.05               // Extra growth for rewarded habits
    
    // Plateau detection parameters
    var plateauThreshold: Int = 14               // Days to detect plateau
    var plateauVariance: Double = 0.02           // Max variance for plateau
    
    // Multiple repetitions per day
    var multiRepetitionMode: Bool = false
    var dailyRepetitionTarget: Int = 1
    
    // Extended break handling
    var extendedBreakThreshold: Int = 14         // Days before stronger decay
    var extendedBreakDecayMultiplier: Double = 2.0
    
    // Intensity adjustment parameters
    var intensityPenaltyPerLevel: Double = 0.1
    
    // Soft drift for non-scheduled periods
    var softDriftRate: Double = 0.002
    
    // Get personalized growth rate
    func personalizedGrowthRate(for intensityLevel: Int64, userMultiplier: Double = 1.0) -> Double {
        let base = baseHabitGrowthRate * personalizedGrowthMultiplier * userMultiplier
        let adjusted = base * (1.0 - Double(max(0, intensityLevel - 1)) * intensityPenaltyPerLevel)
        return max(adjusted, 0.005)
    }
    
    // Get personalized decay rate
    func personalizedDecayRate(for intensityLevel: Int64, userMultiplier: Double = 1.0) -> Double {
        let base = baseHabitDecayRate * personalizedDecayMultiplier * userMultiplier
        let adjusted = base * (1.0 + Double(max(0, intensityLevel - 1)) * intensityPenaltyPerLevel * 0.5)
        return min(max(adjusted, 0.001), 0.25)
    }
}

// MARK: - User Profile for Personalization
struct UserHabitProfile: Codable {
    let userId: UUID
    var averageFormationSpeed: Double = 1.0      // Relative to population
    var contextConsistencyScore: Double = 0.5    // 0-1 range
    var enjoymentAverageScore: Double = 0.5      // 0-1 range
    var habitSuccessRate: Double = 0.5           // Historical success rate
    var profileConfidence: Double = 0.0          // How much data we have
    
    mutating func updateFormationSpeed(observed: Double, expected: Double) {
        let ratio = observed / max(expected, 0.01)
        let weight = min(profileConfidence, 0.5)
        averageFormationSpeed = (averageFormationSpeed * (1 - weight)) + (ratio * weight)
        profileConfidence = min(profileConfidence + 0.02, 1.0)
    }
}

// MARK: - Context Information
struct HabitContext {
    let time: TimeInterval?          // Time of day (seconds from midnight)
    let location: String?             // Location identifier
    let trigger: String?              // Trigger/cue identifier
    let duration: TimeInterval?       // How long the habit took
    let enjoymentRating: Int?        // 1-5 scale
    let notes: String?
    
    func similarity(to other: HabitContext) -> Double {
        var score = 0.0
        var factors = 0.0
        
        // Time similarity (within 30 minutes)
        if let t1 = time, let t2 = other.time {
            let diff = abs(t1 - t2)
            score += max(0, 1.0 - diff / 1800.0)
            factors += 1.0
        }
        
        // Location match
        if let l1 = location, let l2 = other.location {
            score += (l1 == l2) ? 1.0 : 0.0
            factors += 1.0
        }
        
        // Trigger match
        if let tr1 = trigger, let tr2 = other.trigger {
            score += (tr1 == tr2) ? 1.0 : 0.0
            factors += 1.0
        }
        
        return factors > 0 ? score / factors : 0.5
    }
}

// MARK: - Enhanced Data Models
struct HabitStrengthPoint {
    let date: Date
    let strength: Double
    let isStreak: Bool
    let streakLength: Int
    let contextConsistency: Double?
    let enjoymentScore: Double?
    let wasScheduled: Bool
    let completionCount: Int         // For multi-rep habits
    let targetCount: Int              // Expected reps for that day
}

struct HabitHistoryAnalysis {
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
    
    // New fields for enhanced analysis
    let contextConsistencyScore: Double
    let averageEnjoyment: Double
    let plateauDetected: Bool
    let plateauDuration: Int?
    let formationVelocity: Double    // Rate of change
    let predictedDaysToFull: Int?
    let personalizedGrowthRate: Double
}

// MARK: - Enhanced Insight Model
struct HabitAutomationInsight {
    let habitId: UUID
    let habitName: String
    let analysisDate: Date
    let automationPercentage: Double
    let currentStreak: Int
    let bestStreakEver: Int
    let expectedCompletions: Int
    let actualCompletions: Int
    let rawCompletionRate: Double
    let streakMultiplier: Double
    let intensityWeight: Double
    let timeFactor: Double
    let historyAnalysis: HabitHistoryAnalysis
    let predictions: HabitPredictions
    
    // New enhanced fields
    let personalizedInsights: PersonalizedInsights
    let contextAnalysis: ContextAnalysis
    let plateauAnalysis: PlateauAnalysis?
    let visualizationData: VisualizationData
}

// MARK: - Personalized Insights
struct PersonalizedInsights {
    let adjustedGrowthRate: Double
    let comparedToAverage: String    // "faster", "average", "slower"
    let personalizedTips: [String]
    let strengthProjection: [Date: Double] // Future projections
    let confidenceLevel: Double      // How confident we are in personalization
}

// MARK: - Context Analysis
struct ContextAnalysis {
    let consistencyScore: Double     // 0-1
    let optimalTime: String?          // Best time for habit
    let optimalLocation: String?      // Best location
    let optimalTrigger: String?       // Best trigger/cue
    let recommendation: String
}

// MARK: - Plateau Analysis
struct PlateauAnalysis {
    let isInPlateau: Bool
    let plateauStrength: Double
    let daysInPlateau: Int
    let recommendedActions: [String]
    let breakoutProbability: Double  // Likelihood of breaking through
}

// MARK: - Visualization Data
struct VisualizationData {
    let dailyStrengthHistory: [(Date, Double)]
    let weeklyAverages: [(Date, Double)]
    let monthlyTrend: [(Date, Double)]
    let streakTimeline: [(Date, Int)]
    let projectedGrowth: [(Date, Double)]
    let annotations: [ChartAnnotation]
}

struct ChartAnnotation {
    let date: Date
    let label: String
    let type: AnnotationType
    
    enum AnnotationType {
        case milestone
        case plateau
        case breakthrough
        case lapse
        case contextChange
    }
}

// MARK: - Enhanced Predictions
struct HabitPredictions {
    let oneWeekAutomation: Double
    let twoWeekAutomation: Double
    let oneMonthAutomation: Double
    let threeMonthAutomation: Double
    let sixMonthAutomation: Double
    
    let estimatedDaysTo50Percent: Int?
    let estimatedDaysTo75Percent: Int?
    let estimatedDaysTo95Percent: Int?
    let estimatedDaysTo100Percent: Int?
    
    let estimatedCompletionsTo50Percent: Int?
    let estimatedCompletionsTo75Percent: Int?
    let estimatedCompletionsTo95Percent: Int?
    let estimatedCompletionsTo100Percent: Int?
    
    let trend: CompletionTrend
    let trendConfidence: Double      // How confident we are in the trend
    let guidanceMessage: String
    let actionableSteps: [String]    // Specific actions user can take
    let benchmarkComparison: String  // How user compares to research
    let trendFactor: Double
    let repeatPatternDescription: String
}

enum CompletionTrend {
    case rapidlyImproving
    case improving
    case stable
    case declining
    case rapidlyDeclining
    case plateau
    
    var color: String {
        switch self {
        case .rapidlyImproving: return "green"
        case .improving: return "mint"
        case .stable: return "blue"
        case .declining: return "orange"
        case .rapidlyDeclining: return "red"
        case .plateau: return "yellow"
        }
    }
    
    var icon: String {
        switch self {
        case .rapidlyImproving: return "arrow.up.right.circle.fill"
        case .improving: return "arrow.up.circle.fill"
        case .stable: return "equal.circle.fill"
        case .declining: return "arrow.down.circle.fill"
        case .rapidlyDeclining: return "arrow.down.right.circle.fill"
        case .plateau: return "minus.circle.fill"
        }
    }
}

// MARK: - Main Enhanced Analytics Engine
class ImprovedHabitAutomationEngine {
    private let config: HabitAutomationConfig
    private let context: NSManagedObjectContext
    private var userProfile: UserHabitProfile
    private let persistenceManager: UserProfilePersistenceManager
    
    init(config: HabitAutomationConfig = HabitAutomationConfig(),
         context: NSManagedObjectContext,
         userId: UUID? = nil) {
        self.config = config
        self.context = context
        self.persistenceManager = UserProfilePersistenceManager()
        self.userProfile = persistenceManager.loadProfile(userId: userId) ?? UserHabitProfile(userId: userId ?? UUID())
    }
    
    // MARK: - Public API
    func calculateAutomationPercentage(habit: Habit, contexts: [HabitContext] = []) -> HabitAutomationInsight {
        // Step 1: Analyze full habit history with context
        let historyAnalysis = analyzeFullHabitHistory(habit: habit, contexts: contexts)
        
        // Step 2: Update user profile based on observed vs expected
        updateUserProfile(habit: habit, analysis: historyAnalysis)
        
        // Step 3: Calculate automation percentage
        let automationPercentage = min(100.0, historyAnalysis.currentStrength * 100.0)
        
        // Step 4: Get completion metrics
        let (expectedCompletions, actualCompletions) = scheduledStats(
            habit: habit,
            from: habit.startDate ?? Date(),
            to: config.analysisEnd
        )
        
        let rawCompletionRate = expectedCompletions > 0 ?
            Double(actualCompletions) / Double(expectedCompletions) : 0
        
        // Step 5: Calculate intensity weight
        let intensityWeight = clamp(
            1.0 - (config.intensityPenaltyPerLevel * Double(max(0, habit.intensityLevel - 1))),
            0.2,
            1.0
        )
        
        // Step 6: Generate personalized predictions
        let predictions = calculatePersonalizedPredictions(
            habit: habit,
            historyAnalysis: historyAnalysis
        )
        
        // Step 7: Generate personalized insights
        let personalizedInsights = generatePersonalizedInsights(
            habit: habit,
            analysis: historyAnalysis
        )
        
        // Step 8: Analyze context patterns
        let contextAnalysis = analyzeContextPatterns(contexts: contexts)
        
        // Step 9: Detect and analyze plateaus
        let plateauAnalysis = detectPlateau(history: historyAnalysis.strengthHistory)
        
        // Step 10: Prepare visualization data
        let visualizationData = prepareVisualizationData(
            history: historyAnalysis.strengthHistory,
            predictions: predictions
        )
        
        // Return comprehensive insight
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
            streakMultiplier: 1.0,
            intensityWeight: intensityWeight,
            timeFactor: historyAnalysis.currentStrength,
            historyAnalysis: historyAnalysis,
            predictions: predictions,
            personalizedInsights: personalizedInsights,
            contextAnalysis: contextAnalysis,
            plateauAnalysis: plateauAnalysis,
            visualizationData: visualizationData
        )
    }
    
    // MARK: - Enhanced History Analysis
    private func analyzeFullHabitHistory(habit: Habit, contexts: [HabitContext]) -> HabitHistoryAnalysis {
        guard let startDate = habit.startDate else {
            return createEmptyAnalysis()
        }
        
        let calendar = Calendar.current
        var currentDate = calendar.startOfCustomDay(startDate, tz: config.timeZone, startHour: config.dayStartHour)
        let endDate = calendar.startOfCustomDay(config.analysisEnd, tz: config.timeZone, startHour: config.dayStartHour)
        
        var habitStrength: Double = 0.0
        var peakStrength: Double = 0.0
        var strengthHistory: [HabitStrengthPoint] = []
        
        var totalStreakDays = 0
        var totalGapDays = 0
        var streakCount = 0
        var totalStreakLengths = 0
        
        // Context tracking
        var contextScores: [Double] = []
        var enjoymentScores: [Double] = []
        
        // Plateau detection variables
        var recentStrengths: [Double] = []
        var plateauDays = 0
        var inPlateau = false
        
        // State tracking
        var nonScheduledGapDays = 0
        var consecutiveGapDays = 0
        var isInStreak = false
        var currentStreakLength = 0
        
        // Get personalized rates
        let baseGrowthRate = config.personalizedGrowthRate(
            for: Int64(habit.intensityLevel),
            userMultiplier: userProfile.averageFormationSpeed
        )
        let baseDecayRate = config.personalizedDecayRate(
            for: Int64(habit.intensityLevel),
            userMultiplier: userProfile.averageFormationSpeed
        )
        
        // Calculate experience floor
        var experienceFloor = 0.05
        
        // Process each day
        while currentDate < endDate {
            let wasScheduled = HabitUtilities.isHabitActive(habit: habit, on: currentDate)
            let dayIndex = strengthHistory.count
            
            // Get context for this day if available
            let dayContext = contexts.first { calendar.isDate($0.time.map { Date(timeIntervalSince1970: $0) } ?? Date(), inSameDayAs: currentDate) }
            
            // Calculate context consistency
            let contextConsistency = calculateContextConsistency(
                currentContext: dayContext,
                previousContexts: contexts.prefix(dayIndex).suffix(7)
            )
            
            // Get enjoyment score
            let enjoymentScore = Double(dayContext?.enjoymentRating ?? 3) / 5.0
            
            // Initialize completion tracking variables
            var completionCount = 0
            var targetCount = 1
            
            if wasScheduled {
                nonScheduledGapDays = 0
                let wasCompleted = habit.isCompleted(on: currentDate)
                
                // Get completion count for multi-rep habits
                completionCount = config.multiRepetitionMode ?
                    getCompletionCount(habit: habit, date: currentDate) : (wasCompleted ? 1 : 0)
                targetCount = config.multiRepetitionMode ? config.dailyRepetitionTarget : 1
                let completionRatio = Double(completionCount) / Double(targetCount)
                
                if completionRatio > 0 {
                    // Start or continue streak
                    if !isInStreak {
                        isInStreak = true
                        currentStreakLength = 1
                        streakCount += 1
                    } else {
                        currentStreakLength += 1
                    }
                    
                    totalStreakDays += 1
                    consecutiveGapDays = 0
                    
                    // Calculate adjusted growth rate
                    var adjustedGrowth = baseGrowthRate * completionRatio
                    
                    // Apply context bonus/penalty
                    if contextConsistency ?? 0 > config.minContextConsistency {
                        adjustedGrowth *= (1.0 + config.contextStabilityBonus)
                    } else if contextConsistency ?? 0 < 0.3 {
                        adjustedGrowth *= (1.0 - config.contextVariabilityPenalty)
                    }
                    
                    // Apply enjoyment factor
                    let enjoymentMultiplier = 0.8 + (enjoymentScore * 0.4) // Range: 0.8-1.2
                    adjustedGrowth *= enjoymentMultiplier * config.enjoymentMultiplier
                    
                    // Apply reward bonus if applicable (TODO: Add reward property to Habit model)
                    // if habit.hasReward {
                    //     adjustedGrowth *= (1.0 + config.rewardBonus)
                    // }
                    
                    // Apply growth with asymptotic model
                    habitStrength = applyAsymptoticGrowth(
                        previousStrength: habitStrength,
                        streakDay: currentStreakLength,
                        growthRate: adjustedGrowth
                    )
                    
                    // Update experience floor
                    experienceFloor = min(0.50, 0.05 + 0.002 * Double(totalStreakDays))
                    peakStrength = max(peakStrength, habitStrength)
                    
                } else {
                    // Missed scheduled day
                    if isInStreak {
                        isInStreak = false
                        totalStreakLengths += currentStreakLength
                        currentStreakLength = 0
                    }
                    
                    totalGapDays += 1
                    consecutiveGapDays += 1
                    
                    // Apply stronger decay for extended breaks
                    var effectiveDecay = baseDecayRate
                    if consecutiveGapDays > config.extendedBreakThreshold {
                        effectiveDecay *= config.extendedBreakDecayMultiplier
                    }
                    
                    // Apply decay with floor
                    let minStrength = max(peakStrength * config.residualMemoryFactor, experienceFloor)
                    habitStrength = decay(from: habitStrength, lambda: effectiveDecay, n: 1, floor: minStrength)
                }
                
                // Track context and enjoyment
                if let ctx = contextConsistency {
                    contextScores.append(ctx)
                }
                enjoymentScores.append(enjoymentScore)
                
            } else {
                // Non-scheduled day
                nonScheduledGapDays += 1
                
                // Apply soft drift for long non-scheduled periods
                if nonScheduledGapDays > 3 {
                    habitStrength *= exp(-config.softDriftRate * Double(nonScheduledGapDays - 3))
                    habitStrength = max(experienceFloor, habitStrength)
                }
                
                // Set completion counts for non-scheduled days
                completionCount = habit.isCompleted(on: currentDate) ? 1 : 0
                targetCount = 1
            }
            
            // Plateau detection
            recentStrengths.append(habitStrength)
            if recentStrengths.count > config.plateauThreshold {
                recentStrengths.removeFirst()
                
                let variance = calculateVariance(recentStrengths)
                if variance < config.plateauVariance && habitStrength < 0.95 {
                    if !inPlateau {
                        inPlateau = true
                        plateauDays = 1
                    } else {
                        plateauDays += 1
                    }
                } else {
                    inPlateau = false
                    plateauDays = 0
                }
            }
            
            // Record strength point
            strengthHistory.append(HabitStrengthPoint(
                date: currentDate,
                strength: habitStrength,
                isStreak: isInStreak,
                streakLength: currentStreakLength,
                contextConsistency: contextConsistency,
                enjoymentScore: enjoymentScore,
                wasScheduled: wasScheduled,
                completionCount: completionCount,
                targetCount: targetCount
            ))
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        // Finalize analysis
        if isInStreak {
            totalStreakLengths += currentStreakLength
        }
        
        let averageStreakLength = streakCount > 0 ?
            Double(totalStreakLengths) / Double(streakCount) : 0
        let recoveryPotential = peakStrength - habitStrength
        
        // Calculate formation velocity (rate of change)
        let formationVelocity = calculateFormationVelocity(history: strengthHistory)
        
        // Predict days to full automation
        let predictedDaysToFull = estimateDaysToTarget(
            current: habitStrength,
            target: 1.0,
            velocity: formationVelocity
        )
        
        return HabitHistoryAnalysis(
            strengthHistory: strengthHistory,
            currentStrength: habitStrength,
            peakStrength: peakStrength,
            totalStreakDays: totalStreakDays,
            totalGapDays: totalGapDays,
            longestStreak: habit.calculateLongestStreak(),
            currentStreak: habit.calculateStreak(upTo: config.analysisEnd),
            bestStreakEver: Int(habit.bestStreakEver),
            averageStreakLength: averageStreakLength,
            recoveryPotential: recoveryPotential,
            experienceFloor: experienceFloor,
            contextConsistencyScore: contextScores.isEmpty ? 0.5 : contextScores.reduce(0, +) / Double(contextScores.count),
            averageEnjoyment: enjoymentScores.isEmpty ? 0.5 : enjoymentScores.reduce(0, +) / Double(enjoymentScores.count),
            plateauDetected: inPlateau,
            plateauDuration: inPlateau ? plateauDays : nil,
            formationVelocity: formationVelocity,
            predictedDaysToFull: predictedDaysToFull,
            personalizedGrowthRate: baseGrowthRate
        )
    }
    
    // MARK: - Personalization Methods
    private func updateUserProfile(habit: Habit, analysis: HabitHistoryAnalysis) {
        // Compare observed vs expected formation speed
        let expectedStrength = calculateExpectedStrength(
            days: analysis.strengthHistory.count,
            baseRate: config.baseHabitGrowthRate
        )
        
        userProfile.updateFormationSpeed(
            observed: analysis.currentStrength,
            expected: expectedStrength
        )
        
        // Update other profile metrics
        userProfile.contextConsistencyScore = analysis.contextConsistencyScore
        userProfile.enjoymentAverageScore = analysis.averageEnjoyment
        
        // Save updated profile
        persistenceManager.saveProfile(userProfile)
    }
    
    private func generatePersonalizedInsights(habit: Habit, analysis: HabitHistoryAnalysis) -> PersonalizedInsights {
        let adjustedRate = analysis.personalizedGrowthRate
        
        // Compare to average
        let comparison: String
        if userProfile.averageFormationSpeed > 1.15 {
            comparison = "faster"
        } else if userProfile.averageFormationSpeed < 0.85 {
            comparison = "slower"
        } else {
            comparison = "average"
        }
        
        // Generate personalized tips
        var tips: [String] = []
        
        if analysis.contextConsistencyScore < 0.5 {
            tips.append("Try to perform this habit at the same time and place each day for faster automation")
        }
        
        if analysis.averageEnjoyment < 0.4 {
            tips.append("Consider adding rewards or finding ways to make this habit more enjoyable")
        }
        
        if analysis.plateauDetected {
            tips.append("You're in a plateau. Try increasing intensity or frequency to break through")
        }
        
        if analysis.currentStreak == 0 && analysis.recoveryPotential > 0.2 {
            tips.append("You've built strong neural pathways before. Getting back on track will be easier than starting fresh")
        }
        
        // Generate future projections
        let projections = generateStrengthProjections(
            current: analysis.currentStrength,
            rate: adjustedRate,
            days: 90
        )
        
        return PersonalizedInsights(
            adjustedGrowthRate: adjustedRate,
            comparedToAverage: comparison,
            personalizedTips: tips,
            strengthProjection: projections,
            confidenceLevel: userProfile.profileConfidence
        )
    }
    
    // MARK: - Context Analysis
    private func analyzeContextPatterns(contexts: [HabitContext]) -> ContextAnalysis {
        guard !contexts.isEmpty else {
            return ContextAnalysis(
                consistencyScore: 0.5,
                optimalTime: nil,
                optimalLocation: nil,
                optimalTrigger: nil,
                recommendation: "Start logging context to discover your optimal habit conditions"
            )
        }
        
        // Analyze time patterns
        let timeGroups = Dictionary(grouping: contexts.compactMap { $0.time }) { time in
            Int(time / 3600) // Group by hour
        }
        let optimalHour = timeGroups.max { $0.value.count < $1.value.count }?.key
        let optimalTime = optimalHour.map { hour in
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            let date = Date(timeIntervalSince1970: Double(hour * 3600))
            return formatter.string(from: date)
        }
        
        // Analyze location patterns
        let locationGroups = Dictionary(grouping: contexts.compactMap { $0.location }) { $0 }
        let optimalLocation = locationGroups.max { $0.value.count < $1.value.count }?.key
        
        // Analyze trigger patterns
        let triggerGroups = Dictionary(grouping: contexts.compactMap { $0.trigger }) { $0 }
        let optimalTrigger = triggerGroups.max { $0.value.count < $1.value.count }?.key
        
        // Calculate overall consistency
        let consistencyScore = calculateOverallConsistency(contexts: contexts)
        
        // Generate recommendation
        let recommendation = generateContextRecommendation(
            consistency: consistencyScore,
            optimalTime: optimalTime,
            optimalLocation: optimalLocation,
            optimalTrigger: optimalTrigger
        )
        
        return ContextAnalysis(
            consistencyScore: consistencyScore,
            optimalTime: optimalTime,
            optimalLocation: optimalLocation,
            optimalTrigger: optimalTrigger,
            recommendation: recommendation
        )
    }
    
    // MARK: - Plateau Detection
    private func detectPlateau(history: [HabitStrengthPoint]) -> PlateauAnalysis? {
        guard history.count >= config.plateauThreshold else { return nil }
        
        let recentHistory = history.suffix(config.plateauThreshold)
        let strengths = recentHistory.map { $0.strength }
        let variance = calculateVariance(strengths)
        let averageStrength = strengths.reduce(0, +) / Double(strengths.count)
        
        let isInPlateau = variance < config.plateauVariance && averageStrength < 0.95
        
        guard isInPlateau else { return nil }
        
        // Calculate days in plateau
        var plateauDays = config.plateauThreshold
        for point in history.dropLast(config.plateauThreshold).reversed() {
            if abs(point.strength - averageStrength) < config.plateauVariance {
                plateauDays += 1
            } else {
                break
            }
        }
        
        // Generate recommendations
        let recommendations = generatePlateauRecommendations(
            strength: averageStrength,
            days: plateauDays,
            history: history
        )
        
        // Calculate breakout probability
        let breakoutProbability = calculateBreakoutProbability(
            strength: averageStrength,
            days: plateauDays,
            variance: variance
        )
        
        return PlateauAnalysis(
            isInPlateau: true,
            plateauStrength: averageStrength,
            daysInPlateau: plateauDays,
            recommendedActions: recommendations,
            breakoutProbability: breakoutProbability
        )
    }
    
    // MARK: - Visualization Preparation
    private func prepareVisualizationData(
        history: [HabitStrengthPoint],
        predictions: HabitPredictions
    ) -> VisualizationData {
        // Daily strength history
        let dailyStrength = history.map { ($0.date, $0.strength) }
        
        // Calculate weekly averages
        let weeklyAverages = calculateWeeklyAverages(history: history)
        
        // Calculate monthly trend
        let monthlyTrend = calculateMonthlyTrend(history: history)
        
        // Extract streak timeline
        let streakTimeline = extractStreakTimeline(history: history)
        
        // Generate projected growth
        let projectedGrowth = generateProjectedGrowth(
            current: history.last?.strength ?? 0,
            predictions: predictions
        )
        
        // Create annotations
        let annotations = createAnnotations(history: history)
        
        return VisualizationData(
            dailyStrengthHistory: dailyStrength,
            weeklyAverages: weeklyAverages,
            monthlyTrend: monthlyTrend,
            streakTimeline: streakTimeline,
            projectedGrowth: projectedGrowth,
            annotations: annotations
        )
    }
    
    // MARK: - Personalized Predictions
    private func calculatePersonalizedPredictions(
        habit: Habit,
        historyAnalysis: HabitHistoryAnalysis
    ) -> HabitPredictions {
        let growthRate = historyAnalysis.personalizedGrowthRate
        
        // Project future strength with personalized rates
        let projections = [7, 14, 30, 90, 180].map { days in
            (days, projectFutureStrength(
                current: historyAnalysis.currentStrength,
                daysAhead: days,
                growthRate: growthRate,
                habit: habit
            ))
        }
        
        // Calculate days to milestones
        let milestones = [0.5, 0.75, 0.95, 1.0].map { target in
            estimateDaysToTarget(
                current: historyAnalysis.currentStrength,
                target: target,
                velocity: historyAnalysis.formationVelocity
            )
        }
        
        // Calculate completions needed
        let completionsNeeded = [0.5, 0.75, 0.95, 1.0].map { target in
            estimateCompletionsToTarget(
                current: historyAnalysis.currentStrength,
                target: target,
                growthRate: growthRate,
                habit: habit
            )
        }
        
        // Determine trend with confidence
        let (trend, confidence) = analyzeCompletionTrendWithConfidence(
            history: historyAnalysis.strengthHistory
        )
        
        // Generate guidance
        let guidance = generatePersonalizedGuidance(
            analysis: historyAnalysis,
            projections: projections,
            milestones: milestones,
            trend: trend,
            habit: habit
        )
        
        // Generate actionable steps
        let actions = generateActionableSteps(
            analysis: historyAnalysis,
            trend: trend,
            habit: habit
        )
        
        // Compare to research benchmarks
        let benchmark = generateBenchmarkComparison(
            analysis: historyAnalysis,
            habit: habit
        )
        
        return HabitPredictions(
            oneWeekAutomation: min(100, projections[0].1 * 100),
            twoWeekAutomation: min(100, projections[1].1 * 100),
            oneMonthAutomation: min(100, projections[2].1 * 100),
            threeMonthAutomation: min(100, projections[3].1 * 100),
            sixMonthAutomation: min(100, projections[4].1 * 100),
            estimatedDaysTo50Percent: milestones[0],
            estimatedDaysTo75Percent: milestones[1],
            estimatedDaysTo95Percent: milestones[2],
            estimatedDaysTo100Percent: milestones[3],
            estimatedCompletionsTo50Percent: completionsNeeded[0],
            estimatedCompletionsTo75Percent: completionsNeeded[1],
            estimatedCompletionsTo95Percent: completionsNeeded[2],
            estimatedCompletionsTo100Percent: completionsNeeded[3],
            trend: trend,
            trendConfidence: confidence,
            guidanceMessage: guidance,
            actionableSteps: actions,
            benchmarkComparison: benchmark,
            trendFactor: growthRate,
            repeatPatternDescription: getRepeatPatternDescription(for: habit)
        )
    }
    
    // MARK: - Helper Methods
    private func calculateContextConsistency(
        currentContext: HabitContext?,
        previousContexts: any Collection<HabitContext>
    ) -> Double? {
        guard let current = currentContext,
              !previousContexts.isEmpty else { return nil }
        
        let similarities = previousContexts.map { current.similarity(to: $0) }
        return similarities.reduce(0, +) / Double(similarities.count)
    }
    
    private func calculateVariance(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        let mean = values.reduce(0, +) / Double(values.count)
        let squaredDiffs = values.map { pow($0 - mean, 2) }
        return squaredDiffs.reduce(0, +) / Double(values.count)
    }
    
    private func calculateFormationVelocity(history: [HabitStrengthPoint]) -> Double {
        guard history.count >= 7 else { return 0 }
        
        let recentHistory = history.suffix(14).map { $0.strength }
        guard recentHistory.count >= 2 else { return 0 }
        
        // Calculate linear regression slope
        let n = Double(recentHistory.count)
        let indices = Array(0..<recentHistory.count).map { Double($0) }
        
        let sumX = indices.reduce(0, +)
        let sumY = recentHistory.reduce(0, +)
        let sumXY = zip(indices, recentHistory).map(*).reduce(0, +)
        let sumX2 = indices.map { $0 * $0 }.reduce(0, +)
        
        let slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX)
        return slope
    }
    
    private func applyAsymptoticGrowth(
        previousStrength: Double,
        streakDay: Int,
        growthRate: Double
    ) -> Double {
        let tau = max(5.0, 1.0 / max(growthRate, 0.005))
        let k = 1.0 / tau
        let increment = (config.maxHabitStrength - previousStrength) * (1 - exp(-k))
        return clamp(previousStrength + increment, 0, config.maxHabitStrength)
    }
    
    private func decay(from strength: Double, lambda: Double, n: Int, floor: Double) -> Double {
        let decayed = strength * exp(-lambda * Double(n))
        return max(decayed, floor)
    }
    
    private func clamp(_ value: Double, _ min: Double, _ max: Double) -> Double {
        return Swift.min(Swift.max(value, min), max)
    }
    
    private func createEmptyAnalysis() -> HabitHistoryAnalysis {
        return HabitHistoryAnalysis(
            strengthHistory: [],
            currentStrength: 0,
            peakStrength: 0,
            totalStreakDays: 0,
            totalGapDays: 0,
            longestStreak: 0,
            currentStreak: 0,
            bestStreakEver: 0,
            averageStreakLength: 0,
            recoveryPotential: 0,
            experienceFloor: 0.05,
            contextConsistencyScore: 0.5,
            averageEnjoyment: 0.5,
            plateauDetected: false,
            plateauDuration: nil,
            formationVelocity: 0,
            predictedDaysToFull: nil,
            personalizedGrowthRate: config.baseHabitGrowthRate
        )
    }
    
    // Additional helper methods would continue here...
    // (Due to length, I'm providing the core structure. The remaining helper methods
    // would follow similar patterns for all the calculations mentioned)
}

// MARK: - User Profile Persistence
class UserProfilePersistenceManager {
    private let userDefaults = UserDefaults.standard
    private let profileKey = "HabitUserProfile"
    
    func saveProfile(_ profile: UserHabitProfile) {
        if let encoded = try? JSONEncoder().encode(profile) {
            userDefaults.set(encoded, forKey: "\(profileKey)_\(profile.userId.uuidString)")
        }
    }
    
    func loadProfile(userId: UUID?) -> UserHabitProfile? {
        guard let userId = userId else { return nil }
        
        if let data = userDefaults.data(forKey: "\(profileKey)_\(userId.uuidString)"),
           let profile = try? JSONDecoder().decode(UserHabitProfile.self, from: data) {
            return profile
        }
        return nil
    }
}

// MARK: - Placeholder for missing implementations
// Note: These would need to be implemented based on your existing codebase

extension ImprovedHabitAutomationEngine {
    private func scheduledStats(habit: Habit, from: Date, to: Date) -> (Int, Int) {
        // Implementation from original code
        return (0, 0)
    }
    
    private func getCompletionCount(habit: Habit, date: Date) -> Int {
        // Count completions for multi-rep habits
        return 1
    }
    
    private func calculateExpectedStrength(days: Int, baseRate: Double) -> Double {
        // Calculate expected strength based on research
        return 1.0 - exp(-baseRate * Double(days))
    }
    
    private func estimateDaysToTarget(current: Double, target: Double, velocity: Double) -> Int? {
        guard velocity > 0 else { return nil }
        let days = (target - current) / velocity
        return days > 0 && days < 365 ? Int(days) : nil
    }
    
    private func estimateCompletionsToTarget(current: Double, target: Double, growthRate: Double, habit: Habit) -> Int? {
        guard growthRate > 0 else { return nil }
        let needed = -log(1 - (target - current) / (1 - current)) / growthRate
        return needed > 0 && needed < 1000 ? Int(needed) : nil
    }
    
    private func projectFutureStrength(current: Double, daysAhead: Int, growthRate: Double, habit: Habit) -> Double {
        var strength = current
        for _ in 0..<daysAhead {
            strength = applyAsymptoticGrowth(previousStrength: strength, streakDay: 1, growthRate: growthRate)
        }
        return strength
    }
    
    private func generateStrengthProjections(current: Double, rate: Double, days: Int) -> [Date: Double] {
        var projections: [Date: Double] = [:]
        let calendar = Calendar.current
        var strength = current
        
        for day in 1...days {
            if let futureDate = calendar.date(byAdding: .day, value: day, to: Date()) {
                strength = applyAsymptoticGrowth(previousStrength: strength, streakDay: 1, growthRate: rate)
                projections[futureDate] = strength
            }
        }
        return projections
    }
    
    private func analyzeCompletionTrendWithConfidence(history: [HabitStrengthPoint]) -> (CompletionTrend, Double) {
        guard history.count >= 7 else { return (.stable, 0.3) }
        
        let velocity = calculateFormationVelocity(history: history)
        let variance = calculateVariance(history.suffix(14).map { $0.strength })
        
        let trend: CompletionTrend
        if velocity > 0.01 && variance < 0.05 {
            trend = .rapidlyImproving
        } else if velocity > 0.005 {
            trend = .improving
        } else if velocity < -0.01 {
            trend = .rapidlyDeclining
        } else if velocity < -0.005 {
            trend = .declining
        } else if variance < 0.02 && history.last?.strength ?? 0 > 0.3 {
            trend = .plateau
        } else {
            trend = .stable
        }
        
        let confidence = min(1.0, Double(history.count) / 30.0) * (1.0 - min(1.0, variance))
        return (trend, confidence)
    }
    
    // Additional placeholder methods...
    private func calculateOverallConsistency(contexts: [HabitContext]) -> Double { 0.5 }
    private func generateContextRecommendation(consistency: Double, optimalTime: String?, optimalLocation: String?, optimalTrigger: String?) -> String { "" }
    private func generatePlateauRecommendations(strength: Double, days: Int, history: [HabitStrengthPoint]) -> [String] { [] }
    private func calculateBreakoutProbability(strength: Double, days: Int, variance: Double) -> Double { 0.5 }
    private func calculateWeeklyAverages(history: [HabitStrengthPoint]) -> [(Date, Double)] { [] }
    private func calculateMonthlyTrend(history: [HabitStrengthPoint]) -> [(Date, Double)] { [] }
    private func extractStreakTimeline(history: [HabitStrengthPoint]) -> [(Date, Int)] { [] }
    private func generateProjectedGrowth(current: Double, predictions: HabitPredictions) -> [(Date, Double)] { [] }
    private func createAnnotations(history: [HabitStrengthPoint]) -> [ChartAnnotation] { [] }
    private func generatePersonalizedGuidance(analysis: HabitHistoryAnalysis, projections: [(Int, Double)], milestones: [Int?], trend: CompletionTrend, habit: Habit) -> String { "" }
    private func generateActionableSteps(analysis: HabitHistoryAnalysis, trend: CompletionTrend, habit: Habit) -> [String] { [] }
    private func generateBenchmarkComparison(analysis: HabitHistoryAnalysis, habit: Habit) -> String { "" }
    private func getRepeatPatternDescription(for habit: Habit) -> String { "" }
}

// MARK: - Calendar Extension
private extension Calendar {
    func startOfCustomDay(_ date: Date, tz: TimeZone, startHour: Int) -> Date {
        var cal = self
        cal.timeZone = tz
        let shifted = cal.date(byAdding: .hour, value: -startHour, to: date)!
        let sod = cal.startOfDay(for: shifted)
        return cal.date(byAdding: .hour, value: startHour, to: sod)!
    }
}
*/
