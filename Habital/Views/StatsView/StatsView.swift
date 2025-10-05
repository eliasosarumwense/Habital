//
//  StatsView.swift
//  Habital
//
//  Created by Elias Osarumwense on 29.03.25.
//  Enhanced with async loading and shimmer effects
//

import SwiftUI
import CoreData

struct StatsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    
    // Use shared data manager from environment
    @EnvironmentObject var dataManager: StatsDataManager
    
    // Optional filtered habits parameter (for backwards compatibility)
    let filteredHabits: [Habit]?
    
    // Fetch habit lists for navigation bar filtering
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \HabitList.order, ascending: true)],
        animation: .default
    )
    private var habitLists: FetchedResults<HabitList>
    
    // State for UI
    @State private var selectedTimeRange: TimeRange = .lastSevenDays
    @State private var chartId = UUID()
    
    @State private var isViewVisible = false
       @State private var pendingUpdates: [(habit: Habit, date: Date, wasCompleted: Bool, isCompleted: Bool)] = []
    
    // Custom color for the charts
    private var chartColor: Color {
        return Color.primary
    }
    
    // MARK: - Initializers
    
    // Default initializer
    init() {
        self.filteredHabits = nil
    }
    
    // Initializer with filtered habits (for backwards compatibility)
    init(filteredHabits: [Habit]) {
        self.filteredHabits = filteredHabits
    }
    
    private var currentTimeRange: TimeRange {
            selectedTimeRange // Assuming you have this state variable
        }
    private var backgroundGradient: some View {
        let baseColors: [Color]
        
        if let selectedList = getSelectedHabitList(),
           let listColor = getListColor(from: selectedList) {
            // Use list color when available - more visible but still fades fast
            baseColors = [
                colorScheme == .dark ? listColor.opacity(0.18) : listColor.opacity(0.25), // Top opacity
                colorScheme == .dark ? listColor.opacity(0.10) : listColor.opacity(0.15), // Middle
                colorScheme == .dark ? listColor.opacity(0.07) : listColor.opacity(0.08), // Still fades fast
                colorScheme == .dark ? Color(hex: "0A0A0A") : Color.clear                  // Nearly black
            ]
        } else {
            // Default colors with more visible secondary gradient for "All Habits"
            baseColors = [
                colorScheme == .dark ? Color.secondary.opacity(0.15) : Color.secondary.opacity(0.20), // More visible top
                colorScheme == .dark ? Color.secondary.opacity(0.08) : Color.secondary.opacity(0.12), // Visible middle
                colorScheme == .dark ? Color.secondary.opacity(0.04) : Color.secondary.opacity(0.06), // Fade
                colorScheme == .dark ? Color(hex: "0A0A0A") : Color.clear                              // Nearly black to clear
            ]
        }
        
        return LinearGradient(
            gradient: Gradient(colors: baseColors),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }


    // MARK: - Helper Functions for Background
    private func getSelectedHabitList() -> HabitList? {
        guard dataManager.selectedListIndex > 0 && dataManager.selectedListIndex <= habitLists.count else {
            return nil
        }
        return habitLists[dataManager.selectedListIndex - 1]
    }

    private func getListColor(from list: HabitList) -> Color? {
        guard let colorData = list.color,
              let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) else {
            return nil
        }
        return Color(uiColor)
    }
    
    var body: some View {
        ZStack {
            // Add the background gradient
            backgroundGradient
            VStack(spacing: 0) {
                // Stats Navigation Bar
                statsNavigationBar
                
                // Main Stats Content - No Loading States
                VStack(spacing: 20) {
                    // Summary stats using existing component
                    StatsSummaryRow(
                        habits: currentHabits,
                        date: Date()
                    )
                    
                    // Completion trends using cached data
                    OptimizedCompletionTrendsCard(
                        dataManager: dataManager,
                        selectedTimeRange: $selectedTimeRange,
                        chartId: $chartId,
                        chartColor: chartColor,
                        colorScheme: colorScheme,
                        onTimeRangeUpdate: updateTimeRange,
                        currentHabits: currentHabits
                    )
                    .offset(y: -20)
                    
                    TimeRangeSelector(
                        selectedTimeRange: $selectedTimeRange,
                        chartColor: chartColor,
                        colorScheme: colorScheme,
                        onTimeRangeChanged: { range in
                            if selectedTimeRange != range {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.7)
                                selectedTimeRange = range
                                chartId = UUID()
                            }
                        }
                    )
                    .offset(y: -60)
                }
                .padding(.horizontal, 5)
                .padding(.top, 5)
                
                Spacer()
            }
        }
        .onAppear {
                    handleViewAppear()
                }
                .onDisappear {
                    isViewVisible = false
                }
                // MODIFY: Your existing notification listener
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("HabitUIRefreshNeeded"))) { notification in
                    handleHabitToggleWithVisibilityCheck(notification)
                }
        //.background(optimizedNotificationListeners)
    }
    
    private func handleViewAppear() {
            isViewVisible = true
            
            // Process any pending updates that occurred while view was hidden
            if !pendingUpdates.isEmpty {
                Task {
                    await processPendingUpdates()
                }
            }
            
            // Refresh the current time range data to ensure it's up to date
            refreshCurrentTimeRangeData()
        }
    
    @MainActor
        private func processPendingUpdates() async {
            guard !pendingUpdates.isEmpty else { return }
            
            print("📊 Processing \(pendingUpdates.count) pending chart updates...")
            
            // Group updates by date for efficiency
            var updatesByDate: [Date: [(habit: Habit, wasCompleted: Bool, isCompleted: Bool)]] = [:]
            
            for update in pendingUpdates {
                let dayStart = Calendar.current.startOfDay(for: update.date)
                if updatesByDate[dayStart] == nil {
                    updatesByDate[dayStart] = []
                }
                updatesByDate[dayStart]?.append((update.habit, update.wasCompleted, update.isCompleted))
            }
            
            // Process each date's updates
            for (date, updates) in updatesByDate {
                // Calculate net change for this date
                var netChange = 0
                for update in updates {
                    if update.isCompleted && !update.wasCompleted {
                        netChange += 1
                    } else if !update.isCompleted && update.wasCompleted {
                        netChange -= 1
                    }
                }
                
                // Apply the net change if non-zero
                if netChange != 0 {
                    let habitsToCheck = dataManager.selectedListIndex == 0 ?
                        dataManager.filteredHabits : dataManager.filteredHabits
                    
                    let activeCount = habitsToCheck.filter {
                        HabitUtilities.isHabitActive(habit: $0, on: date)
                    }.count
                    
                    if activeCount > 0 {
                        let percentageChange = (Double(netChange) / Double(activeCount)) * 100
                        updateChartDataPoint(for: date, change: percentageChange)
                    }
                }
            }
            
            // Clear pending updates
            pendingUpdates.removeAll()
            
            // Trigger chart refresh
            withAnimation(.easeOut(duration: 0.15)) {
                chartId = UUID()
            }
        }
        
        // ADD: Update a specific data point in the chart
        private func updateChartDataPoint(for date: Date, change: Double) {
            guard var trendsData = dataManager.getCompletionTrends(
                for: selectedTimeRange,
                habits: currentHabits
            ) else { return }
            
            // Find the index for this date
            let calendar = Calendar.current
            let dayStart = calendar.startOfDay(for: date)
            
            var index: Int?
            switch selectedTimeRange {
            case .lastSevenDays, .lastThirtyDays:
                let days = calendar.dateComponents([.day],
                    from: trendsData.startDate, to: dayStart).day ?? -1
                index = days >= 0 && days < trendsData.completionRates.count ? days : nil
                
            case .threeMonths, .sixMonths:
                let weeks = calendar.dateComponents([.weekOfYear],
                    from: trendsData.startDate, to: dayStart).weekOfYear ?? -1
                index = weeks >= 0 && weeks < trendsData.completionRates.count ? weeks : nil
                
            case .year:
                let months = calendar.dateComponents([.month],
                    from: trendsData.startDate, to: dayStart).month ?? -1
                index = months >= 0 && months < trendsData.completionRates.count ? months : nil
            }
            
            // Apply the change if index is valid
            if let validIndex = index {
                trendsData.completionRates[validIndex] += change
                trendsData.completionRates[validIndex] = max(0, min(100, trendsData.completionRates[validIndex]))
            }
        }
        
        // MODIFY: Handle toggle with visibility check
        private func handleHabitToggleWithVisibilityCheck(_ notification: Foundation.Notification) {
            guard let habit = notification.object as? Habit,
                  let userInfo = notification.userInfo,
                  let date = userInfo["completionDate"] as? Date,
                  let wasCompleted = userInfo["wasCompleted"] as? Bool,
                  let isCompleted = userInfo["isCompleted"] as? Bool else { return }
            
            if isViewVisible {
                // View is visible - update immediately
                dataManager.handleHabitToggleIncremental(
                    habit: habit,
                    date: date,
                    wasCompleted: wasCompleted,
                    isCompleted: isCompleted
                )
                
                // Animate the chart update
                withAnimation(.easeOut(duration: 0.15)) {
                    chartId = UUID()
                }
            } else {
                // View is hidden - queue the update for later
                pendingUpdates.append((habit, date, wasCompleted, isCompleted))
            }
        }
        
        // ADD: Refresh current time range data
        private func refreshCurrentTimeRangeData() {
            // Force recalculation of current time range
            dataManager.currentTimeRange = selectedTimeRange
            
            // Get fresh data for the current view
            if let freshData = dataManager.getCompletionTrends(
                for: selectedTimeRange,
                habits: currentHabits
            ) {
                // This will trigger a chart update
                withAnimation(.easeOut(duration: 0.2)) {
                    chartId = UUID()
                }
            }
        }
    // MARK: - Computed Properties
    
    private var currentHabits: [Habit] {
        return filteredHabits ?? dataManager.filteredHabits
    }
    
    private var currentStatsListName: String {
        if dataManager.selectedListIndex == 0 {
            return "All Habits"
        } else if dataManager.selectedListIndex <= habitLists.count {
            return habitLists[dataManager.selectedListIndex - 1].name ?? "Unnamed List"
        }
        return "All Habits"
    }
    
    private var currentStatsListIcon: String {
        if dataManager.selectedListIndex == 0 {
            return "tray.full"
        } else if dataManager.selectedListIndex > 0 && dataManager.selectedListIndex <= habitLists.count {
            let list = Array(habitLists)[dataManager.selectedListIndex - 1]
            return list.icon ?? "list.bullet"
        }
        return "list.bullet"
    }
    
    private var currentStatsListColor: Color {
        if dataManager.selectedListIndex == 0 {
            return .secondary
        } else if dataManager.selectedListIndex > 0 && dataManager.selectedListIndex <= habitLists.count {
            let list = Array(habitLists)[dataManager.selectedListIndex - 1]
            if let colorData = list.color,
               let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
                return Color(uiColor)
            }
            return .secondary
        }
        return .secondary
    }
    
    private var statsNavigationBar: some View {
        ZStack {
            Rectangle()
                .fill(.clear)
                .edgesIgnoringSafeArea(.top)
            
            HStack(spacing: 0) {
                // Left side - Stats title
                VStack(alignment: .leading, spacing: 2) {
                    Text("Statistics")
                        .font(.customFont("Lexend", .bold, 22))
                        .foregroundColor(.primary)
                    
                    Text("Your habit insights")
                        .font(.customFont("Lexend", .medium, 13))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                // Right side - Circular Glass Menu Button
                if filteredHabits == nil { // Only show if not using pre-filtered habits
                    Menu {
                        // All Habits option with enhanced animation
                        Button(action: {
                            // Enhanced input animation with modern spring (matching HabitListTabView)
                            withAnimation(.interpolatingSpring(stiffness: 350, damping: 20)) {
                                // Visual feedback animation
                            }
                            
                            // Enhanced list selection animation with chart update
                            withAnimation(.interpolatingSpring(stiffness: 300, damping: 30).delay(0.1)) {
                                dataManager.updateSelectedList(0)
                            }
                            
                            // Regenerate chart with new data (like MainHabitsView)
                            chartId = UUID()
                            
                            // Add haptic feedback like in HabitListTabView
                            UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.7)
                        }) {
                            Label("All Habits", systemImage: "tray.full")
                        }
                        
                        // Individual lists with enhanced animations
                        ForEach(Array(habitLists.enumerated()), id: \.element.id) { listIndex, list in
                            Button(action: {
                                // Enhanced input animation with modern spring
                                withAnimation(.interpolatingSpring(stiffness: 350, damping: 20)) {
                                    // Visual feedback animation
                                }
                                
                                // Enhanced list selection animation (matching HabitListTabView exactly)
                                withAnimation(.interpolatingSpring(stiffness: 300, damping: 30).delay(0.1)) {
                                    dataManager.updateSelectedList(listIndex + 1)
                                }
                                
                                // Regenerate chart with new data (like MainHabitsView)
                                chartId = UUID()
                                
                                // Add haptic feedback like in HabitListTabView
                                UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.7)
                            }) {
                                //let habitCount = (list.habits as? Set<Habit>)?.filter { !$0.isArchived }.count ?? 0
                                Label("\(list.name ?? "Unnamed List")", systemImage: list.icon ?? "list.bullet")
                            }
                        }
                    } label: {
                        CircularGlassMenuButton(
                            currentStatsListIcon: currentStatsListIcon,
                            currentStatsListColor: currentStatsListColor
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .frame(height: 50)
    }

    // MARK: - Circular Glass Menu Button Component
    struct CircularGlassMenuButton: View {
        let currentStatsListIcon: String
        let currentStatsListColor: Color
        
        @Environment(\.colorScheme) private var colorScheme
        
        var body: some View {
            ZStack {
                // Icon
                Image(systemName: currentStatsListIcon)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(currentStatsListColor)
            }
            .frame(width: 36, height: 36)
            .glassCircleBackground(backgroundColor: currentStatsListColor.opacity(0.1))
            .contentShape(Circle())
        }
    }
    // MARK: - Helper Methods
    
    private func updateTimeRange(for timeRange: TimeRange) {
        // No need to calculate dates here - data manager handles everything
        chartId = UUID()
    }
}

struct OptimizedCompletionTrendsCard: View {
    @ObservedObject var dataManager: StatsDataManager
    @Binding var selectedTimeRange: TimeRange
    @Binding var chartId: UUID
    let chartColor: Color
    let colorScheme: ColorScheme
    let onTimeRangeUpdate: (TimeRange) -> Void
    let currentHabits: [Habit]
    
    var body: some View {
        VStack(spacing: 0) {
            // Card header
            VStack(spacing: 5) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Completion Trends")
                            .customFont("Lexend", .bold, 16)
                            .foregroundColor(.primary)
                        
                        Text(getLabelForTimeRange())
                            .customFont("Lexend", .medium, 14)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Average badge - directly using computed property
                    VStack(alignment: .trailing, spacing: 2) {
                        AnimatedPercentage(
                            value: currentTrendsData?.averageRate ?? 0,
                            font: .customFont("Lexend", .bold, 18),
                            color: chartColor
                        )
                        
                        Text("Average")
                            .customFont("Lexend", .medium, 11)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                }
            }
            .padding(.horizontal, 10)
            .padding(.top, 15)
            
            // Chart content
            VStack(spacing: 0) {
                if let trendsData = currentTrendsData {
                                AnimatedLabeledLineChart(
                                    data: trendsData.completionRates,
                                    labels: trendsData.labels,
                                    detailedLabels: trendsData.detailedLabels,
                                    title: "",
                                    legend: "",
                                    chartStyle: ChartStyle(
                                        backgroundColor: Color.clear,
                                        accentColor: chartColor,
                                        secondGradientColor: chartColor.opacity(0.3),
                                        textColor: .primary,
                                        legendTextColor: .secondary,
                                        dropShadowColor: .clear
                                    )
                                )
                                .frame(width: 340, height: 300)
                                .padding(.horizontal, 20)
                                // Use animation value instead of id
                                .animation(.easeOut(duration: 0.15), value: dataManager.chartDataVersion)
                            }
            }
            .offset(y: -35)
        }
        // Force refresh when toggle happens
        //.id("\(chartId)-\(dataManager.lastToggleUpdate)")
    }
    
    private var currentTrendsData: CompletionTrendsData? {
        return dataManager.getCompletionTrends(for: selectedTimeRange, habits: currentHabits)
    }
    
    private func getLabelForTimeRange() -> String {
        switch selectedTimeRange {
        case .lastSevenDays:
            return "Last 7 Days"
        case .lastThirtyDays:
            return "Last 30 Days"
        case .threeMonths:
            return "Last 3 Months (weekly)"
        case .sixMonths:
            return "Last 6 Months (weekly)"
        case .year:
            return "Last Year (monthly)"
        }
    }
}

// MARK: - Shimmer Components

struct StatsSummaryShimmer: View {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("useGlassEffect") private var useGlassEffect = true
    
    var body: some View {
        VStack(spacing: 12) {
            // First row of 3 shimmer cards
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { _ in
                    shimmerStatCard()
                }
            }
            .padding(.horizontal, 10)
            
            // Second row of 3 shimmer cards
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { _ in
                    shimmerStatCard()
                }
            }
            .padding(.horizontal, 10)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 5)
    }
    
    @ViewBuilder
    private func shimmerStatCard() -> some View {
        VStack(spacing: 0) {
            // Two-row title shimmer with fixed height (matches real cards)
            VStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 9)
                    .performantShimmer()
                
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.gray.opacity(0.25))
                    .frame(width: 50, height: 9)
                    .performantShimmer()
            }
            .frame(height: 24) // Fixed height matching real cards
            
            Spacer(minLength: 4) // Small controlled spacing
            
            // Value and icon section shimmer
            HStack(spacing: 4) {
                // Large value shimmer
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 35, height: 20)
                    .performantShimmer()
                
                // Icon shimmer
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 16, height: 16)
                    .performantShimmer()
            }
            .frame(height: 28) // Fixed height matching real cards
            
            Spacer(minLength: 0) // Fill remaining space
        }
        .frame(width: 95, height: 80) // Exact same dimensions as real cards
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(
            Group {
                if useGlassEffect {
                    shimmerGlassCardBackground()
                } else {
                    shimmerOriginalCardBackground()
                }
            }
        )
    }
    
    @ViewBuilder
    private func shimmerGlassCardBackground() -> some View {
        ZStack {
            // Base ultra-thin material
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
            
            // Shimmer-specific glass layer
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.gray.opacity(0.15),
                            Color.gray.opacity(0.08),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .blendMode(.overlay)
            
            // Glass reflection highlights
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(colorScheme == .dark ? 0.15 : 0.3),
                            Color.clear,
                            Color.clear,
                            Color.black.opacity(colorScheme == .dark ? 0.08 : 0.03)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .blendMode(.overlay)
            
            // Glass edges
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(colorScheme == .dark ? 0.1 : 0.4),
                            Color.gray.opacity(0.1),
                            Color.clear,
                            Color.gray.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.8
                )
        }
    }
    
    @ViewBuilder
    private func shimmerOriginalCardBackground() -> some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(
                LinearGradient(
                    colors: [
                        colorScheme == .dark ?
                            Color(UIColor.systemGray6).opacity(0.8) :
                            Color.white.opacity(0.9),
                        colorScheme == .dark ?
                            Color(UIColor.systemGray6).opacity(0.6) :
                            Color.white.opacity(0.7)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.gray.opacity(0.15),
                                Color.clear,
                                Color.gray.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
            )
    }
}

