//
//  HabitGitHubGrid.swift
//  Habital
//
//  Updated to support repetition, quantity, and duration tracking
//  Color opacity based on completion percentage
//

import SwiftUI
import CoreData

struct HabitGitHubGrid: View {
    let habit: Habit
    let showHeader: Bool
    @State private var completionData: [[DayData]] = []
    @State private var animate: Bool = false
    @State private var totalDays: Int = 0
    @State private var completedDays: Int = 0
    @State private var numberOfWeeks: Int = 21
    @State private var totalWeeksFromStart: Int = 21
    @State private var isLoading = true
    @State private var trackingType: HabitTrackingType = .repetitions
    
    private let daysOfWeek = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    private let dayLabels = ["", "Tue", "", "Thu", "", "Sat", ""]
    
    // Convenience initializer with default showHeader = true
    init(habit: Habit, showHeader: Bool = true) {
        self.habit = habit
        self.showHeader = showHeader
    }
    
    // MARK: - Models
    struct DayData: Identifiable {
        let id = UUID()
        let date: Date
        let isActive: Bool
        let isCompleted: Bool
        let completionRatio: Double // 0.0 to 1.0
        let completionCount: Int
        let requiredCount: Int
        let isFuture: Bool
        let isToday: Bool
        // New fields for tracking types
        let trackingType: HabitTrackingType
        let durationCompleted: Int
        let durationTarget: Int
        let quantityCompleted: Int
        let quantityTarget: Int
        let quantityUnit: String
        // New: mark if this day belongs to the best (longest) streak
        let isInBestStreak: Bool
    }
    
