//
//  AllXPHistoryView.swift
//  Habital
//
//  Created by Elias Osarumwense on 27.04.25.
//

import SwiftUI
import CoreData

struct AllXPHistoryView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    let completionRecords: [CompletionRecord]
    @State private var selectedTimeFilter: XPTimeFilter = .thisWeek
    @State private var filteredRecords: [CompletionRecord] = []
    @State private var chartData: [ChartPoint] = []
    @State private var selectedChartPoint: ChartPoint?
    @State private var showChartDetails: Bool = false
    @State private var isShowingFullChart: Bool = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Time filter picker for records
                    timeFilterPicker
                    
                    // Chart section
                    //chartSectionView
                    
                    // Summary section
                    summarySectionView
                        .padding(.horizontal)
                    
                    // Records list
                    recordsListView
                        .padding(.horizontal)
                }
                .padding(.bottom, 16)
            }
            .background(colorScheme == .dark ? Color(hex: "121212") : Color(UIColor.systemGroupedBackground).opacity(0.85))
            .navigationTitle("XP History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                filterRecords()
                generateChartData()
            }
            .onChange(of: selectedTimeFilter) { _, _ in
                filterRecords()
                // Reset selected point when filter changes
                selectedChartPoint = nil
            }
        }
    }
    
    // Time filter picker
    private var timeFilterPicker: some View {
        Picker("Time Period", selection: $selectedTimeFilter) {
            ForEach(XPTimeFilter.allCases) { filter in
                Text(filter.rawValue).tag(filter)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    // Chart section view - extracted to reduce complexity
    private var chartSectionView: some View {
        Group {
            if selectedTimeFilter == .allTime || isShowingFullChart {
                chartContentView
            } else if selectedTimeFilter == .allTime {
                showChartButton
            }
        }
    }
    
    // Chart content view
    private var chartContentView: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Chart header
            chartHeaderView
            
            // Chart detail card
            if let selectedPoint = selectedChartPoint {
                XPPointDetailCard(point: selectedPoint)
                    .padding(.bottom, 8)
            }
            
            // Interactive chart
            chartContainerView
        }
    }
    
    // Chart header with title and toggle
    private var chartHeaderView: some View {
        HStack {
            Text("XP Progression")
                .customFont("Lexend", .bold, 18)
                .foregroundColor(.primary)
            
            Spacer()
            
            // Toggle button to expand/collapse chart
            if selectedTimeFilter != .allTime {
                Button(action: {
                    withAnimation {
                        isShowingFullChart.toggle()
                    }
                }) {
                    Label(isShowingFullChart ? "Hide Chart" : "Show Chart",
                          systemImage: isShowingFullChart ? "chevron.up" : "chevron.down")
                        
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal)
    }
    
    // Chart container
    private var chartContainerView: some View {
        InteractiveXPChart(chartData: chartData, selectedPoint: $selectedChartPoint)
            .frame(height: 230)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color(UIColor.systemGray6) : Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
            .padding(.horizontal)
    }
    
    // Show chart button
    private var showChartButton: some View {
        Button(action: {
            withAnimation {
                isShowingFullChart = true
            }
        }) {
            HStack {
                Text("Show XP Progression Chart")
                    .customFont("Lexend", .medium, 14)
                    .foregroundColor(.blue)
                
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.blue)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.1))
            )
        }
        .padding(.horizontal)
    }
    
    // Summary section showing total XP for selected period
    private var summarySectionView: some View {
        VStack(spacing: 8) {
            Text("XP Summary: \(selectedTimeFilter.rawValue)")
                .customFont("Lexend", .bold, 18)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 16) {
                // Total XP gained
                totalXPView
                
                // Stats
                statsView
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(UIColor.systemGray6) : Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    // Total XP view
    private var totalXPView: some View {
        VStack(spacing: 4) {
            Text("Total XP")
                .customFont("Lexend", .medium, 14)
                .foregroundColor(.secondary)
            
            Text("\(calculateTotalXP())")
                .customFont("Lexend", .bold, 22)
                .foregroundColor(.primary)
            
            if let averageXP = calculateAverageXP(), averageXP > 0 {
                Text("Avg: \(averageXP) XP/day")
                    .customFont("Lexend", .regular, 12)
                    .foregroundColor(.secondary)
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(UIColor.systemGray5) : Color.white)
        )
    }
    
    // Stats view
    private var statsView: some View {
        VStack(spacing: 4) {
            Text("Stats")
                .customFont("Lexend", .medium, 14)
                .foregroundColor(.secondary)
            
            HStack(spacing: 8) {
                // Completions
                VStack(spacing: 2) {
                    Text("\(filteredRecords.count)")
                        .customFont("Lexend", .bold, 18)
                        .foregroundColor(.primary)
                    
                    Text("Entries")
                        .customFont("Lexend", .regular, 10)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                    .frame(height: 24)
                
                // Max XP day
                VStack(spacing: 2) {
                    Text("\(calculateMaxDailyXP())")
                        .customFont("Lexend", .bold, 18)
                        .foregroundColor(.green)
                    
                    Text("Max Day")
                        .customFont("Lexend", .regular, 10)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(UIColor.systemGray5) : Color.white)
        )
    }
    
    // List of all XP records for the selected period
    private var recordsListView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("XP Records")
                .customFont("Lexend", .bold, 18)
                .foregroundColor(.primary)
            
            if filteredRecords.isEmpty {
                emptyRecordsView
            } else {
                recordsList
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(UIColor.systemGray6) : Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    // Empty records view
    private var emptyRecordsView: some View {
        HStack {
            Spacer()
            Text("No XP records for this period")
                .customFont("Lexend", .medium, 14)
                .foregroundColor(.secondary)
                .padding(.vertical, 20)
            Spacer()
        }
    }
    
    // Records list
    private var recordsList: some View {
        VStack(spacing: 12) {
            ForEach(filteredRecords) { record in
                recordRow(for: record)
                
                if record.id != filteredRecords.last?.id {
                    Divider()
                }
            }
        }
    }
    
    // Individual record row
    private func recordRow(for record: CompletionRecord) -> some View {
        HStack(alignment: .center) {
            // Habit icon
            habitIcon(for: record.habit)
            
            // Record info
            recordInfo(for: record)
            
            Spacer()
            
            // XP amount
            xpAmount(for: record)
        }
        .padding(.vertical, 8)
    }
    
    // Habit icon
    private func habitIcon(for habit: Habit) -> some View {
        ZStack {
            Circle()
                .fill(getHabitColor(habit).opacity(0.2))
                .frame(width: 40, height: 40)
            
            if let icon = habit.icon {
                if isEmoji(icon) {
                    Text(icon)
                        .font(.system(size: 18))
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(getHabitColor(habit))
                }
            } else {
                Image(systemName: "star")
                    .font(.system(size: 18))
                    .foregroundColor(getHabitColor(habit))
            }
        }
    }
    
    // Record info
    private func recordInfo(for record: CompletionRecord) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(record.habit.name ?? "Unnamed Habit")
                .customFont("Lexend", .medium, 15)
                .foregroundColor(.primary)
            
            HStack(spacing: 6) {
                Text(record.formattedDate)
                    .customFont("Lexend", .regular, 12)
                    .foregroundColor(.secondary)
                
                if record.streak > 1 {
                    streakBadge(for: record)
                }
            }
        }
    }
    
    // Streak badge
    private func streakBadge(for record: CompletionRecord) -> some View {
        HStack(spacing: 2) {
            Image(systemName: "flame.fill")
                .font(.system(size: 10))
                .foregroundColor(.orange)
            
            Text("\(record.streak)")
                .customFont("Lexend", .medium, 12)
                .foregroundColor(.orange)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 1)
        .background(
            Capsule()
                .fill(Color.orange.opacity(0.15))
        )
    }
    
    // XP amount
    private func xpAmount(for record: CompletionRecord) -> some View {
        VStack(alignment: .trailing, spacing: 2) {
            // Show negative XP for broken bad habits
            if record.totalXP < 0 {
                Text("\(record.totalXP) XP")
                    .customFont("Lexend", .bold, 16)
                    .foregroundColor(.red)
            } else {
                Text("+\(record.totalXP) XP")
                    .customFont("Lexend", .bold, 16)
                    .foregroundColor(.green)
            }
            
            if record.totalMultiplier != 1.0 {
                Text("×\(String(format: "%.1f", abs(record.totalMultiplier)))")
                    .customFont("Lexend", .medium, 12)
                    .foregroundColor(record.totalMultiplier < 0 ? .red : .secondary)
            }
        }
    }
    
    // Filter records based on selected time period
    private func filterRecords() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // First filter by time period
        var timeFilteredRecords: [CompletionRecord] = []
        
        switch selectedTimeFilter {
        case .today:
            // Filter records from today
            timeFilteredRecords = completionRecords.filter { record in
                calendar.isDate(record.date, inSameDayAs: today)
            }
            
        case .yesterday:
            // Filter records from yesterday
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else {
                filteredRecords = []
                return
            }
            
            timeFilteredRecords = completionRecords.filter { record in
                calendar.isDate(record.date, inSameDayAs: yesterday)
            }
            
        case .thisWeek:
            // Filter records from this week (starting Monday)
            let weekday = calendar.component(.weekday, from: today)
            let daysToSubtract = (weekday + 5) % 7 // Convert to Monday = 0
            
            guard let startOfWeek = calendar.date(byAdding: .day, value: -daysToSubtract, to: today) else {
                filteredRecords = []
                return
            }
            
            timeFilteredRecords = completionRecords.filter { record in
                return record.date >= startOfWeek && record.date <= today
            }
            
        
            
        case .allTime:
            // Show all records
            timeFilteredRecords = completionRecords
        }
        
        // Sort by most recent first for display
        filteredRecords = timeFilteredRecords.sorted { $0.date > $1.date }
    }
    
    // Generate data for the progression chart
    private func generateChartData() {
        if completionRecords.isEmpty {
            chartData = []
            return
        }
        
        // Use all records for chart data (sorted by date)
        let sortedRecords = completionRecords.sorted { $0.date < $1.date }
        
        // Group by date to get daily totals
        let calendar = Calendar.current
        var dailyXP = [DailyXPData]()
        let groupedRecords = Dictionary(grouping: sortedRecords) { record in
            calendar.startOfDay(for: record.date)
        }
        
        // Calculate daily amounts
        for (date, records) in groupedRecords {
            let dailyAmount = records.reduce(0) { sum, record in
                sum + record.totalXP
            }
            dailyXP.append(DailyXPData(date: date, amount: dailyAmount))
        }
        
        // Sort by date
        dailyXP.sort { $0.date < $1.date }
        
        // Calculate cumulative XP
        var runningTotal = 0
        var resultChartData = [ChartPoint]()
        
        for data in dailyXP {
            runningTotal += data.amount
            let point = ChartPoint(
                date: data.date,
                amount: data.amount,
                cumulativeAmount: runningTotal
            )
            resultChartData.append(point)
        }
        
        chartData = resultChartData
    }
    
    // Calculate total XP for the filtered time period
    private func calculateTotalXP() -> Int {
        filteredRecords.reduce(0) { $0 + $1.totalXP }
    }
    
    // Calculate average XP per day for the filtered period
    private func calculateAverageXP() -> Int? {
        guard !filteredRecords.isEmpty else { return nil }
        
        // Get unique days
        let calendar = Calendar.current
        let uniqueDates = Set(filteredRecords.map { calendar.startOfDay(for: $0.date) })
        let uniqueDays = uniqueDates.count
        
        if uniqueDays == 0 { return nil }
        
        let totalXP = calculateTotalXP()
        return totalXP / uniqueDays
    }
    
    // Calculate maximum daily XP gain
    private func calculateMaxDailyXP() -> Int {
        let calendar = Calendar.current
        
        // Group by day
        let groupedByDay = Dictionary(grouping: filteredRecords) { record in
            calendar.startOfDay(for: record.date)
        }
        
        // Calculate total for each day
        var dailyTotals = [Int]()
        for (_, records) in groupedByDay {
            let dayTotal = records.reduce(0) { $0 + $1.totalXP }
            dailyTotals.append(dayTotal)
        }
        
        // Return the maximum daily total or 0 if there are no records
        return dailyTotals.max() ?? 0
    }
    
    // Get color for a habit
    private func getHabitColor(_ habit: Habit) -> Color {
        if let colorData = habit.color,
           let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
            return Color(uiColor)
        }
        return .blue // Default color
    }
    
    // Check if a string is an emoji
    private func isEmoji(_ text: String) -> Bool {
        for scalar in text.unicodeScalars {
            if scalar.properties.isEmoji {
                return true
            }
        }
        return false
    }
}
