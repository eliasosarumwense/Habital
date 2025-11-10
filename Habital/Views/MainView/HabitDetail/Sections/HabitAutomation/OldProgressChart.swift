//
//  OldProgressChart.swift
//  Habital
//
//  Created by Elias Osarumwense on 25.10.25.
//

/*
 import SwiftUI
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
         .padding(.horizontal, 20)
         .padding(.vertical, 16)
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
                 
                 HStack(spacing: 8) {
                     if let currentAutomation = chartData.first(where: { !$0.isPrediction })?.automationPercentage {
                         Text("Current: \(Int(currentAutomation))%")
                             .font(.caption)
                             .foregroundStyle(.secondary)
                             .fontWeight(.medium)
                     } else {
                         Text("Track your habit automation")
                             .font(.caption)
                             .foregroundStyle(.secondary)
                     }
                     
                     // Show prediction info if available
                     if chartData.contains(where: { $0.isPrediction }) {
                         Divider()
                             .frame(height: 12)
                         
                         Image(systemName: "crystal.ball")
                             .foregroundStyle(.blue.opacity(0.6))
                             .font(.caption2)
                         
                         Text("14-day forecast")
                             .font(.caption2)
                             .foregroundStyle(.blue.opacity(0.8))
                             .fontWeight(.medium)
                     }
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
         let calendar = Calendar.current
         let today = calendar.startOfDay(for: Date())
         
         // Separate historical and prediction data
         let historicalData = chartData.filter { !$0.isPrediction }
         let predictionData = chartData.filter { $0.isPrediction }
         
         let automationData = chartData.compactMap { $0.automationPercentage }
         let chartLabels = generateChartLabels()
         let detailedLabels = generateDetailedLabels()
         
         return VStack(spacing: 0) {
             // Add a subtle divider line to mark today's date
             if chartData.contains(where: { $0.isPrediction }) {
                 HStack(spacing: 4) {
                     Rectangle()
                         .fill(Color.secondary.opacity(0.3))
                         .frame(height: 1)
                     
                     Text("Today")
                         .font(.caption2)
                         .foregroundStyle(.secondary)
                         .padding(.horizontal, 6)
                         .background(
                             Capsule()
                                 .fill(.ultraThinMaterial)
                         )
                     
                     Rectangle()
                         .fill(Color.secondary.opacity(0.3))
                         .frame(height: 1)
                 }
                 .padding(.bottom, 8)
             }
             
             AnimatedHabitLineChart(
                 data: automationData,
                 labels: chartLabels,
                 detailedLabels: detailedLabels,
                 title: "",
                 legend: "",
                 chartStyle: ChartStyle(
                     backgroundColor: Color.clear,
                     accentColor: .blue,
                     secondGradientColor: Color.blue.opacity(0.3),
                     textColor: .primary,
                     legendTextColor: .secondary,
                     dropShadowColor: .clear
                 )
             )
             .frame(height: 280)
         }
         .clipped()
     }
     
     // MARK: - Chart Form Size
     private var chartFormSize: CGSize {
         switch selectedRange {
         case .month:
             return ChartForm.medium
         case .threeMonths:
             return ChartForm.large
         case .sixMonths:
             return ChartForm.extraLarge
         }
     }
     
     // MARK: - Chart Label Generation
     private func generateChartLabels() -> [String] {
         guard !chartData.isEmpty else { return [] }
         
         let calendar = Calendar.current
         let dateFormatter = DateFormatter()
         let today = calendar.startOfDay(for: Date())
         
         switch selectedRange {
         case .month:
             // Show 4-5 smart labels for 30 days to avoid crowding
             dateFormatter.dateFormat = "M/d"
             let interval = max(1, chartData.count / 4) // Show only 4-5 labels
             
             var labels: [String] = []
             for i in stride(from: 0, to: chartData.count, by: interval) {
                 if i < chartData.count {
                     let dataPoint = chartData[i]
                     let dateString = dateFormatter.string(from: dataPoint.date)
                     
                     // Mark future dates
                     if dataPoint.date > today && dataPoint.isPrediction {
                         labels.append("\(dateString)*")  // Add asterisk for future
                     } else {
                         labels.append(dateString)
                     }
                 }
             }
             return labels
             
         case .threeMonths:
             // Show 6-7 smart labels for 3 months
             dateFormatter.dateFormat = "M/d"
             let interval = max(1, chartData.count / 6) // Show 6-7 labels
             
             var labels: [String] = []
             for i in stride(from: 0, to: chartData.count, by: interval) {
                 if i < chartData.count {
                     let dataPoint = chartData[i]
                     let dateString = dateFormatter.string(from: dataPoint.date)
                     
                     // Mark future dates
                     if dataPoint.date > today && dataPoint.isPrediction {
                         labels.append("\(dateString)*")
                     } else {
                         labels.append(dateString)
                     }
                 }
             }
             return labels
             
         case .sixMonths:
             // Show monthly labels for 6 months
             dateFormatter.dateFormat = "MMM"
             let interval = max(1, chartData.count / 6)
             
             var labels: [String] = []
             for i in stride(from: 0, to: chartData.count, by: interval) {
                 if i < chartData.count {
                     let dataPoint = chartData[i]
                     let dateString = dateFormatter.string(from: dataPoint.date)
                     
                     if dataPoint.date > today && dataPoint.isPrediction {
                         labels.append("\(dateString)*")
                     } else {
                         labels.append(dateString)
                     }
                 }
             }
             return labels
         }
     }
     
     private func generateDetailedLabels() -> [String] {
         let calendar = Calendar.current
         let today = calendar.startOfDay(for: Date())
         let dateFormatter = DateFormatter()
         dateFormatter.dateFormat = "MMM d, yyyy"
         
         return chartData.map { dataPoint in
             let dateString = dateFormatter.string(from: dataPoint.date)
             let automationValue = Int(dataPoint.automationPercentage)
             
             if dataPoint.isPrediction {
                 return "\(dateString)\n🔮 Predicted: \(automationValue)%"
             } else {
                 if dataPoint.date >= today {
                     return "\(dateString)\n📅 Today: \(automationValue)%"
                 } else {
                     return "\(dateString)\n📊 Actual: \(automationValue)%"
                 }
             }
         }
     }
     
     // MARK: - Chart Helper Properties
     private var currentAutomationLegend: String {
         if let currentAutomation = chartData.first(where: { !$0.isPrediction })?.automationPercentage {
             return "Current automation: \(Int(currentAutomation))%"
         }
         return "Track your habit automation"
     }
     
     private func calculateGrowthRate() -> Int {
         guard chartData.count >= 2 else { return 0 }
         
         let recentData = chartData.filter { !$0.isPrediction }.suffix(7) // Last 7 days
         guard recentData.count >= 2 else { return 0 }
         
         let firstValue = recentData.first!.automationPercentage
         let lastValue = recentData.last!.automationPercentage
         
         if firstValue == 0 { return 0 }
         
         let growthRate = ((lastValue - firstValue) / firstValue) * 100
         return Int(growthRate.rounded())
     }
     
     // MARK: - Legend Section
     private var legendSection: some View {
         VStack(alignment: .leading, spacing: 8) {
             Text("Chart Information")
                 .font(.caption)
                 .fontWeight(.semibold)
                 .foregroundStyle(.secondary)
             
             HStack(spacing: 20) {
                 legendItem(
                     symbol: .line,
                     color: .blue,
                     label: "Automation Progress",
                     description: "Your habit automation percentage over time"
                 )
                 
                 if chartData.contains(where: { $0.isPrediction }) {
                     legendItem(
                         symbol: .line,
                         color: .blue.opacity(0.4),
                         label: "Future Prediction",
                         description: "Projected automation levels (marked with *)"
                     )
                 }
             }
             
             VStack(alignment: .leading, spacing: 2) {
                 Text("Tap and drag on the chart to see detailed values")
                     .font(.caption2)
                     .foregroundStyle(.tertiary)
                 
                 if chartData.contains(where: { $0.isPrediction }) {
                     Text("Dates with * indicate future predictions")
                         .font(.caption2)
                         .foregroundStyle(.tertiary)
                         .italic()
                 }
             }
             .padding(.top, 4)
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

 // MARK: - Animated Habit Line Chart
 struct AnimatedHabitLineChart: View {
     let data: [Double]
     let labels: [String]
     let detailedLabels: [String]
     let title: String
     let legend: String
     let chartStyle: ChartStyle
     
     // Animation state
     @State private var animationProgress: CGFloat = 0
     
     var body: some View {
         VStack(alignment: .leading, spacing: 0) {
             // Title and legend (if provided)
             if !title.isEmpty || !legend.isEmpty {
                 HStack {
                     if !title.isEmpty {
                         Text(title)
                             .font(.system(size: 18, weight: .semibold))
                             .foregroundColor(chartStyle.textColor)
                     }
                     Spacer()
                     if !legend.isEmpty {
                         Text(legend)
                             .font(.system(size: 14, weight: .medium))
                             .foregroundColor(chartStyle.legendTextColor)
                     }
                 }
                 .padding(.bottom, 8)
             }
             
             // The actual chart
             GeometryReader { geometry in
                 ZStack {
                     LineView(
                         data: data,
                         title: "",
                         legend: "",
                         style: chartStyle,
                         valueSpecifier: "%.0f%%",
                         xAxisLabels: labels,
                         dataLabels: detailedLabels
                     )
                 }
                 .frame(height: geometry.size.height)
             }
         }
         .onAppear {
             // Reset animation when view appears
             animationProgress = 0
             
             // Start animation after a brief delay
             DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                 withAnimation(.easeInOut(duration: 1.5)) {
                     animationProgress = 1.0
                 }
             }
         }
     }
 }
 */