    private var habitColor: Color {
        if let colorData = habit.color,
           let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
            return Color(uiColor)
        }
        return .blue
    }
    
    private var completionPercentage: Double {
        guard totalDays > 0 else { return 0.0 }
        return Double(completedDays) / Double(totalDays)
    }
    
    private var completionText: String {
        switch trackingType {
        case .repetitions:
            return "\(completedDays) out of \(totalDays) days"
        case .duration:
            return "\(completedDays) days completed"
        case .quantity:
            return "\(completedDays) targets reached"
        }
    }
    
    private func getSquareColor(for day: DayData) -> Color {
        // Don't show future days
        if day.isFuture {
            return Color.clear
        }
        
        // If before habit start date, show very light gray
        if day.date < (habit.startDate ?? Date()) {
            return Color.gray.opacity(0.08)
        }
        
        if !day.isActive {
            return Color.gray.opacity(0.08)
        }
        
        // Use habit color for all squares (no different color for best streak)
        let baseColor: Color = habitColor
        
        // Use completion ratio for varying opacity
        if day.completionRatio > 0 {
            // Map completion ratio to opacity range: 0.2 to 1.0
            let minOpacity = 0.2
            let maxOpacity = 1.0
            let opacity = minOpacity + (day.completionRatio * (maxOpacity - minOpacity))
            return baseColor.opacity(opacity)
        } else {
            return Color.gray.opacity(0.25)
        }
    }
    
    private func getLoadingMonthText(for weekIndex: Int) -> String {
        let calendar = Calendar.current
        let today = Date()
        
        let todayWeekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (todayWeekday == 1) ? 6 : todayWeekday - 2
        let mondayOfCurrentWeek = calendar.date(byAdding: .day, value: -daysFromMonday, to: today) ?? today
        
        // Calculate the start date for the grid (52 weeks back from current week)
        let gridStartWeek = calendar.date(byAdding: .weekOfYear, value: -(52 - 1), to: mondayOfCurrentWeek) ?? mondayOfCurrentWeek
        let gridStartMonday = calendar.startOfDay(for: gridStartWeek)
        
        guard let weekStartDate = calendar.date(byAdding: .day, value: weekIndex * 7, to: gridStartMonday) else { return "" }
        
        // Check if this week contains the first day of a month
        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: weekStartDate) else { continue }
            let dayOfMonth = calendar.component(.day, from: date)
            
            if dayOfMonth == 1 {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM"
                return formatter.string(from: date)
            }
        }
        
        return ""
    }
    
    private func getWeekStartDate(weekIndex: Int) -> Date {
        let calendar = Calendar.current
        let habitStartDate = habit.startDate ?? Date()
        
        let habitStartWeekday = calendar.component(.weekday, from: habitStartDate)
        let daysFromMondayStart = (habitStartWeekday == 1) ? 6 : habitStartWeekday - 2
        let mondayOfStartWeek = calendar.date(byAdding: .day, value: -daysFromMondayStart, to: habitStartDate) ?? habitStartDate
        
        return calendar.date(byAdding: .day, value: weekIndex * 7, to: mondayOfStartWeek) ?? mondayOfStartWeek
    }
    
    private func getWeekHeaderText(for weekIndex: Int) -> String {
        let calendar = Calendar.current
        
        guard weekIndex < completionData.count else { return "" }
        guard let firstDayData = completionData[weekIndex].first else { return "" }
        
        // Check for first day of month first - this takes priority
        for dayData in completionData[weekIndex] {
            if dayData.isFuture {
                continue
            }
            
            let dayOfMonth = calendar.component(.day, from: dayData.date)
            
            if dayOfMonth == 1 {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM"
                return formatter.string(from: dayData.date)
            }
        }
        
        // Check if we've already shown this month in a previous week
        if let habitStart = habit.startDate {
            let habitStartMonth = calendar.component(.month, from: habitStart)
            let habitStartYear = calendar.component(.year, from: habitStart)
            
            // Look for any previous week that already displayed this month
            for prevWeekIndex in 0..<weekIndex {
                if prevWeekIndex < completionData.count {
                    for dayData in completionData[prevWeekIndex] {
                        if !dayData.isFuture {
                            let dayMonth = calendar.component(.month, from: dayData.date)
                            let dayYear = calendar.component(.year, from: dayData.date)
                            let dayOfMonth = calendar.component(.day, from: dayData.date)
                            
                            // If we found a first-of-month in a previous week for the same month/year as habit start
                            if dayOfMonth == 1 && dayMonth == habitStartMonth && dayYear == habitStartYear {
                                return "" // Don't show duplicate month
                            }
                        }
                    }
                }
            }
            
            // Only show habit start month if it's the first time we're showing this month
            let habitStartWeek = getWeekStartForDate(habitStart)
            let firstRealDay = completionData[weekIndex].first(where: { !$0.isFuture })?.date
            
            if let firstRealDay = firstRealDay,
               calendar.isDate(firstRealDay, equalTo: habitStartWeek, toGranularity: .weekOfYear) {
                
                // Only show if habit doesn't start on the 1st of the month
                let habitStartDay = calendar.component(.day, from: habitStart)
                if habitStartDay != 1 {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "MMM"
                    return formatter.string(from: habitStart)
                }
            }
        }
        
        return ""
    }
    
    private func getWeekStartForDate(_ date: Date) -> Date {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        let daysFromMonday = (weekday == 1) ? 6 : weekday - 2
        return calendar.date(byAdding: .day, value: -daysFromMonday, to: date) ?? date
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header - conditionally shown
            if showHeader {
                HStack(spacing: 2) {
                    // Habit icon on the left
                    HabitIconView(
                        iconName: habit.icon,
                        isActive: true,
                        habitColor: habitColor,
                        streak: getCurrentStreak(),
                        showStreaks: true, // Don't show streak badge in grid header
                        useModernBadges: true,
                        isFutureDate: false,
                        isBadHabit: habit.isBadHabit,
                        intensityLevel: getHabitIntensity()
                    )
                    .scaleEffect(0.65)
                    //.frame(width: 32, height: 32) // Small size to match VStack height
                    
                    VStack(alignment: .leading, spacing: 1) {
                        HStack(spacing: 7){
                            Text(habit.name ?? "Habit")
                                .font(.customFont("Lexend", .bold, 16))
                            if let startDate = habit.startDate {
                                HStack(spacing: 2) {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 6))
                                        .foregroundColor(.secondary)

                                    Text(formatStartDate(startDate))
                                        .font(.customFont("Lexend", .regular, 10))
                                        .foregroundColor(.secondary)
                                }
                            }

                        }
                        Text(completionText)
                            .font(.customFont("Lexend", .regular, 10))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Small consistency circle
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 3)
                        
                        Circle()
                            .trim(from: 0, to: completionPercentage)
                            .stroke(
                                habitColor,
                                style: StrokeStyle(lineWidth: 3, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                        
                        Text("\(Int(completionPercentage * 100))%")
                            .font(.customFont("Lexend", .semiBold, 10))
                            .foregroundColor(.primary)
                    }
                    .frame(width: 30, height: 30)
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 2)
            }
            
            // Grid with day labels
            if isLoading {
                // Loading placeholder - match exact structure and spacing
                HStack(spacing: 2) {
                    VStack(spacing: 2) {
                        Color.clear
                            .frame(width: 25, height: 12)
                        
                        ForEach(0..<7, id: \.self) { dayIndex in
                            Text(dayLabels[dayIndex])
                                .font(.customFont("Lexend", .regular, 9))
                                .foregroundColor(.secondary)
                                .frame(width: 25, height: 12, alignment: .trailing)
                        }
                    }
                    .padding(.trailing, 3)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        VStack(spacing: 2) {
                            // Header row - match exact height with month placeholders
                            HStack(spacing: 2) {
                                ForEach(0..<52, id: \.self) { weekIndex in
                                    // Show month placeholders during loading
                                    Text(getLoadingMonthText(for: weekIndex))
                                        .font(.customFont("Lexend", .medium, 6.5))
                                        .foregroundColor(.secondary.opacity(0.3))
                                        .frame(width: 12, height: 12, alignment: .center)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                }
                            }
                            
                            // Data rows - match exact structure
                            ForEach(0..<7, id: \.self) { _ in
                                HStack(spacing: 2) {
                                    ForEach(0..<52, id: \.self) { _ in
                                        RoundedRectangle(cornerRadius: 5)
                                            .fill(Color.gray.opacity(0.1))
                                            .frame(width: 12, height: 12)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 6)
                        .padding(.leading, 2)
                        .padding(.trailing, 6)
                    }
                    .defaultScrollAnchor(.trailing)
                }
                .offset(x: -5)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 5)
            } else {
                HStack(spacing: 2) {
                    VStack(spacing: 2) {
                        
                        Color.clear
                            .frame(width: 25, height: 12)
                        
                        ForEach(0..<7, id: \.self) { dayIndex in
                            Text(dayLabels[dayIndex])
                                .font(.customFont("Lexend", .regular, 9))
                                .foregroundColor(.secondary)
                                .frame(width: 25, height: 12, alignment: .trailing)
                        }
                    }
                    .padding(.trailing, 3)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        VStack(spacing: 2) {
                            HStack(spacing: 2) {
                                ForEach(0..<totalWeeksFromStart, id: \.self) { weekIndex in
                                    Text(getWeekHeaderText(for: weekIndex))
                                        .font(.customFont("Lexend", .medium, 6.5))
                                        .foregroundColor(.secondary)
                                        .frame(width: 12, height: 12, alignment: .center)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                }
                            }
                            
                            ForEach(0..<7, id: \.self) { dayOfWeekIndex in
                                HStack(spacing: 2) {
                                    ForEach(0..<totalWeeksFromStart, id: \.self) { weekIndex in
                                        if weekIndex < completionData.count && dayOfWeekIndex < completionData[weekIndex].count {
                                            let dayData = completionData[weekIndex][dayOfWeekIndex]
                                            
                                            if !dayData.isFuture {
                                                GitHubSquare(
                                                    data: dayData,
                                                    animate: $animate,
                                                    color: getSquareColor(for: dayData),
                                                    isToday: dayData.isToday,
                                                    habitColor: habitColor
                                                )
                                            } else {
                                                Color.clear
                                                    .frame(width: 12, height: 12)
                                            }
                                        } else {
                                            // Show inactive square for missing data
                                            RoundedRectangle(cornerRadius: 5)
                                                .fill(Color.gray.opacity(0.08))
                                                .frame(width: 12, height: 12)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 6)
                        .padding(.leading, 2)
                        .padding(.trailing, 6)
                    }
                    .defaultScrollAnchor(.trailing)
                }
                .offset(x: -5)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 5)
            }
            
            // Legend - only show when header is hidden
            if !showHeader {
                HStack(spacing: 10) {
                    // Best Streak indicator
                    HStack(spacing: 4) {
                        Text("Best Streak")
                            .font(.customFont("Lexend", .regular, 11))
                            .foregroundColor(.secondary)
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(habitColor)
                            .frame(width: 10, height: 10)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Text("Less")
                            .font(.customFont("Lexend", .regular, 11))
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 2) {
                            ForEach(0..<5) { index in
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(getLegendColor(for: index))
                                    .frame(width: 10, height: 10)
                            }
                        }
                        
                        Text("More")
                            .font(.customFont("Lexend", .regular, 11))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 10)
            }
        }
        .padding(showHeader == true ? 7 : 10)
        .sheetGlassBackground()
        .frame(maxWidth: .infinity)
        .onAppear {
            loadTrackingType()
            loadDataAsync()
        }
    }
    
    private func loadTrackingType() {
        if let pattern = habit.repeatPattern?.allObjects.first as? RepeatPattern,
           let trackingTypeString = pattern.trackingType,
           let type = HabitTrackingType(rawValue: trackingTypeString) {
            trackingType = type
        }
    }
    
    private func getLegendColor(for index: Int) -> Color {
        switch index {
        case 0: return Color.gray.opacity(0.1)
        case 1: return habitColor.opacity(0.3)
        case 2: return habitColor.opacity(0.5)
        case 3: return habitColor.opacity(0.7)
        case 4: return habitColor.opacity(1.0)
        default: return Color.gray.opacity(0.1)
        }
    }
    
    private func formatStartDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    private func loadDataAsync() {
        isLoading = true
        
        Task {
            let processedData = await processHabitDataInBackground()
            
            await MainActor.run {
                self.completionData = processedData.data
                self.totalDays = processedData.totalDays
                self.completedDays = processedData.completedDays
                self.totalWeeksFromStart = processedData.totalWeeks
                
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.isLoading = false
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        self.animate = true
                    }
                }
            }
        }
    }
    
    private func processHabitDataInBackground() async -> (data: [[DayData]], totalDays: Int, completedDays: Int, totalWeeks: Int) {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = self.processHabitData()
                continuation.resume(returning: result)
            }
        }
    }
    
    private func processHabitData() -> (data: [[DayData]], totalDays: Int, completedDays: Int, totalWeeks: Int) {
        let calendar = Calendar.current
        let today = Date()
        let todayStart = calendar.startOfDay(for: today)
        
        let todayWeekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (todayWeekday == 1) ? 6 : todayWeekday - 2
        let mondayOfCurrentWeek = calendar.date(byAdding: .day, value: -daysFromMonday, to: today) ?? today
        
        // Always show a fixed number of weeks (like GitHub's 53 weeks)
        let totalWeeksToShow = 52 // Show a full year worth of squares
        
        // Calculate the start date for the grid (52 weeks back from current week)
        let gridStartWeek = calendar.date(byAdding: .weekOfYear, value: -(totalWeeksToShow - 1), to: mondayOfCurrentWeek) ?? mondayOfCurrentWeek
        let gridStartMonday = calendar.startOfDay(for: gridStartWeek)
        
        let habitStartDate = habit.startDate ?? today
        let habitStartDateNormalized = calendar.startOfDay(for: habitStartDate)
        
        var tempData: [[DayData]] = []
        var activeDaysCount = 0
        var completedActiveDays = 0
        
        // Get tracking type and pattern
        let pattern = habit.repeatPattern?.allObjects.first as? RepeatPattern
        let habitTrackingType = getHabitTrackingType()
        let targetDuration = Int(pattern?.duration ?? 30)
        let targetQuantity = Int(pattern?.targetQuantity ?? 1)
        let quantityUnit = pattern?.quantityUnit ?? "items"
        
        // Pre-fetch all completion data
        let completions = (habit.completion as? Set<Completion>) ?? []
        
        for weekIndex in 0..<totalWeeksToShow {
            guard let weekStartDate = calendar.date(byAdding: .day, value: weekIndex * 7, to: gridStartMonday) else { continue }
            
            var weekData: [DayData] = []
            
            for dayOffset in 0..<7 {
                guard let date = calendar.date(byAdding: .day, value: dayOffset, to: weekStartDate) else { continue }
                let dateStart = calendar.startOfDay(for: date)
                
                if dateStart < habitStartDateNormalized {
                    // Before habit start date - show as inactive but visible
                    weekData.append(DayData(
                        date: date,
                        isActive: false,
                        isCompleted: false,
                        completionRatio: 0.0,
                        completionCount: 0,
                        requiredCount: 0,
                        isFuture: false,
                        isToday: false,
                        trackingType: habitTrackingType,
                        durationCompleted: 0,
                        durationTarget: targetDuration,
                        quantityCompleted: 0,
                        quantityTarget: targetQuantity,
                        quantityUnit: quantityUnit,
                        isInBestStreak: false
                    ))
                    continue
                }
                
                let isActive = HabitUtilities.isHabitActive(habit: habit, on: date)
                let isToday = calendar.isDate(date, inSameDayAs: today)
                let isFuture = dateStart > todayStart
                
                // Calculate completion based on tracking type
                var completionRatio: Double = 0.0
                var isCompleted = false
                var durationCompleted = 0
                var quantityCompleted = 0
                var completionCount = 0
                var requiredCount = habit.currentRepeatsPerDay(on: date)
                
                if isActive && !isFuture {
                    switch habitTrackingType {
                    case .repetitions:
                        completionCount = getCompletedRepeatsCount(on: date, from: completions)
                        completionRatio = Double(completionCount) / Double(max(1, requiredCount))
                        isCompleted = completionCount >= requiredCount
                        
                    case .duration:
                        durationCompleted = getDurationCompleted(on: date, from: completions)
                        completionRatio = Double(durationCompleted) / Double(max(1, targetDuration))
                        isCompleted = durationCompleted >= targetDuration
                        
                    case .quantity:
                        quantityCompleted = getQuantityCompleted(on: date, from: completions)
                        completionRatio = Double(quantityCompleted) / Double(max(1, targetQuantity))
                        isCompleted = quantityCompleted >= targetQuantity
                    }
                    
                    completionRatio = min(1.0, completionRatio)
                    
                    activeDaysCount += 1
                    if isCompleted {
                        completedActiveDays += 1
                    }
                }
                
                weekData.append(DayData(
                    date: date,
                    isActive: isActive,
                    isCompleted: isCompleted,
                    completionRatio: completionRatio,
                    completionCount: completionCount,
                    requiredCount: requiredCount,
                    isFuture: isFuture,
                    isToday: isToday,
                    trackingType: habitTrackingType,
                    durationCompleted: durationCompleted,
                    durationTarget: targetDuration,
                    quantityCompleted: quantityCompleted,
                    quantityTarget: targetQuantity,
                    quantityUnit: quantityUnit,
                    isInBestStreak: false
                ))
            }
            
            tempData.append(weekData)
        }
        
        // No need to pad with minimum weeks anymore since we always show exactly totalWeeksToShow weeks
        
        // Compute best (longest) streak based on active+completed consecutive days
        let bestStreakDates = computeBestStreakDates(from: tempData)
        
        // Apply best streak flags
        let flaggedData: [[DayData]] = tempData.map { week in
            week.map { day in
                let normalized = calendar.startOfDay(for: day.date)
                if bestStreakDates.contains(normalized) {
                    return DayData(
                        date: day.date,
                        isActive: day.isActive,
                        isCompleted: day.isCompleted,
                        completionRatio: day.completionRatio,
                        completionCount: day.completionCount,
                        requiredCount: day.requiredCount,
                        isFuture: day.isFuture,
                        isToday: day.isToday,
                        trackingType: day.trackingType,
                        durationCompleted: day.durationCompleted,
                        durationTarget: day.durationTarget,
                        quantityCompleted: day.quantityCompleted,
                        quantityTarget: day.quantityTarget,
                        quantityUnit: day.quantityUnit,
                        isInBestStreak: true
                    )
                } else {
                    return day
                }
            }
        }
        
        return (
            data: flaggedData,
            totalDays: activeDaysCount,
            completedDays: completedActiveDays,
            totalWeeks: flaggedData.count
        )
    }
    
    // Helper: compute the best (longest) streak dates from built data
    private func computeBestStreakDates(from data: [[DayData]]) -> Set<Date> {
        let calendar = Calendar.current
        
        // Flatten to chronological order by date
        let allDays: [DayData] = data.flatMap { $0 }
            .filter { !$0.isFuture && $0.isActive } // only non-future active days
            .sorted { $0.date < $1.date }
        
        var bestStreakDates: [Date] = []
        var currentStreakDates: [Date] = []
        
        for day in allDays {
            let dayDate = calendar.startOfDay(for: day.date)
            
            if day.isCompleted {
                // Check if this day continues the current streak
                if let lastDate = currentStreakDates.last {
                    // Calculate expected next date (yesterday + 1 day)
                    if let expectedDate = calendar.date(byAdding: .day, value: 1, to: lastDate),
                       calendar.isDate(expectedDate, inSameDayAs: dayDate) {
                        // Consecutive day - add to current streak
                        currentStreakDates.append(dayDate)
                    } else {
                        // Gap in streak - check if current is better than best
                        if currentStreakDates.count > bestStreakDates.count {
                            bestStreakDates = currentStreakDates
                        }
                        // Start new streak
                        currentStreakDates = [dayDate]
                    }
                } else {
                    // Start new streak
                    currentStreakDates = [dayDate]
                }
            } else {
                // Day not completed - check if current streak is better than best
                if currentStreakDates.count > bestStreakDates.count {
                    bestStreakDates = currentStreakDates
                }
                // Reset current streak
                currentStreakDates = []
            }
        }
        
        // Final check in case the best streak goes to the end
        if currentStreakDates.count > bestStreakDates.count {
            bestStreakDates = currentStreakDates
        }
        
        return Set(bestStreakDates)
    }
    
    
    // Helper: calculate streak connections for a day
    private func getStreakConnection(for dayData: DayData, at weekIndex: Int, dayIndex: Int, in data: [[DayData]]) -> GitHubSquare.StreakConnection {
        // Removed - no longer used
        return GitHubSquare.StreakConnection(connectsLeft: false, connectsRight: false, connectsUp: false, connectsDown: false)
    }
    
    // Local darker color helper: create a darker version of the habit color
    private func darkerColor(for base: Color) -> Color {
        // Convert to UIColor
        let ui = UIColor(base)
        var h: CGFloat = 0
        var s: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        if ui.getHue(&h, saturation: &s, brightness: &b, alpha: &a) {
            // Reduce brightness by 30% to make it darker
            let darkerB = max(0.0, b * 0.7)
            // Optionally increase saturation slightly for more vibrancy
            let adjustedS = min(1.0, s * 1.1)
            let darker = UIColor(hue: h, saturation: adjustedS, brightness: darkerB, alpha: a)
            return Color(darker)
        }
        
        // Fallback: reduce RGB values by 30%
        var r: CGFloat = 0
        var g: CGFloat = 0
        var bl: CGFloat = 0
        if ui.getRed(&r, green: &g, blue: &bl, alpha: &a) {
            let darker = UIColor(red: r * 0.7, green: g * 0.7, blue: bl * 0.7, alpha: a)
            return Color(darker)
        }
        
        // Final fallback
        return base
    }
    
    // Local opposite color helper: complementary hue (rotate hue by 180°), preserve saturation/brightness/alpha
    private func oppositeColor(for base: Color) -> Color {
        // Convert to UIColor
        let ui = UIColor(base)
        var h: CGFloat = 0
        var s: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        if ui.getHue(&h, saturation: &s, brightness: &b, alpha: &a) {
            let newH = fmod(h + 0.5, 1.0) // rotate hue by 180°
            let opposite = UIColor(hue: newH, saturation: s, brightness: b, alpha: a)
            return Color(opposite)
        }
        
        // Fallback: invert RGB if HSB unavailable
        var r: CGFloat = 0
        var g: CGFloat = 0
        var bl: CGFloat = 0
        if ui.getRed(&r, green: &g, blue: &bl, alpha: &a) {
            let opposite = UIColor(red: 1.0 - r, green: 1.0 - g, blue: 1.0 - bl, alpha: a)
            return Color(opposite)
        }
        
        // Final fallback
        return base
    }
    
    // Helper methods for tracking types
    private func getHabitTrackingType() -> HabitTrackingType {
        if let pattern = habit.repeatPattern?.allObjects.first as? RepeatPattern,
           let trackingTypeString = pattern.trackingType,
           let type = HabitTrackingType(rawValue: trackingTypeString) {
            return type
        }
        return .repetitions
    }
    
    private func getCompletedRepeatsCount(on date: Date, from completions: Set<Completion>, isToday: Bool = false) -> Int {
        let calendar = Calendar.current
        
        if isToday {
            // For today, check both by dayKey and by actual date comparison
            let key = DayKeyFormatter.localKey(from: date)
            let todayCompletions = completions.filter { c in
                if c.completed && c.dayKey == key {
                    return true
                }
                // Also check if the completion date is actually today
                if let compDate = c.date, c.completed {
                    return calendar.isDate(compDate, inSameDayAs: date)
                }
                return false
            }
            return todayCompletions.count
        } else {
            // For past dates, use dayKey
            let key = DayKeyFormatter.localKey(from: date)
            return completions.filter { c in
                c.completed && c.dayKey == key
            }.count
        }
    }
    
    private func getDurationCompleted(on date: Date, from completions: Set<Completion>, isToday: Bool = false) -> Int {
        let calendar = Calendar.current
        
        if isToday {
            // For today, check both by dayKey and by actual date comparison
            let key = DayKeyFormatter.localKey(from: date)
            let todayCompletions = completions.filter { c in
                if c.dayKey == key {
                    return true
                }
                // Also check if the completion date is actually today
                if let compDate = c.date {
                    return calendar.isDate(compDate, inSameDayAs: date)
                }
                return false
            }
            return todayCompletions.reduce(0) { $0 + Int($1.duration) }
        } else {
            // For past dates, use dayKey
            let key = DayKeyFormatter.localKey(from: date)
            return completions.filter { c in
                c.dayKey == key
            }.reduce(0) { $0 + Int($1.duration) }
        }
    }
    
    private func getQuantityCompleted(on date: Date, from completions: Set<Completion>, isToday: Bool = false) -> Int {
        let calendar = Calendar.current
        
        if isToday {
            // For today, check both by dayKey and by actual date comparison
            let key = DayKeyFormatter.localKey(from: date)
            let todayCompletions = completions.filter { c in
                if c.dayKey == key {
                    return true
                }
                // Also check if the completion date is actually today
                if let compDate = c.date {
                    return calendar.isDate(compDate, inSameDayAs: date)
                }
                return false
            }
            return todayCompletions.reduce(0) { $0 + Int($1.quantity) }
        } else {
            // For past dates, use dayKey
            let key = DayKeyFormatter.localKey(from: date)
            return completions.filter { c in
                c.dayKey == key
            }.reduce(0) { $0 + Int($1.quantity) }
        }
    }
    
    // MARK: - Helper methods for HabitIconView
    
    private func getCurrentStreak() -> Int {
        return habit.calculateStreak(upTo: Date())
    }
    
    private func getHabitIntensity() -> Int16 {
        return habit.intensityLevel
    }
    
    private func getDurationMinutes() -> Int16? {
        if let pattern = habit.repeatPattern?.allObjects.first as? RepeatPattern,
           pattern.duration > 0 {
            return Int16(pattern.duration)
        }
        return nil
    }
}