struct CompletionTrendsShimmer: View {
    @Binding var selectedTimeRange: TimeRange
    let chartColor: Color
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            // Header shimmer
            VStack(spacing: 5) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 150, height: 18)
                            .performantShimmer()
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 100, height: 14)
                            .performantShimmer()
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 40, height: 18)
                            .performantShimmer()
                        
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 50, height: 11)
                            .performantShimmer()
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                }
            }
            .padding(.horizontal, 10)
            .padding(.top, 15)
            
            // Chart shimmer
            VStack(spacing: 0) {
                ChartShimmerView()
                    .frame(width: 340, height: 300)
                    .padding(.horizontal, 20)
            }
            .offset(y: -35)
        }
    }
}

struct ChartShimmerView: View {
    var body: some View {
        VStack(spacing: 20) {
            // Simulated line chart with shimmering line
            GeometryReader { geometry in
                ZStack {
                    // Chart background grid (subtle)
                    VStack(spacing: 0) {
                        ForEach(0..<5, id: \.self) { _ in
                            Rectangle()
                                .fill(Color.gray.opacity(0.1))
                                .frame(height: 0.5)
                            Spacer()
                        }
                    }
                    
                    // Horizontal grid lines
                    HStack(spacing: 0) {
                        ForEach(0..<8, id: \.self) { _ in
                            Rectangle()
                                .fill(Color.gray.opacity(0.05))
                                .frame(width: 0.5)
                            Spacer()
                        }
                    }
                    
                    // Shimmering line chart
                    ShimmerLineChart()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.gray.opacity(0.6),
                                    Color.gray.opacity(0.8),
                                    Color.gray.opacity(0.6)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round)
                        )
                        .performantShimmer()
                    
                    // Data points that shimmer
                    ForEach(Array(shimmerDataPoints.enumerated()), id: \.offset) { index, point in
                        Circle()
                            .fill(Color.gray.opacity(0.4))
                            .frame(width: 6, height: 6)
                            .position(
                                x: CGFloat(index) * (geometry.size.width / CGFloat(shimmerDataPoints.count - 1)),
                                y: geometry.size.height * (1 - point)
                            )
                            .performantShimmer()
                    }
                }
            }
            .frame(height: 200)
        }
    }
    
    // Sample data points for the shimmer line (0.0 to 1.0 range)
    private var shimmerDataPoints: [CGFloat] {
        [0.3, 0.5, 0.4, 0.7, 0.6, 0.8, 0.75, 0.9, 0.85, 0.7, 0.8]
    }
}

