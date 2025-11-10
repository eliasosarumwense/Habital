//
//  WeeklyCompletionPieCard.swift
//  Habital
//
//  Shows a pie chart of completions by day of the week
//

import SwiftUI
import CoreData

struct WeeklyCompletionPieCard: View {
    let habit: Habit
    
    private let daysOfWeek = ["M", "T", "W", "T", "F", "S", "S"]
    @State private var weekData: [DayData] = []
    @State private var primaryHabitColor: Color = .blue
    @State private var isDataLoaded: Bool = false
    @State private var animatedCounts: [Int] = Array(repeating: 0, count: 7)
    
    var body: some View {
        VStack(spacing: 8) {
            // Compact pie chart
            if !weekData.isEmpty {
                PieChartView(
                    data: weekData.map { $0.percentage },
                    colors: weekData.map { $0.color },
                    title: "Weekly",
                    legend: "",
                    style: ChartStyle(
                        backgroundColor: .clear,
                        accentColor: primaryHabitColor,
                        secondGradientColor: primaryHabitColor.opacity(0.5),
                        textColor: .primary,
                        legendTextColor: .clear,
                        dropShadowColor: .clear
                    ),
                    form: CGSize(width: 80, height: 80),
                    dropShadow: false,
                    valueSpecifier: "%.0f%%"
                )
                .opacity(isDataLoaded ? 1.0 : 0.0)
                .scaleEffect(isDataLoaded ? 1.0 : 0.8)
                .animation(.spring(response: 0.8, dampingFraction: 0.7), value: isDataLoaded)
                
                // Compact horizontal legend with single letters
                HStack(spacing: 4) {
                    ForEach(Array(weekData.enumerated()), id: \.offset) { index, item in
                        VStack(spacing: 2) {
                            Circle()
                                .fill(item.color)
                                .frame(width: 8, height: 8)
                                .scaleEffect(isDataLoaded ? 1.0 : 0.8)
                                .opacity(isDataLoaded ? 1.0 : 0.6)
                            
                            Text(daysOfWeek[getDayIndex(for: item.day)])
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                            
                            AnimatedCounterText(
                                value: item.count,
                                animatedValue: getAnimatedCount(for: index),
                                font: .system(size: 8),
                                fontWeight: .medium
                            )
                        }
                        .opacity(isDataLoaded ? 1.0 : 0.8)
                    }
                }
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isDataLoaded)
            } else {
                // Placeholder content while loading
                VStack(spacing: 8) {
                    // Placeholder for pie chart
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 80, height: 80)
                    
                    // Placeholder for legend
                    HStack(spacing: 4) {
                        ForEach(0..<7, id: \.self) { index in
                            VStack(spacing: 2) {
                                Circle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 8, height: 8)
                                
                                Text(daysOfWeek[index])
                                    .font(.system(size: 9))
                                    .foregroundColor(.secondary)
                                
                                Text("-")
                                    .font(.system(size: 8))
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .frame(width: 100, height: 125) // Fixed height to prevent layout shift
        .padding(7)
        .sheetGlassBackground()
        .task {
            // Reset animation state when starting
            isDataLoaded = false
            animatedCounts = Array(repeating: 0, count: 7)
            await loadWeeklyData()
        }
        .onChange(of: weekData) { _, _ in
            startCountingAnimation()
        }
    }
    
    private func startCountingAnimation() {
        guard !weekData.isEmpty else { return }
        
        // Animate each counter with a slight delay
        for (index, dayData) in weekData.enumerated() {
            let targetValue = dayData.count
            
            withAnimation(
                .easeOut(duration: 0.8)
                .delay(Double(index) * 0.1)
            ) {
                if index < animatedCounts.count {
                    animatedCounts[index] = targetValue
                }
            }
        }
    }
    
    private func getAnimatedCount(for index: Int) -> Int {
        guard index < animatedCounts.count else { return 0 }
        return animatedCounts[index]
    }
    
    
    private func loadWeeklyData() async {
        // Perform data calculation on background queue
        let calculatedData = await Task.detached {
            return await MainActor.run {
                self.getWeeklyCompletionData()
            }
        }.value
        
        let calculatedColor = await Task.detached {
            return await MainActor.run {
                self.getPrimaryHabitColor()
            }
        }.value
        
        // Add 0.3 second delay before visualizing
        try? await Task.sleep(for: .milliseconds(150))
        
        // Update UI on main actor
        await MainActor.run {
            self.weekData = calculatedData
            self.primaryHabitColor = calculatedColor
            
            // Reset animation state
            self.isDataLoaded = true
            self.animatedCounts = Array(repeating: 0, count: 7)
        }
    }
    
    
    private struct AnimatedCounterText: View {
        let value: Int
        let animatedValue: Int
        let font: Font
        let fontWeight: Font.Weight
        
        var body: some View {
            Text("\(animatedValue)")
                .font(font)
                .fontWeight(fontWeight)
                .foregroundColor(.primary)
                .contentTransition(.numericText())
        }
    }
    
    private struct DayData: Equatable {
        let day: String
        let count: Int
        let percentage: Double
        let color: Color
        
        static func == (lhs: DayData, rhs: DayData) -> Bool {
            return lhs.day == rhs.day &&
                   lhs.count == rhs.count &&
                   lhs.percentage == rhs.percentage
        }
    }
    
    private func getDayIndex(for dayName: String) -> Int {
        switch dayName {
        case "Mon": return 0
        case "Tue": return 1
        case "Wed": return 2
        case "Thu": return 3
        case "Fri": return 4
        case "Sat": return 5
        case "Sun": return 6
        default: return 0
        }
    }
    
    private func getPrimaryHabitColor() -> Color {
        // Get the habit's color or default to blue
        if let colorData = habit.color,
           let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
            return Color(uiColor)
        }
        return .blue
    }
    
    private func getWeeklyCompletionData() -> [DayData] {
        let calendar = Calendar.current
        
        // Count completions per day of week (all time) for this specific habit
        var completionsByDay: [Int: Int] = [:] // weekday index -> count
        
        guard let completions = habit.completion as? Set<Completion> else {
            return getEmptyWeekData()
        }
        
        for completion in completions {
            guard let date = completion.date,
                  completion.completed else {
                continue
            }
            
            let weekday = calendar.component(.weekday, from: date)
            // Convert Sunday=1, Monday=2... to Monday=0, Tuesday=1...
            let dayIndex = (weekday == 1) ? 6 : weekday - 2
            
            completionsByDay[dayIndex, default: 0] += 1
        }
        
        // Calculate total completions and find max completions for opacity scaling
        let totalCompletions = completionsByDay.values.reduce(0, +)
        let maxCompletions = completionsByDay.values.max() ?? 1
        
        // Get primary habit color
        let primaryColor = getPrimaryHabitColor()
        
        // If no completions, show even distribution with low opacity
        if totalCompletions == 0 {
            return getEmptyWeekData()
        }
        
        // Build result array with single habit color at varying opacity
        let fullDaysOfWeek = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        return fullDaysOfWeek.enumerated().compactMap { index, day in
            let count = completionsByDay[index] ?? 0
            let percentage = totalCompletions > 0 ? (Double(count) / Double(totalCompletions)) * 100 : 0
            
            // Skip days with no completions
            guard percentage > 0 else { return nil }
            
            // Calculate opacity based on completion count (0.4 to 1.0)
            let opacityRange = 0.6 // from 0.4 to 1.0
            let minOpacity = 0.4
            let opacity = minOpacity + (Double(count) / Double(maxCompletions)) * opacityRange
            
            return DayData(
                day: day,
                count: count,
                percentage: percentage,
                color: primaryColor.opacity(opacity)
            )
        }
    }
    
    private func getEmptyWeekData() -> [DayData] {
        let fullDaysOfWeek = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        let primaryColor = getPrimaryHabitColor()
        
        return fullDaysOfWeek.enumerated().map { index, day in
            return DayData(
                day: day,
                count: 0,
                percentage: 14.3, // ~100/7
                color: primaryColor.opacity(0.2)
            )
        }
    }

}

#if DEBUG
struct WeeklyCompletionPieCard_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let habit = Habit(context: context)
        habit.name = "Sample Habit"
        
        return WeeklyCompletionPieCard(habit: habit)
            .frame(width: 140, height: 160)
    }
}
#endif
