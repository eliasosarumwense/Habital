//
//  StatsDataManager.swift
//  Habital
//
//  Created by Elias Osarumwense on 23.07.25.
//
import SwiftUI
import CoreData
import Combine

struct StatsData {
    let totalHabits: Int
    let completedToday: Int
    let currentStreak: Int
    let longestStreak: Int
    let completionRate: Double
    let weeklyAverage: Double
    
    static let empty = StatsData(
        totalHabits: 0,
        completedToday: 0,
        currentStreak: 0,
        longestStreak: 0,
        completionRate: 0.0,
        weeklyAverage: 0.0
    )
}

struct CompletionTrendsData {
    let timeRange: TimeRange
    var completionRates: [Double]
    let labels: [String]
    let detailedLabels: [String]
    let averageRate: Double
    let startDate: Date
    let endDate: Date
}

// MARK: - Per-Habit Cached Data
struct HabitCompletionCache {
    let habitId: UUID
    var completionData: [Date: Bool] // Date -> completion status
    let lastUpdated: Date
}

// MARK: - Statistics Data Manager
@MainActor
class StatsDataManager: ObservableObject {
    @Published var chartDataVersion: Int = 0
    // ADD: Cache for active habits count per date to avoid recalculation
        private var activeHabitsCountCache: [Date: Int] = [:]
        
        // ADD: Set for faster lookup when checking filtered habits
        private var filteredHabitIds: Set<UUID> = []
    // MARK: - Published Properties
    @Published var dataReady = false
    @Published var summaryStats = StatsData.empty
    @Published var filteredHabits: [Habit] = []
    @Published var selectedListIndex = 0
    
    // Track current time range for optimization
    var currentTimeRange: TimeRange = .lastSevenDays
    
    // MARK: - Private Properties
    private var viewContext: NSManagedObjectContext
    private var cancellables = Set<AnyCancellable>()
    private var allHabits: [Habit] = []
    private var habitLists: [HabitList] = []
    
    // OPTIMIZATION: Per-habit completion cache
    private var habitCompletionCache: [UUID: HabitCompletionCache] = [:]
    
    // OPTIMIZATION: Cached aggregated trends for all habits (by time range)
    private var allHabitsCompletionTrends: [TimeRange: CompletionTrendsData] = [:]
    
    // Cache invalidation
    private var lastCalculationDate = Date()
    private let cacheValidityDuration: TimeInterval = 3600 // 1 hour
    
