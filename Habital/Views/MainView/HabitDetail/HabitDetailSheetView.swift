//
//  HabitDetailSheetView.swift
//  Habital
//
//  Created by Elias Osarumwense on 15.04.25.
//

import SwiftUI

import SwiftUI
import CoreData

struct HabitDetailSheet: View {
    let habit: Habit
    let date: Date
    @Binding var isPresented: Bool
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    
    // App storage for settings
    @AppStorage("showStreaks") private var showStreaks = true
    @AppStorage("useModernBadges") private var useModernBadges = false
    
    @State private var calendarTitle: String = Calendar.monthAndYear(from: Date())
    @State private var focusedWeek: Week = Week(days: Calendar.currentWeek(from: Calendar.nearestMonday(from: Date())), order: .current)
    @State private var selectedCalendarDate: Date? = Date()
    @State private var isDraggingCalendar = false
    @State private var calendarDragProgress: CGFloat = 1.0
    
    @State private var refreshChart = false
    
    @Binding var selectedDetent: PresentationDetent
    
    // Tab navigation
    @State private var selectedTab: Int = 0
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    
    @State private var preloadedCalendarView: AnyView?
    
    // Calculate streak and other metrics
    private var streak: Int {
        return habit.calculateStreak(upTo: date)
    }
    
    private func getFilteredHabitsForDate(_ date: Date) -> [Habit] {
        // Just return this single habit for the calendar view
        return [habit]
    }
    
    // Overdue days calculation
    private var overdueDays: Int? {
        return habit.calculateOverdueDays(on: date)
    }
    
