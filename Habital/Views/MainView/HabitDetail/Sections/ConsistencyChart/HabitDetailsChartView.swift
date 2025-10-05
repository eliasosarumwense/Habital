//
//  HabitDetailsChartView.swift
//  Habital
//
//  Created by Elias Osarumwense on 15.04.25.
//

import SwiftUI
import CoreData
/*
struct DaysToShowKey: EnvironmentKey {
    static let defaultValue: Int = 30
}

extension EnvironmentValues {
    var daysToShow: Int {
        get { self[DaysToShowKey.self] }
        set { self[DaysToShowKey.self] = newValue }
    }
}

struct HabitConsistencyChart: View {
    
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("accentColorIndex") private var accentColorIndex: Int = 0
    @AppStorage("showChartTrackIndicator") private var showChartTrackIndicator = true
    let habit: Habit
    @State private var daysToShow: Int
    @State private var animate: Bool = false
    @State private var consistencyData: [DayConsistencyData] = []
    @State private var overallConsistency: Double = 0.0
    @State private var animatedConsistency: Double = 0.0
    @State private var isTransitioning = false
    
    @Binding var refreshTrigger: Bool
    
    init(habit: Habit, refreshTrigger: Binding<Bool>, initialDays: Int = 14) {
        self.habit = habit
        self._refreshTrigger = refreshTrigger
        self._daysToShow = State(initialValue: initialDays)
    }
    
    private var accentColor: Color {
        return ColorPalette.color(at: accentColorIndex)
    }
    
    private var habitColor: Color {
        if let colorData = habit.color,
           let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
            return Color(uiColor)
        }
        return .blue // Default color if not set
    }
    
    // Get display label for the duration
    private var daysLabel: String {
        switch daysToShow {
        case 14:
            return "14-Day"
        case 30:
            return "30-Day"
        case 96: // 3 months + 5 days
            return "3-Months"
        case 189: // 6 months (approx)
            return "6-Months"
        case 378: // 1 year + 13 days
            return "1-Year"
        default:
            return "\(daysToShow)-Day"
        }
    }
    
    var progressColor: Color {
            switch overallConsistency {
            case 0..<0.33:
                return Color(red: 0.8, green: 0.2, blue: 0.2) // Red
            case 0.33..<0.66:
                return Color(red: 0.9, green: 0.5, blue: 0.1) // Orange
            default:
                return Color(red: 0.2, green: 0.8, blue: 0.2) // Green
            }
        }
    // MARK: - Models
    struct DayConsistencyData: Identifiable {
        let id = UUID()
        let date: Date
        let isActive: Bool
        let isCompleted: Bool
        let completionRatio: Double // How many completions out of required
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    Text("\(daysLabel) Consistency")
                        .font(.customFont("Lexend", .semiBold, 15))
                        .foregroundColor(.secondary)
                        .transition(.opacity)
                        .animation(.easeInOut, value: daysToShow)
                    
                    Text(habit.name ?? "Habit")
                        .font(.customFont("Lexend", .bold, 18))
                        .fontWeight(.bold)
                    
                    if showChartTrackIndicator {
                        EnhancedChartTrackIndicator(
                            habit: habit,
                            date: Date(),
                            textColor: .primary,
                            showBorder: false,
                            condensed: true
                        )
                        .offset(y: 13)
                    }
                    
                    Spacer()
                    // Date display in top-right corner
                    
                    
                }
                
                Spacer()
                HStack {
                    // Consistency Score Circle
                    ZStack {
                        Circle()
                            .stroke(
                                Color.gray.opacity(0.2),
                                lineWidth: 8
                            )
                        
                        Circle()
                            .trim(from: 0, to: animatedConsistency)
                            .stroke(
                                progressColor,
                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                        
                            .onAppear {
                                // Animate from 0 to initial value
                                withAnimation(.easeOut(duration: 1.2)) {
                                    animatedConsistency = overallConsistency
                                }
                            }
                            .onChange(of: overallConsistency) { newValue in
                                withAnimation(.easeOut(duration: 1.0)) {
                                    animatedConsistency = newValue
                                }
                            }
                        
                        VStack(spacing: 0) {
                            Text("\(Int(overallConsistency * 100))%")
                                .font(.system(.title3, design: .rounded))
                                .fontWeight(.bold)
                                .animation(.easeInOut, value: overallConsistency)
                            
                            Text("consistency")
                                .font(.customFont("Lexend", .medium, 9))
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(width: 75, height: 75)
                    .offset(x: -5, y: 3)
                }
            }
            //Spacer()
            
            // Day Markers
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    /*
                    Text("Last \(daysLabel)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    */
                    /*
                    HabitStartDateView(
                        startDate: habit.startDate,
                        formatDate: formatDate
                    )
                     */
                    Spacer()
                    
                    // Time range selector
                    HStack(spacing: 4) {
                        Button("14d") {
                            selectTimeRange(days: 14)
                            triggerHaptic(.impactRigid)
                        }
                        .buttonStyle(DayRangeButtonStyle(isSelected: daysToShow == 14))
                        
                        Button("30d") {
                            selectTimeRange(days: 30)
                            triggerHaptic(.impactRigid)
                        }
                        .buttonStyle(DayRangeButtonStyle(isSelected: daysToShow == 30))
                        
                        Button("3M") {
                            selectTimeRange(days: 96) // 3 months + 5 days
                            triggerHaptic(.impactRigid)
                        }
                        .buttonStyle(DayRangeButtonStyle(isSelected: daysToShow == 96))
                        
                        Button("6M") {
                            selectTimeRange(days: 189) // 6 months
                            triggerHaptic(.impactRigid)
                        }
                        .buttonStyle(DayRangeButtonStyle(isSelected: daysToShow == 189))
                        
                        Button("1Y+") {
                            selectTimeRange(days: 378) // 1 year + 13 days
                            triggerHaptic(.impactRigid)
                        }
                        .buttonStyle(DayRangeButtonStyle(isSelected: daysToShow == 378))
                    } 
                    .font(.caption)
                }
                Spacer()
                // Chart content with improved transitions
                ZStack {
                    if daysToShow <= 30 {
                        // Single row display for 14 and 30 days
                        barChartView
                            .padding(.top, 20)
                            .padding(.bottom, 20)
                            .transition(.opacity)
                    } else {
                        // Multi-row grid display for 3M, 6M, and 1Y+
                        gridChartView
                            //.padding(.top, 20)
                            .padding(.bottom, 20)
                            .transition(.opacity)
                    }
                }
                .frame(height: daysToShow <= 30 ? 60 : getGridHeight())
                .id("chart-view-\(daysToShow)") // Force new view when days change
                .animation(.easeInOut(duration: 0.3), value: daysToShow)

                /*
                // Legend
                HStack(spacing: 16) {
                    LegendItem(label: habit.isBadHabit ? "Avoided" : "Completed", habitColor: habitColor)
                    LegendItem(label: habit.isBadHabit ? "Broke" : "Missed", habitColor: Color.gray.opacity(0.6))
                    LegendItem(label: "Not scheduled", habitColor: Color.gray.opacity(0.1))
                }
                .padding(.top, 4)
                 */
            }
            .padding(.top, 10)
        }
        .onChange(of: refreshTrigger) { _, _ in
            loadDataAndAnimate()
        }
        
        .frame(width: 340, height: getChartHeight())
        .padding()
        .glassBackground()
        //.cornerRadius(16)
        //.shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        .environment(\.daysToShow, daysToShow) // Pass daysToShow to child views
        .onAppear {
            loadDataAndAnimate()
        }
    }
    
    // MARK: - Chart Views
    
    // Bar chart view for 14 and 30 days
    private var barChartView: some View {
        HStack(spacing: getMarkerSpacing()) {
            ForEach(consistencyData.reversed()) { day in
                BarDayMarker(
                    data: day,
                    animate: $animate,
                    markerWidth: getMarkerWidth(),
                    textSize: getTextSize(),
                    habitColor: habitColor
                )
            }
        }
        .padding(.vertical, 30)
        .frame(width: 316) // Fixed width to match the grid view
        .frame(maxWidth: .infinity) // Center in parent
        
    }
    
    // Grid chart view for 3M, 6M, and 1Y+
    private var gridChartView: some View {
        VStack(spacing: 2) {
            ForEach(0..<getNumberOfRows(), id: \.self) { rowIndex in
                HStack(spacing: getMarkerSpacing()) {
                    let rowItems = getItemsForRow(rowIndex)
                    let squaresPerRow = getSquaresPerRow()
                    
                    // Display all items for this row
                    ForEach(rowItems) { day in
                        SquareDayMarker(
                            data: day,
                            animate: $animate,
                            markerWidth: getMarkerWidth(),
                            accentColor: habitColor
                        )
                    }
                    
                    // Fill with placeholders to complete the row
                    if rowItems.count < squaresPerRow && rowIndex == getNumberOfRows() - 1 {
                        ForEach(0..<(squaresPerRow - rowItems.count), id: \.self) { _ in
                            Color.clear
                                .frame(width: getMarkerWidth(), height: getMarkerWidth())
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, -20)
        .padding(.vertical, 4)
    }
    
    private func selectTimeRange(days: Int) {
        // Smooth transition when changing time range
        withAnimation(.easeOut(duration: 0.2)) {
            self.animate = false
        }
        
        // Small delay before changing days value
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeInOut(duration: 0.3)) {
                self.daysToShow = days
            }
            
            // Load new data after changing days
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.loadDataAndAnimate()
            }
        }
    }
    
    private func getChartHeight() -> CGFloat {
        // Base height calculation
        let baseHeight: CGFloat = 210
        
        if daysToShow <= 30 {
            return baseHeight
        } else {
            // Add just enough height for the grid
            return baseHeight - 60 + getGridHeight()
        }
    }
    
    private func getGridHeight() -> CGFloat {
        // Calculate grid height
        let squareHeight = getMarkerWidth()
        let rowSpacing: CGFloat = 2
        let numberOfRows = getNumberOfRows()
        
        // Total height for all squares + spacing between rows
        return (squareHeight * CGFloat(numberOfRows)) + (rowSpacing * CGFloat(numberOfRows - 1))
    }
    
    private func getSquaresPerRow() -> Int {
        // Return fixed number of squares per row for each time range
        switch daysToShow {
        case 96: // 3 months + 5 days
            return 16 // 19 - 3 (requested to delete last 3 squares)
        case 189: // 6 months
            return 21 // 15 + 6
        case 378: // 1 year + 13 days
            return 27 // 15 + 12
        default:
            return 15
        }
    }
    
    private func getNumberOfRows() -> Int {
        // Calculate number of rows needed
        let squaresPerRow = getSquaresPerRow()
        return (daysToShow + squaresPerRow - 1) / squaresPerRow // Ceiling division
    }
    
    private func getItemsForRow(_ rowIndex: Int) -> [DayConsistencyData] {
        let squaresPerRow = getSquaresPerRow()
        let startIndex = rowIndex * squaresPerRow
        let endIndex = min(startIndex + squaresPerRow, consistencyData.count)
        
        if startIndex >= consistencyData.count {
            return []
        }
        
        // Get the slice of data for this row and reverse it (for proper ordering)
        let rowData = Array(consistencyData.reversed()[startIndex..<endIndex])
        return rowData
    }
    
    private func getMarkerWidth() -> CGFloat {
        // Calculate marker width based on available view width
        let availableWidth: CGFloat = 326 // Adjusted for precise fitting
        
        switch daysToShow {
        case 14:
            return 20
        case 30:
            return 7.5
        case 96, 189, 378: // Grid views
            // Distribute squares evenly across available width
            let spacing = getMarkerSpacing()
            let squaresPerRow = getSquaresPerRow()
            return (availableWidth - (spacing * CGFloat(squaresPerRow - 1))) / CGFloat(squaresPerRow)
        default:
            return 7.5
        }
    }
    
    private func getTextSize() -> CGFloat {
        // Calculate text size based on marker width
        return max(5, min(10, getMarkerWidth() * 0.7))
    }

    private func getMarkerSpacing() -> CGFloat {
        // Adjust spacing based on marker width and days to show
        switch daysToShow {
        case 14, 30:
            return max(2, min(4, getMarkerWidth() / 2))
        case 96, 189, 378: // Grid views
            return 2 // Consistent spacing for grid layout
        default:
            return 2
        }
    }
    
    private func loadDataAndAnimate() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Generate data for the specified number of days
        var tempData: [DayConsistencyData] = []
        var activeAndCompletedCount = 0
        var activeCount = 0
        
        for dayOffset in 0..<self.daysToShow {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            
            // Check if habit is scheduled for this day
            let isActive = HabitUtilities.isHabitActive(habit: self.habit, on: date)
            
            // Check completion status
            let isCompleted = self.habit.isCompleted(on: date)
            
            // Calculate completion ratio
            let requiredRepeats = self.habit.currentRepeatsPerDay(on: date)
            let actualCompletions = self.habit.completedCount(on: date)
            let completionRatio = requiredRepeats > 0 ? min(1.0, Double(actualCompletions) / Double(requiredRepeats)) : 0.0
            
            // Update counters for overall consistency
            if isActive {
                activeCount += 1
                if isCompleted {
                    activeAndCompletedCount += 1
                }
            }
            
            tempData.append(DayConsistencyData(
                date: date,
                isActive: isActive,
                isCompleted: isCompleted,
                completionRatio: completionRatio
            ))
        }
        
        // Calculate overall consistency
        let newConsistency = activeCount > 0 ? Double(activeAndCompletedCount) / Double(activeCount) : 0.0
        
        // Update state to trigger animations
        withAnimation(.easeInOut(duration: 0.3)) {
            self.consistencyData = tempData
            self.overallConsistency = newConsistency
        }
        
        // Trigger the bar animations after the data is set
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 0.5)) {
                self.animate = true
            }
        }
    }
}