// Custom shape for the shimmering line chart
struct ShimmerLineChart: Shape {
    func path(in rect: CGRect) -> Path {
        let dataPoints: [CGFloat] = [0.3, 0.5, 0.4, 0.7, 0.6, 0.8, 0.75, 0.9, 0.85, 0.7, 0.8]
        
        var path = Path()
        
        guard dataPoints.count > 1 else { return path }
        
        let stepX = rect.width / CGFloat(dataPoints.count - 1)
        
        // Start at first point
        let firstPoint = CGPoint(
            x: 0,
            y: rect.height * (1 - dataPoints[0])
        )
        path.move(to: firstPoint)
        
        // Create smooth curve through all points
        for i in 1..<dataPoints.count {
            let currentPoint = CGPoint(
                x: CGFloat(i) * stepX,
                y: rect.height * (1 - dataPoints[i])
            )
            
            if i == 1 {
                // First curve segment
                let controlPoint1 = CGPoint(
                    x: stepX * 0.5,
                    y: firstPoint.y
                )
                let controlPoint2 = CGPoint(
                    x: currentPoint.x - stepX * 0.5,
                    y: currentPoint.y
                )
                path.addCurve(to: currentPoint, control1: controlPoint1, control2: controlPoint2)
            } else {
                // Subsequent curve segments
                let previousPoint = CGPoint(
                    x: CGFloat(i - 1) * stepX,
                    y: rect.height * (1 - dataPoints[i - 1])
                )
                
                let controlPoint1 = CGPoint(
                    x: previousPoint.x + stepX * 0.5,
                    y: previousPoint.y
                )
                let controlPoint2 = CGPoint(
                    x: currentPoint.x - stepX * 0.5,
                    y: currentPoint.y
                )
                path.addCurve(to: currentPoint, control1: controlPoint1, control2: controlPoint2)
            }
        }
        
        return path
    }
}

