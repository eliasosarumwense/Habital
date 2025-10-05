//
//  HabitWeeklyCompletionChart.swift
//  Habital
//
//  Created by Assistant on 17.08.25.
//

import SwiftUI
import CoreData

struct HabitWeeklyCompletionChart: View {
    let habit: Habit
    @State private var weeklyData: [WeeklyCompletionData] = []
    @State private var animate: Bool = false
    @State private var totalActiveDays: Int = 0
    @State private var totalBrokenDays: Int = 0 // For bad habits: days with completions (broken), for good habits: days completed
    
    private let daysOfWeek = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    
    // MARK: - Models
    struct WeeklyCompletionData: Identifiable {
        let id = UUID()
        let dayOfWeek: String
        let dayIndex: Int
        let brokenDays: Int // For bad habits: days with completions (broken), for good habits: days completed
        let activeDays: Int
        let brokenPercentage: Double // For bad habits: % of days broken (higher = worse), for good habits: % completed (higher = better)
        let isToday: Bool
    }
    
    private var habitColor: Color {
        if let colorData = habit.color,
           let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
            return Color(uiColor)
        }
        return .blue
    }
    
    private var overallBrokenPercentage: Double {
        guard totalActiveDays > 0 else { return 0.0 }
        return Double(totalBrokenDays) / Double(totalActiveDays)
    }
    
    private var maxPercentage: Double {
        weeklyData.map { $0.brokenPercentage }.max() ?? 1.0
    }
    
    private var minPercentage: Double {
        weeklyData.map { $0.brokenPercentage }.min() ?? 0.0
    }
    
    private var bestDays: [String] {
        guard !weeklyData.isEmpty else { return [] }
        if habit.isBadHabit {
            // For bad habits, best days have LOWEST percentage (least broken days)
            let minPercentage = weeklyData.map { $0.brokenPercentage }.min() ?? 0.0
            return weeklyData.filter { $0.brokenPercentage == minPercentage }.map { $0.dayOfWeek }
        } else {
            // For good habits, best days have HIGHEST percentage (most completed days)
            let maxPercentage = weeklyData.map { $0.brokenPercentage }.max() ?? 0.0
            return weeklyData.filter { $0.brokenPercentage == maxPercentage }.map { $0.dayOfWeek }
        }
    }
    
    private var worstDays: [String] {
        guard !weeklyData.isEmpty else { return [] }
        if habit.isBadHabit {
            // For bad habits, worst days have HIGHEST percentage (most broken days)
            let maxPercentage = weeklyData.map { $0.brokenPercentage }.max() ?? 0.0
            return weeklyData.filter { $0.brokenPercentage == maxPercentage }.map { $0.dayOfWeek }
        } else {
            // For good habits, worst days have LOWEST percentage (least completed days)
            let minPercentage = weeklyData.map { $0.brokenPercentage }.min() ?? 0.0
            return weeklyData.filter { $0.brokenPercentage == minPercentage }.map { $0.dayOfWeek }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            Text("Weekly Completion Pattern")
                .font(.customFont("Lexend", .regular, 11))
                .foregroundColor(.secondary)
            
            // Main Chart
            VStack(alignment: .leading, spacing: 6) {
                // Day labels and bars
                ForEach(weeklyData) { dayData in
                    HStack(spacing: 8) {
                        // Day label
                        Text(dayData.dayOfWeek)
                            .font(.customFont("Lexend", .regular, 10))
                            .foregroundColor(getDayLabelColor(for: dayData))
                            .fontWeight(getDayLabelWeight(for: dayData))
                            .frame(width: 28, alignment: .leading)
                        
                        // Progress bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                // Background bar
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(height: 10)
                                
                                // Progress bar
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(getBarColor(for: dayData))
                                    .frame(
                                        width: animate ?
                                        geometry.size.width * CGFloat(dayData.brokenPercentage) : 0,
                                        height: 10
                                    )
                                    .animation(
                                        .easeInOut(duration: 0.8)
                                        .delay(Double(dayData.dayIndex) * 0.1),
                                        value: animate
                                    )
                            }
                        }
                        .frame(height: 10)
                        
                        // Percentage label
                        Text("\(Int(dayData.brokenPercentage * 100))%")
                            .font(.customFont("Lexend", .regular, 9))
                            .foregroundColor(getDayLabelColor(for: dayData))
                            .fontWeight(getDayLabelWeight(for: dayData))
                            .frame(width: 28, alignment: .trailing)
                        /*
                        // Count label - show different text for bad vs good habits
                        Text(getCountText(for: dayData))
                            .font(.customFont("Lexend", .regular, 8))
                            .foregroundColor(.secondary)
                            .frame(width: 32, alignment: .trailing)
                         */
                    }
                }
            }
        }
        .padding(12)
        .glassBackground()
        .onAppear {
            loadWeeklyData()
        }
    }
    
    private func getCountText(for dayData: WeeklyCompletionData) -> String {
        if habit.isBadHabit {
            // For bad habits: show broken/total (broken = days with completions)
            return "\(dayData.brokenDays)/\(dayData.activeDays)"
        } else {
            // For good habits: show completed/total
            return "\(dayData.brokenDays)/\(dayData.activeDays)"
        }
    }
    
    private func getDayLabelColor(for dayData: WeeklyCompletionData) -> Color {
        if bestDays.contains(dayData.dayOfWeek) && worstDays.contains(dayData.dayOfWeek) {
            // If a day is both best and worst (all days have same percentage), use primary color
            return .primary
        } else if bestDays.contains(dayData.dayOfWeek) {
            return .green
        } else if worstDays.contains(dayData.dayOfWeek) {
            return .red
        } else {
            return .primary
        }
    }
    
    private func getDayLabelWeight(for dayData: WeeklyCompletionData) -> Font.Weight {
        if bestDays.contains(dayData.dayOfWeek) && worstDays.contains(dayData.dayOfWeek) {
            // If a day is both best and worst (all days have same percentage), use medium weight
            return .medium
        } else if bestDays.contains(dayData.dayOfWeek) || worstDays.contains(dayData.dayOfWeek) {
            return .bold
        } else {
            return .medium
        }
    }
    
    private func getBarColor(for dayData: WeeklyCompletionData) -> Color {
        if dayData.activeDays == 0 {
            return Color.gray.opacity(0.2)
        }
        
        let intensity = dayData.brokenPercentage
        
        if habit.isBadHabit {
            // For bad habits: higher percentage = worse (use habit color with higher opacity)
            // Lower percentage = better (use habit color with lower opacity)
            let opacity = max(0.2, min(1.0, intensity))
            return habitColor.opacity(opacity)
        } else {
            // For good habits: higher percentage = better (use habit color with higher opacity)
            let opacity = max(0.2, min(1.0, intensity))
            return habitColor.opacity(opacity)
        }
    }
    
    private func formatStartDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
    
    private func loadWeeklyData() {
        let calendar = Calendar.current
        let today = Date()
        let todayWeekday = calendar.component(.weekday, from: today)
        
        // Convert Sunday = 1, Monday = 2... to Monday = 0, Tuesday = 1...
        let todayIndex = (todayWeekday == 1) ? 6 : todayWeekday - 2
        
        var tempData: [WeeklyCompletionData] = []
        var totalActive = 0
        var totalBroken = 0
        
        // Analyze each day of the week
        for dayIndex in 0..<7 {
            let dayName = daysOfWeek[dayIndex]
            var brokenCount = 0 // For bad habits: days with completions (broken), for good habits: completed days
            var activeCount = 0
            
            // Go through all instances of this day of week since habit started
            if let startDate = habit.startDate {
                let habitStartDate = calendar.startOfDay(for: startDate)
                var currentDate = habitStartDate
                
                // Find the first occurrence of this day of week at or after start date
                while calendar.component(.weekday, from: currentDate) != getWeekdayForIndex(dayIndex) {
                    guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
                    currentDate = nextDate
                }
                
                // Now go through every occurrence of this day of week until today
                while currentDate <= today {
                    // Check if habit is active on this date (both good and bad habits)
                    let isActive = HabitUtilities.isHabitActive(habit: habit, on: currentDate)
                    
                    if isActive {
                        activeCount += 1
                        totalActive += 1
                        
                        // Check completion status using the existing isCompleted method
                        if habit.isBadHabit {
                            // Bad habit: isCompleted = true means avoided, false means broken
                            // We want to count broken days, so count when NOT completed
                            if !habit.isCompleted(on: currentDate) {
                                brokenCount += 1
                                totalBroken += 1
                            }
                        } else {
                            // Good habit: isCompleted = true means completed
                            if habit.isCompleted(on: currentDate) {
                                brokenCount += 1 // For good habits, this represents completed days
                                totalBroken += 1
                            }
                        }
                    }
                    
                    // Move to next week (same day of week)
                    guard let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: currentDate) else { break }
                    currentDate = nextWeek
                }
            }
            
            // Calculate percentage
            let percentage: Double
            if habit.isBadHabit {
                // For bad habits: percentage of days broken (days with completion entries)
                // Higher percentage = worse performance (more broken days)
                percentage = activeCount > 0 ? Double(brokenCount) / Double(activeCount) : 0.0
            } else {
                // For good habits: percentage of days completed
                // Higher percentage = better performance
                percentage = activeCount > 0 ? Double(brokenCount) / Double(activeCount) : 0.0
            }
            
            tempData.append(WeeklyCompletionData(
                dayOfWeek: dayName,
                dayIndex: dayIndex,
                brokenDays: brokenCount,
                activeDays: activeCount,
                brokenPercentage: percentage,
                isToday: dayIndex == todayIndex
            ))
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            self.weeklyData = tempData
            self.totalActiveDays = totalActive
            self.totalBrokenDays = totalBroken
        }
        
        // Trigger bar animations
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 0.8)) {
                self.animate = true
            }
        }
    }
    

    
    private func getWeekdayForIndex(_ index: Int) -> Int {
        // Convert Monday = 0, Tuesday = 1... to Sunday = 1, Monday = 2...
        return index == 6 ? 1 : index + 2
    }
}

