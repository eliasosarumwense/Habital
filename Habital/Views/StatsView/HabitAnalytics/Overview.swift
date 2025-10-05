//
//  Overview.swift
//  Habital
//
//  Created by Elias Osarumwense on 11.06.25.
//

//
//  StatsOverviewView.swift
//  Habital
//
//  Created by AI Assistant on 11.06.25.
//

import SwiftUI
import CoreData

struct StatsOverviewView: View {
    let habits: [Habit]
    let habitLists: [HabitList]
    let startDate: Date
    let endDate: Date
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 16) {
            // Weekly pattern chart
            GlassCard(title: "Weekly Patterns", subtitle: "Your habit completion by day of week") {
                BarChartView(
                    data: ChartData(points: getWeeklyPatternData()),
                    title: "Weekly Distribution",
                    legend: "Average completion by day",
                    style: ChartStyle(
                        backgroundColor: .clear,
                        accentColor: .orange,
                        secondGradientColor: .orange.opacity(0.3),
                        textColor: .primary,
                        legendTextColor: .secondary,
                        dropShadowColor: .clear
                    ),
                    form: CGSize(width: 300, height: 180),
                    dropShadow: false,
                    valueSpecifier: "%.1f"
                )
            }
            
            // Streak analysis
            GlassCard(title: "Streak Analysis", subtitle: "Your longest streaks over time") {
                LineChartView(
                    data: getStreakData(),
                    title: "Best Streaks",
                    legend: "Days in a row",
                    style: ChartStyle(
                        backgroundColor: .clear,
                        accentColor: .green,
                        secondGradientColor: .green.opacity(0.3),
                        textColor: .primary,
                        legendTextColor: .secondary,
                        dropShadowColor: .clear
                    ),
                    form: CGSize(width: 300, height: 200),
                    dropShadow: false,
                    valueSpecifier: "%.0f days"
                )
            }
            
            // Habit intensity distribution
            HabitIntensityCard(habits: habits)
            
            // Habit lists distribution
            HabitListDistributionCard(habits: habits, habitLists: habitLists)
            
            // Habit types distribution (Good vs Bad habits)
            HabitTypeDistributionCard(habits: habits)
            
            // Habit list performance comparison
            HabitListPerformanceCard(habits: habits, habitLists: habitLists, startDate: startDate, endDate: endDate)
            
            // Bad habit tracking insights
            BadHabitInsightsCard(habits: habits, startDate: startDate, endDate: endDate)
        }
    }
    
    // MARK: - Data Generation Methods
    
    private func getWeeklyPatternData() -> [Double] {
        let calendar = Calendar.current
        var weeklyData = Array(repeating: 0.0, count: 7)
        var weeklyCounts = Array(repeating: 0, count: 7)
        
        let numberOfDays = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 7
        
        for dayOffset in 0...numberOfDays {
            guard let currentDate = calendar.date(byAdding: .day, value: dayOffset, to: startDate) else { continue }
            
            let weekday = calendar.component(.weekday, from: currentDate) - 1
            let adjustedWeekday = weekday == 0 ? 6 : weekday - 1
            
            let completionRate = HabitUtilities.calculateHabitCompletionPercentage(for: currentDate, habits: habits)
            weeklyData[adjustedWeekday] += completionRate * 100
            weeklyCounts[adjustedWeekday] += 1
        }
        
        for i in 0..<7 {
            if weeklyCounts[i] > 0 {
                weeklyData[i] = weeklyData[i] / Double(weeklyCounts[i])
            }
        }
        
        return weeklyData.allSatisfy({ $0 == 0 }) ? [4.2, 3.8, 4.5, 4.1, 3.9, 2.8, 2.3] : weeklyData
    }
    
    private func getStreakData() -> [Double] {
        let calendar = Calendar.current
        let weeks = calendar.dateComponents([.weekOfYear], from: startDate, to: endDate).weekOfYear ?? 4
        let weeksToShow = min(weeks, 12)
        
        var streakData: [Double] = []
        
        for i in 0..<weeksToShow {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weeksToShow + i, to: endDate) else { continue }
            
            var maxStreak = 0.0
            
            for habit in habits {
                let streak = habit.calculateStreak(upTo: weekStart)
                maxStreak = max(maxStreak, Double(streak))
            }
            
            streakData.append(maxStreak)
        }
        
        return streakData.isEmpty ? [3, 5, 7, 4, 8, 12, 9, 15, 11, 18, 14, 22] : streakData
    }
}



