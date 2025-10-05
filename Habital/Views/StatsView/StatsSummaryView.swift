//
//  StatsSummaryView.swift
//  Habital
//
//  Created by Elias Osarumwense on 08.05.25.
//

import SwiftUI

struct AnimatedNumber: View {
    let value: Int
    let font: Font
    let color: Color
    
    @State private var displayValue: Int = 0

        var body: some View {
            Text("\(displayValue)")
                .font(font)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.primary, Color.primary.opacity(0.9)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .onAppear {
                    displayValue = value
                }
                .onChange(of: value) { oldValue, newValue in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        displayValue = newValue
                    }
                }
        }
}

struct AnimatedPercentage: View {
    let value: Double
    let font: Font
    let color: Color
    
    @State private var displayValue: Double = 0.0
    
    var body: some View {
        Text("\(Int(displayValue))%")
            .font(font)
            .foregroundStyle(
                LinearGradient(
                    colors: [Color.primary, Color.primary.opacity(0.5)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .onAppear {
                displayValue = value
            }
            .onChange(of: value) { oldValue, newValue in
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    displayValue = newValue
                }
            }
    }
}

struct StatsSummaryRow: View {
    let habits: [Habit]  // This is the FILTERED list based on selected habit list
    let date: Date
    let usePreloadedData: Bool
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.managedObjectContext) private var context
    @EnvironmentObject var statsSummaryManager: StatsSummaryDataManager
    @AppStorage("useGlassEffect") private var useGlassEffect = true
    
    // State for streak calculations
    @State private var bestCurrentStreakData: (Habit, Int)? = nil
    @State private var bestHistoricalStreakData: (Habit, Int)? = nil
    @State private var isLoadingStreaks = false
    
    // State for cached values that update immediately
    @State private var cachedTotalCompletions: Int = 0
    @State private var cachedTotalGoodHabits: Int = 0
    @State private var cachedTotalBadHabits: Int = 0
    @State private var lastCachedHabitIds: Set<UUID> = Set()
    
    // FIXED: Track which habits we're currently displaying to prevent cross-list contamination
    @State private var currentDisplayedHabitIds: Set<UUID> = Set()
    
    // Notification observers
    @State private var notificationObservers: [NSObjectProtocol] = []
    
    init(habits: [Habit], date: Date, usePreloadedData: Bool = false) {
        self.habits = habits
        self.date = date
        self.usePreloadedData = usePreloadedData
    }
    
    // FIXED: Filter valid habits AND ensure they match current displayed list
    private var validHabits: [Habit] {
        return habits.filter { !$0.isFault && !$0.isDeleted }
    }
    
    // Use cached data when available, fallback to real-time calculations
    private var totalCompletions: Int {
        return cachedTotalCompletions
    }
    
    private var bestHistoricalStreak: (Habit, Int)? {
        if let cached = bestHistoricalStreakData {
            // FIXED: Only return cached data if the habit is still in our current list
            if currentDisplayedHabitIds.contains(cached.0.id ?? UUID()) {
                return cached
            } else {
                // Clear stale cache if habit is no longer in our list
                bestHistoricalStreakData = nil
            }
        }
        
        // FIXED: Always calculate from our own validHabits to ensure list filtering
        // Never trust statsSummaryManager as it might contain habits from other lists
        return validHabits.habitWithBestHistoricalStreak()
    }
    
    private var bestCurrentStreak: (Habit, Int)? {
        if let cached = bestCurrentStreakData {
            // FIXED: Only return cached data if the habit is still in our current list
            if currentDisplayedHabitIds.contains(cached.0.id ?? UUID()) {
                return cached
            } else {
                // Clear stale cache if habit is no longer in our list
                bestCurrentStreakData = nil
            }
        }
        
        // FIXED: Always calculate from our own validHabits to ensure list filtering
        // Never trust statsSummaryManager as it might contain habits from other lists
        return validHabits.habitWithBestCurrentStreak(on: date)
    }
    
    private var totalGoodHabits: Int {
        return cachedTotalGoodHabits
    }
    
    private var totalBadHabits: Int {
        return cachedTotalBadHabits
    }
    
    // FIXED: Add safety checks for habit color extraction
    private func getHabitColor(_ habit: Habit) -> Color {
        guard !habit.isFault && !habit.isDeleted else { return .blue }
        
        if let colorData = habit.color,
           let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
            return Color(uiColor)
        }
        return .blue // Default color
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // First row of stats cards
            HStack(spacing: 8) {
                // Total Completions Card
                modernStatCard(
                    title: "Total",
                    subtitle: "Completions",
                    value: "\(totalCompletions)",
                    icon: "checkmark.circle.fill",
                    color: .green,
                    habit: nil
                )
                
                // Best Historical Streak Card
                if let (habit, streak) = bestHistoricalStreak {
                    modernStatCard(
                        title: "Best",
                        subtitle: "Streak",
                        value: "\(streak)",
                        icon: nil,
                        color: getHabitColor(habit),
                        habit: habit
                    )
                } else {
                    modernStatCard(
                        title: "Best",
                        subtitle: "Streak",
                        value: isLoadingStreaks ? "-" : "0",
                        icon: "flame.fill",
                        color: .orange,
                        habit: nil
                    )
                }
                
                // Current Best Streak Card
                if let (habit, streak) = bestCurrentStreak {
                    modernStatCard(
                        title: "Current",
                        subtitle: "Best",
                        value: "\(streak)",
                        icon: nil,
                        color: getHabitColor(habit),
                        habit: habit
                    )
                } else {
                    modernStatCard(
                        title: "Current",
                        subtitle: "Best",
                        value: isLoadingStreaks ? "-" : "0",
                        icon: "star.fill",
                        color: .blue,
                        habit: nil
                    )
                }
            }
            .padding(.horizontal, 10)
            
            // Second row of stats cards
            HStack(spacing: 8) {
                // Total Good Habits Card
                modernStatCard(
                    title: "Good",
                    subtitle: "Habits",
                    value: "\(totalGoodHabits)",
                    icon: "plus.circle.fill",
                    color: .blue,
                    habit: nil
                )
                
                // Total Bad Habits Card
                modernStatCard(
                    title: "Bad",
                    subtitle: "Habits",
                    value: "\(totalBadHabits)",
                    icon: "minus.circle.fill",
                    color: .red,
                    habit: nil
                )
                
                // Coming Soon Card
                modernStatCard(
                    title: "Coming",
                    subtitle: "Soon",
                    value: "-",
                    icon: "ellipsis.circle.fill",
                    color: .gray,
                    habit: nil
                )
            }
            .padding(.horizontal, 10)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 5)
        .task {
            await loadAllDataSafely()
            setupSimpleNotificationListeners()
        }
        .onDisappear {
            removeNotificationListeners()
        }
        .onChange(of: habits.count) { _, _ in
            Task {
                await handleHabitListChange()
            }
        }
        .onChange(of: habits.map(\.id)) { _, _ in
            Task {
                await handleHabitListChange()
            }
        }
        .onChange(of: validHabits.compactMap { $0.completion?.count }) { _, _ in
            Task {
                await updateCachedTotals()
            }
        }
    }
    
    // MARK: - FIXED: Handle habit list changes properly
    
    @MainActor
    private func handleHabitListChange() async {
        // Update our tracking of current displayed habits
        let newHabitIds = Set(validHabits.compactMap { $0.id })
        
        // Clear best streak caches if we're showing a different set of habits
        if newHabitIds != currentDisplayedHabitIds {
            print("📊 StatsSummaryRow: Habit list changed, clearing streak caches")
            bestCurrentStreakData = nil
            bestHistoricalStreakData = nil
            currentDisplayedHabitIds = newHabitIds
        }
        
        await loadAllDataSafely()
    }
    
    // MARK: - Simple Notification System
    
    private func setupSimpleNotificationListeners() {
        // Clear existing observers
        removeNotificationListeners()
        
        // Listen for habit toggles for immediate completion count updates
        let toggleObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("HabitToggled"),
            object: nil,
            queue: .main
        ) { (foundationNotification: Foundation.Notification) in
            self.handleHabitToggle(foundationNotification)
        }
        notificationObservers.append(toggleObserver)
        
        // Listen for efficient streak updates
        let streakObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("StreakUpdatedEfficient"),
            object: nil,
            queue: .main
        ) { (foundationNotification: Foundation.Notification) in
            self.handleStreakUpdate(foundationNotification)
        }
        notificationObservers.append(streakObserver)
    }
    
    private func removeNotificationListeners() {
        for observer in notificationObservers {
            NotificationCenter.default.removeObserver(observer)
        }
        notificationObservers.removeAll()
    }
    
    // MARK: - FIXED: Update Handlers with Proper List Filtering
    
    /// Handle habit toggles for completion count updates
    private func handleHabitToggle(_ foundationNotification: Foundation.Notification) {
        guard let habit = foundationNotification.object as? Habit,
              let userInfo = foundationNotification.userInfo,
              let wasCompleted = userInfo["wasCompleted"] as? Bool,
              let isCompleted = userInfo["isCompleted"] as? Bool else { return }
        
        // FIXED: Only process if this habit is in our CURRENT DISPLAYED list
        guard let habitId = habit.id,
              currentDisplayedHabitIds.contains(habitId) else {
            print("📊 Ignoring toggle for habit not in current list: \(habit.name ?? "Unknown")")
            return
        }
        
        // INSTANT UPDATE: Update completion count immediately with animation
        updateCompletionCountInstant(wasCompleted: wasCompleted, isCompleted: isCompleted)
    }
    
    /// Handle streak updates - smartly check if this habit should update best streaks
    private func handleStreakUpdate(_ foundationNotification: Foundation.Notification) {
        guard let habit = foundationNotification.object as? Habit,
              let userInfo = foundationNotification.userInfo,
              let streakData = userInfo["streakData"] as? StreakData else { return }
        
        // FIXED: Only process if this habit is in our CURRENT DISPLAYED list
        guard let habitId = habit.id,
              currentDisplayedHabitIds.contains(habitId) else {
            print("📊 Ignoring streak update for habit not in current list: \(habit.name ?? "Unknown")")
            return
        }
        
        // SMART CHECK: Only update if this habit could affect best streaks within our current list
        smartUpdateBestStreaks(habit: habit, streakData: streakData)
    }
    
    // MARK: - FIXED: Smart Best Streak Updates (Only within current list)
    
    @MainActor
    private func smartUpdateBestStreaks(habit: Habit, streakData: StreakData) {
        var shouldUpdateCurrent = false
        var shouldUpdateHistorical = false
        
        // Check if this habit should update current best streak
        if let currentBest = bestCurrentStreakData {
            // Case 1: This habit was the current best - always check
            if currentBest.0.id == habit.id {
                shouldUpdateCurrent = true
            }
            // Case 2: This habit's new streak beats the current best
            else if streakData.currentStreak > currentBest.1 {
                shouldUpdateCurrent = true
                bestCurrentStreakData = (habit, streakData.currentStreak)
            }
        } else {
            // No current best - set this one if it has a streak
            if streakData.currentStreak > 0 {
                bestCurrentStreakData = (habit, streakData.currentStreak)
                shouldUpdateCurrent = true
            }
        }
        
        // Check if this habit should update historical best streak
        if let historicalBest = bestHistoricalStreakData {
            // Case 1: This habit was the historical best - always check
            if historicalBest.0.id == habit.id {
                shouldUpdateHistorical = true
            }
            // Case 2: This habit's new streak beats the historical best
            else if streakData.longestStreak > historicalBest.1 {
                shouldUpdateHistorical = true
                bestHistoricalStreakData = (habit, streakData.longestStreak)
            }
        } else {
            // No historical best - set this one if it has a streak
            if streakData.longestStreak > 0 {
                bestHistoricalStreakData = (habit, streakData.longestStreak)
                shouldUpdateHistorical = true
            }
        }
        
        // If this habit was the best but now decreased, we need to find the new best FROM CURRENT LIST ONLY
        if shouldUpdateCurrent && bestCurrentStreakData?.0.id == habit.id {
            if streakData.currentStreak < (bestCurrentStreakData?.1 ?? 0) {
                // This habit decreased - need to find new best from current list only
                findNewBestCurrentStreakFromCurrentList(excluding: habit, newStreakForHabit: streakData.currentStreak)
            } else {
                // This habit is still the best or improved
                bestCurrentStreakData = (habit, streakData.currentStreak)
            }
        }
        
        if shouldUpdateHistorical && bestHistoricalStreakData?.0.id == habit.id {
            if streakData.longestStreak < (bestHistoricalStreakData?.1 ?? 0) {
                // This habit decreased - need to find new best from current list only
                findNewBestHistoricalStreakFromCurrentList(excluding: habit, newStreakForHabit: streakData.longestStreak)
            } else {
                // This habit is still the best or improved
                bestHistoricalStreakData = (habit, streakData.longestStreak)
            }
        }
        
        // Animate changes
        if shouldUpdateCurrent || shouldUpdateHistorical {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                // Trigger animation by updating the state (already updated above)
            }
        }
        
        print("📊 Smart streak check (filtered): Updated=\(shouldUpdateCurrent || shouldUpdateHistorical) for habit '\(habit.name ?? "Unknown")'")
    }
    
    // MARK: - FIXED: Find New Best Streaks (Only from current list)
    
    private func findNewBestCurrentStreakFromCurrentList(excluding excludedHabit: Habit, newStreakForHabit: Int) {
        var newBest: (Habit, Int)? = nil
        
        // Include the excluded habit with its new streak value
        if newStreakForHabit > 0 {
            newBest = (excludedHabit, newStreakForHabit)
        }
        
        // FIXED: Only check habits from current displayed list
        for habit in validHabits {
            guard habit.id != excludedHabit.id,
                  !habit.isFault && !habit.isDeleted,
                  let habitId = habit.id,
                  currentDisplayedHabitIds.contains(habitId) else { continue }
            
            let streak = habit.calculateStreak(upTo: date)
            
            if let current = newBest {
                if streak > current.1 {
                    newBest = (habit, streak)
                }
            } else if streak > 0 {
                newBest = (habit, streak)
            }
        }
        
        bestCurrentStreakData = newBest
        print("📊 Found new best current streak from current list: \(newBest?.1 ?? 0)")
    }
    
    private func findNewBestHistoricalStreakFromCurrentList(excluding excludedHabit: Habit, newStreakForHabit: Int) {
        var newBest: (Habit, Int)? = nil
        
        // Include the excluded habit with its new streak value
        if newStreakForHabit > 0 {
            newBest = (excludedHabit, newStreakForHabit)
        }
        
        // FIXED: Only check habits from current displayed list
        for habit in validHabits {
            guard habit.id != excludedHabit.id,
                  !habit.isFault && !habit.isDeleted,
                  let habitId = habit.id,
                  currentDisplayedHabitIds.contains(habitId) else { continue }
            
            let streak = habit.calculateLongestStreak()
            
            if let current = newBest {
                if streak > current.1 {
                    newBest = (habit, streak)
                }
            } else if streak > 0 {
                newBest = (habit, streak)
            }
        }
        
        bestHistoricalStreakData = newBest
        print("📊 Found new best historical streak from current list: \(newBest?.1 ?? 0)")
    }
    
    // MARK: - Instant Update Methods
    
    @MainActor
    private func updateCompletionCountInstant(wasCompleted: Bool, isCompleted: Bool) {
        withAnimation(.easeInOut(duration: 0.3)) {
            if wasCompleted && !isCompleted {
                cachedTotalCompletions = max(0, cachedTotalCompletions - 1)
            } else if !wasCompleted && isCompleted {
                cachedTotalCompletions += 1
            }
        }
    }
    
    // MARK: - Data Loading Methods (same as original but with proper tracking)
    
    @MainActor
    private func loadAllDataSafely() async {
        let safeHabits = validHabits
        guard !safeHabits.isEmpty else {
            // Set default values if no valid habits
            cachedTotalCompletions = 0
            cachedTotalGoodHabits = 0
            cachedTotalBadHabits = 0
            bestCurrentStreakData = nil
            bestHistoricalStreakData = nil
            isLoadingStreaks = false
            currentDisplayedHabitIds = Set()
            return
        }
        
        // Update tracking of current displayed habits
        currentDisplayedHabitIds = Set(safeHabits.compactMap { $0.id })
        
        do {
            await loadAllData()
        } catch {
            print("Error loading stats data: \(error)")
            // Set safe defaults on error
            cachedTotalCompletions = 0
            cachedTotalGoodHabits = safeHabits.count
            cachedTotalBadHabits = 0
            bestCurrentStreakData = nil
            bestHistoricalStreakData = nil
            isLoadingStreaks = false
        }
    }
    
    private func loadAllData() async {
        await loadCachedTotals()
        await loadStreakDataDirect()
        await statsSummaryManager.refreshData(habits: validHabits)
    }
    
    private func loadCachedTotals() async {
        let currentHabitIds = Set(validHabits.compactMap { $0.id })
        
        // Only recalculate if habits have changed
        if currentHabitIds != lastCachedHabitIds || cachedTotalCompletions == 0 {
            await updateCachedTotals()
        }
    }
    
    private func updateCachedTotals() async {
        let safeHabits = validHabits
        guard !safeHabits.isEmpty else {
            await MainActor.run {
                cachedTotalCompletions = 0
                cachedTotalGoodHabits = 0
                cachedTotalBadHabits = 0
                lastCachedHabitIds = Set()
            }
            return
        }
        
        do {
            let completions = safeHabits.totalCompletions()
            let goodHabits = safeHabits.totalGoodHabits()
            let badHabits = safeHabits.totalBadHabits()
            let currentHabitIds = Set(safeHabits.compactMap { $0.id })
            
            await MainActor.run {
                cachedTotalCompletions = completions
                cachedTotalGoodHabits = goodHabits
                cachedTotalBadHabits = badHabits
                lastCachedHabitIds = currentHabitIds
            }
        } catch {
            print("Error updating cached totals: \(error)")
            await MainActor.run {
                cachedTotalCompletions = 0
                cachedTotalGoodHabits = safeHabits.count
                cachedTotalBadHabits = 0
                lastCachedHabitIds = Set()
            }
        }
    }
    
    private func loadStreakDataDirect() async {
        let safeHabits = validHabits
        guard !safeHabits.isEmpty else { return }
        
        await MainActor.run {
            isLoadingStreaks = true
        }
        
        // Perform calculations on main thread safely
        await MainActor.run {
            do {
                var bestCurrent: (Habit, Int)? = nil
                var bestHistorical: (Habit, Int)? = nil
                
                for habit in safeHabits {
                    // Additional safety checks
                    guard !habit.isFault && !habit.isDeleted && habit.id != nil else { continue }
                    
                    // Use the existing habit calculation methods directly
                    let currentStreak = habit.calculateStreak(upTo: date)
                    let historicalStreak = habit.calculateLongestStreak()
                    
                    // Check current streak
                    if let current = bestCurrent {
                        if currentStreak > current.1 {
                            bestCurrent = (habit, currentStreak)
                        }
                    } else if currentStreak > 0 {
                        bestCurrent = (habit, currentStreak)
                    }
                    
                    // Check historical streak
                    if let historical = bestHistorical {
                        if historicalStreak > historical.1 {
                            bestHistorical = (habit, historicalStreak)
                        }
                    } else if historicalStreak > 0 {
                        bestHistorical = (habit, historicalStreak)
                    }
                }
                
                // Update state with results
                bestCurrentStreakData = bestCurrent
                bestHistoricalStreakData = bestHistorical
                isLoadingStreaks = false
                
            } catch {
                print("Error loading streak data: \(error)")
                bestCurrentStreakData = nil
                bestHistoricalStreakData = nil
                isLoadingStreaks = false
            }
        }
    }
    
    // MARK: - Card Components (same as original)
    
    @ViewBuilder
    private func modernStatCard(
        title: String,
        subtitle: String,
        value: String,
        icon: String?,
        color: Color,
        habit: Habit?
    ) -> some View {
        VStack(spacing: 0) {
            // Two-row title with fixed height
            VStack(spacing: 0) {
                Text(title)
                    .customFont("Lexend", .bold, 9)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.3)
                    .lineLimit(1)
                
                Text(subtitle)
                    .customFont("Lexend", .bold, 9)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.3)
                    .lineLimit(1)
            }
            .frame(height: 24)
            
            Spacer(minLength: 4)
            
            // Value and icon section
            HStack(spacing: 4) {
                // Large value
                Group {
                    if value.contains("%") {
                        AnimatedPercentage(
                            value: Double(value.replacingOccurrences(of: "%", with: "")) ?? 0.0,
                            font: .customFont("Lexend", .medium, 25),
                            color: .primary
                        )
                    } else if value == "-" {
                        Text("-")
                            .customFont("Lexend", .bold, 25)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.primary, Color.primary.opacity(0.5)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    } else {
                        AnimatedNumber(
                            value: Int(value) ?? 0,
                            font: .customFont("Lexend", .medium, 25),
                            color: .primary
                        )
                    }
                }
                .lineLimit(1)
                .minimumScaleFactor(0.9)
                
                // Icon or HabitIconView with safety checks
                if let habit = habit, !habit.isFault && !habit.isDeleted {
                    HabitIconView(
                        iconName: habit.icon,
                        isActive: true,
                        habitColor: color,
                        streak: 0,
                        showStreaks: false,
                        useModernBadges: false,
                        isFutureDate: false,
                        isBadHabit: habit.isBadHabit,
                        intensityLevel: habit.intensityLevel
                    )
                    .scaleEffect(0.8)
                } else if let iconName = icon {
                    ZStack {
                        if useGlassEffect {
                            glassIconBackground(color: color, size: 20)
                        } else {
                            originalIconBackground(color: color, size: 20)
                        }
                        
                        Image(systemName: iconName)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(color)
                    }
                }
            }
            .frame(height: 28) // Fixed height for value/icon area
            
            Spacer(minLength: 0) // Fill remaining space
        }
        .frame(width: 95, height: 80) // Fixed card dimensions
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        //.modernGlassBackground(cornerRadius: 30, tintColor: color)
        .glassBackground(cornerRadius: 25)
    }
    
    // MARK: - Glass Effect Components (same as original)
    
    @ViewBuilder
    private func glassIconBackground(color: Color, size: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .opacity(0.6)
                .frame(width: size, height: size)
            
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: size, height: size)
                .blendMode(.overlay)
            
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(colorScheme == .dark ? 0.2 : 0.35),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .blendMode(.overlay)
            
            Circle()
                .strokeBorder(
                    Color.white.opacity(colorScheme == .dark ? 0.3 : 0.5),
                    lineWidth: 0.6
                )
                .frame(width: size, height: size)
        }
    }
    
    @ViewBuilder
    private func originalIconBackground(color: Color, size: CGFloat) -> some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [color.opacity(0.2), color.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .stroke(color.opacity(0.3), lineWidth: 0.8)
                    .frame(width: size, height: size)
            )
    }
}

