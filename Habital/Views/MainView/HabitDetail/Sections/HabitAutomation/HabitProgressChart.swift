//
//  MinimalHabitChartView.swift
//  Habital
//
//  Beautiful minimal progress chart for habit automation
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
}

// MARK: - Time Range Enum
enum ChartTimeRange: Int, CaseIterable {
    case month = 30
    case threeMonths = 90
    case sixMonths = 180
    
    var label: String {
        switch self {
        case .month: return "30 Days"
        case .threeMonths: return "3 Months"
        case .sixMonths: return "6 Months"
        }
    }
    
    var shortLabel: String {
        switch self {
        case .month: return "30D"
        case .threeMonths: return "3M"
        case .sixMonths: return "6M"
        }
    }
}

// MARK: - Minimal Habit Chart View
struct MinimalHabitChartView: View {
    let habit: Habit
    @State private var chartData: [ChartDataPoint] = []
    @State private var isLoading = true
    @State private var selectedRange: ChartTimeRange = .month
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    
    private let chartHeight: CGFloat = 220
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with controls
            headerSection
            
            // Chart
            if !isLoading && !chartData.isEmpty {
                chartSection
                    .frame(height: chartHeight)
                    .padding(.vertical, 8)
                    .animation(.easeInOut(duration: 0.3), value: selectedRange)
                
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
        .glassBackground()
        .task {
            await loadChartData()
        }
        .onChange(of: selectedRange) { _ in
            Task {
                await loadChartData()
                // If you need to animate state changes after loading:
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        // update some state here if needed
                    }
                }
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Progress Visualization")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                if let currentAutomation = chartData.first(where: { !$0.isPrediction })?.automationPercentage {
                    Text("Current automation: \(Int(currentAutomation))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fontWeight(.medium)
                } else {
                    Text("Track your habit automation journey")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Time range picker
            Picker("Range", selection: $selectedRange) {
                ForEach(ChartTimeRange.allCases, id: \.self) { range in
                    Text(range.shortLabel)
                        .tag(range)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 140)
        }
    }
    
    // MARK: - Chart Section
    private var chartSection: some View {
        Chart(chartData) { point in
            // Main automation line
            LineMark(
                x: .value("Date", point.date),
                y: .value("Automation", point.automationPercentage)
            )
            .foregroundStyle(
                point.isPrediction ?
                Color.blue.opacity(0.4) :
                Color.blue
            )
            .lineStyle(StrokeStyle(
                lineWidth: point.isPrediction ? 1.5 : 2.5,
                lineCap: .round,
                lineJoin: .round,
                dash: point.isPrediction ? [6, 3] : []
            ))
            .interpolationMethod(.catmullRom)
            
            // Completion dots - smaller for 30 and 180 day views
            if !point.isPrediction {
                PointMark(
                    x: .value("Date", point.date),
                    y: .value("Automation", point.automationPercentage)
                )
                .foregroundStyle(
                    point.isCompleted ?
                    Color.green.gradient :
                    Color.red.opacity(0.7).gradient
                )
                .symbolSize(getPointSize())
                .annotation(position: .overlay) {
                    if Calendar.current.isDateInToday(point.date) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 6))
                            .foregroundStyle(.yellow)
                    }
                }
            }
            
