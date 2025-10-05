//
//  InteractiveXPChart.swift
//  Habital
//
//  Created by Elias Osarumwense on 27.04.25.
//

import SwiftUI
import Charts

struct DailyXPData: Identifiable {
    var id = UUID()
    var date: Date
    var amount: Int
    var formattedDate: String
    
    init(date: Date, amount: Int) {
        self.date = date
        self.amount = amount
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        self.formattedDate = formatter.string(from: date)
    }
}

struct WeeklyXPData: Identifiable {
    var id = UUID()
    var weekStartDate: Date
    var weekEndDate: Date
    var amount: Int
    var formattedWeekRange: String
    
    init(weekStartDate: Date, amount: Int) {
        self.weekStartDate = weekStartDate
        
        // Calculate week end date (Sunday)
        let calendar = Calendar.current
        self.weekEndDate = calendar.date(byAdding: .day, value: 6, to: weekStartDate) ?? weekStartDate
        
        self.amount = amount
        
        // Format the date range
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        self.formattedWeekRange = "\(formatter.string(from: weekStartDate)) - \(formatter.string(from: weekEndDate))"
    }
}

struct ChartPoint: Identifiable {
    var id = UUID()
    var date: Date       // Using the week start date
    var amount: Int      // XP for the week
    var cumulativeAmount: Int
    var formattedDate: String
    var weekRange: String
    
    init(date: Date, amount: Int, cumulativeAmount: Int) {
        self.date = date
        self.amount = amount
        self.cumulativeAmount = cumulativeAmount
        
        let calendar = Calendar.current
        let weekEndDate = calendar.date(byAdding: .day, value: 6, to: date) ?? date
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        self.formattedDate = formatter.string(from: date)
        self.weekRange = "\(formatter.string(from: date)) - \(formatter.string(from: weekEndDate))"
    }
}

struct InteractiveXPChart: View {
    let chartData: [ChartPoint]
    @Binding var selectedPoint: ChartPoint?
    
    @State private var animationProgress: CGFloat = 0
    @State private var showingChart = false
    
    private let height: CGFloat = 200
    
    // Computed property to get visible data points based on animation progress
    private var visibleChartData: [ChartPoint] {
        let count = Int(animationProgress * CGFloat(chartData.count))
        return Array(chartData.prefix(count))
    }
    
    var body: some View {
        VStack {
            if chartData.isEmpty {
                Text("No data available for this period")
                    .customFont("Lexend", .medium, 14)
                    .foregroundColor(.secondary)
                    .frame(height: height)
                    .frame(maxWidth: .infinity)
            } else {
                chartView
                    .frame(height: height + 30)
                    .padding(.top, 10)
                    .onAppear {
                        // Animate the chart when it appears
                        withAnimation(.easeInOut(duration: 1.2)) {
                            showingChart = true
                            animationProgress = 1.0
                        }
                    }
            }
        }
    }
    
    private var chartView: some View {
        Chart {
            // Area chart for filled background - softer gradient
            ForEach(visibleChartData) { point in
                AreaMark(
                    x: .value("Week", point.date),
                    y: .value("XP", point.cumulativeAmount)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue.opacity(0.15), .blue.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }
            
            // Line chart - thinner, more elegant line
            ForEach(visibleChartData) { point in
                LineMark(
                    x: .value("Week", point.date),
                    y: .value("XP", point.cumulativeAmount)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue.opacity(0.8), .blue.opacity(0.6)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                .interpolationMethod(.monotone) // Smoother interpolation
            }
            
            // Points - much smaller and more subtle
            ForEach(visibleChartData) { point in
                PointMarkWithID(
                    date: point.date,
                    value: point.cumulativeAmount,
                    isSelected: selectedPoint?.id == point.id
                )
            }
            
            // Highlight selection if any - more subtle
            if let selectedPoint = selectedPoint {
                RuleMark(
                    x: .value("Selected Week", selectedPoint.date)
                )
                .foregroundStyle(Color.blue.opacity(0.2))
            }
        }
        .chartXAxis {
            AxisMarks(position: .bottom, values: .stride(by: .weekOfYear)) { value in
                AxisGridLine()
                    .foregroundStyle(Color.gray.opacity(0.2))
                
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        Text(formatWeekLabel(date))
                            .customFont("Lexend", .regular, 9)
                            .foregroundColor(.secondary)
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
                        Text("\(yValue)")
                            .customFont("Lexend", .regular, 9)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                updateSelection(at: value.location, proxy: proxy)
                            }
                    )
            }
        }
        .chartYScale(domain: {
            let upperBound = (chartData.map { $0.cumulativeAmount }.max() ?? 0) + 50
            return 0...max(1, upperBound) // Ensure upperBound is at least 1
        }())
    }
    