// MARK: - Array Extensions (same as original)
extension Array where Element == Habit {
    func totalCompletions() -> Int {
        return self.reduce(0) { total, habit in
            total + habit.getTotalCompletionCount()
        }
    }
    
    func habitWithBestHistoricalStreak() -> (Habit, Int)? {
        guard !self.isEmpty else { return nil }
        
        let habitWithStreak = self.map { habit -> (Habit, Int) in
            return (habit, habit.calculateLongestStreak())
        }
        
        return habitWithStreak.max { $0.1 < $1.1 }
    }
    
    func habitWithBestCurrentStreak(on date: Date) -> (Habit, Int)? {
        guard !self.isEmpty else { return nil }
        
        let habitWithStreak = self.map { habit -> (Habit, Int) in
            return (habit, habit.calculateStreak(upTo: date))
        }
        
        return habitWithStreak.max { $0.1 < $1.1 }
    }
    
    func totalGoodHabits() -> Int {
        return self.filter { !$0.isBadHabit }.count
    }
    
    func totalBadHabits() -> Int {
        return self.filter { $0.isBadHabit }.count
    }
}

// MARK: - HabitUtilities Extensions (Same as your existing code)
extension HabitUtilities {
    
    /// Calculates a 30-day consistency score for a habit (0.0 to 1.0)
    /// Returns a score based on completion frequency and consistency over the last 30 days
    /// Score >= 0.8 is considered "good", < 0.8 needs improvement
    static func calculateConsistency30Days(for habit: Habit, referenceDate: Date = Date()) -> Double {
        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: referenceDate) ?? referenceDate
        