// MARK: - Component Views

// Bar day marker for 14d and 30d views
struct BarDayMarker: View {
    let data: HabitConsistencyChart.DayConsistencyData
    @Binding var animate: Bool
    let markerWidth: CGFloat
    let textSize: CGFloat
    let habitColor: Color
    @Environment(\.daysToShow) private var daysToShow
    
    var body: some View {
        VStack(spacing: 2) {
            // Vertical bar with fixed height container
            ZStack(alignment: .bottom) {
                // Fixed-size container to prevent layout shifts
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: markerWidth, height: 60)
                    
                
                if data.isActive {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(data.isCompleted ? habitColor.opacity(0.8) : Color.gray.opacity(0.6))
                        .frame(width: markerWidth, height: animate ? getHeight(ratio: data.completionRatio) : 0)
                        .animation(.spring(response: 0.4, dampingFraction: 1).delay(getDelay()), value: animate)
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: markerWidth, height: animate ? 8 : 0)
                        .animation(.spring(response: 0.4, dampingFraction: 1).delay(getDelay()), value: animate)
                }
            }
            
            /*
                Text("\(Calendar.current.component(.day, from: data.date))")
                    .customFont("Lexend", .regular, textSize)
                    .foregroundColor(.secondary)
                    .frame(width: 15, height: 15) // Fixed height prevents jumps
                    .animation(.spring(response: 0.5, dampingFraction: 0.9).delay(getDelay()), value: animate)
            */
        }
        .frame(width: markerWidth) // Ensure fixed width
        .padding(.bottom, 15)
    }
    
    private func getHeight(ratio: Double) -> CGFloat {
        return max(8, 60 * ratio)
    }
    
    private func getDelay() -> Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if let daysAgo = calendar.dateComponents([.day], from: data.date, to: today).day {
            return Double(daysAgo) * 0.02
        }
        return 0
    }
}