// MARK: - Preview
struct HabitWeeklyCompletionChartPreview: View {
    @State private var demoHabit: Habit?
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        ScrollView {
            VStack {
                if let habit = demoHabit {
                    HabitWeeklyCompletionChart(habit: habit)
                        .padding()
                } else {
                    ProgressView()
                        .onAppear {
                            createDemoHabit()
                        }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    private func createDemoHabit() {
        let habit = Habit(context: viewContext)
        habit.id = UUID()
        habit.name = "Social Media Scrolling"
        habit.habitDescription = "Avoid mindless social media scrolling"
        habit.startDate = Calendar.current.date(byAdding: .day, value: -90, to: Date())
        habit.icon = "iphone"
        habit.isBadHabit = true // Demo bad habit
        
        // Store red color for bad habit
        if let colorData = try? NSKeyedArchiver.archivedData(withRootObject: UIColor.systemRed, requiringSecureCoding: false) {
            habit.color = colorData
        }
        
        // Create pattern
        let pattern = RepeatPattern(context: viewContext)
        pattern.effectiveFrom = habit.startDate
        pattern.followUp = false
        pattern.repeatsPerDay = 1
        pattern.habit = habit
        
        // Daily goal
        let dailyGoal = DailyGoal(context: viewContext)
        dailyGoal.everyDay = true
        dailyGoal.repeatPattern = pattern
        
        habit.addToRepeatPattern(pattern)
        
        // Add realistic bad habit completion pattern with day-of-week preferences
        addRealisticBadHabitCompletions(to: habit)
        
        demoHabit = habit
    }
    
    private func addRealisticBadHabitCompletions(to habit: Habit) {
        let calendar = Calendar.current
        let today = Date()
        
        // Create different broken rates for different days (higher = more likely to break habit)
        let dayBrokenRates: [Int: Double] = [
            2: 0.2,  // Monday - low broken rate (good avoidance)
            3: 0.25, // Tuesday - low broken rate
            4: 0.3,  // Wednesday - medium-low
            5: 0.4,  // Thursday - medium
            6: 0.6,  // Friday - higher broken rate
            7: 0.8,  // Saturday - high broken rate
            1: 0.7   // Sunday - high broken rate
        ]
        
        for day in 0..<90 {
            if let date = calendar.date(byAdding: .day, value: -day, to: today) {
                let weekday = calendar.component(.weekday, from: date)
                let brokenRate = dayBrokenRates[weekday] ?? 0.4
                
                // Add some randomness
                let randomFactor = Double.random(in: 0.8...1.2)
                let finalRate = min(1.0, brokenRate * randomFactor)
                
                // If the habit was broken on this day, create a completion entry
                if Double.random(in: 0...1) < finalRate {
                    let completion = Completion(context: viewContext)
                    completion.date = calendar.startOfDay(for: date)
                    completion.completed = true
                    completion.habit = habit
                    habit.addToCompletion(completion)
                }
            }
        }
    }
}

struct HabitWeeklyCompletionChartPreview_Previews: PreviewProvider {
    static var previews: some View {
        HabitWeeklyCompletionChartPreview()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