        guard let completions = habit.completion as? Set<Completion> else {
            return 0.0
        }
        
        // Filter completions to last 30 days
        let recentCompletions = completions.filter { completion in
            guard let completionDate = completion.date, completion.completed else { return false }
            return completionDate >= thirtyDaysAgo && completionDate <= referenceDate
        }.sorted { ($0.date ?? Date.distantPast) > ($1.date ?? Date.distantPast) }
        
        if recentCompletions.isEmpty {
            return 0.0
        }
        
        var score: Double = 0.0
        let totalPossibleDays = 30.0
        
        // Component 1: Recency Bonus (40% of score)
        // Most recent completion gets higher weight
        if let mostRecentCompletion = recentCompletions.first,
           let mostRecentDate = mostRecentCompletion.date {
            let daysSinceLastCompletion = calendar.dateComponents([.day],
                                                                from: mostRecentDate,
                                                                to: referenceDate).day ?? 30
            let recencyScore = max(0, (30.0 - Double(daysSinceLastCompletion)) / 30.0)
            score += recencyScore * 0.4
        }
        
        // Component 2: Completion Frequency (35% of score)
        let completionCount = Double(recentCompletions.count)
        let frequencyScore = min(1.0, completionCount / totalPossibleDays)
        score += frequencyScore * 0.35
        
