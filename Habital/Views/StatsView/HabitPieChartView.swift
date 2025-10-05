//
//  HabitPieChartView.swift
//  Habital
//
//  Created by Elias Osarumwense on 09.05.25.
//
import SwiftUI
import CoreData

struct HabitPieChartsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Habit.order, ascending: true)],
        animation: .default
    )
    private var habits: FetchedResults<Habit>
    
    @State private var selectedTab = 0
    let startDate: Date
    let endDate: Date
    
    var body: some View {
        VStack {
            Picker("Pie Chart Type", selection: $selectedTab) {
                Text("Status").tag(0)
                Text("Types").tag(1)
                Text("Categories").tag(2)
                Text("Intensity").tag(3)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            TabView(selection: $selectedTab) {
                // Tab 1: Completion Status
                VStack {
                    let statusData = getCompletionStatusData()
                    
                    // Make sure data and colors are in same order
                    PieChartView(
                        data: statusData.map { $0.value },
                        colors: statusData.map { $0.color },
                        title: "Completion Status",
                        legend: "Active Habits: \(habits.filter { HabitUtilities.isHabitActive(habit: $0, on: Date()) }.count)",
                        style: ChartStyle(
                            backgroundColor: colorScheme == .dark ? Color(UIColor.systemGray6) : .white,
                            accentColor: .green,
                            secondGradientColor: .green.opacity(0.5),
                            textColor: .primary,
                            legendTextColor: .secondary,
                            dropShadowColor: .primary
                        ),
                        valueSpecifier: "%.0f%%"
                    )
                    
                    // Legend with correct colors - same order as in the data array
                    HStack(spacing: 20) {
                        ForEach(statusData, id: \.name) { item in
                            LegendItemPieChart(name: item.name, color: item.color)
                        }
                    }
                    .padding(.top, 10)
                }
                .padding()
                .tag(0)
                
                // Tab 2: Habit Types
                VStack {
                    let typeData = getHabitTypeData()
                    
                    PieChartView(
                        data: typeData.map { $0.value },
                        colors: typeData.map { $0.color },
                        title: "Habit Types",
                        legend: "Total Habits: \(habits.count)",
                        style: ChartStyle(
                            backgroundColor: colorScheme == .dark ? Color(UIColor.systemGray6) : .white,
                            accentColor: .blue,
                            secondGradientColor: .blue.opacity(0.5),
                            textColor: .primary,
                            legendTextColor: .secondary,
                            dropShadowColor: .primary
                        ),
                        valueSpecifier: "%.0f%%"
                    )
                    
                    // Legend - same order as data
                    HStack(spacing: 20) {
                        ForEach(typeData, id: \.name) { item in
                            LegendItemPieChart(name: item.name, color: item.color)
                        }
                    }
                    .padding(.top, 10)
                }
                .padding()
                .tag(1)
                
                // Tab 3: Categories/Lists
                VStack {
                    let categoryData = getCategoryData()
                    
                    PieChartView(
                        data: categoryData.map { $0.value },
                        colors: categoryData.map { $0.color },
                        title: "Habit Categories",
                        legend: "Groups: \(categoryData.count)",
                        style: ChartStyle(
                            backgroundColor: colorScheme == .dark ? Color(UIColor.systemGray6) : .white,
                            accentColor: .purple,
                            secondGradientColor: .purple.opacity(0.5),
                            textColor: .primary,
                            legendTextColor: .secondary,
                            dropShadowColor: .primary
                        ),
                        valueSpecifier: "%.0f%%"
                    )
                    
                    // Legend (scrollable if many categories) - same order as data
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            ForEach(categoryData, id: \.name) { item in
                                LegendItemPieChart(name: item.name, color: item.color)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top, 10)
                }
                .padding()
                .tag(2)
                
                // Tab 4: Intensity Levels
                VStack {
                    let intensityData = getIntensityData()
                    
                    PieChartView(
                        data: intensityData.map { $0.value },
                        colors: intensityData.map { $0.color },
                        title: "Habit Intensity",
                        legend: "By effort level",
                        style: ChartStyle(
                            backgroundColor: colorScheme == .dark ? Color(UIColor.systemGray6) : .white,
                            accentColor: .orange,
                            secondGradientColor: .orange.opacity(0.5),
                            textColor: .primary,
                            legendTextColor: .secondary,
                            dropShadowColor: .primary
                        ),
                        valueSpecifier: "%.0f%%"
                    )
                    
                    // Legend - same order as data
                    HStack(spacing: 20) {
                        ForEach(intensityData, id: \.name) { item in
                            LegendItemPieChart(name: item.name, color: item.color)
                        }
                    }
                    .padding(.top, 10)
                }
                .padding()
                .tag(3)
            }
            
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 300)
        }
        .background(Color(UIColor.systemBackground).opacity(0.6))
        .cornerRadius(12)
        .padding(.horizontal)
        
    }
    
    // MARK: - Data Calculation Methods
    
    // 1. Completion Status Data
    private func getCompletionStatusData() -> [(name: String, value: Double, color: Color)] {
        let activeHabits = habits.filter { HabitUtilities.isHabitActive(habit: $0, on: Date()) }
        let totalActive = activeHabits.count
        
        if totalActive == 0 {
            return [
                (name: "No Active Habits", value: 100, color: .gray)
            ]
        }
        
        let completed = activeHabits.filter { $0.isCompleted(on: Date()) }.count
        let missed = totalActive - completed
        
        let completedPercentage = Double(completed) / Double(totalActive) * 100
        let missedPercentage = Double(missed) / Double(totalActive) * 100
        
        return [
            (name: "Completed", value: completedPercentage, color: .green),
            (name: "Not Completed", value: missedPercentage, color: .red)
        ]
    }
    
    // 2. Habit Type Data
    private func getHabitTypeData() -> [(name: String, value: Double, color: Color)] {
        let totalHabits = habits.count
        
        if totalHabits == 0 {
            return [
                (name: "No Habits", value: 100, color: .gray)
            ]
        }
        
        let goodHabits = habits.filter { !$0.isBadHabit }.count
        let badHabits = habits.filter { $0.isBadHabit }.count
        
        let goodPercentage = Double(goodHabits) / Double(totalHabits) * 100
        let badPercentage = Double(badHabits) / Double(totalHabits) * 100
        
        return [
            (name: "Good Habits", value: goodPercentage, color: .green),
            (name: "Bad Habits", value: badPercentage, color: .red)
        ]
    }
    
    // 3. Category/List Data
    private func getCategoryData() -> [(name: String, value: Double, color: Color)] {
        let totalHabits = habits.count
        
        if totalHabits == 0 {
            return [
                (name: "No Habits", value: 100, color: .gray)
            ]
        }
        
        // Group habits by list
        var habitsByList: [String: (count: Int, color: Color)] = [:]
        
        // Add "No List" category for habits without a list
        habitsByList["No List"] = (0, .gray)
        
        // Count habits in each list
        for habit in habits {
            if let list = habit.habitList, let name = list.name {
                if habitsByList[name] == nil {
                    // Get list color if available
                    var listColor: Color = .blue
                    if let colorData = list.color,
                       let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
                        listColor = Color(uiColor)
                    }
                    
                    habitsByList[name] = (1, listColor)
                } else {
                    habitsByList[name]!.count += 1
                }
            } else {
                habitsByList["No List"]!.count += 1
            }
        }
        
        // Convert to percentage
        return habitsByList.map { key, value in
            let percentage = Double(value.count) / Double(totalHabits) * 100
            return (name: key, value: percentage, color: value.color)
        }.filter { $0.value > 0 } // Only include non-zero values
    }
    
    // 4. Intensity Level Data
    private func getIntensityData() -> [(name: String, value: Double, color: Color)] {
        let totalHabits = habits.count
        
        if totalHabits == 0 {
            return [
                (name: "No Habits", value: 100, color: .gray)
            ]
        }
        
        // Count habits by intensity
        var lightCount = 0
        var moderateCount = 0
        var highCount = 0
        var extremeCount = 0
        
        for habit in habits {
            let intensity = HabitIntensity(rawValue: habit.intensityLevel) ?? .light
            
            switch intensity {
            case .light:
                lightCount += 1
            case .moderate:
                moderateCount += 1
            case .high:
                highCount += 1
            case .extreme:
                extremeCount += 1
            }
        }
        
        // Calculate percentages
        let lightPercentage = Double(lightCount) / Double(totalHabits) * 100
        let moderatePercentage = Double(moderateCount) / Double(totalHabits) * 100
        let highPercentage = Double(highCount) / Double(totalHabits) * 100
        let extremePercentage = Double(extremeCount) / Double(totalHabits) * 100
        
        return [
            (name: "Light", value: lightPercentage, color: .green),
            (name: "Moderate", value: moderatePercentage, color: .blue),
            (name: "High", value: highPercentage, color: .orange),
            (name: "Extreme", value: extremePercentage, color: .red)
        ].filter { $0.value > 0 } // Only include non-zero values
    }
}

// Helper view for legend items
struct LegendItemPieChart: View {
    let name: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(name)
                .font(.caption)
                .foregroundColor(.primary)
        }
    }
}