    // Extract the habit color or use a default
    private var habitColor: Color {
        if let colorData = habit.color,
           let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
            return Color(uiColor)
        }
        return .blue // Default color if not set
    }
    
    // Format date with specific style
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "Not set" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    // Format completion percentage
    private func formattedCompletionRate() -> String {
        guard let completions = habit.completion as? Set<Completion>,
              !completions.isEmpty,
              let startDate = habit.startDate else {
            return "0%"
        }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let startDay = calendar.startOfDay(for: startDate)
        
        // Calculate total days from start until today
        let totalDays = max(1, calendar.dateComponents([.day], from: startDay, to: today).day ?? 0) + 1
        
        // Count active days within this period
        var activeDays = 0
        var currentDate = startDay
        
        while currentDate <= today {
            if HabitUtilities.isHabitActive(habit: habit, on: currentDate) {
                activeDays += 1
            }
            
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }
        
        // Count completed days
        let completedDays = (0..<totalDays).reduce(0) { count, offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: startDay) else { return count }
            return count + (habit.isCompleted(on: day) ? 1 : 0)
        }
        
        // Calculate percentage based on active days
        let percentage = activeDays > 0 ? Double(completedDays) / Double(activeDays) * 100 : 0
        return String(format: "%.1f%%", percentage)
    }
    
    // Get the repeat pattern text
    private var repeatPatternText: String {
        guard let repeatPattern = HabitUtilities.getEffectiveRepeatPattern(for: habit, on: date) else {
            return "Not scheduled"
        }
        
        // Add repeats per day to the pattern text if > 1
        let repeatsText = repeatPattern.repeatsPerDay > 1 ? " (\(repeatPattern.repeatsPerDay)x per day)" : ""
        
        // Check for daily goal
        if let dailyGoal = repeatPattern.dailyGoal {
            if dailyGoal.everyDay {
                return "Daily" + repeatsText
            } else if dailyGoal.daysInterval > 0 {
                return "Every \(dailyGoal.daysInterval) days" + repeatsText
            } else if let specificDays = dailyGoal.specificDays as? [Bool] {
                // Check if we have multiple weeks
                let weekCount = specificDays.count / 7
                
                if weekCount > 1 && specificDays.count % 7 == 0 {
                    // Multi-week pattern
                    return "\(weekCount) weeks rotation" + repeatsText
                } else if specificDays.count == 7 {
                    // Single week pattern
                    let dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
                    let fullDayNames = ["Mondays", "Tuesdays", "Wednesdays", "Thursdays", "Fridays", "Saturdays", "Sundays"]
                    let selectedDays = zip(dayNames, specificDays)
                        .filter { $0.1 }
                        .map { $0.0 }
                    
                    if selectedDays.isEmpty {
                        return "No days selected" + repeatsText
                    } else if selectedDays.count == 1 {
                        // For a single day, use the plural form (e.g., "Sundays")
                        let dayIndex = dayNames.firstIndex(of: selectedDays[0]) ?? 0
                        return "On \(fullDayNames[dayIndex])" + repeatsText
                    } else {
                        return "On \(selectedDays.joined(separator: ", "))" + repeatsText
                    }
                } else {
                    return "Custom daily pattern" + repeatsText
                }
            }
        }
        
        // Check for weekly goal
        if let weeklyGoal = repeatPattern.weeklyGoal {
            let baseText = weeklyGoal.everyWeek ? "Weekly" : "Every \(weeklyGoal.weekInterval) weeks"
            return baseText + repeatsText
        }
        
        // Check for monthly goal
        if let monthlyGoal = repeatPattern.monthlyGoal {
            let baseText = monthlyGoal.everyMonth ? "Monthly" : "Every \(monthlyGoal.monthInterval) months"
            return baseText + repeatsText
        }
        
        return "Not scheduled"
    }
    
    // Get total completions count
    private var totalCompletions: Int {
        return (habit.completion as? Set<Completion>)?.filter { $0.completed }.count ?? 0
    }
    
    private var backgroundGradient: some View {
        let base = habitColor ?? .secondary

        let top   = colorScheme == .dark ? 0.10 : 0.15
        let mid   = colorScheme == .dark ? 0.06 : 0.11
        let low   = colorScheme == .dark ? 0.04 : 0.08
        let floor = colorScheme == .dark ? Color(hex: "0A0A0A") : Color.clear

        return LinearGradient(
            gradient: Gradient(colors: [
                floor,                 // now at the TOP side
                base.opacity(low),
                base.opacity(mid),
                base.opacity(top)               // faintest color now at BOTTOM
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            backgroundGradient
            // TabView with swipe navigation
            TabView(selection: $selectedTab) {
                // Tab 3: Schedule
                ScrollView {
                    VStack(spacing: 14) {
                        // Add spacing at the top to account for the navbar height
                        Color.clear.frame(height: 10 )
                        
                         
                        
                        VStack(alignment: .leading, spacing: 12) {
                            if let calendarView = preloadedCalendarView {
                                calendarView
                            } else {
                                ProgressView().frame(height: 200)
                            }
                        }
                        .padding(.horizontal)
                        /*
                        // Schedule section
                        scheduleSection
                            .transition(.opacity)
                            .scaleEffect(0.97)
                         */
                         
                    }
                         
                    .ignoresSafeArea(.container, edges: .bottom)
                }
                .tag(0)
                // Tab 1: Overview - Header + Calendar Toggle + Streaks
                ScrollView {
                    VStack(spacing: 14) {
                        // Add spacing at the top to account for the navbar height
                        Color.clear.frame(height: 10 )
                        
                        // Header is always displayed
                        HabitHeaderView(habit: habit, showStreaks: true)
                            .padding(.horizontal)
                        
                        
                        //scheduleSection
                        
                        HabitStreaksView(habit: habit, date: date, showStreaks: showStreaks)
                            .padding(.horizontal)
                            .transition(.opacity)
                        /*
                        CalendarAndToggleView(habit: habit, date: date)
                            .padding(.horizontal)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                         */
                        /*
                        // NEW: Circle Menu Button
                        CircleMenuButton(habit: habit, date: date)
                            .padding(.horizontal)
                            .padding(.top, 8)
                         */
                        HabitGitHubGrid(habit: habit)
                            .padding(.horizontal)
                        .transition(.opacity)
                        
                    }
                    .ignoresSafeArea(.container, edges: .bottom)
                }
                .tag(1)
                ScrollView {
                    VStack(spacing: 14) {
                        // Add spacing at the top to account for the navbar height
                        Color.clear.frame(height: 10 )
                        
                         /*
                        HabitScoreSection(habit: habit)
                            .padding(.horizontal)
                         */
                        
                        
                        
                        
                    }
                    .ignoresSafeArea(.container, edges: .bottom)
                    //.padding(.bottom, 37) // Extra padding for tab indicator
                }
                .tag(2)
                // Tab 2: Analytics - Consistency Chart + Calendar
                ScrollView {
                    VStack(spacing: 14) {
                        // Add spacing at the top to account for the navbar height
                        Color.clear.frame(height: 10)
                        /*
                        // Consistency Chart
                        HabitConsistencyChart(habit: habit, refreshTrigger: $refreshChart)
                            .padding(.horizontal)
                            .transition(.opacity)
                         
                        */
                        HabitAnalyticsView(habit: habit)
                            .padding(.horizontal)
                        
                        /*
                        HabitWeeklyCompletionChart(habit: habit)
                            .padding(.horizontal)
                        .transition(.opacity)
                         */
                        // Calendar and Completion View
                        /*
                        scheduleSection
                            .transition(.opacity)
                         */
                        
                    }
                    .ignoresSafeArea(.container, edges: .bottom)
                    //.padding(.bottom, 100) // Extra padding for tab indicator
                }
                .tag(3)
                
                
                
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .onAppear {
                // Ensure we start on the first tab
                selectedTab = 1
                
                if preloadedCalendarView == nil {
                        preloadedCalendarView = AnyView(
                            CalendarAndCompletionView(
                                habit: habit,
                                selectedCalendarDate: $selectedCalendarDate,
                                calendarTitle: $calendarTitle,
                                focusedWeek: $focusedWeek,
                                isDraggingCalendar: $isDraggingCalendar,
                                calendarDragProgress: $calendarDragProgress,
                                getFilteredHabitsForDate: getFilteredHabitsForDate,
                                refreshTrigger: $refreshChart
                            )
                            .environment(\.managedObjectContext, viewContext)
                            //.scaleEffect(0.9)
                        )
                    }
            }
            
            // Custom Tab Indicator at bottom
            VStack {
                Spacer()
                HStack(spacing: 8) {
                    ForEach(0..<4, id: \.self) { index in
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                selectedTab = index
                            }
                        }) {
                            Group {
                                if index == 1 {
                                    // Special handling for habit icon (index 1)
                                    TabIconView(
                                        iconString: habit.icon,
                                        isSelected: selectedTab == index,
                                        habitColor: habitColor
                                    )
                                    .foregroundColor(selectedTab == index ? habitColor : .secondary.opacity(0.6))
                                } else {
                                    // Regular SF Symbol icons for other tabs
                                    Image(systemName: tabIcon(for: index))
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(selectedTab == index ? habitColor : .secondary.opacity(0.6))
                                        .scaleEffect(selectedTab == index ? 1.1 : 1.0)
                                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTab)
                                }
                            }
                            .frame(width: 22, height: 22)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .padding(.bottom, 30)
            }
            .zIndex(1)
            /*
            // Custom navbar - placed at the top of the ZStack to stay fixed
            if selectedDetent != .height(470) {
                UltraThinMaterialNavBar(
                    title: "Habit Details",
                    leftIcon: "xmark",
                    rightIcon: nil, // Remove config icon since we removed customization
                    leftAction: {
                        isPresented = false
                    },
                    rightAction: nil,
                    titleColor: .primary,
                    leftIconColor: .secondary,
                    rightIconColor: .secondary
                )
                .zIndex(2) // Ensure the navbar stays on top
            }
             */
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .onChange(of: selectedCalendarDate) { oldDate, newDate in
            if let date = newDate {
                print("tapped")
            }
        }
        .onDisappear() {
            HabitUtilities.clearHabitActivityCache()
        }
    }
    
    // Helper functions for tab content
    private func tabIcon(for index: Int) -> String {
        switch index {
        case 0: return "calendar.badge.clock"
        case 1: return habit.icon ?? "questionmark"
        case 2: return "chart.line.uptrend.xyaxis"
        case 3: return "ellipsis"  
        default: return "questionmark"
        }
    }
    
    private func tabTitle(for index: Int) -> String {
        switch index {
        case 0: return "Overview"
        case 1: return "Analytics"
        case 2: return "Schedule"
        default: return "Unknown"
        }
    }
    
    // Helper function to format impact values with sign
    private func formatImpactValue(_ value: Int) -> String {
        if value > 0 {
            return "+\(value)"
        } else if value < 0 {
            return "\(value)" // Already includes minus sign
        } else {
            return "0"
        }
    }
    
    
    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Check if there are multiple repeat patterns
            if let repeatPatterns = habit.repeatPattern as? Set<RepeatPattern>, repeatPatterns.count > 1 {
                VStack(spacing: 15) {
                    // Header for patterns history
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundColor(habitColor)
                        Text("Schedule History")
                            .font(.headline)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 5)
                    // Convert to array and sort chronologically by effectiveFrom date
                    let sortedPatterns = repeatPatterns.compactMap { pattern -> (RepeatPattern, Date)? in
                        guard let effectiveFrom = pattern.effectiveFrom else { return nil }
                        return (pattern, effectiveFrom)
                    }
                    .sorted { $0.1 > $1.1 } // Most recent first
                    
                    // Display each pattern with its effective date
                    ForEach(Array(sortedPatterns.enumerated()), id: \.element.0.objectID) { index, pair in
                        let pattern = pair.0
                        let effectiveDate = pair.1
                        
                        // Format the date for display
                        let formattedDate = formatDate(effectiveDate)
                        
                        // Pattern card with effective date
                        VStack(alignment: .leading, spacing: 8) {
                            // Show "Current" badge for the most recent pattern
                            if index == 0 {
                                HStack {
                                    Text("Current")
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(habitColor.opacity(0.2))
                                        .cornerRadius(8)
                                    
                                    Spacer()
                                    
                                    Text("Effective from: \(formattedDate)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                HStack {
                                    Text("Previous")
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(8)
                                    
                                    Spacer()
                                    
                                    Text("Effective from: \(formattedDate)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            // Display pattern details based on type
                            if let dailyGoal = pattern.dailyGoal {
                                let icon = dailyGoal.everyDay ? "repeat.1" :
                                          (dailyGoal.daysInterval > 0 ? "calendar.day.timeline.right" : "calendar")
                                
                                patternCard(
                                    title: getPatternText(for: pattern),
                                    subtitle: "Repeats \(pattern.repeatsPerDay > 1 ? "\(pattern.repeatsPerDay)x per day" : "on scheduled days")",
                                    icon: icon,
                                    followUp: pattern.followUp
                                )
                                
                                // Show days selection if it's a specific days pattern
                                if !dailyGoal.everyDay && dailyGoal.daysInterval == 0,
                                   let specificDays = dailyGoal.specificDays as? [Bool],
                                   specificDays.count >= 7, index == 0 { // Only show visualization for current pattern
                                    daysSelectionView(specificDays: specificDays)
                                }
                            }
                            else if let weeklyGoal = pattern.weeklyGoal {
                                let icon = weeklyGoal.everyWeek ? "calendar.badge.clock" : "calendar.badge.plus"
                                
                                patternCard(
                                    title: getPatternText(for: pattern),
                                    subtitle: "Repeats \(pattern.repeatsPerDay > 1 ? "\(pattern.repeatsPerDay)x per day" : "on scheduled days")",
                                    icon: icon,
                                    followUp: pattern.followUp
                                )
                                
                                if let specificDays = weeklyGoal.specificDays as? [Bool],
                                   specificDays.count == 7, index == 0 { // Only show visualization for current pattern
                                    daysSelectionView(specificDays: specificDays)
                                }
                            }
                            else if let monthlyGoal = pattern.monthlyGoal {
                                let icon = monthlyGoal.everyMonth ? "calendar.badge.clock" : "calendar.badge.plus"
                                
                                patternCard(
                                    title: getPatternText(for: pattern),
                                    subtitle: "Repeats \(pattern.repeatsPerDay > 1 ? "\(pattern.repeatsPerDay)x per day" : "on scheduled days")",
                                    icon: icon,
                                    followUp: pattern.followUp
                                )
                                
                                if let specificDays = monthlyGoal.specificDays as? [Bool],
                                   specificDays.count == 31, index == 0 { // Only show visualization for current pattern
                                    monthDaysSelectionView(specificDays: specificDays)
                                }
                            }
                        }
                        .padding(10)
                        .glassBackground()
                        
                        // Add a divider between patterns, except after the last one
                        if index < sortedPatterns.count - 1 {
                            Divider()
                                .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical, 10)
                .padding(.horizontal)
                .glassBackground()
            }
            // If there's only one pattern, show it as before
            else if let repeatPattern = HabitUtilities.getEffectiveRepeatPattern(for: habit, on: date) {
                VStack(spacing: 15) {
                    // Don't show effective date when there's only one pattern
                    
                    // Pattern card in RepeatPatternView style - reusing your existing code
                    if let dailyGoal = repeatPattern.dailyGoal {
                        let icon = dailyGoal.everyDay ? "repeat.1" :
                                  (dailyGoal.daysInterval > 0 ? "calendar.day.timeline.right" : "calendar")
                        
                        patternCard(
                            title: repeatPatternText,
                            subtitle: "Repeats \(repeatPattern.repeatsPerDay > 1 ? "\(repeatPattern.repeatsPerDay)x per day" : "on scheduled days")",
                            icon: icon,
                            followUp: repeatPattern.followUp
                        )
                        
                        // Show days selection if it's a specific days pattern
                        if !dailyGoal.everyDay && dailyGoal.daysInterval == 0,
                           let specificDays = dailyGoal.specificDays as? [Bool],
                           specificDays.count >= 7 {
                            daysSelectionView(specificDays: specificDays)
                        }
                    }
                    else if let weeklyGoal = repeatPattern.weeklyGoal {
                        let icon = weeklyGoal.everyWeek ? "calendar.badge.clock" : "calendar.badge.plus"
                        
                        patternCard(
                            title: repeatPatternText,
                            subtitle: "Repeats \(repeatPattern.repeatsPerDay > 1 ? "\(repeatPattern.repeatsPerDay)x per day" : "on scheduled days")",
                            icon: icon,
                            followUp: repeatPattern.followUp
                        )
                        
                        if let specificDays = weeklyGoal.specificDays as? [Bool], specificDays.count == 7 {
                            daysSelectionView(specificDays: specificDays)
                        }
                    }
                    else if let monthlyGoal = repeatPattern.monthlyGoal {
                        let icon = monthlyGoal.everyMonth ? "calendar.badge.clock" : "calendar.badge.plus"
                        
                        patternCard(
                            title: repeatPatternText,
                            subtitle: "Repeats \(repeatPattern.repeatsPerDay > 1 ? "\(repeatPattern.repeatsPerDay)x per day" : "on scheduled days")",
                            icon: icon,
                            followUp: repeatPattern.followUp
                        )
                        
                        if let specificDays = monthlyGoal.specificDays as? [Bool], specificDays.count == 31 {
                            monthDaysSelectionView(specificDays: specificDays)
                        }
                    }
                }
                .padding(.vertical, 10)
                .padding(.horizontal)
                .glassBackground()
            } else {
                // No pattern found case
                patternCard(
                    title: "Not Scheduled",
                    subtitle: "No active schedule for this habit",
                    icon: "calendar.badge.exclamationmark",
                    followUp: false
                )
                .padding(.vertical, 10)
                .padding(.horizontal)
                .background(
                    ZStack {
                        // Glass morphism background
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .fill(.ultraThinMaterial)
                        
                        // Subtle inner glow
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(colorScheme == .dark ? 0.05 : 0.15),
                                        Color.clear,
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        
                        // Modern border with gradient
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(colorScheme == .dark ? 0.15 : 0.4),
                                        Color.primary.opacity(0.08),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    }
                )
            }
        }
        .padding(.horizontal)
    }

    // Helper function to format a date nicely
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    // Helper function to get pattern text for a specific RepeatPattern instance
    private func getPatternText(for pattern: RepeatPattern) -> String {
        // Daily Goal
        if let dailyGoal = pattern.dailyGoal {
            if dailyGoal.everyDay {
                return "Daily"
            } else if dailyGoal.daysInterval > 0 {
                return "Every \(dailyGoal.daysInterval) days"
            } else if let specificDays = dailyGoal.specificDays as? [Bool] {
                // Check if we have multiple weeks
                let weekCount = specificDays.count / 7
                
                if weekCount > 1 && specificDays.count % 7 == 0 {
                    // Multi-week pattern
                    var weekDescriptions: [String] = []
                    let dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
                    
                    // Generate description for each week
                    for week in 0..<weekCount {
                        let startIndex = week * 7
                        let endIndex = startIndex + 7
                        
                        if endIndex <= specificDays.count {
                            let daysForWeek = Array(specificDays[startIndex..<endIndex])
                            let selectedDays = zip(dayNames, daysForWeek)
                                .filter { $0.1 }
                                .map { $0.0 }
                            
                            if !selectedDays.isEmpty {
                                weekDescriptions.append("Week \(week + 1): \(selectedDays.joined(separator: ", "))")
                            }
                        }
                    }
                    
                    if weekDescriptions.isEmpty {
                        return "No days selected"
                    } else if weekDescriptions.count == 1 {
                        return weekDescriptions[0]
                    } else {
                        return "\(weekCount) weeks rotation"
                    }
                } else if specificDays.count == 7 {
                    // Single week pattern
                    let dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
                    let selectedDays = zip(dayNames, specificDays)
                        .filter { $0.1 }
                        .map { $0.0 }
                    
                    if selectedDays.isEmpty {
                        return "No days selected"
                    } else {
                        return selectedDays.joined(separator: ", ")
                    }
                } else {
                    return "Custom daily pattern"
                }
            }
        }
        
        // Weekly Goal
        if let weeklyGoal = pattern.weeklyGoal {
            let baseText = weeklyGoal.everyWeek ? "Weekly" : "Every \(weeklyGoal.weekInterval) weeks"
            
            if let specificDays = weeklyGoal.specificDays as? [Bool], specificDays.count == 7 {
                let dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
                let selectedDays = zip(dayNames, specificDays)
                    .filter { $0.1 }
                    .map { $0.0 }
                
                if selectedDays.isEmpty {
                    return "\(baseText): No days selected"
                } else {
                    return "\(baseText): \(selectedDays.joined(separator: ", "))"
                }
            }
            
            return baseText
        }
        
        // Monthly Goal
        if let monthlyGoal = pattern.monthlyGoal {
            let baseText = monthlyGoal.everyMonth ? "Monthly" : "Every \(monthlyGoal.monthInterval) months"
            
            if let specificDays = monthlyGoal.specificDays as? [Bool], specificDays.count == 31 {
                let selectedDays = (0..<specificDays.count)
                    .filter { specificDays[$0] }
                    .map { String($0 + 1) }
                
                if selectedDays.isEmpty {
                    return "\(baseText): No days selected"
                } else if selectedDays.count <= 3 {
                    return "\(baseText): \(selectedDays.joined(separator: ", "))"
                } else {
                    return "\(baseText): \(selectedDays.count) days"
                }
            }
            
            return baseText
        }
        
        return "Not scheduled"
    }
    
    
    private var completionHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Completions")
                .font(.headline)
                .padding(.leading, 5)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 10) {
                if let completions = habit.completion as? Set<Completion>, !completions.isEmpty {
                    let sortedCompletions = completions.sorted {
                        ($0.date ?? Date.distantPast) > ($1.date ?? Date.distantPast)
                    }
                    
                    let limitedCompletions = Array(sortedCompletions.prefix(5))
                    
                    ForEach(limitedCompletions, id: \.self) { completion in
                        HStack {
                            Image(systemName: completion.completed ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(completion.completed ? .green : .gray)
                            
                            Text(formatDate(completion.date))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if completion.duration > 0 {
                                Text("\(completion.duration) min")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                        .padding(.vertical, 4)
                        
                        if completion != limitedCompletions.last {
                            Divider()
                        }
                    }
                    
                    if completions.count > 5 {
                        Divider()
                        HStack {
                            Spacer()
                            Text("+ \(completions.count - 5) more completions")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding(.top, 8)
                    }
                } else {
                    HStack {
                        Spacer()
                        Text("No completions recorded yet")
                            .foregroundColor(.secondary)
                            .padding(.vertical)
                        Spacer()
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color(UIColor.systemGray6) : Color.white)
                    //.shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
        }
        .padding(.horizontal)
    }
    
    // MARK: - Helper View Components
    
    private func patternCard(title: String, subtitle: String, icon: String, followUp: Bool) -> some View {
        HStack(spacing: 14) {
            // More elegant icon circle
            ZStack {
                Circle()
                    .fill(colorScheme == .dark ?
                        Color(UIColor.systemGray5) :
                        Color.primary.opacity(0.05))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                    .font(.system(size: 16, weight: .semibold))
            }
            
            // Text content with more refined spacing
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.customFont("Lexend", .medium, 16))
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.customFont("Lexend", .regular, 12))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Refined follow-up indicator
            if followUp {
                HStack(spacing: 3) {
                    Image(systemName: "arrow.turn.down.right")
                        .font(.system(size: 10, weight: .medium))
                    
                    Text("Follow-up")
                        .font(.customFont("Lexend", .medium, 12))
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(Color.primary.opacity(0.08))
                        .overlay(
                            Capsule()
                                .strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5)
                        )
                )
                .foregroundColor(.primary.opacity(0.8))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
    }
    
    private func daysSelectionView(specificDays: [Bool]) -> some View {
        VStack(spacing: 8) {
            let dayNames = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
            let shortDayNames = ["M", "T", "W", "T", "F", "S", "S"]
            
            // For multi-week patterns, we need to show multiple week rows
            let weekCount = specificDays.count / 7
            
            // Divider with "Selected Days" label
            HStack {
                Divider()
                Text("Selected Days")
                    .font(.customFont("Lexend", .medium, 11))
                    .foregroundColor(.secondary)
                Divider()
            }
            .padding(.vertical, 5)
            
            ForEach(0..<weekCount, id: \.self) { weekIndex in
               
                
                HStack(spacing: 10) {
                    ForEach(0..<7, id: \.self) { dayIndex in
                        let globalDayIndex = (weekIndex * 7) + dayIndex
                        let isSelected = globalDayIndex < specificDays.count && specificDays[globalDayIndex]
                        
                        VStack(spacing: 2) {
                            ZStack {
                                Circle()
                                    .fill(isSelected ? (colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.7)) : Color.gray.opacity(0.2))
                                    .frame(width: 28, height: 28)
                                
                                Text(shortDayNames[dayIndex])
                                    .font(.customFont("Lexend", .medium, 9))
                                    .foregroundColor(isSelected ? (colorScheme == .dark ? .black : .white) : .primary)
                            }
                            
                            if weekIndex == 0 {
                                // Only show day names for first week
                                Text(String(dayNames[dayIndex].prefix(3)))
                                    .font(.customFont("Lexend", .medium, 10))
                                    .foregroundColor(.gray)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                // Show "Week X" label for all weeks ONLY if there are multiple weeks
                if weekCount > 1 {
                    Text("Week \(weekIndex + 1)")
                        .font(.customFont("Lexend", .medium, 11))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(weekIndex > 0 ? 5 : 0)
                }
            }
        }
        .padding(.bottom, 10)
        .padding(.top, -5)
    }
    
    private func monthDaysSelectionView(specificDays: [Bool]) -> some View {
        VStack(spacing: 10) {
            // Divider with "Selected Days" label
            HStack {
                Divider()
                Text("Selected Days of Month")
                    .font(.customFont("Lexend", .medium, 11))
                    .foregroundColor(.secondary)
                Divider()
            }
            .padding(.vertical, 5)
            
            // Grid of days 1-31
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 12) {
                ForEach(0..<31, id: \.self) { index in
                    let day = index + 1
                    ZStack {
                        Circle()
                            .fill(specificDays[index] ? (colorScheme == .dark ? .white : .black) : Color.gray.opacity(0.2))
                            .frame(width: 25, height: 25)
                        // Highlight 29, 30, 31 with a subtle border
                            .overlay(
                                Circle()
                                    .strokeBorder(
                                        day >= 29 ? Color.orange.opacity(0.7) : Color.clear,
                                        lineWidth: 1
                                    )
                            )
                        
                        Text("\(day)")
                            .font(.customFont("Lexend", .medium, 10))
                            .foregroundColor(specificDays[index] ? (colorScheme == .dark ? .black : .white) : .primary)
                    }
                }
            }
            
            // Info about 29-31 days
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.orange.opacity(0.7))
                    .frame(width: 6, height: 6)
                
                Text("Days 29-31 are highlighted")
                    .font(.customFont("Lexend", .regular, 11))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 2)
        }
        .padding(.bottom, 10)
        .padding(.top, -5)
    }
}
/*
struct MetricCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 5)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color.black.opacity(0.3) : color.opacity(0.1))
        )
    }
}
*/


/*
#if DEBUG
struct HabitDetailSheet_Previews: PreviewProvider {
    static var previews: some View {
        HabitDetailSheet(
            habit: Habit(),
            date: Date(),
            isPresented: .constant(true)
        )
    }
}
#endif
*/

struct ExpandSheetButton: View {
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false
    @State private var isHovered = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPressed = true
            }
            
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isPressed = false
                }
                action()
            }
        }) {
            HStack(spacing: 12) {
                // Left chevron with subtle animation
                Image(systemName: "chevron.up")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary.opacity(0.8))
                    .scaleEffect(isPressed ? 0.9 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isPressed)
                
                // Modern text with better spacing
                Text("View More")
                    .font(.customFont("Lexend", .medium, 13))
                    .foregroundColor(.primary.opacity(0.9))
                    .tracking(0.3) // Letter spacing for modern look
                
                // Right chevron with subtle animation
                Image(systemName: "chevron.up")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary.opacity(0.8))
                    .scaleEffect(isPressed ? 0.9 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isPressed)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(
                ZStack {
                    // Glass morphism background
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .opacity(isPressed ? 0.8 : 1.0)
                    
                    // Subtle inner glow
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(colorScheme == .dark ? 0.05 : 0.15),
                                    Color.clear,
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    
                    // Modern border with gradient
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(colorScheme == .dark ? 0.15 : 0.4),
                                    Color.primary.opacity(0.08),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                }
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08),
                radius: isPressed ? 4 : 8,
                x: 0,
                y: isPressed ? 2 : 4
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Alternative: Ultra-minimal version
struct MinimalExpandButton: View {
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                isPressed = true
            }
            
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isPressed = false
                }
                action()
            }
        }) {
            VStack(spacing: 6) {
                // Double chevron for "more" indication
                Image(systemName: "chevron.compact.up")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary.opacity(0.6))
                
                Text("More")
                    .font(.customFont("Lexend", .medium, 11))
                    .foregroundColor(.primary.opacity(0.7))
                    .tracking(0.5)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule()
                            .strokeBorder(
                                Color.primary.opacity(0.12),
                                lineWidth: 1
                            )
                    )
            )
            .scaleEffect(isPressed ? 0.94 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TabIconView: View {
    let iconString: String?
    let isSelected: Bool
    let habitColor: Color
    
    var body: some View {
        Group {
            if let iconString = iconString {
                // Check if it's an emoji
                if iconString.first?.isEmoji ?? false {
                    // Emoji without circle
                    Text(iconString)
                        .font(.system(size: isSelected ? 12 : 10))
                        .scaleEffect(isSelected ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
                } else {
                    // SF Symbol
                    Image(systemName: iconString)
                        .font(.system(size: 10, weight: .medium))
                        .scaleEffect(isSelected ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
                }
            } else {
                // Fallback icon
                Image(systemName: "questionmark")
                    .font(.system(size: 10, weight: .medium))
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
            }
        }
    }
}