            // Area under the curve for better visualization
            if !point.isPrediction {
                AreaMark(
                    x: .value("Date", point.date),
                    y: .value("Automation", point.automationPercentage)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.blue.opacity(0.2),
                            Color.blue.opacity(0.05)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }
        }
        .chartYScale(domain: 0...100)
        .chartYAxis {
            AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                AxisGridLine(
                    stroke: StrokeStyle(
                        lineWidth: 0.5,
                        dash: [4, 4]
                    )
                )
                .foregroundStyle(Color.gray.opacity(0.15))
                
                AxisValueLabel {
                    if let intValue = value.as(Int.self) {
                        Text("\(intValue)%")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: getXAxisValues()) { value in
                AxisGridLine(
                    stroke: StrokeStyle(
                        lineWidth: 0.5,
                        dash: [2, 4]
                    )
                )
                .foregroundStyle(Color.gray.opacity(0.1))
                
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        let label = formatDateForAxis(date)
                        if !label.isEmpty {
                            Text(label)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .chartPlotStyle { plotArea in
            plotArea
                .background(
                    LinearGradient(
                        colors: [
                            Color.blue.opacity(0.02),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .border(Color.gray.opacity(0.1), width: 0.5)
        }
    }
    
    // MARK: - Legend Section
    private var legendSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Main legend items
            HStack(spacing: 20) {
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
                    color: .blue.opacity(0.4),
                    label: "Predicted",
                    description: "Expected future progress"
                )
            }
        }
    }
    
    // MARK: - Helper Views
    private func legendItem(symbol: LegendSymbol, color: Color, label: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                switch symbol {
                case .circle:
                    Circle()
                        .fill(color.gradient)
                        .frame(width: 10, height: 10)
                case .line:
                    Rectangle()
                        .fill(color)
                        .frame(width: 16, height: 2)
                        .overlay(
                            HStack(spacing: 2) {
                                Rectangle().frame(width: 4, height: 2)
                                Rectangle().frame(width: 4, height: 2).opacity(0)
                                Rectangle().frame(width: 4, height: 2)
                            }
                        )
                }
                
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            
            Text(description)
                .font(.system(size: 9))
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
        case .month: return 20  // Smaller for 30 days
        case .threeMonths: return 15  // Medium for 3 months
        case .sixMonths: return 10  // Smallest for 6 months
        }
    }
    
    private func getXAxisValues() -> [Date] {
        guard !chartData.isEmpty else { return [] }
        
        let historicalData = chartData.filter { !$0.isPrediction }
        guard let firstDate = historicalData.first?.date,
              let lastDate = historicalData.last?.date else { return [] }
        
        let calendar = Calendar.current
        var dates: [Date] = []
        
        switch selectedRange {
        case .month:
            // Show only 5 labels for 30 days
            let interval = 7 // Every week
            var currentDate = firstDate
            while currentDate <= lastDate {
                dates.append(currentDate)
                currentDate = calendar.date(byAdding: .day, value: interval, to: currentDate) ?? lastDate
            }
            // Always add the last date if not already included
            if let last = dates.last, !calendar.isDate(last, inSameDayAs: lastDate) {
                dates.append(lastDate)
            }
            
        case .threeMonths:
            // Show every 2 weeks
            let interval = 14
            var currentDate = firstDate
            while currentDate <= lastDate {
                dates.append(currentDate)
                currentDate = calendar.date(byAdding: .day, value: interval, to: currentDate) ?? lastDate
            }
            if let last = dates.last, !calendar.isDate(last, inSameDayAs: lastDate) {
                dates.append(lastDate)
            }
            
        case .sixMonths:
            // Show monthly
            var currentDate = firstDate
            while currentDate <= lastDate {
                dates.append(currentDate)
                currentDate = calendar.date(byAdding: .month, value: 1, to: currentDate) ?? lastDate
            }
            if let last = dates.last, !calendar.isDate(last, inSameDayAs: lastDate) {
                dates.append(lastDate)
            }
        }
        
        return dates
    }
    
    private func formatDateForAxis(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        // Check if this date is in our axis values
        let axisValues = getXAxisValues()
        let shouldShow = axisValues.contains { calendar.isDate($0, inSameDayAs: date) }
        
        guard shouldShow else { return "" }
        
        switch selectedRange {
        case .month:
            if calendar.isDateInToday(date) {
                return "Today"
            }
            formatter.dateFormat = "d"
            return formatter.string(from: date)
            
        case .threeMonths:
            if calendar.isDateInToday(date) {
                return "Today"
            }
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
            
        case .sixMonths:
            if calendar.isDateInToday(date) {
                return "Today"
            }
            formatter.dateFormat = "MMM"
            return formatter.string(from: date)
        }
    }
    
    // MARK: - Load Chart Data
    private func loadChartData() async {
        await MainActor.run {
            isLoading = true
        }
        
        let config = HabitAutomationConfig()
        let engine = HabitAutomationEngine(config: config, context: viewContext)
        
        // Get habit analysis
        let insight = engine.calculateAutomationPercentage(habit: habit)
        
        var dataPoints: [ChartDataPoint] = []
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Get historical data based on selected range
        if let historyAnalysis = insight.historyAnalysis {
            let daysAgo = calendar.date(byAdding: .day, value: -(selectedRange.rawValue - 1), to: today)!
            
            for point in historyAnalysis.strengthHistory {
                if point.date >= daysAgo && point.date <= today {
                    dataPoints.append(ChartDataPoint(
                        date: point.date,
                        automationPercentage: min(100, point.strength * 100),
                        isCompleted: point.isStreak,
                        isPrediction: false
                    ))
                }
            }
        }
        
        // Always add prediction for next 14 days
        if let _ = insight.predictions {
            var projectedStrength = insight.historyAnalysis?.currentStrength ?? 0
            let growthRate = config.adjustedGrowthRate(for: Int64(habit.intensityLevel))
            
            // Predict for next 14 days
            for day in 1...14 {
                if let futureDate = calendar.date(byAdding: .day, value: day, to: today) {
                    // Apply growth for prediction
                    let maxStrength = 1.0
                    let remainingGrowthPotential = maxStrength - projectedStrength
                    let dailyGrowth = remainingGrowthPotential * (1 - exp(-growthRate))
                    projectedStrength = min(maxStrength, projectedStrength + dailyGrowth)
                    
                    dataPoints.append(ChartDataPoint(
                        date: futureDate,
                        automationPercentage: min(100, projectedStrength * 100),
                        isCompleted: true,
                        isPrediction: true
                    ))
                }
            }
        }
        
        await MainActor.run {
            withAnimation(.easeInOut(duration: 0.3)) {
                self.chartData = dataPoints
                self.isLoading = false
            }
        }
    }
}
