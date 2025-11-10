//
//  HabitProgressChart.swift
//  Habital
//
//  Interactive habit progress chart with drag selection
//

import SwiftUI
import Charts
import CoreData

// MARK: - Chart Data Point
struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let automationPercentage: Double
    let isCompleted: Bool
    let isPrediction: Bool
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    var formattedPercentage: String {
        return "\(Int(automationPercentage))%"
    }
}

// MARK: - Time Range Enum
enum ChartTimeRange: Int, CaseIterable {
    case month = 30
    case threeMonths = 90
    case sixMonths = 180
    case year = 365
    case threeYears = 1095
    
    var label: String {
        switch self {
        case .month: return "30 Days"
        case .threeMonths: return "3 Months"
        case .sixMonths: return "6 Months"
        case .year: return "1 Year"
        case .threeYears: return "3 Years"
        }
    }
    
    var shortLabel: String {
        switch self {
        case .month: return "1M"
        case .threeMonths: return "3M"
        case .sixMonths: return "6M"
        case .year: return "1Y"
        case .threeYears: return "3Y"
        }
    }
}

// MARK: - Interactive Habit Chart View
struct MinimalHabitChartView: View {
    let habit: Habit
    @State private var allChartData: [ChartDataPoint] = []
    @State private var isLoading = true
    @State private var selectedRange: ChartTimeRange = .month
    @State private var selectedDataPoint: ChartDataPoint?
    @State private var showSelectionBar = false
    @State private var offsetX: CGFloat = 0
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    
    private let chartHeight: CGFloat = 240
    
    // Computed property to get filtered data based on selected range
    private var filteredChartData: [ChartDataPoint] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let startDate = calendar.date(byAdding: .day, value: -(selectedRange.rawValue - 1), to: today) ?? today
        