    // Update selection with debouncing for smoother interaction
    private func updateSelection(at position: CGPoint, proxy: ChartProxy) {
        let xPosition = position.x
        
        // Convert position to date value and find nearest point
        if let date = proxy.value(atX: xPosition, as: Date.self) {
            // Find closest point
            let closest = chartData.min(by: {
                abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
            })
            
            selectedPoint = closest
        }
    }
    
    // Format date labels to show week starts
    private func formatWeekLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        
        let dateRange = chartData.last?.date.timeIntervalSince(chartData.first?.date ?? Date()) ?? 0
        let weeks = dateRange / (7 * 24 * 60 * 60)
        
        if weeks > 52 {
            // For large date ranges (years), show month/year
            formatter.dateFormat = "MMM yy"
        } else if weeks > 8 {
            // For medium date ranges (months)
            formatter.dateFormat = "MMM d"
        } else {
            // For small date ranges (weeks)
            formatter.dateFormat = "M/d"
        }
        
        return formatter.string(from: date)
    }
}

// Separate struct for point marks with smaller points
struct PointMarkWithID: ChartContent {
    let date: Date
    let value: Int
    let isSelected: Bool
    
    var body: some ChartContent {
        PointMark(
            x: .value("Week", date),
            y: .value("XP", value)
        )
        .symbolSize(isSelected ? 60 : 15) // Much smaller dots
        .foregroundStyle(
            isSelected ?
                Color.blue.opacity(0.8) :
                Color.blue.opacity(0.6)
        )
    }
}

struct XPPointDetailCard: View {
    let point: ChartPoint
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(point.weekRange)
                    .customFont("Lexend", .semiBold, 16)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "calendar.week")
                    .foregroundColor(.blue)
                    .font(.system(size: 14))
            }
            
            Divider()
            
            HStack(spacing: 20) {
                // Weekly XP
                VStack(alignment: .leading, spacing: 4) {
                    Text("Weekly XP")
                        .customFont("Lexend", .regular, 12)
                        .foregroundColor(.secondary)
                    
                    HStack(alignment: .center, spacing: 4) {
                        Image(systemName: point.amount >= 0 ? "arrow.up.forward" : "arrow.down.forward")
                            .foregroundColor(point.amount >= 0 ? .green : .red)
                            .font(.system(size: 14, weight: .bold))
                        
                        Text("\(point.amount >= 0 ? "+" : "")\(point.amount)")
                            .customFont("Lexend", .bold, 20)
                            .foregroundColor(point.amount >= 0 ? .green : .red)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(point.amount >= 0 ?
                              Color.green.opacity(0.1) :
                              Color.red.opacity(0.1))
                )
                
                // Total XP
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total XP")
                        .customFont("Lexend", .regular, 12)
                        .foregroundColor(.secondary)
                    
                    HStack(alignment: .center, spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 14, weight: .bold))
                        
                        Text("\(point.cumulativeAmount)")
                            .customFont("Lexend", .bold, 20)
                            .foregroundColor(.blue)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.1))
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(UIColor.systemGray6) : Color.white)
                .shadow(color: Color.black.opacity(0.07), radius: 3, x: 0, y: 2)
        )
        .padding(.horizontal)
        .transition(.opacity.combined(with: .move(edge: .top)))
        .animation(.spring(), value: point.id)
    }
}

// Helper extension to get week start date (Monday)
extension Date {
    func startOfWeek() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components)!
    }
}

// Helper function to group daily XP data by week
func groupXPDataByWeek(_ dailyData: [DailyXPData]) -> [ChartPoint] {
    var weeklyGroupedData: [Date: Int] = [:]
    
    // Group data by week start date
    for dailyPoint in dailyData {
        let weekStart = dailyPoint.date.startOfWeek()
        weeklyGroupedData[weekStart, default: 0] += dailyPoint.amount
    }
    
    // Convert to sorted array
    let sortedWeekData = weeklyGroupedData.sorted { $0.key < $1.key }
    
    // Calculate cumulative amounts
    var cumulativeAmount = 0
    var result: [ChartPoint] = []
    
    for (weekStart, amount) in sortedWeekData {
        cumulativeAmount += amount
        result.append(ChartPoint(
            date: weekStart,
            amount: amount,
            cumulativeAmount: cumulativeAmount
        ))
    }
    
    return result
}