struct TimeRangeSelector: View {
    @Binding var selectedTimeRange: TimeRange
    let chartColor: Color
    let colorScheme: ColorScheme
    let onTimeRangeChanged: (TimeRange) -> Void
    
    @AppStorage("useGlassEffect") private var useGlassEffect = true
    @Namespace private var animationNamespace
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0)) {
                        onTimeRangeChanged(range)
                    }
                } label: {
                    Text(range.displayText)
                        .customFont("Lexend", selectedTimeRange == range ? .semiBold : .medium, 13)
                        .foregroundStyle(
                            selectedTimeRange == range
                                ? (colorScheme == .dark ? .black : .white)
                                : .primary.opacity(0.7)
                        )
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .contentShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .background {
                    if selectedTimeRange == range {
                        backgroundForSelected
                            .matchedGeometryEffect(id: "selectedBackground", in: animationNamespace)
                            .shadow(
                                color: chartColor.opacity(0.3),
                                radius: 2,
                                x: 0,
                                y: 1
                            )
                    }
                }
                .overlay {
                    if selectedTimeRange != range {
                        backgroundForUnselected
                    }
                }
                .scaleEffect(selectedTimeRange == range ? 1.0 : 0.96)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTimeRange)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .glassBackground(cornerRadius: 12, borderWidth: 0)
    }
    
    @ViewBuilder
    private var backgroundForSelected: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(.ultraThinMaterial)
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        .linearGradient(
                            colors: [
                                chartColor.opacity(0.5),
                                chartColor.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blendMode(.overlay)
            }
    }
    
    @ViewBuilder
    private var backgroundForUnselected: some View {
        if useGlassEffect {
            Color.clear
        } else {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.primary.opacity(colorScheme == .dark ? 0.06 : 0.04))
        }
    }
}
// MARK: - Animated Line Chart
struct AnimatedLabeledLineChart: View {
    let data: [Double]
    let labels: [String]      // For display on x-axis
    let detailedLabels: [String]  // For magnifier context labels
    let title: String
    let legend: String
    let chartStyle: ChartStyle
    