        return allChartData.filter { point in
            point.date >= startDate || point.isPrediction
        }
    }
    
    // Computed property to get the best percentage ever achieved (from all data)
    private var bestPercentageEver: Double {
        let historicalData = allChartData.filter { !$0.isPrediction }
        return historicalData.map { $0.automationPercentage }.max() ?? 0
    }

    
    // Get habit color
    private var habitColor: Color {
        if let colorData = habit.color,
           let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
            return Color(uiColor)
        }
        return .blue // Default color if not set
    }
    
    // Get automation colors based on percentage (same logic as HabitAutomationView)
    private func getAutomationColors(for percentage: Double) -> [Color] {
        if habit.isBadHabit {
            // For bad habits: red = still doing it, green = successfully avoiding
            if percentage < 30 {
                return [.red, .orange]
            } else if percentage < 70 {
                return [.orange, .yellow]
            } else {
                return [.green, .mint]
            }
        } else {
            // For good habits: standard progression
            if percentage < 30 {
                return [.red, .orange]
            } else if percentage < 70 {
                return [.orange, .yellow]
            } else {
                return [.green, .blue]
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with controls
            headerSection
            
            // Chart
            if !isLoading && !allChartData.isEmpty {
                chartSection
                    .padding(.top, 4)
                
                // Enhanced legend
                legendSection
                
            } else if isLoading {
                ProgressView()
                    .frame(height: chartHeight)
                    .frame(maxWidth: .infinity)
            } else {
                ContentUnavailableView(
                    "No data available",
                    systemImage: "chart.line.uptrend.xyaxis",
                    description: Text("Start completing your habit to see progress")
                )
                .frame(height: chartHeight)
            }
        }
        .padding()
        .sheetGlassBackground()
        .customFont("Lexend", .regular, 14)
        .task {
            await loadChartData()
        }
        .onChange(of: selectedRange) { oldValue, newValue in
            withAnimation(.easeInOut(duration: 0.6)) {
                // Chart will automatically animate the transition
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Progress Visualization")
                    .customFont("Lexend", .semiBold, 15)
                    .foregroundStyle(.primary)
                
                // Status info under title - show current automation percentage
                if let currentAutomation = filteredChartData.last(where: { !$0.isPrediction && Calendar.current.isDateInToday($0.date) })?.automationPercentage ??
                   filteredChartData.first(where: { !$0.isPrediction })?.automationPercentage {
                    HStack(spacing: 4) {
                        Text("Currently:")
                            .customFont("Lexend", .regular, 11)
                            .foregroundStyle(.secondary)
                        Text("\(Int(currentAutomation))% automated")
                            .customFont("Lexend", .semiBold, 11)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("Track your automation journey")
                        .customFont("Lexend", .regular, 11)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Time range picker - smaller and more compact
            Picker("Range", selection: $selectedRange) {
                ForEach(ChartTimeRange.allCases, id: \.self) { range in
                    Text(range.shortLabel)
                        .customFont("Lexend", .regular, 8)
                        .tag(range)
                }
            }
            .offset(x: 10)
            .pickerStyle(.segmented)
            .scaleEffect(0.95)
            //.frame(width: 170)
        }
    }
    
    // MARK: - Chart Section
    private var chartSection: some View {
        ZStack {
            Chart {
                // Area chart for filled background - softer gradient
                ForEach(filteredChartData.filter { !$0.isPrediction }) { point in
                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("Automation", point.automationPercentage)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.primary.opacity(0.15), Color.primary.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }
                
                // Main line chart - thinner, more elegant line
                ForEach(filteredChartData.filter { !$0.isPrediction }) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Automation", point.automationPercentage)
                    )
                    .foregroundStyle(Color.primary.opacity(0.8))
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.monotone)
                }
                
                // Prediction line - dashed
                ForEach(filteredChartData.filter { $0.isPrediction }) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Automation", point.automationPercentage)
                    )
                    .foregroundStyle(Color.primary.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, dash: [5, 5]))
                    .interpolationMethod(.monotone)
                }
                
                // Best percentage ever line - only show if we have historical data and it's > 0
                if bestPercentageEver > 0 {
                    let colors = getAutomationColors(for: bestPercentageEver)
                    RuleMark(
                        y: .value("Best Ever", bestPercentageEver)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: colors,
                            startPoint: .trailing,
                            endPoint: .leading
                        )
                    )
                    .lineStyle(StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [8, 4]))
                }
                
                // Points - much smaller and more subtle - MOVED TO FRONT
                ForEach(filteredChartData) { point in
                    PointMarkWithSelection(
                        point: point,
                        isSelected: selectedDataPoint?.id == point.id,
                        habitColor: habitColor
                    )
                }
                
                // Highlight selection if any - more subtle
                if let selectedPoint = selectedDataPoint {
                    RuleMark(
                        x: .value("Selected Date", selectedPoint.date)
                    )
                    .foregroundStyle(Color.primary)
                }
            }
            .id(selectedRange) // Force chart recreation on time range change
            .chartXAxis {
                AxisMarks(position: .bottom, values: getXAxisValues()) { value in
                    AxisGridLine()
                        .foregroundStyle(Color.gray.opacity(0.2))
                    
                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            let label = formatDateForAxis(date)
                            if !label.isEmpty {
                                Text(label)
                                    .customFont("Lexend", .regular, 9)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                    AxisGridLine()
                        .foregroundStyle(Color.gray.opacity(0.2))
                    
                    AxisValueLabel {
                        if let yValue = value.as(Int.self) {
                            Text("\(yValue)%")
                                .customFont("Lexend", .regular, 9)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .chartYScale(domain: 0...105)
            .chartOverlay { proxy in
                GeometryReader { geoProxy in
                    // Best percentage ever label - minimal style above the line
                    if bestPercentageEver > 0 {
                        if let yPosition = proxy.position(forY: bestPercentageEver) {
                            HStack {
                                Text("Peak: \(Int(bestPercentageEver))%")
                                    .customFont("Lexend", .semibold, 10)
                                    .foregroundColor(.primary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 7))
                                
                                Spacer()
                            }
                            .offset(x: 10, y: yPosition - 25)
                        }
                    }
                        
                    if !filteredChartData.isEmpty {
                        let halfWidth: CGFloat = 90 / 2
                        let safeOffsetX = min(max(offsetX, halfWidth), geoProxy.size.width - halfWidth)

                        RoundedRectangle(cornerRadius: 8)
                            .fill(.regularMaterial)
                            .frame(width: 70, height: 40)
                            .overlay {
                                VStack(spacing: 3) {
                                    Text(selectedDataPoint?.formattedDate ?? "")
                                        .customFont("Lexend", .medium, 10)
                                        .foregroundColor(.secondary)
                                    
                                    HStack(spacing: 3) {
                                        Text(selectedDataPoint?.formattedPercentage ?? "0%")
                                            .customFont("Lexend", .bold, 13)
                                            .foregroundColor(.primary)
                                        
                                    }
                                }
                                .onChange(of: selectedDataPoint?.id) { oldValue, newValue in
                                    // Haptic feedback when selection changes
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                    impactFeedback.impactOccurred()
                                }
                            }
                            .opacity(showSelectionBar ? 1.0 : 0.0)
                            .offset(x: safeOffsetX - 30, y: -25)
                           
                    }
                    
                    if !filteredChartData.isEmpty {
                        Rectangle().fill(.clear).contentShape(Rectangle())
                            .gesture(DragGesture().onChanged { value in
                                if !showSelectionBar {
                                    showSelectionBar = true
                                }
                                let origin = geoProxy[proxy.plotFrame!].origin
                                let location = CGPoint(
                                    x: value.location.x - origin.x,
                                    y: value.location.y - origin.y
                                )
                                offsetX = location.x + origin.x
                                
                                if let nearestData = findNearestDataPoint(to: location, in: proxy, geoProxy: geoProxy) {
                                    selectedDataPoint = nearestData
                                }
                            }
                            .onEnded { _ in
                                showSelectionBar = false
                                selectedDataPoint = nil
                            })
                    }
                }
            }
        }
        .frame(height: chartHeight)
        .padding(.top, 30)
        .clipped()
    }
    
    // MARK: - Legend Section
    private var legendSection: some View {
        HStack(spacing: 24) {
            legendItem(
                symbol: .circle,
                color: .green,
                label: "Completed",
                description: habit.isBadHabit ? "Days avoided" : "Days completed"
            )
            
            legendItem(
                symbol: .circle,
                color: .red.opacity(0.7),
                label: "Missed",
                description: habit.isBadHabit ? "Days failed" : "Days missed"
            )
            
            legendItem(
                symbol: .line,
                color: .primary.opacity(0.6),
                label: "Projected",
                description: "If done daily"
            )
        }
    }
    
    
    // MARK: - Helper Views
    private func legendItem(symbol: LegendSymbol, color: Color, label: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                switch symbol {
                case .circle:
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [color.opacity(0.8), color],
                                center: .center,
                                startRadius: 2,
                                endRadius: 8
                            )
                        )
                        .frame(width: 12, height: 12)
                        .shadow(color: color.opacity(0.3), radius: 2)
                        
                case .line:
                    RoundedRectangle(cornerRadius: 1)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.8), color],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 18, height: 3)
                        .overlay(
                            HStack(spacing: 3) {
                                RoundedRectangle(cornerRadius: 1).frame(width: 5, height: 3)
                                RoundedRectangle(cornerRadius: 1).frame(width: 5, height: 3).opacity(0)
                                RoundedRectangle(cornerRadius: 1).frame(width: 5, height: 3)
                            }
                            .foregroundStyle(color.opacity(0.6))
                        )
                }
                
                Text(label)
                    .customFont("Lexend", .semiBold, 13)
                    .foregroundStyle(.primary)
            }
            
            Text(description)
                .customFont("Lexend", .regular, 10)
                .foregroundStyle(.tertiary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    enum LegendSymbol {
        case circle, line
    }
    
    // MARK: - Helper Functions
    private func getPointSize() -> CGFloat {
        switch selectedRange {
        case .month: return 20
        case .threeMonths: return 15
        case .sixMonths: return 10
        case .year: return 8
        case .threeYears: return 6
        }
    }
    
    private func getXAxisValues() -> [Date] {
        guard !filteredChartData.isEmpty else { return [] }
        
        // Include both historical and prediction data for axis values
        let allData = filteredChartData
        guard let firstDate = allData.first?.date,
              let lastDate = allData.last?.date else { return [] }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var dates: [Date] = []
        
        switch selectedRange {
        case .month:
            let interval = 7
            var currentDate = firstDate
            while currentDate <= lastDate {
                dates.append(currentDate)
                currentDate = calendar.date(byAdding: .day, value: interval, to: currentDate) ?? lastDate
            }
            
        case .threeMonths:
            let interval = 14
            var currentDate = firstDate
            while currentDate <= lastDate {
                dates.append(currentDate)
                currentDate = calendar.date(byAdding: .day, value: interval, to: currentDate) ?? lastDate
            }
            
        case .sixMonths:
            var currentDate = firstDate
            while currentDate <= lastDate {
                dates.append(currentDate)
                currentDate = calendar.date(byAdding: .month, value: 1, to: currentDate) ?? lastDate
            }
            
        case .year:
            var currentDate = firstDate
            while currentDate <= lastDate {
                dates.append(currentDate)
                currentDate = calendar.date(byAdding: .month, value: 3, to: currentDate) ?? lastDate
            }
            
        case .threeYears:
            var currentDate = firstDate
            while currentDate <= lastDate {
                dates.append(currentDate)
                currentDate = calendar.date(byAdding: .month, value: 6, to: currentDate) ?? lastDate
            }
        }
        
        // Always ensure today is included if it's within the range
        if today >= firstDate && today <= lastDate && !dates.contains(where: { calendar.isDate($0, inSameDayAs: today) }) {
            dates.append(today)
        }
        
        // Always ensure the last date is included (this could be a prediction date)
        if !dates.contains(where: { calendar.isDate($0, inSameDayAs: lastDate) }) {
            dates.append(lastDate)
        }
        
        return dates.sorted()
    }
    
    private func formatDateForAxis(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        // Always show "Today" for today's date, regardless of other conditions
        if calendar.isDateInToday(date) {
            return "Today"
        }
        
        let axisValues = getXAxisValues()
        let shouldShow = axisValues.contains { calendar.isDate($0, inSameDayAs: date) }
        
        // Always show the last date (rightmost) even if it wouldn't normally be shown
        let isLastDate = axisValues.last.map { calendar.isDate($0, inSameDayAs: date) } ?? false
        
        guard shouldShow || isLastDate else { return "" }
        
        // Check if this date is too close to "Today" and should be hidden to avoid overlap
        let today = calendar.startOfDay(for: Date())
        let daysBetween = calendar.dateComponents([.day], from: date, to: today).day ?? 0
        let absoluteDaysBetween = abs(daysBetween)
        
        // Define minimum spacing based on time range to prevent overlap
        let minimumDaysFromToday: Int
        switch selectedRange {
        case .month:
            minimumDaysFromToday = 3  // Hide dates within 3 days of "Today"
        case .threeMonths:
            minimumDaysFromToday = 7  // Hide dates within 1 week of "Today"
        case .sixMonths:
            minimumDaysFromToday = 14 // Hide dates within 2 weeks of "Today"
        case .year:
            minimumDaysFromToday = 30 // Hide dates within 1 month of "Today"
        case .threeYears:
            minimumDaysFromToday = 60 // Hide dates within 2 months of "Today"
        }
        
        // Skip showing this date if it's too close to "Today" (but always show the last date)
        if absoluteDaysBetween < minimumDaysFromToday && !isLastDate {
            return ""
        }
        
        // Check if this is a prediction date
        let isPredictionDate = filteredChartData.first { calendar.isDate($0.date, inSameDayAs: date) }?.isPrediction ?? false
        
        switch selectedRange {
        case .month:
            if isPredictionDate && isLastDate {
                formatter.dateFormat = "MMM d"
                return formatter.string(from: date)
            }
            formatter.dateFormat = "d"
            return formatter.string(from: date)
            
        case .threeMonths:
            if isPredictionDate && isLastDate {
                formatter.dateFormat = "MMM d"
                return formatter.string(from: date)
            }
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
            
        case .sixMonths:
            if isPredictionDate && isLastDate {
                formatter.dateFormat = "MMM d"
                return formatter.string(from: date)
            }
            formatter.dateFormat = "MMM"
            return formatter.string(from: date)
            
        case .year:
            if isPredictionDate && isLastDate {
                formatter.dateFormat = "MMM d"
                return formatter.string(from: date)
            }
            formatter.dateFormat = "MMM yy"
            return formatter.string(from: date)
            
        case .threeYears:
            if isPredictionDate && isLastDate {
                formatter.dateFormat = "MMM yy"
                return formatter.string(from: date)
            }
            formatter.dateFormat = "MMM yy"
            return formatter.string(from: date)
        }
    }
    
    // MARK: - Find Nearest Data Point
    private func findNearestDataPoint(to location: CGPoint, in proxy: ChartProxy, geoProxy: GeometryProxy) -> ChartDataPoint? {
        let distances = filteredChartData.map { data in
            let xPosition = proxy.position(forX: data.date) ?? 0
            let distance = abs(xPosition - location.x)
            return (data, distance)
        }
        return distances.min(by: { $0.1 < $1.1 })?.0
    }
    
    // MARK: - Load Chart Data
    private func loadChartData() async {
        await MainActor.run {
            isLoading = true
            selectedDataPoint = nil // Clear selected data point when loading new data
        }
        
        let config = HabitAutomationConfig()
        let engine = HabitAutomationEngine(config: config, context: viewContext)
        
        // Get habit analysis
        let insight = engine.calculateAutomationPercentage(habit: habit)
        
        var dataPoints: [ChartDataPoint] = []
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Load ALL historical data (3 years) upfront
        if let historyAnalysis = insight.historyAnalysis {
            // Get data from 3 years ago to today
            let threeYearsAgo = calendar.date(byAdding: .day, value: -(ChartTimeRange.threeYears.rawValue - 1), to: today)!
            
            for point in historyAnalysis.strengthHistory {
                if point.date >= threeYearsAgo && point.date <= today {
                    dataPoints.append(ChartDataPoint(
                        date: point.date,
                        automationPercentage: min(100, point.strength * 100),
                        isCompleted: point.isStreak,
                        isPrediction: false
                    ))
                }
            }
            
            // Ensure today's data point is included if it exists
            if let todayStrength = historyAnalysis.strengthHistory.first(where: { calendar.isDate($0.date, inSameDayAs: today) }) {
                // Remove any existing today entry to avoid duplicates
                dataPoints.removeAll { calendar.isDate($0.date, inSameDayAs: today) }
                
                // Add today's point
                dataPoints.append(ChartDataPoint(
                    date: today,
                    automationPercentage: min(100, todayStrength.strength * 100),
                    isCompleted: todayStrength.isStreak,
                    isPrediction: false
                ))
            } else {
                // If no today data exists, add current strength as today's point
                dataPoints.append(ChartDataPoint(
                    date: today,
                    automationPercentage: min(100, historyAnalysis.currentStrength * 100),
                    isCompleted: true,
                    isPrediction: false
                ))
            }
        }
        
        // Always add prediction for next 14 days
        if let predictions = insight.predictions {
            var projectedStrength = insight.historyAnalysis?.currentStrength ?? 0
            
            // Use the predictions from the engine instead of calculating our own
            // The engine already accounts for intensity mapping and scheduled days
            let predictionsData = [
                (days: 7, strength: predictions.oneWeekAutomation / 100.0),
                (days: 14, strength: predictions.twoWeekAutomation / 100.0)
            ]
            
            // Interpolate between current, 1 week, and 2 week predictions
            for day in 1...14 {
                if let futureDate = calendar.date(byAdding: .day, value: day, to: today) {
                    let interpolatedStrength: Double
                    
                    if day <= 7 {
                        // Interpolate between current and 1-week prediction
                        let progress = Double(day) / 7.0
                        interpolatedStrength = projectedStrength + (predictionsData[0].strength - projectedStrength) * progress
                    } else {
                        // Interpolate between 1-week and 2-week predictions
                        let progress = Double(day - 7) / 7.0
                        interpolatedStrength = predictionsData[0].strength + (predictionsData[1].strength - predictionsData[0].strength) * progress
                    }
                    
                    dataPoints.append(ChartDataPoint(
                        date: futureDate,
                        automationPercentage: min(100, interpolatedStrength * 100),
                        isCompleted: true,
                        isPrediction: true
                    ))
                }
            }
        }
        
        await MainActor.run {
            withAnimation(.easeInOut(duration: 0.3)) {
                self.allChartData = dataPoints.sorted { $0.date < $1.date }
                self.isLoading = false
            }
        }
    }
}

// MARK: - Point Mark with Selection Support
struct PointMarkWithSelection: ChartContent {
    let point: ChartDataPoint
    let isSelected: Bool
    let habitColor: Color
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(point.date)
    }
    
    var body: some ChartContent {
        PointMark(
            x: .value("Date", point.date),
            y: .value("Automation", point.automationPercentage)
        )
        .symbolSize(
            isSelected ? 60 : 
            isToday ? 25 :
            (point.isPrediction ? 10 : 15)
        )
        .foregroundStyle(
            isSelected ? 
            Color.primary.opacity(0.8) :
                isToday ?
                    Color.primary :
                (point.isPrediction ? 
                 Color.primary.opacity(0.3) :
                    (point.isCompleted ? Color.green.opacity(0.6) : Color.red.opacity(0.6))
                )
        )
    }
}