        // Component 3: Consistency Pattern (25% of score)
        // Reward habits completed more consistently throughout the period
        let consistencyScore = calculateConsistencyPattern(completions: recentCompletions,
                                                         thirtyDaysAgo: thirtyDaysAgo,
                                                         referenceDate: referenceDate)
        score += consistencyScore * 0.25
        
        return min(1.0, score) // Ensure we don't exceed 1.0
    }
    
    /// Calculates how consistently a habit was completed across the 30-day period
    private static func calculateConsistencyPattern(completions: [Completion],
                                                  thirtyDaysAgo: Date,
                                                  referenceDate: Date) -> Double {
        let calendar = Calendar.current
        
        // Divide 30 days into 6 periods of 5 days each
        let periodsWithCompletions = (0..<6).map { periodIndex in
            let periodStart = calendar.date(byAdding: .day, value: periodIndex * 5, to: thirtyDaysAgo) ?? thirtyDaysAgo
            let periodEnd = calendar.date(byAdding: .day, value: (periodIndex + 1) * 5 - 1, to: thirtyDaysAgo) ?? periodStart
            
            // Check if any completions fall within this period
            return completions.contains { completion in
                guard let completionDate = completion.date else { return false }
                return completionDate >= periodStart && completionDate <= periodEnd
            }
        }
        
        // Count how many periods had at least one completion
        let periodsWithActivity = periodsWithCompletions.filter { $0 }.count
        
        // Return consistency score based on distribution across periods
        return Double(periodsWithActivity) / 6.0
    }
}

