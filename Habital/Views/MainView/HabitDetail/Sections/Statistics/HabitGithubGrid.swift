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
        
        if day.date < (habit.startDate ?? Date()) {
            return Color.clear
        }
        
        if !day.isActive {
            return Color.gray.opacity(0.08)
        }
        
        // Use completion ratio for varying opacity
        if day.completionRatio > 0 {
            // Map completion ratio to opacity range: 0.2 to 1.0
            let minOpacity = 0.2
            let maxOpacity = 1.0
            let opacity = minOpacity + (day.completionRatio * (maxOpacity - minOpacity))
            return habitColor.opacity(opacity)
        } else {
            return Color.gray.opacity(0.25)
        }
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
        
        if firstDayData.date == Date.distantPast {
            return ""
        }
        
        for dayData in completionData[weekIndex] {
            if dayData.date == Date.distantPast || dayData.isFuture {
                continue
            }
            
            let dayOfMonth = calendar.component(.day, from: dayData.date)
            
            if dayOfMonth == 1 {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM"
                return formatter.string(from: dayData.date)
            }
        }
        
        if let habitStart = habit.startDate {
            let habitStartWeek = getWeekStartForDate(habitStart)
            let firstRealDay = completionData[weekIndex].first(where: { $0.date != Date.distantPast })?.date
            
            if let firstRealDay = firstRealDay,
               calendar.isDate(firstRealDay, equalTo: habitStartWeek, toGranularity: .weekOfYear) {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM"
                return formatter.string(from: habitStart)
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
        VStack(alignment: .leading, spacing: 4) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(habit.name ?? "Habit")
                        .font(.customFont("Lexend", .bold, 16))
                    
                    Text(completionText)
                        .font(.customFont("Lexend", .regular, 11))
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
            
            // Grid with day labels
            if isLoading {
                // Loading placeholder
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
                    
                    VStack(spacing: 2) {
                        HStack(spacing: 2) {
                            ForEach(0..<21, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(width: 12, height: 8)
                            }
                        }
                        
                        ForEach(0..<7, id: \.self) { _ in
                            HStack(spacing: 2) {
                                ForEach(0..<21, id: \.self) { _ in
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.gray.opacity(0.1))
                                        .frame(width: 12, height: 12)
                                }
                            }
                        }
                    }
                    .padding(6)
                }
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
                                        .font(.customFont("Lexend", .medium, 9))
                                        .foregroundColor(.secondary)
                                        .frame(width: 12, height: 12, alignment: .center)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.5)
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
                                            Color.clear
                                                .frame(width: 12, height: 12)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(6)
                    }
                    .defaultScrollAnchor(.trailing)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            
            // Legend
            HStack(spacing: 16) {
                Text("Less")
                    .font(.customFont("Lexend", .regular, 11))
                    .foregroundColor(.secondary)
                
                HStack(spacing: 2) {
                    ForEach(0..<5) { index in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(getLegendColor(for: index))
                            .frame(width: 10, height: 10)
                    }
                }
                
                Text("More")
                    .font(.customFont("Lexend", .regular, 11))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let startDate = habit.startDate {
                    Text("Since \(formatStartDate(startDate))")
                        .font(.customFont("Lexend", .regular, 9))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .glassBackground()
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
        
        let habitStartDate = habit.startDate ?? today
        let habitStartDateNormalized = calendar.startOfDay(for: habitStartDate)
        let habitStartWeekday = calendar.component(.weekday, from: habitStartDate)
        let daysFromMondayStart = (habitStartWeekday == 1) ? 6 : habitStartWeekday - 2
        let mondayOfStartWeek = calendar.date(byAdding: .day, value: -daysFromMondayStart, to: habitStartDate) ?? habitStartDate
        
        let currentWeekMonday = calendar.startOfDay(for: mondayOfCurrentWeek)
        let startWeekMonday = calendar.startOfDay(for: mondayOfStartWeek)
        
        let daysBetweenRaw = calendar.dateComponents([.day], from: startWeekMonday, to: currentWeekMonday).day ?? 0
        let daysBetween = max(0, daysBetweenRaw)
        let weeksBetween = daysBetween / 7
        
        let actualTotalWeeks = weeksBetween + 1
        let minWeeks = 21
        let finalTotalWeeks = max(minWeeks, actualTotalWeeks)
        
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
        
        for weekIndex in 0..<actualTotalWeeks {
            guard let weekStartDate = calendar.date(byAdding: .day, value: weekIndex * 7, to: startWeekMonday) else { continue }
            
            var weekData: [DayData] = []
            
            for dayOffset in 0..<7 {
                guard let date = calendar.date(byAdding: .day, value: dayOffset, to: weekStartDate) else { continue }
                let dateStart = calendar.startOfDay(for: date)
                
                if dateStart < habitStartDateNormalized {
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
                        quantityUnit: quantityUnit
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
                    quantityUnit: quantityUnit
                ))
            }
            
            tempData.append(weekData)
        }
        
        // Pad with minimum weeks if needed
        while tempData.count < minWeeks {
            let emptyWeek = (0..<7).map { _ in
                DayData(
                    date: Date.distantPast,
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
                    quantityUnit: quantityUnit
                )
            }
            tempData.insert(emptyWeek, at: 0)
        }
        
        return (
            data: tempData,
            totalDays: activeDaysCount,
            completedDays: completedActiveDays,
            totalWeeks: tempData.count
        )
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
}

// MARK: - GitHub Square Component with Tooltip
struct GitHubSquare: View {
    let data: HabitGitHubGrid.DayData
    @Binding var animate: Bool
    let color: Color
    let isToday: Bool
    let habitColor: Color
    
    @State private var showTooltip = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3)
                .fill(color)
                .frame(width: 12, height: 12)
                .scaleEffect(animate ? 1.0 : 0.1)
                .animation(
                    .spring(response: 0.5, dampingFraction: 0.7)
                    .delay(getDelay()),
                    value: animate
                )
            
            if isToday {
                RoundedRectangle(cornerRadius: 3)
                    .stroke(Color.primary, lineWidth: 1.5)
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