// MARK: - GitHub Square Component with Tooltip
struct GitHubSquare: View {
    let data: HabitGitHubGrid.DayData
    @Binding var animate: Bool
    let color: Color
    let isToday: Bool
    let habitColor: Color
    
    @State private var showTooltip = false
    
    struct StreakConnection {
        let connectsLeft: Bool
        let connectsRight: Bool
        let connectsUp: Bool
        let connectsDown: Bool
    }
    
    var body: some View {
        ZStack {
            // Base square - use different corner radius based on best streak status
            let cornerRadius: CGFloat = data.isInBestStreak ? 3 : 5
            
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(color)
                .frame(width: 12, height: 12)
                .scaleEffect(animate ? 1.0 : 0.1)
                .animation(
                    .spring(response: 0.5, dampingFraction: 0.7)
                    .delay(getDelay()),
                    value: animate
                )
            
            // Today indicator
            if isToday {
                RoundedRectangle(cornerRadius: data.isInBestStreak ? 3 : 5)
                    .stroke(Color.secondary, lineWidth: 1.5)
                    .frame(width: 12, height: 12)
                    .scaleEffect(animate ? 1.0 : 0.1)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.7)
                        .delay(getDelay()),
                        value: animate
                    )
            }
        }
        .frame(width: 12, height: 12)
        .onTapGesture {
            showTooltip.toggle()
        }
        .popover(isPresented: $showTooltip, arrowEdge: .top) {
            tooltipContent
                .padding(8)
                .presentationCompactAdaptation(.popover)
        }
    }
    
    private var tooltipContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(formatDate(data.date))
                .font(.customFont("Lexend", .bold, 11))
            
            if data.isActive {
                switch data.trackingType {
                case .repetitions:
                    HStack {
                        Text("Completed:")
                        Text("\(data.completionCount)/\(data.requiredCount)")
                            .foregroundColor(habitColor)
                            .bold()
                    }
                    
                case .duration:
                    HStack {
                        Text("Duration:")
                        Text("\(formatMinutes(data.durationCompleted))/\(formatMinutes(data.durationTarget))")
                            .foregroundColor(habitColor)
                            .bold()
                    }
                    
                case .quantity:
                    HStack {
                        Text("Quantity:")
                        Text("\(data.quantityCompleted)/\(data.quantityTarget) \(data.quantityUnit)")
                            .foregroundColor(habitColor)
                            .bold()
                    }
                }
                
                if data.completionRatio > 0 {
                    Text("\(Int(data.completionRatio * 100))% complete")
                        .font(.customFont("Lexend", .regular, 10))
                        .foregroundColor(.secondary)
                } else {
                    Text("Not completed")
                        .font(.customFont("Lexend", .regular, 10))
                        .foregroundColor(.secondary)
                }
            } else {
                Text("Inactive day")
                    .font(.customFont("Lexend", .regular, 10))
                    .foregroundColor(.secondary)
            }
        }
        .font(.customFont("Lexend", .regular, 11))
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
    
    private func formatMinutes(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        }
    }
    
    private func getDelay() -> Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if let daysAgo = calendar.dateComponents([.day], from: data.date, to: today).day {
            return Double(abs(daysAgo)) * 0.003
        }
        return 0
    }
}