    // Animation state
    @State private var animationProgress: CGFloat = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Title and legend
            HStack {
                Text(title)
                    .customFont("Lexend", .semiBold, 18)
                    .foregroundColor(chartStyle.textColor)
                Spacer()
                Text(legend)
                    .customFont("Lexend", .medium, 14)
                    .foregroundColor(chartStyle.legendTextColor)
            }
            .padding(.bottom, 8)
            
            // The actual chart with clipping mask for animation
            GeometryReader { geometry in
                ZStack {
                    // Use our modified LineView with context labels
                    LineView(
                        data: data,
                        title: "",     // Empty as we show title above
                        legend: "",    // Empty as we show legend above
                        style: chartStyle,
                        xAxisLabels: labels, // Labels for x-axis
                        dataLabels: detailedLabels // Detailed labels for magnifier
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

// MARK: - Supporting Types
enum TimeRange: CaseIterable {
    case lastSevenDays, lastThirtyDays, threeMonths, sixMonths, year
    
    var displayText: String {
        switch self {
        case .lastSevenDays: return "7D"
        case .lastThirtyDays: return "30D"
        case .threeMonths: return "3M"
        case .sixMonths: return "6M"
        case .year: return "1Y"
        }
    }
}

// MARK: - Extensions

extension Date {
    func startOfMonth() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components) ?? self
    }
}

extension View {
    func customFont(_ fontName: String, _ weight: Font.Weight, _ size: CGFloat) -> some View {
        self.font(.system(size: size, weight: weight))
    }
}

extension StatsView {
    
    /// Replace your existing notification listeners with these optimized ones
    private var optimizedNotificationListeners: some View {
        EmptyView()
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("HabitUIRefreshNeeded"))) { notification in
                        handleOptimizedHabitToggle(notification)
                    }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("TabBarListSelectionChanged"))) { notification in
                guard let userInfo = notification.userInfo,
                      let listIndex = userInfo["selectedListIndex"] as? Int,
                      let showArchived = userInfo["showArchivedHabits"] as? Bool else { return }
                
                // StatsView doesn't show archived habits, so we only handle list index changes
                if !showArchived {
                    // Update the data manager's selected list (this will automatically refresh filtered habits)
                    withAnimation(.easeInOut(duration: 0.4)) {
                        dataManager.updateSelectedList(listIndex)
                    }
                    
                    // Regenerate chart with new data
                    chartId = UUID()
                }
            }
    }
    
    private func handleOptimizedHabitToggle(_ notification: Foundation.Notification) {
            guard let habit = notification.object as? Habit,
                  let userInfo = notification.userInfo,
                  let date = userInfo["completionDate"] as? Date,
                  let wasCompleted = userInfo["wasCompleted"] as? Bool,
                  let isCompleted = userInfo["isCompleted"] as? Bool else { return }
            
            // Only update data, don't recreate chart
            dataManager.updateTrendPointIncremental(
                habit: habit,
                date: date,
                wasCompleted: wasCompleted,
                isCompleted: isCompleted
            )
            
            // DON'T update chartId - let the data change trigger the update
            // chartId = UUID() // REMOVE THIS LINE
        }
}