// Square day marker for grid views
struct SquareDayMarker: View {
    let data: HabitConsistencyChart.DayConsistencyData
    @Binding var animate: Bool
    let markerWidth: CGFloat
    let accentColor: Color
    
    var body: some View {
        ZStack {
            if data.isActive {
                RoundedRectangle(cornerRadius: 2)
                    .fill(data.isCompleted ? accentColor.opacity(0.8) : Color.gray.opacity(0.6))
                    .frame(width: markerWidth, height: markerWidth)
                    .scaleEffect(animate ? 1.0 : 0.1)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(getDelay()), value: animate)
            } else {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: markerWidth, height: markerWidth)
                    .scaleEffect(animate ? 1.0 : 0.1)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(getDelay()), value: animate)
            }
        }
    }
    
    private func getDelay() -> Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if let daysAgo = calendar.dateComponents([.day], from: data.date, to: today).day {
            return Double(daysAgo) * 0.005 // Fast animation for grid
        }
        return 0
    }
}

// Legend item
struct LegendItem: View {
    let label: String
    let habitColor: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Rectangle()
                .fill(habitColor.opacity(0.8))
                .frame(width: 10, height: 10)
                .cornerRadius(2)
            
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
        }
    }
}

struct DayRangeButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme
    let isSelected: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(isSelected ? (colorScheme == .dark ? .white : .black) : Color.gray.opacity(0.2))
            .foregroundColor(isSelected ? (colorScheme == .dark ? .black : .white) : .secondary)
            .cornerRadius(15)
            .font(.caption.bold())
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SimpleHabitChartPreview: View {
    @State private var refreshTrigger = false
    @State private var demoHabit: Habit?
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        VStack {
            if let habit = demoHabit {
                HabitConsistencyChart(
                    habit: habit,
                    refreshTrigger: $refreshTrigger
                )
                
                Button("Refresh Chart") {
                    refreshTrigger.toggle()
                }
                .buttonStyle(.borderedProminent)
                .padding()
            } else {
                ProgressView()
                    .onAppear {
                        createDemoHabit()
                    }
            }
        }
        .padding()
    }
    
    private func createDemoHabit() {
        // Create a demo habit
        let habit = Habit(context: viewContext)
        habit.id = UUID()
        habit.name = "Demo Habit"
        habit.habitDescription = "Demo habit for chart preview"
        habit.startDate = Calendar.current.date(byAdding: .day, value: -45, to: Date())
        habit.icon = "star.fill"
        habit.isBadHabit = false
        
        // Store color data
        if let colorData = try? NSKeyedArchiver.archivedData(withRootObject: UIColor.blue, requiringSecureCoding: false) {
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
        
        // Add pattern to habit
        habit.addToRepeatPattern(pattern)
        
        // Add some random completions
        addRandomCompletions(to: habit)
        
        // Set the habit
        demoHabit = habit
    }
    
    private func addRandomCompletions(to habit: Habit) {
        let calendar = Calendar.current
        let today = Date()
        
        // Add completions for some days
        for day in 0..<40 {
            if let date = calendar.date(byAdding: .day, value: -day, to: today) {
                // Create a completion with 70% chance
                if Double.random(in: 0...1) < 0.7 {
                    let completion = Completion(context: viewContext)
                    completion.date = date
                    completion.completed = true
                    completion.habit = habit
                    habit.addToCompletion(completion)
                }
            }
        }
    }
}

struct SimpleHabitChartPreview_Previews: PreviewProvider {
    static var previews: some View {
        SimpleHabitChartPreview()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}


// Subview for date display

*/