// MARK: - Shadow Cache for Performance
struct ShadowCache {
    private static var cachedShadowColors: [String: Color] = [:]
    
    static func shadowColor(for colorScheme: ColorScheme) -> Color {
        let key = colorScheme == .dark ? "dark" : "light"
        
        if let cached = cachedShadowColors[key] {
            return cached
        }
        
        let color = Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05)
        cachedShadowColors[key] = color
        return color
    }
}

// MARK: - Preview Provider
struct StatsSummaryRow_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Light mode preview with glass effect
            VStack(spacing: 20) {
                Text("Enhanced Stats with 6 Cards")
                    .font(.headline)
                StatsSummaryRow(habits: sampleHabits(), date: Date())
                    .environmentObject(StatsSummaryDataManager())
            }
            .previewLayout(.fixed(width: 400, height: 250))
            .preferredColorScheme(.light)
            .padding()
            .background(Color(UIColor.systemGroupedBackground))
            .previewDisplayName("Light Mode - Enhanced")
            
            // Dark mode preview with glass effect
            VStack(spacing: 20) {
                Text("Enhanced Stats with 6 Cards")
                    .font(.headline)
                StatsSummaryRow(habits: sampleHabits(), date: Date())
                    .environmentObject(StatsSummaryDataManager())
            }
            .previewLayout(.fixed(width: 400, height: 250))
            .preferredColorScheme(.dark)
            .padding()
            .background(Color(UIColor.systemGroupedBackground))
            .previewDisplayName("Dark Mode - Enhanced")
        }
    }
    
    // Sample data for preview
    static func sampleHabits() -> [Habit] {
        let context = PersistenceController.preview.container.viewContext
        
        // Create sample habits with different streaks and completions
        let habits: [Habit] = (1...7).map { index in
            let habit = Habit(context: context)
            habit.id = UUID()
            habit.name = "Habit \(index)"
            habit.icon = ["star.fill", "heart.fill", "drop.fill", "leaf.fill", "medal.fill", "flame.fill", "moon.fill"][index - 1]
            habit.startDate = Date().addingTimeInterval(-Double(index * 30) * 86400) // Different start dates
            habit.isBadHabit = index > 5 // Last 2 are bad habits
            
            // Set different colors
            let colors = [UIColor.systemBlue, UIColor.systemRed, UIColor.systemGreen,
                          UIColor.systemPurple, UIColor.systemOrange, UIColor.systemPink, UIColor.systemTeal]
            if let colorData = try? NSKeyedArchiver.archivedData(withRootObject: colors[index - 1],
                                                              requiringSecureCoding: false) {
                habit.color = colorData
            }
            
            // Create some sample completions
            let completionsCount = index * 5 // Different number of completions
            let streak = min(index * 3, 12) // Different streak lengths
            
            // Add completions for streak calculation
            for day in 0..<streak {
                let completion = Completion(context: context)
                completion.date = Calendar.current.date(byAdding: .day, value: -day, to: Date())
                completion.completed = true
                habit.addToCompletion(completion)
            }
            
            // Add some historical completions
            for _ in 0..<(completionsCount - streak) {
                let completion = Completion(context: context)
                let randomDay = Int.random(in: 30...120)
                completion.date = Calendar.current.date(byAdding: .day, value: -randomDay, to: Date())
                completion.completed = true
                habit.addToCompletion(completion)
            }
            
            return habit
        }
        
        // Try to save the context for preview
        do {
            try context.save()
        } catch {
            print("Error saving preview context: \(error)")
        }
        
        return habits
    }
}