    // MARK: - Initialization
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
    }
    
    // MARK: - Helper to get current habits based on selection
    private var currentHabits: [Habit] {
        return selectedListIndex == 0 ? allHabits : filteredHabits
    }
    
    // MARK: - Public Methods
    
    /// Load all data - call this from HabitalApp on startup
    func loadInitialData() {
        Task {
            await refreshAllData()
        }
    }
    
    /// Get stats for specific filtered habits (using cached data)
    func getStatsForHabits(_ habits: [Habit]) -> StatsData {
        return calculateSummaryStatsFromCache(for: habits)
    }
    
    /// Get completion trends for specific time range and habits (using cached data)
    func getCompletionTrends(for timeRange: TimeRange, habits: [Habit]) -> CompletionTrendsData? {
        // Update current time range for optimization
        currentTimeRange = timeRange
        
        // If requesting trends for all habits and we have cached data, return it
        if habits.count == allHabits.count,
           let cachedData = allHabitsCompletionTrends[timeRange],
           isCacheValid() {
            return cachedData
        }
        
        // Calculate trends from cached habit data
        return calculateCompletionTrendsFromCache(for: timeRange, habits: habits)
    }
    
    /// Update selected list and filter habits accordingly (NO recalculation needed!)
    func updateSelectedList(_ index: Int) {
        selectedListIndex = index
        updateFilteredHabits()
        
        // Recalculate summary stats using cached data - this is fast!
        summaryStats = calculateSummaryStatsFromCache(for: currentHabits)
    }
    
    func updateTrendPointIncremental(habit: Habit, date: Date, wasCompleted: Bool, isCompleted: Bool) {
        guard let habitId = habit.id else { return }
        
        // OPTIMIZATION 1: Skip if no actual change
        guard wasCompleted != isCompleted else { return }
        
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        
        // OPTIMIZATION 2: Direct cache update without creating intermediate object
        habitCompletionCache[habitId]?.completionData[dayStart] = isCompleted
        
        // OPTIMIZATION 3: Faster eligibility check using Set
        let shouldUpdate: Bool
        if selectedListIndex == 0 {
            shouldUpdate = !habit.isArchived
        } else {
            // Use the cached Set for O(1) lookup
            shouldUpdate = filteredHabitIds.contains(habitId)
        }
        
        guard shouldUpdate else { return }
        
        // OPTIMIZATION 4: Use cached active count if available
        Task.detached { [weak self] in
            await self?.performIncrementalUpdate(
                for: dayStart,
                wasCompleted: wasCompleted,
                isCompleted: isCompleted
            )
        }
    }
    @MainActor
    private func performIncrementalUpdate(for date: Date, wasCompleted: Bool, isCompleted: Bool) async {
        // OPTIMIZATION 5: Check cache first for active count
        let activeCount: Int
        if let cachedCount = activeHabitsCountCache[date] {
            activeCount = cachedCount
        } else {
            let habitsToUpdate = currentHabits
            activeCount = habitsToUpdate.filter {
                HabitUtilities.isHabitActive(habit: $0, on: date)
            }.count
            // Cache for future use
            activeHabitsCountCache[date] = activeCount
        }
        
        guard activeCount > 0 else { return }
        
        // OPTIMIZATION 6: Calculate change only once
        let percentageChange = ((isCompleted ? 1.0 : -1.0) / Double(activeCount)) * 100
        
        // OPTIMIZATION 7: Direct access without optional binding
        guard var trendsData = allHabitsCompletionTrends[currentTimeRange] else { return }
        
        // OPTIMIZATION 8: Simplified index calculation
        let dayIndex: Int?
        switch currentTimeRange {
        case .lastSevenDays, .lastThirtyDays:
            let days = Int(date.timeIntervalSince(trendsData.startDate) / 86400)
            dayIndex = days >= 0 && days < trendsData.completionRates.count ? days : nil
        case .threeMonths, .sixMonths:
            let weeks = Int(date.timeIntervalSince(trendsData.startDate) / 604800) // 7 * 86400
            dayIndex = weeks >= 0 && weeks < trendsData.completionRates.count ? weeks : nil
        case .year:
            let calendar = Calendar.current
            let months = calendar.dateComponents([.month], from: trendsData.startDate, to: date).month
            dayIndex = months.map { $0 >= 0 && $0 < trendsData.completionRates.count ? $0 : nil } ?? nil
        }
        
        guard let validIndex = dayIndex else { return }
        
        // OPTIMIZATION 9: In-place modification
        trendsData.completionRates[validIndex] += percentageChange
        trendsData.completionRates[validIndex] = max(0, min(100, trendsData.completionRates[validIndex]))
        
        // OPTIMIZATION 10: Faster average calculation
        let newAverage = trendsData.completionRates.reduce(0, +) / Double(trendsData.completionRates.count)
        
        // Update cache with modified data
        allHabitsCompletionTrends[currentTimeRange] = CompletionTrendsData(
            timeRange: currentTimeRange,
            completionRates: trendsData.completionRates,
            labels: trendsData.labels,
            detailedLabels: trendsData.detailedLabels,
            averageRate: newAverage / 100.0,
            startDate: trendsData.startDate,
            endDate: trendsData.endDate
        )
        
        // Trigger UI update
        chartDataVersion += 1
        
        // OPTIMIZATION 11: Update stats only if visible
        if dataReady {
            let habitsToUpdate = currentHabits
            summaryStats = calculateSummaryStatsFromCache(for: habitsToUpdate)
        }
    }
    
    private func clearStaleCache() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Keep only last 30 days of cache
        activeHabitsCountCache = activeHabitsCountCache.filter { date, _ in
            let days = calendar.dateComponents([.day], from: date, to: today).day ?? 0
            return days <= 30
        }
    }
    
    // Optimized index finding - uses time intervals instead of date components
    private func findDataPointIndexFast(for date: Date, timeRange: TimeRange, startDate: Date) -> Int? {
        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: date)
        let normalizedStart = calendar.startOfDay(for: startDate)
        
        // Calculate time difference in seconds
        let timeDiff = targetDate.timeIntervalSince(normalizedStart)
        guard timeDiff >= 0 else { return nil }
        
        switch timeRange {
        case .lastSevenDays:
            let days = Int(timeDiff / 86400)
            return days < 7 ? days : nil
            
        case .lastThirtyDays:
            let days = Int(timeDiff / 86400)
            return days < 30 ? days : nil
            
        case .threeMonths, .sixMonths:
            let days = Int(timeDiff / 86400)
            let weeks = days / 7
            let maxWeeks = timeRange == .threeMonths ? 13 : 26
            return weeks < maxWeeks ? weeks : nil
            
        case .year:
            // For monthly, we still need calendar calculation but optimize it
            let months = calendar.dateComponents([.month], from: normalizedStart, to: targetDate).month ?? -1
            return months >= 0 && months < 12 ? months : nil
        }
    }
    
    /// Handle incremental habit toggle updates (entry point from UI)
    func handleHabitToggleIncremental(habit: Habit, date: Date, wasCompleted: Bool, isCompleted: Bool) {
        // Delegate to the optimized incremental update
        updateTrendPointIncremental(
            habit: habit,
            date: date,
            wasCompleted: wasCompleted,
            isCompleted: isCompleted
        )
    }
    
    func refreshAllData() async {
        // Fetch all habits and lists
        await fetchHabitsAndLists()
        
        // Build completion cache for all habits
        await buildHabitCompletionCache()
        
        // Calculate aggregated trends for all habits (cached for performance)
        await calculateAllHabitsCompletionTrends()
        
        // Set initial filtered habits
        updateFilteredHabits()
        
        // Calculate summary stats
        summaryStats = calculateSummaryStatsFromCache(for: currentHabits)
        
        dataReady = true
    }

    private func fetchHabitsAndLists() async {
        let habitRequest: NSFetchRequest<Habit> = Habit.fetchRequest()
        habitRequest.predicate = NSPredicate(format: "isArchived == %@", NSNumber(value: false))
        habitRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Habit.order, ascending: true)]
        
        let listRequest: NSFetchRequest<HabitList> = HabitList.fetchRequest()
        listRequest.sortDescriptors = [NSSortDescriptor(keyPath: \HabitList.order, ascending: true)]
        
        do {
            allHabits = try viewContext.fetch(habitRequest)
            habitLists = try viewContext.fetch(listRequest)
        } catch {
            print("Failed to fetch habits or lists: \(error)")
        }
    }

    private func buildHabitCompletionCache() async {
        habitCompletionCache.removeAll()
        
        let calendar = Calendar.current
        let endDate = Date()
        
        // Go back 1 year for comprehensive cache
        guard let startDate = calendar.date(byAdding: .year, value: -1, to: endDate) else { return }
        
        for habit in allHabits {
            guard let habitId = habit.id else { continue }
            
            var completionData: [Date: Bool] = [:]
            
            // Fetch all completions for this habit in the date range
            let completionRequest: NSFetchRequest<Completion> = Completion.fetchRequest()
            completionRequest.predicate = NSPredicate(
                format: "habit == %@ AND date >= %@ AND date <= %@",
                habit, startDate as NSDate, endDate as NSDate
            )
            
            do {
                let completions = try viewContext.fetch(completionRequest)
                for completion in completions {
                    if let date = completion.date {
                        let dayStart = calendar.startOfDay(for: date)
                        completionData[dayStart] = completion.completed
                    }
                }
                
                habitCompletionCache[habitId] = HabitCompletionCache(
                    habitId: habitId,
                    completionData: completionData,
                    lastUpdated: Date()
                )
            } catch {
                print("Failed to fetch completions for habit \(habit.name ?? "Unknown"): \(error)")
            }
        }
    }

    private func calculateAllHabitsCompletionTrends() async {
        allHabitsCompletionTrends.removeAll()
        
        for timeRange in TimeRange.allCases {
            if let trendsData = calculateCompletionTrendsFromCache(for: timeRange, habits: allHabits) {
                allHabitsCompletionTrends[timeRange] = trendsData
            }
        }
        
        lastCalculationDate = Date()
    }

    private func updateFilteredHabits() {
        if selectedListIndex == 0 {
            // All habits
            filteredHabits = allHabits
            filteredHabitIds = Set(allHabits.compactMap { $0.id })
        } else if selectedListIndex > 0 && selectedListIndex <= habitLists.count {
            // Specific list
            let selectedList = habitLists[selectedListIndex - 1]
            if let habitSet = selectedList.habits as? Set<Habit> {
                filteredHabits = habitSet.filter { !$0.isArchived }.sorted { $0.order < $1.order }
                filteredHabitIds = Set(filteredHabits.compactMap { $0.id })
            } else {
                filteredHabits = []
                filteredHabitIds = []
            }
        } else {
            filteredHabits = []
            filteredHabitIds = []
        }
        
        // Clear cache when list changes
        activeHabitsCountCache.removeAll()
    }

    private func isCacheValid() -> Bool {
        Date().timeIntervalSince(lastCalculationDate) < cacheValidityDuration
    }
    
    private func calculateSummaryStatsFromCache(for habits: [Habit]) -> StatsData {
        guard !habits.isEmpty else { return StatsData.empty }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Calculate completed today from cache
        var completedToday = 0
        for habit in habits {
            if let habitId = habit.id,
               let cache = habitCompletionCache[habitId],
               let isCompleted = cache.completionData[today],
               isCompleted {
                completedToday += 1
            }
        }
        
        // Calculate completion rate (last 30 days) from cache
        let completionRate = calculateRecentCompletionRateFromCache(habits: habits, days: 30)
        
        // Calculate weekly average from cache
        let weeklyAverage = calculateRecentCompletionRateFromCache(habits: habits, days: 7)
        
        // Calculate streaks from cache
        let (currentStreak, longestStreak) = calculateStreaksFromCache(habits: habits)
        
        return StatsData(
            totalHabits: habits.count,
            completedToday: completedToday,
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            completionRate: completionRate,
            weeklyAverage: weeklyAverage
        )
    }

    private func calculateRecentCompletionRateFromCache(habits: [Habit], days: Int) -> Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var totalCompletions = 0
        var totalPossible = 0
        
        for dayOffset in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            
            for habit in habits {
                if let habitId = habit.id,
                   let cache = habitCompletionCache[habitId],
                   HabitUtilities.isHabitActive(habit: habit, on: date) {
                    totalPossible += 1
                    if let isCompleted = cache.completionData[date], isCompleted {
                        totalCompletions += 1
                    }
                }
            }
        }
        
        return totalPossible > 0 ? Double(totalCompletions) / Double(totalPossible) : 0.0
    }

    private func calculateStreaksFromCache(habits: [Habit]) -> (current: Int, longest: Int) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var currentStreak = 0
        var longestStreak = 0
        var tempStreak = 0
        
        // Check up to 365 days back
        for dayOffset in 0..<365 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { break }
            
            let dayCompletionRate = calculateDayCompletionRateFromCache(habits: habits, date: date)
            
            if dayCompletionRate >= 0.8 { // 80% completion threshold
                tempStreak += 1
                if dayOffset < 30 { // Only count recent days for current streak
                    currentStreak = max(currentStreak, tempStreak)
                }
            } else {
                longestStreak = max(longestStreak, tempStreak)
                tempStreak = 0
            }
        }
        
        longestStreak = max(longestStreak, tempStreak)
        
        return (currentStreak, longestStreak)
    }

    private func calculateDayCompletionRateFromCache(habits: [Habit], date: Date) -> Double {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        
        var completedCount = 0
        var activeCount = 0
        
        for habit in habits {
            if HabitUtilities.isHabitActive(habit: habit, on: dayStart) {
                activeCount += 1
                if let habitId = habit.id,
                   let cache = habitCompletionCache[habitId],
                   let isCompleted = cache.completionData[dayStart],
                   isCompleted {
                    completedCount += 1
                }
            }
        }
        
        return activeCount > 0 ? Double(completedCount) / Double(activeCount) : 0.0
    }
    
    private func calculateCompletionTrendsFromCache(for timeRange: TimeRange, habits: [Habit]) -> CompletionTrendsData? {
        let calendar = Calendar.current
        let endDate = calendar.startOfDay(for: Date())
        
        switch timeRange {
        case .lastSevenDays:
            return calculateDailyTrendsFromCache(habits: habits, endDate: endDate, days: 7)
        case .lastThirtyDays:
            return calculateDailyTrendsFromCache(habits: habits, endDate: endDate, days: 30)
        case .threeMonths:
            guard let startDate = calendar.date(byAdding: .month, value: -3, to: endDate) else { return nil }
            return calculateWeeklyTrendsFromCache(habits: habits, startDate: startDate, endDate: endDate, weeks: 13)
        case .sixMonths:
            guard let startDate = calendar.date(byAdding: .month, value: -6, to: endDate) else { return nil }
            return calculateWeeklyTrendsFromCache(habits: habits, startDate: startDate, endDate: endDate, weeks: 26)
        case .year:
            guard let startDate = calendar.date(byAdding: .year, value: -1, to: endDate) else { return nil }
            return calculateMonthlyTrendsFromCache(habits: habits, startDate: startDate, endDate: endDate, months: 12)
        }
    }

    // Calculate daily trends from cached data
    private func calculateDailyTrendsFromCache(
        habits: [Habit],
        endDate: Date,
        days: Int
    ) -> CompletionTrendsData {
        let calendar = Calendar.current
        var completionRates: [Double] = []
        var labels: [String] = []
        var detailedLabels: [String] = []
        
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = days == 7 ? "E" : "d/M"
        
        for dayOffset in 0..<days {
            guard let currentDate = calendar.date(byAdding: .day, value: -(days-1) + dayOffset, to: endDate) else { continue }
            
            let completionRate = calculateDayCompletionRateFromCache(habits: habits, date: currentDate) * 100
            completionRates.append(completionRate)
            
            if days == 7 {
                let dayName = dayFormatter.string(from: currentDate).prefix(2)
                labels.append(String(dayName).uppercased())
                detailedLabels.append(dayFormatter.string(from: currentDate))
            } else {
                // For 30 days, show fewer labels
                if dayOffset % 5 == 0 || dayOffset == days - 1 {
                    labels.append(dayFormatter.string(from: currentDate))
                }
                
                let detailFormatter = DateFormatter()
                detailFormatter.dateFormat = "EE"
                detailedLabels.append(detailFormatter.string(from: currentDate))
            }
        }
        
        let averageRate = completionRates.isEmpty ? 0 : completionRates.reduce(0, +) / Double(completionRates.count)
        
        return CompletionTrendsData(
            timeRange: days == 7 ? .lastSevenDays : .lastThirtyDays,
            completionRates: completionRates,
            labels: labels,
            detailedLabels: detailedLabels,
            averageRate: averageRate / 100.0,
            startDate: calendar.date(byAdding: .day, value: -(days-1), to: endDate) ?? endDate,
            endDate: endDate
        )
    }

    // Calculate weekly trends from cached data
    private func calculateWeeklyTrendsFromCache(
        habits: [Habit],
        startDate: Date,
        endDate: Date,
        weeks: Int
    ) -> CompletionTrendsData {
        let calendar = Calendar.current
        var completionRates: [Double] = []
        var labels: [String] = []
        var detailedLabels: [String] = []
        
        for weekIndex in 0..<weeks {
            let weekStartOffset = weekIndex * 7
            guard let weekStartDate = calendar.date(byAdding: .day, value: weekStartOffset, to: startDate) else { continue }
            
            var weekTotal = 0.0
            var daysCount = 0
            
            for dayOffset in 0...6 {
                if let currentDate = calendar.date(byAdding: .day, value: dayOffset, to: weekStartDate),
                   currentDate <= endDate {
                    let completionRate = calculateDayCompletionRateFromCache(habits: habits, date: currentDate)
                    weekTotal += completionRate
                    daysCount += 1
                }
            }
            
            let weeklyAverage = daysCount > 0 ? (weekTotal / Double(daysCount)) * 100 : 0
            completionRates.append(weeklyAverage)
            
            let weekNumber = calendar.component(.weekOfYear, from: weekStartDate)
            detailedLabels.append("W\(weekNumber)")
        }
        
        // Generate fewer labels for display
        if weeks == 13 { // 3 months
            for i in stride(from: 0, to: weeks, by: 3) {
                if i < detailedLabels.count {
                    labels.append(detailedLabels[i])
                }
            }
            if !labels.isEmpty && labels.last != detailedLabels.last {
                labels.append(detailedLabels.last ?? "")
            }
        } else { // 6 months
            for i in stride(from: 0, to: weeks, by: 5) {
                if i < detailedLabels.count {
                    labels.append(detailedLabels[i])
                }
            }
            if !labels.isEmpty && labels.last != detailedLabels.last {
                labels.append(detailedLabels.last ?? "")
            }
        }
        
        let averageRate = completionRates.isEmpty ? 0 : completionRates.reduce(0, +) / Double(completionRates.count)
        
        return CompletionTrendsData(
            timeRange: weeks == 13 ? .threeMonths : .sixMonths,
            completionRates: completionRates,
            labels: labels,
            detailedLabels: detailedLabels,
            averageRate: averageRate / 100.0,
            startDate: startDate,
            endDate: endDate
        )
    }

    // Calculate monthly trends from cached data
    private func calculateMonthlyTrendsFromCache(
        habits: [Habit],
        startDate: Date,
        endDate: Date,
        months: Int
    ) -> CompletionTrendsData {
        let calendar = Calendar.current
        var completionRates: [Double] = []
        var labels: [String] = []
        var detailedLabels: [String] = []
        
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMM"
        
        for monthIndex in 0..<months {
            guard let monthStartDate = calendar.date(byAdding: .month, value: monthIndex, to: startDate) else { continue }
            
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: monthStartDate)) ?? monthStartDate
            var comps = DateComponents()
            comps.month = 1
            comps.day = -1
            let endOfMonth = calendar.date(byAdding: comps, to: startOfMonth) ?? monthStartDate
            
            var monthTotal = 0.0
            var daysCount = 0
            
            var currentDate = startOfMonth
            while currentDate <= endOfMonth && currentDate <= endDate {
                let dayStart = calendar.startOfDay(for: currentDate)
                let completionRate = calculateDayCompletionRateFromCache(habits: habits, date: dayStart)
                monthTotal += completionRate
                daysCount += 1
                
                guard let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
                currentDate = nextDay
            }
            
            let monthlyAverage = daysCount > 0 ? (monthTotal / Double(daysCount)) * 100 : 0
            completionRates.append(monthlyAverage)
            
            let monthLabel = monthFormatter.string(from: monthStartDate)
            detailedLabels.append(monthLabel)
        }
        
        // For 12 months, show every 2nd month
        for i in stride(from: 0, to: months, by: 2) {
            if i < detailedLabels.count {
                labels.append(detailedLabels[i])
            }
        }
        if !labels.isEmpty && labels.last != detailedLabels.last {
            labels.append(detailedLabels.last ?? "")
        }
        
        let averageRate = completionRates.isEmpty ? 0 : completionRates.reduce(0, +) / Double(completionRates.count)
        
        return CompletionTrendsData(
            timeRange: .year,
            completionRates: completionRates,
            labels: labels,
            detailedLabels: detailedLabels,
            averageRate: averageRate / 100.0,
            startDate: startDate,
            endDate: endDate
        )
    }
}