// MARK: - Supporting Card Views

struct HabitListDistributionCard: View {
    let habits: [Habit]
    let habitLists: [HabitList]
    
    @Environment(\.colorScheme) private var colorScheme
    
    private func getListDistributionData() -> [(name: String, count: Int, color: Color)] {
        var listCounts: [String: (count: Int, color: Color)] = [:]
        
        // Count habits without lists
        var noListCount = 0
        
        for habit in habits {
            if let list = habit.habitList, let listName = list.name {
                if listCounts[listName] == nil {
                    // Get list color
                    let listColor: Color
                    if let colorData = list.color,
                       let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
                        listColor = Color(uiColor)
                    } else {
                        listColor = .blue
                    }
                    listCounts[listName] = (1, listColor)
                } else {
                    listCounts[listName]!.count += 1
                }
            } else {
                noListCount += 1
            }
        }
        
        var result = listCounts.map { (name: $0.key, count: $0.value.count, color: $0.value.color) }
        
        if noListCount > 0 {
            result.append((name: "No List", count: noListCount, color: .gray))
        }
        
        return result.sorted { $0.count > $1.count }
    }
    
    var body: some View {
        GlassCard(title: "Habit Lists", subtitle: "Distribution across your lists") {
            let listData = getListDistributionData()
            
            if listData.isEmpty {
                Text("No habits found")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    ForEach(listData.prefix(6), id: \.name) { item in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(item.color)
                                .frame(width: 12, height: 12)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                
                                Text("\(item.count) habit\(item.count == 1 ? "" : "s")")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(item.color.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .strokeBorder(item.color.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                }
            }
        }
    }
}

struct HabitTypeDistributionCard: View {
    let habits: [Habit]
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var typeData: (good: Int, bad: Int) {
        let goodHabits = habits.filter { !$0.isBadHabit }.count
        let badHabits = habits.filter { $0.isBadHabit }.count
        return (good: goodHabits, bad: badHabits)
    }
    
    var body: some View {
        GlassCard(title: "Habit Types", subtitle: "Good vs Bad habits breakdown") {
            let data = typeData
            
            HStack(spacing: 20) {
                // Good habits
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.2))
                            .frame(width: 60, height: 60)
                        
                        Text("\(data.good)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.green)
                    }
                    
                    Text("Good Habits")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Bad habits
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(0.2))
                            .frame(width: 60, height: 60)
                        
                        Text("\(data.bad)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.red)
                    }
                    
                    Text("Bad Habits")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct HabitIntensityCard: View {
    let habits: [Habit]
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var intensityData: [(level: String, count: Int, color: Color, multiplier: String)] {
        let light = habits.filter { $0.intensityLevel == 1 }.count
        let moderate = habits.filter { $0.intensityLevel == 2 }.count
        let high = habits.filter { $0.intensityLevel == 3 }.count
        let extreme = habits.filter { $0.intensityLevel == 4 }.count
        
        return [
            (level: "Light", count: light, color: .green, multiplier: "1x"),
            (level: "Moderate", count: moderate, color: .blue, multiplier: "1.5x"),
            (level: "High", count: high, color: .orange, multiplier: "2x"),
            (level: "Extreme", count: extreme, color: .red, multiplier: "3x")
        ]
    }
    
    var body: some View {
        GlassCard(title: "Intensity Levels", subtitle: "How challenging are your habits") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(intensityData, id: \.level) { item in
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(item.color.opacity(0.2))
                                .frame(width: 50, height: 50)
                            
                            VStack(spacing: 2) {
                                Text("\(item.count)")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(item.color)
                                
                                Text(item.multiplier)
                                    .font(.caption2)
                                    .foregroundColor(item.color)
                            }
                        }
                        
                        Text(item.level)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

struct HabitListPerformanceCard: View {
    let habits: [Habit]
    let habitLists: [HabitList]
    let startDate: Date
    let endDate: Date
    
    @Environment(\.colorScheme) private var colorScheme
    
    private func getListPerformance() -> [(name: String, rate: Double, color: Color, count: Int)] {
        let calendar = Calendar.current
        let numberOfDays = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 1
        
        var listPerformance: [String: (totalActive: Int, totalCompleted: Int, color: Color, count: Int)] = [:]
        
        // Track habits without lists
        var noListActive = 0
        var noListCompleted = 0
        var noListCount = 0
        
        for habit in habits {
            var habitActive = 0
            var habitCompleted = 0
            
            for dayOffset in 0...numberOfDays {
                if let currentDate = calendar.date(byAdding: .day, value: dayOffset, to: startDate) {
                    if HabitUtilities.isHabitActive(habit: habit, on: currentDate) {
                        habitActive += 1
                        if habit.isCompleted(on: currentDate) {
                            habitCompleted += 1
                        }
                    }
                }
            }
            
            if let list = habit.habitList, let listName = list.name {
                let listColor: Color
                if let colorData = list.color,
                   let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
                    listColor = Color(uiColor)
                } else {
                    listColor = .blue
                }
                
                if listPerformance[listName] == nil {
                    listPerformance[listName] = (habitActive, habitCompleted, listColor, 1)
                } else {
                    listPerformance[listName]!.totalActive += habitActive
                    listPerformance[listName]!.totalCompleted += habitCompleted
                    listPerformance[listName]!.count += 1
                }
            } else {
                noListActive += habitActive
                noListCompleted += habitCompleted
                noListCount += 1
            }
        }
        
        var result: [(name: String, rate: Double, color: Color, count: Int)] = []
        
        for (name, data) in listPerformance {
            let rate = data.totalActive > 0 ? Double(data.totalCompleted) / Double(data.totalActive) : 0
            result.append((name: name, rate: rate, color: data.color, count: data.count))
        }
        
        if noListActive > 0 {
            let rate = Double(noListCompleted) / Double(noListActive)
            result.append((name: "No List", rate: rate, color: .gray, count: noListCount))
        }
        
        return result.sorted { $0.rate > $1.rate }
    }
    
    var body: some View {
        GlassCard(title: "List Performance", subtitle: "Completion rates by habit list") {
            let listData = getListPerformance()
            
            if listData.isEmpty {
                Text("No list performance data")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                VStack(spacing: 8) {
                    ForEach(listData.indices, id: \.self) { index in
                        let item = listData[index]
                        
                        HStack(spacing: 12) {
                            Circle()
                                .fill(item.color)
                                .frame(width: 12, height: 12)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                
                                Text("\(item.count) habit\(item.count == 1 ? "" : "s")")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text("\(Int(item.rate * 100))%")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(item.color)
                        }
                        .padding(.vertical, 4)
                        
                        if index < listData.count - 1 {
                            Divider()
                        }
                    }
                }
            }
        }
    }
}

struct BadHabitInsightsCard: View {
    let habits: [Habit]
    let startDate: Date
    let endDate: Date
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var badHabitStats: (total: Int, avoided: Int, broken: Int, avoidanceRate: Double) {
        let badHabits = habits.filter { $0.isBadHabit }
        let calendar = Calendar.current
        let numberOfDays = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 1
        
        var totalActive = 0
        var totalAvoided = 0
        
        for habit in badHabits {
            for dayOffset in 0...numberOfDays {
                if let currentDate = calendar.date(byAdding: .day, value: dayOffset, to: startDate) {
                    if HabitUtilities.isHabitActive(habit: habit, on: currentDate) {
                        totalActive += 1
                        // For bad habits, isCompleted = true means they avoided it successfully
                        if habit.isCompleted(on: currentDate) {
                            totalAvoided += 1
                        }
                    }
                }
            }
        }
        
        let broken = totalActive - totalAvoided
        let avoidanceRate = totalActive > 0 ? Double(totalAvoided) / Double(totalActive) : 0
        
        return (total: badHabits.count, avoided: totalAvoided, broken: broken, avoidanceRate: avoidanceRate)
    }
    
    var body: some View {
        GlassCard(title: "Bad Habit Tracking", subtitle: "How well you're avoiding bad habits") {
            let stats = badHabitStats
            
            if stats.total == 0 {
                Text("No bad habits tracked")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                HStack(spacing: 20) {
                    // Avoidance rate
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.2))
                                .frame(width: 60, height: 60)
                            
                            Text("\(Int(stats.avoidanceRate * 100))%")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.green)
                        }
                        
                        Text("Avoided")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Times broken
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color.red.opacity(0.2))
                                .frame(width: 60, height: 60)
                            
                            Text("\(stats.broken)")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.red)
                        }
                        
                        Text("Broken")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}




// MARK: - GlassCard Component (if not already defined elsewhere)
