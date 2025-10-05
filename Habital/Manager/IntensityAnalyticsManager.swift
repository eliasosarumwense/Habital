import Foundation
import CoreData

// MARK: - Configuration & Models
/*
struct AnalyticsConfig {
    var zone: TimeZone = TimeZone.current
    var dayStartHour: Int = 4 // Day starts at 4 AM
    var morningRange: Range<Int> = 5..<11
    var afternoonRange: Range<Int> = 11..<17
    var eveningRange: Range<Int> = 17..<23
    var nightRange: Range<Int> = 23..<29 // Wraps to next day
    var goldilocksLow: Double = 0.60
    var goldilocksHigh: Double = 0.85
    var upgradeHigh: Double = 0.85
    var downgradeLow: Double = 0.50
    var stabilizationThreshold: Double = 0.80
    var stabilizationHoldDays: Int = 14
}

struct LevelAnalytics {
    let level: Int
    let habitCount: Int
    // Rates
    let successRate30d: Double
    let baselineRate30d: Double
    let trendDelta: Double
    let goldilocks: GoldilocksStatus
    // Streaks
    let currentStreakDays: Int
    let bestStreakDays: Int
    let bounceBackDaysMedian: Double?
    // Timing
    let rateMorning: Double
    let rateAfternoon: Double
    let rateEvening: Double
    let rateNight: Double
    // Strain
    let meanMoodImpact: Double?
    let meanEnergyImpact: Double?
    let meanDuration: Double?
    let strainZ: Double?
    // Plan adherence
    let expected30d: Int
    let completed30d: Int
    let adherence30d: Double
    // Stabilization
    let stabilizationDays: Int?
    // Weeks
    let bestWeek: WeekRate?
    let worstWeek: WeekRate?
    // Recommendation
    let recommendation: Recommendation?
}

struct WeekRate {
    let year: Int
    let week: Int
    let rate: Double
}

enum GoldilocksStatus {
    case tooEasy, optimal, tooHard, notApplicable
}

struct Recommendation {
    let rule: String
    let message: String
}

struct SeriesPoint {
    let date: Date
    let successRate7d: Double
}

struct LevelSeries {
    let level: Int
    let points: [SeriesPoint]
}

// MARK: - Internal Models

private struct ExpectedOccurrence {
    let habitID: UUID
    let date: Date
    let slotIndexInDay: Int
    let habit: Habit
}

private struct OccurrenceResult {
    let expected: ExpectedOccurrence
    var isCompleted: Bool = false
    var completion: Completion?
}

// MARK: - Main Manager

class IntensityAnalyticsManager {
    
    private let context: NSManagedObjectContext
    private let config: AnalyticsConfig
    private var calendar: Calendar
    
    init(context: NSManagedObjectContext, config: AnalyticsConfig = AnalyticsConfig()) {
        self.context = context
        self.config = config
        self.calendar = Calendar.current
        self.calendar.timeZone = config.zone
    }
    
    // MARK: - Public Interface
    
    func computeLevelAnalytics(from: Date, to: Date) throws -> [LevelAnalytics] {
        var results: [LevelAnalytics] = []
        
        for level in 1...4 {
            if let analytics = try computeAnalyticsForLevel(level, from: from, to: to) {
                results.append(analytics)
            }
        }
        
        return results
    }
    
    func levelSeries(from: Date, to: Date) throws -> [LevelSeries] {
        var results: [LevelSeries] = []
        
        for level in 1...4 {
            let series = try computeSeriesForLevel(level, from: from, to: to)
            if !series.points.isEmpty {
                results.append(series)
            }
        }
        
        return results
    }
    
    // MARK: - Core Analytics Computation
    
    private func computeAnalyticsForLevel(_ level: Int, from: Date, to: Date) throws -> LevelAnalytics? {
        // Fetch habits for this intensity level
        let habits = try fetchHabits(level: level)
        guard !habits.isEmpty else { return nil }
        
        // Define time windows
        let now = Date()
        let last30d = calendar.date(byAdding: .day, value: -30, to: now)!
        let last60d = calendar.date(byAdding: .day, value: -60, to: now)!
        let last90d = calendar.date(byAdding: .day, value: -90, to: now)!
        
        // Build expected occurrences and map completions
        let recent30 = try processOccurrences(habits: habits, from: last30d, to: now)
        let baseline30 = try processOccurrences(habits: habits, from: last60d, to: last30d)
        let last90 = try processOccurrences(habits: habits, from: last90d, to: now)
        
        // Calculate core metrics
        let successRate30d = calculateSuccessRate(occurrences: recent30)
        let baselineRate30d = calculateSuccessRate(occurrences: baseline30)
        let trendDelta = successRate30d - baselineRate30d
        
        // Goldilocks status
        let goldilocks = determineGoldilocksStatus(rate: successRate30d)
        
        // Streaks
        let (currentStreak, bestStreak) = calculateStreaks(habits: habits, to: now)
        
        // Time-of-day analysis
        let (rateMorning, rateAfternoon, rateEvening, rateNight) = calculateTimeOfDayRates(occurrences: recent30)
        
        // Strain metrics
        let (moodImpact, energyImpact, duration, strainZ) = calculateStrainMetrics(occurrences: recent30, allLevels: 1...4)
        
        // Adherence
        let expected30d = recent30.count
        let completed30d = recent30.filter { $0.isCompleted }.count
        let adherence30d = expected30d > 0 ? Double(completed30d) / Double(expected30d) : 0
        
        // Weekly analysis
        let (bestWeek, worstWeek) = try analyzeWeeklyPerformance(habits: habits, weeks: 12)
        
        // Bounce-back time
        let bounceBackMedian = calculateBounceBackMedian(habits: habits, days: 90)
        
        // Stabilization time
        let stabilizationDays = calculateStabilizationDays(habits: habits)
        
        // Generate recommendation
        let recommendation = generateRecommendation(
            level: level,
            successRate: successRate30d,
            strain: strainZ ?? 0,
            bounceBack: bounceBackMedian,
            morningRate: rateMorning,
            eveningRate: rateEvening
        )
        
        return LevelAnalytics(
            level: level,
            habitCount: habits.count,
            successRate30d: successRate30d,
            baselineRate30d: baselineRate30d,
            trendDelta: trendDelta,
            goldilocks: goldilocks,
            currentStreakDays: currentStreak,
            bestStreakDays: bestStreak,
            bounceBackDaysMedian: bounceBackMedian,
            rateMorning: rateMorning,
            rateAfternoon: rateAfternoon,
            rateEvening: rateEvening,
            rateNight: rateNight,
            meanMoodImpact: moodImpact,
            meanEnergyImpact: energyImpact,
            meanDuration: duration,
            strainZ: strainZ,
            expected30d: expected30d,
            completed30d: completed30d,
            adherence30d: adherence30d,
            stabilizationDays: stabilizationDays,
            bestWeek: bestWeek,
            worstWeek: worstWeek,
            recommendation: recommendation
        )
    }
    
    // MARK: - Expected Occurrences Generation
    
    private func buildExpectedOccurrences(habits: [Habit], from: Date, to: Date) -> [ExpectedOccurrence] {
        var occurrences: [ExpectedOccurrence] = []
        
        for habit in habits {
            let activeFrom = max(habit.startDate ?? from, from)
            let activeTo = to
            
            guard activeFrom <= activeTo else { continue }
            
            // Get repeat pattern or default to daily
            // Since repeatPattern is a to-many relationship (NSSet), get the first one
            let repeatPattern = (habit.repeatPattern as? Set<RepeatPattern>)?.first
            let dailyOccurrences = generateDailyOccurrences(
                habit: habit,
                pattern: repeatPattern,
                from: activeFrom,
                to: activeTo
            )
            
            occurrences.append(contentsOf: dailyOccurrences)
        }
        
        return occurrences
    }
    
    private func generateDailyOccurrences(habit: Habit, pattern: RepeatPattern?, from: Date, to: Date) -> [ExpectedOccurrence] {
        var occurrences: [ExpectedOccurrence] = []
        
        // Default to daily if no pattern
        guard let pattern = pattern else {
            return generateDefaultDailyOccurrences(habit: habit, from: from, to: to)
        }
        
        // Handle different goal types
        if let dailyGoal = pattern.dailyGoal {
            occurrences = generateDailyGoalOccurrences(habit: habit, goal: dailyGoal, from: from, to: to)
        } else if let weeklyGoal = pattern.weeklyGoal {
            occurrences = generateWeeklyGoalOccurrences(habit: habit, goal: weeklyGoal, from: from, to: to)
        } else if let monthlyGoal = pattern.monthlyGoal {
            occurrences = generateMonthlyGoalOccurrences(habit: habit, goal: monthlyGoal, from: from, to: to)
        }
        
        // Apply repeats per day if specified
        let repeatsPerDay = Int(pattern.repeatsPerDay)
        if repeatsPerDay > 1 {
            occurrences = multiplyOccurrences(occurrences, repeats: repeatsPerDay)
        }
        
        return occurrences
    }
    
    private func generateDefaultDailyOccurrences(habit: Habit, from: Date, to: Date) -> [ExpectedOccurrence] {
        var occurrences: [ExpectedOccurrence] = []
        var currentDate = startOfDay(from)
        let endDate = startOfDay(to)
        
        while currentDate <= endDate {
            occurrences.append(ExpectedOccurrence(
                habitID: habit.id!,
                date: currentDate,
                slotIndexInDay: 0,
                habit: habit
            ))
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        return occurrences
    }
    
    private func generateDailyGoalOccurrences(habit: Habit, goal: DailyGoal, from: Date, to: Date) -> [ExpectedOccurrence] {
        var occurrences: [ExpectedOccurrence] = []
        var currentDate = startOfDay(from)
        let endDate = startOfDay(to)
        
        if goal.everyDay {
            // Every day
            while currentDate <= endDate {
                occurrences.append(ExpectedOccurrence(
                    habitID: habit.id!,
                    date: currentDate,
                    slotIndexInDay: 0,
                    habit: habit
                ))
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            }
        } else if goal.daysInterval > 0 {
            // Every N days
            let interval = Int(goal.daysInterval)
            var dayCount = 0
            
            while currentDate <= endDate {
                if dayCount % interval == 0 {
                    occurrences.append(ExpectedOccurrence(
                        habitID: habit.id!,
                        date: currentDate,
                        slotIndexInDay: 0,
                        habit: habit
                    ))
                }
                dayCount += 1
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            }
        } else if let specificDays = goal.specificDays as? [Int], !specificDays.isEmpty {
            // Specific weekdays
            while currentDate <= endDate {
                let weekday = calendar.component(.weekday, from: currentDate)
                if specificDays.contains(weekday) {
                    occurrences.append(ExpectedOccurrence(
                        habitID: habit.id!,
                        date: currentDate,
                        slotIndexInDay: 0,
                        habit: habit
                    ))
                }
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            }
        }
        
        return occurrences
    }
    
    private func generateWeeklyGoalOccurrences(habit: Habit, goal: WeeklyGoal, from: Date, to: Date) -> [ExpectedOccurrence] {
        var occurrences: [ExpectedOccurrence] = []
        var currentDate = startOfDay(from)
        let endDate = startOfDay(to)
        
        let weekInterval = max(1, Int(goal.weekInterval))
        var weekCount = 0
        
        while currentDate <= endDate {
            let weekOfYear = calendar.component(.weekOfYear, from: currentDate)
            let isTargetWeek = weekCount % weekInterval == 0
            
            if isTargetWeek {
                if goal.everyWeek {
                    // Add for specific days if defined, otherwise daily
                    if let days = goal.specificDays as? [Int], !days.isEmpty {
                        let weekday = calendar.component(.weekday, from: currentDate)
                        if days.contains(weekday) {
                            occurrences.append(ExpectedOccurrence(
                                habitID: habit.id!,
                                date: currentDate,
                                slotIndexInDay: 0,
                                habit: habit
                            ))
                        }
                    } else {
                        occurrences.append(ExpectedOccurrence(
                            habitID: habit.id!,
                            date: currentDate,
                            slotIndexInDay: 0,
                            habit: habit
                        ))
                    }
                }
            }
            
            // Track week changes
            let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            let nextWeek = calendar.component(.weekOfYear, from: nextDate)
            if nextWeek != weekOfYear {
                weekCount += 1
            }
            
            currentDate = nextDate
        }
        
        return occurrences
    }
    
    private func generateMonthlyGoalOccurrences(habit: Habit, goal: MonthlyGoal, from: Date, to: Date) -> [ExpectedOccurrence] {
        var occurrences: [ExpectedOccurrence] = []
        var currentDate = startOfDay(from)
        let endDate = startOfDay(to)
        
        let monthInterval = max(1, Int(goal.monthInterval))
        var monthCount = 0
        
        while currentDate <= endDate {
            let month = calendar.component(.month, from: currentDate)
            let isTargetMonth = monthCount % monthInterval == 0
            
            if isTargetMonth && goal.everyMonth {
                if let days = goal.specificDays as? [Int], !days.isEmpty {
                    let dayOfMonth = calendar.component(.day, from: currentDate)
                    if days.contains(dayOfMonth) {
                        occurrences.append(ExpectedOccurrence(
                            habitID: habit.id!,
                            date: currentDate,
                            slotIndexInDay: 0,
                            habit: habit
                        ))
                    }
                }
            }
            
            // Track month changes
            let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            let nextMonth = calendar.component(.month, from: nextDate)
            if nextMonth != month {
                monthCount += 1
            }
            
            currentDate = nextDate
        }
        
        return occurrences
    }
    
    private func multiplyOccurrences(_ occurrences: [ExpectedOccurrence], repeats: Int) -> [ExpectedOccurrence] {
        var multiplied: [ExpectedOccurrence] = []
        
        for occurrence in occurrences {
            for slot in 0..<repeats {
                multiplied.append(ExpectedOccurrence(
                    habitID: occurrence.habitID,
                    date: occurrence.date,
                    slotIndexInDay: slot,
                    habit: occurrence.habit
                ))
            }
        }
        
        return multiplied
    }
    
    // MARK: - Completion Mapping
    
    private func processOccurrences(habits: [Habit], from: Date, to: Date) throws -> [OccurrenceResult] {
        let expectedOccurrences = buildExpectedOccurrences(habits: habits, from: from, to: to)
        let completions = try fetchCompletions(habits: habits, from: from, to: to)
        
        // Group completions by habit and date
        var completionMap: [UUID: [Date: [Completion]]] = [:]
        for completion in completions {
            guard let habitID = completion.habit?.id else { continue }
            let dayStart = startOfDay(completion.date!)
            
            if completionMap[habitID] == nil {
                completionMap[habitID] = [:]
            }
            if completionMap[habitID]![dayStart] == nil {
                completionMap[habitID]![dayStart] = []
            }
            completionMap[habitID]![dayStart]!.append(completion)
        }
        
        // Map completions to expected occurrences
        var results: [OccurrenceResult] = []
        
        for expected in expectedOccurrences {
            var result = OccurrenceResult(expected: expected)
            
            let dayStart = startOfDay(expected.date)
            if let dayCompletions = completionMap[expected.habitID]?[dayStart],
               expected.slotIndexInDay < dayCompletions.count {
                // Since completions only exist when completed=true, any completion counts
                result.isCompleted = true
                result.completion = dayCompletions[expected.slotIndexInDay]
            }
            
            results.append(result)
        }
        
        return results
    }
    
    // MARK: - Metrics Calculation
    
    private func calculateSuccessRate(occurrences: [OccurrenceResult]) -> Double {
        guard !occurrences.isEmpty else { return 0 }
        let completed = occurrences.filter { $0.isCompleted }.count
        return Double(completed) / Double(occurrences.count)
    }
    
    private func determineGoldilocksStatus(rate: Double) -> GoldilocksStatus {
        if rate >= config.goldilocksHigh {
            return .tooEasy
        } else if rate >= config.goldilocksLow {
            return .optimal
        } else if rate > 0 {
            return .tooHard
        } else {
            return .notApplicable
        }
    }
    
    private func calculateStreaks(habits: [Habit], to: Date) -> (current: Int, best: Int) {
        var allDates = Set<Date>()
        var completionsByDate: [Date: Int] = [:]
        var expectedByDate: [Date: Int] = [:]
        
        // Build daily aggregates
        for habit in habits {
            guard let startDate = habit.startDate else { continue }
            let occurrences = buildExpectedOccurrences(habits: [habit], from: startDate, to: to)
            
            for occ in occurrences {
                let day = startOfDay(occ.date)
                allDates.insert(day)
                expectedByDate[day, default: 0] += 1
            }
            
            // Count completions
            if let completions = habit.completion as? Set<Completion> {
                for completion in completions {
                    let day = startOfDay(completion.date!)
                    completionsByDate[day, default: 0] += 1
                }
            }
        }
        
        // Calculate streaks
        let sortedDates = allDates.sorted()
        var currentStreak = 0
        var bestStreak = 0
        
        for date in sortedDates {
            let expected = expectedByDate[date, default: 0]
            let completed = min(completionsByDate[date, default: 0], expected)
            
            if expected > 0 && completed == expected {
                currentStreak += 1
                bestStreak = max(bestStreak, currentStreak)
            } else if expected > 0 {
                currentStreak = 0
            }
        }
        
        return (currentStreak, bestStreak)
    }
    
    private func calculateTimeOfDayRates(occurrences: [OccurrenceResult]) -> (morning: Double, afternoon: Double, evening: Double, night: Double) {
        var buckets: [String: (completed: Int, expected: Int)] = [
            "morning": (0, 0),
            "afternoon": (0, 0),
            "evening": (0, 0),
            "night": (0, 0)
        ]
        
        for result in occurrences {
            let bucket = getTimeBucket(for: result.completion?.whenCompleted ?? result.expected.date)
            buckets[bucket]!.expected += 1
            if result.isCompleted {
                buckets[bucket]!.completed += 1
            }
        }
        
        let morning = buckets["morning"]!.expected > 0 ?
            Double(buckets["morning"]!.completed) / Double(buckets["morning"]!.expected) : 0
        let afternoon = buckets["afternoon"]!.expected > 0 ?
            Double(buckets["afternoon"]!.completed) / Double(buckets["afternoon"]!.expected) : 0
        let evening = buckets["evening"]!.expected > 0 ?
            Double(buckets["evening"]!.completed) / Double(buckets["evening"]!.expected) : 0
        let night = buckets["night"]!.expected > 0 ?
            Double(buckets["night"]!.completed) / Double(buckets["night"]!.expected) : 0
        
        return (morning, afternoon, evening, night)
    }
    
    private func getTimeBucket(for date: Date) -> String {
        let hour = calendar.component(.hour, from: date)
        
        if config.morningRange.contains(hour) {
            return "morning"
        } else if config.afternoonRange.contains(hour) {
            return "afternoon"
        } else if config.eveningRange.contains(hour) {
            return "evening"
        } else {
            return "night"
        }
    }
    
    private func calculateStrainMetrics(occurrences: [OccurrenceResult], allLevels: ClosedRange<Int>) -> (mood: Double?, energy: Double?, duration: Double?, strainZ: Double?) {
        let completed = occurrences.filter { $0.isCompleted && $0.completion != nil }
        guard !completed.isEmpty else { return (nil, nil, nil, nil) }
        
        // Calculate means for this level
        var moodSum = 0.0, energySum = 0.0, durationSum = 0.0
        var moodCount = 0, energyCount = 0, durationCount = 0
        
        for result in completed {
            if let completion = result.completion {
                if completion.moodImpact != 0 {
                    moodSum += Double(completion.moodImpact)
                    moodCount += 1
                }
                if completion.energyImpact != 0 {
                    energySum += Double(completion.energyImpact)
                    energyCount += 1
                }
                if completion.duration > 0 {
                    durationSum += Double(completion.duration)
                    durationCount += 1
                }
            }
        }
        
        let meanMood = moodCount > 0 ? moodSum / Double(moodCount) : nil
        let meanEnergy = energyCount > 0 ? energySum / Double(energyCount) : nil
        let meanDuration = durationCount > 0 ? durationSum / Double(durationCount) : nil
        
        // For proper z-score calculation, we'd need all levels' data
        // Simplified version: normalize to -1 to +1 range
        var strainZ: Double? = nil
        if let mood = meanMood, let energy = meanEnergy, let duration = meanDuration {
            // Simplified strain calculation (higher = more strain)
            // Negative mood impact = strain, negative energy = strain, longer duration = strain
            let moodStrain = -mood / 5.0  // Normalize from -5 to 5 scale
            let energyStrain = -energy / 5.0
            let durationStrain = min(duration / 60.0, 1.0)  // Normalize to 1 hour max
            
            strainZ = (moodStrain * 0.4 + energyStrain * 0.4 + durationStrain * 0.2)
        }
        
        return (meanMood, meanEnergy, meanDuration, strainZ)
    }
    
    private func analyzeWeeklyPerformance(habits: [Habit], weeks: Int) throws -> (best: WeekRate?, worst: WeekRate?) {
        let endDate = Date()
        let startDate = calendar.date(byAdding: .weekOfYear, value: -weeks, to: endDate)!
        
        var weeklyRates: [WeekRate] = []
        var currentWeekStart = startDate
        
        while currentWeekStart < endDate {
            let weekEnd = calendar.date(byAdding: .day, value: 6, to: currentWeekStart)!
            let occurrences = try processOccurrences(habits: habits, from: currentWeekStart, to: weekEnd)
            
            if !occurrences.isEmpty {
                let rate = calculateSuccessRate(occurrences: occurrences)
                let year = calendar.component(.yearForWeekOfYear, from: currentWeekStart)
                let week = calendar.component(.weekOfYear, from: currentWeekStart)
                
                weeklyRates.append(WeekRate(year: year, week: week, rate: rate))
            }
            
            currentWeekStart = calendar.date(byAdding: .weekOfYear, value: 1, to: currentWeekStart)!
        }
        
        let sorted = weeklyRates.sorted { $0.rate > $1.rate }
        return (sorted.first, sorted.last)
    }
    
    private func calculateBounceBackMedian(habits: [Habit], days: Int) -> Double? {
        // Simplified implementation - would need more complex logic for full spec
        // This would track miss events and recovery times
        return nil
    }
    
    private func calculateStabilizationDays(habits: [Habit]) -> Int? {
        // Simplified implementation - would need rolling window analysis
        return nil
    }
    
    // MARK: - Recommendations
    
    private func generateRecommendation(level: Int, successRate: Double, strain: Double, bounceBack: Double?, morningRate: Double, eveningRate: Double) -> Recommendation? {
        // Upgrade suggestion
        if successRate >= config.upgradeHigh && strain <= 0.5 && (bounceBack ?? 3) <= 2 {
            return Recommendation(
                rule: "upgrade",
                message: "Great consistency! Consider increasing intensity or adding more repetitions."
            )
        }
        
        // Hold (sweet spot)
        if successRate >= config.goldilocksLow && successRate < config.goldilocksHigh {
            return Recommendation(
                rule: "hold",
                message: "Perfect balance! Keep up the current intensity and focus on consistency."
            )
        }
        
        // Downgrade suggestion
        if successRate < config.downgradeLow || strain >= 1.0 {
            return Recommendation(
                rule: "downgrade",
                message: "This intensity might be too challenging. Consider reducing by one level."
            )
        }
        
        // Timing tip for high intensity
        if level >= 3 && (morningRate - eveningRate) >= 0.10 {
            return Recommendation(
                rule: "timing",
                message: "You perform better in the morning. Try scheduling this habit earlier in the day."
            )
        }
        
        return nil
    }
    
    // MARK: - Series Generation
    
    private func computeSeriesForLevel(_ level: Int, from: Date, to: Date) throws -> LevelSeries {
        let habits = try fetchHabits(level: level)
        guard !habits.isEmpty else { return LevelSeries(level: level, points: []) }
        
        var points: [SeriesPoint] = []
        var currentDate = from
        
        while currentDate <= to {
            let windowStart = calendar.date(byAdding: .day, value: -6, to: currentDate)!
            let occurrences = try processOccurrences(habits: habits, from: windowStart, to: currentDate)
            let rate = calculateSuccessRate(occurrences: occurrences)
            
            points.append(SeriesPoint(date: currentDate, successRate7d: rate))
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        return LevelSeries(level: level, points: points)
    }
    
    // MARK: - Core Data Access
    
    private func fetchHabits(level: Int) throws -> [Habit] {
        let request: NSFetchRequest<Habit> = Habit.fetchRequest()
        request.predicate = NSPredicate(format: "intensityLevel == %d AND isArchived == false", level)
        return try context.fetch(request)
    }
    
    private func fetchCompletions(habits: [Habit], from: Date, to: Date) throws -> [Completion] {
        let habitIDs = habits.compactMap { $0.id }
        guard !habitIDs.isEmpty else { return [] }
        
        let request: NSFetchRequest<Completion> = Completion.fetchRequest()
        request.predicate = NSPredicate(
            format: "habit.id IN %@ AND date >= %@ AND date <= %@",
            habitIDs, from as NSDate, to as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        return try context.fetch(request)
    }
    
    // MARK: - Date Helpers
    
    private func startOfDay(_ date: Date) -> Date {
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = config.dayStartHour
        components.minute = 0
        components.second = 0
        return calendar.date(from: components) ?? date
    }
    
    private func endOfDay(_ date: Date) -> Date {
        let nextDay = calendar.date(byAdding: .day, value: 1, to: startOfDay(date))!
        return calendar.date(byAdding: .second, value: -1, to: nextDay)!
    }
}

// MARK: - Protocol Conformance

protocol AnalyticsComputing {
    func computeLevelAnalytics(from: Date, to: Date, config: AnalyticsConfig, context: NSManagedObjectContext) throws -> [LevelAnalytics]
    func levelSeries(from: Date, to: Date, config: AnalyticsConfig, context: NSManagedObjectContext) throws -> [LevelSeries]
}

extension IntensityAnalyticsManager: AnalyticsComputing {
    func computeLevelAnalytics(from: Date, to: Date, config: AnalyticsConfig, context: NSManagedObjectContext) throws -> [LevelAnalytics] {
        return try computeLevelAnalytics(from: from, to: to)
    }
    
    func levelSeries(from: Date, to: Date, config: AnalyticsConfig, context: NSManagedObjectContext) throws -> [LevelSeries] {
        return try levelSeries(from: from, to: to)
    }
}

// MARK: - Usage Example

/*
 Usage in your app:
 
 let analyticsManager = IntensityAnalyticsManager(context: viewContext)
 
 // Get analytics for all intensity levels
 do {
     let analytics = try analyticsManager.computeLevelAnalytics(
         from: Date().addingTimeInterval(-90 * 24 * 60 * 60),
         to: Date()
     )
     
     for levelAnalytics in analytics {
         print("Level \(levelAnalytics.level):")
         print("  Success Rate (30d): \(levelAnalytics.successRate30d * 100)%")
         print("  Goldilocks: \(levelAnalytics.goldilocks)")
         print("  Current Streak: \(levelAnalytics.currentStreakDays) days")
         print("  Recommendation: \(levelAnalytics.recommendation?.message ?? "None")")
     }
     
     // Get time series for charts
     let series = try analyticsManager.levelSeries(
         from: Date().addingTimeInterval(-30 * 24 * 60 * 60),
         to: Date()
     )
     
     // Use series data for charts...
 } catch {
     print("Error computing analytics: \(error)")
 }
 */
*/
