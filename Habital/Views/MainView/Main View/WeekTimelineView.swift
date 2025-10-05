//
//  WeekTimelineView.swift
//  Habital
//
//  Created by Elias Osarumwense on 01.04.25.
//

import SwiftUI
import CoreData


struct WeekTimelineView: View {
    @EnvironmentObject var habitManager: HabitPreloadManager
    @Binding var selectedDate: Date
    @Binding var weekOffset: Int
    var onDateSelected: (Date) -> Void
    
    // Add filtered habits for each date
    var getFilteredHabits: (Date) -> [Habit]
    
    // State for the scrollable calendar integration
    @State private var selection: Date?
    @State private var title: String = Calendar.monthAndYear(from: .now)
    @State private var focusedWeek: Week = .current
    
    // State for calendar type toggling
    @State private var calendarType: CalendarType = .week
    @State private var isDragging: Bool = false
    @State private var dragProgress: CGFloat = .zero
    @State private var initialDragOffset: CGFloat? = nil
    @State private var verticalDragOffset: CGFloat = .zero
    
    // Animation state for the completion rings
    @State private var animateRings: Bool = false
    
    @AppStorage("showMonthView") private var showMonthView = true
    @AppStorage("enableCalendarDragGesture") private var enableCalendarDragGesture = true
    @AppStorage("showProgressBars") private var showProgressBars = true
    @AppStorage("accentColorIndex") private var accentColorIndex: Int = 0
    @AppStorage("includeBadHabitsInStats") private var includeBadHabitsInStats = true
    
    @State private var visibleDates: [Date] = []
    @State private var activityCache: [String: [TimeInterval: Bool]] = [:]
    @State private var completionCache: [String: [TimeInterval: Bool]] = [:]
    
    @StateObject private var cacheManager = CalendarCacheManager()
    
    let calendar = Calendar.current
    
    private var accentColor: Color {
        return ColorPalette.color(at: accentColorIndex)
    }
    
    enum CalendarType {
        case week, month
    }
    
    // Initialize with filtered habits function
    init(selectedDate: Binding<Date>, weekOffset: Binding<Int>, getFilteredHabits: @escaping (Date) -> [Habit]) {
        self._selectedDate = selectedDate
        self._weekOffset = weekOffset
        self.onDateSelected = { _ in }
        self.getFilteredHabits = getFilteredHabits
    }
    
    // Backward compatibility initializer
    init(selectedDate: Binding<Date>, weekOffset: Binding<Int>) {
        self._selectedDate = selectedDate
        self._weekOffset = weekOffset
        self.onDateSelected = { _ in }
        self.getFilteredHabits = { _ in return [] }
    }
    
    // Full initializer with callback
    init(selectedDate: Binding<Date>, weekOffset: Binding<Int>, onDateSelected: @escaping (Date) -> Void, getFilteredHabits: @escaping (Date) -> [Habit]) {
        self._selectedDate = selectedDate
        self._weekOffset = weekOffset
        self.onDateSelected = onDateSelected
        self.getFilteredHabits = getFilteredHabits
    }
    
    var body: some View {
        VStack (spacing: 0) {
            //ModernDayHeaders()
            // WeekCalendarView instead of TabView
            VStack {
                switch calendarType {
                case .week:
                    WeekCalendarView(
                                            $title,
                                            selection: $selection,
                                            focused: $focusedWeek,
                                            isDragging: $isDragging,
                                            getFilteredHabits: getFilteredHabits,
                                            animateRings: animateRings
                                        )
                    .environmentObject(cacheManager) // Pass the cache manager
                    //.environment(\.weekTimelineView, self)
                case .month:
                    MonthCalendarView(
                        $title,
                        selection: $selection,
                        focused: $focusedWeek,
                        isDragging: $isDragging,
                        dragProgress: dragProgress,
                        getFilteredHabits: getFilteredHabits,
                        animateRings: animateRings
                    )
                    .environmentObject(cacheManager) // Pass the cache manager
                    //.environment(\.weekTimelineView, self)
                }
            }
            
            //.padding(.bottom, 10)
            .frame(height: Constants.dayHeight + verticalDragOffset)
            .clipped()
            .gesture(
                        showMonthView && enableCalendarDragGesture ?
                        DragGesture(minimumDistance: 2.0, coordinateSpace: .local)
                            .onChanged { value in
                                // Only set isDragging true once at the start of the gesture
                                if !isDragging {
                                    
                                        isDragging = true
                                    
                                    
                                    initialDragOffset = verticalDragOffset
                                }
                                
                                calendarType = verticalDragOffset == 0 ? .week : .month
                                
                                // Use interpolation for smoother dragging
                                let targetOffset = max(
                                    .zero,
                                    min(
                                        (initialDragOffset ?? 0) + value.translation.height,
                                        Constants.monthHeight - Constants.dayHeight
                                    )
                                )
                                
                                // Apply velocity-based smoothing
                                let smoothingFactor: CGFloat = 0.5 // Lower = smoother but more lag
                                verticalDragOffset = verticalDragOffset + (targetOffset - verticalDragOffset) * smoothingFactor
                                
                                // Calculate progress once and reuse
                                dragProgress = verticalDragOffset / (Constants.monthHeight - Constants.dayHeight)
                            }
                            .onEnded { value in
                                // Track velocity for predictive animation
                                let velocity = value.predictedEndTranslation.height - value.translation.height
                                let gestureIsFlick = abs(velocity) > 400
                                
                                initialDragOffset = nil
                                
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    // Use velocity to determine end state
                                    if gestureIsFlick {
                                        if velocity > 0 {
                                            // Flicking down - expand to month
                                            verticalDragOffset = Constants.monthHeight - Constants.dayHeight
                                        } else {
                                            // Flicking up - collapse to week
                                            verticalDragOffset = 0
                                        }
                                    } else {
                                        // Normal drag - use threshold
                                        switch calendarType {
                                        case .week:
                                            verticalDragOffset = verticalDragOffset > Constants.monthHeight/3 ?
                                                Constants.monthHeight - Constants.dayHeight : 0
                                        case .month:
                                            verticalDragOffset = verticalDragOffset < Constants.monthHeight/3 ?
                                                0 : Constants.monthHeight - Constants.dayHeight
                                        }
                                    }
                                    
                                    dragProgress = verticalDragOffset / (Constants.monthHeight - Constants.dayHeight)
                                } completion: {
                                    // Update calendar type and reset isDragging after animation completes
                                    calendarType = verticalDragOffset == 0 ? .week : .month
                                    
                                        isDragging = false
                                    
                                    
                                }
                            } : nil
            )

            .onChange(of: verticalDragOffset) { _, newValue in
                        // This is more efficient than recalculating in multiple places
                        dragProgress = newValue / (Constants.monthHeight - Constants.dayHeight)
                    }
            .onAppear {
                
                // Set initial selection
                selection = selectedDate
                
                // Debug habits for the current week
                let weekDates = (0..<7).map { getDayDate(for: $0, weekOffset: 0) }
                for date in weekDates {
                    debugHabitsForDay(date: date)
                }
                
                // Trigger initial animation for rings
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        animateRings = true
                    }
                
            }
            
            if showMonthView {
                Capsule()
                    .fill(.gray.mix(with: .white, by: 0.8).opacity(0.3))
                    .frame(width: 40, height: 4)
                    .padding(.bottom, 1)
                    .padding(.top, 5)
                    .onTapGesture {
                        withAnimation(.spring()) {
                            switch calendarType {
                            case .week:
                                verticalDragOffset = Constants.monthHeight - Constants.dayHeight
                                calendarType = .month
                            case .month:
                                verticalDragOffset = 0
                                calendarType = .week
                            }
                            dragProgress = verticalDragOffset / (Constants.monthHeight - Constants.dayHeight)
                        }
                    }
            }
            
            // Rest of the existing code remains the same...
            if showProgressBars {
                VStack (spacing: 0) {
                    // Get the habits and calculate daily completion percentage
                    let selectedDateHabits = getFilteredHabits(selectedDate)
                    let dailyCompletionPercentage = calculateHabitCompletionPercentage(for: selectedDate, habits: selectedDateHabits)
                    
                    // Calculate weekly completion percentage
                    let weeklyCompletionPercentage = calculateWeeklyCompletionPercentage()
                    if calendarType == .month {
                        let monthlyCompletionPercentage = calculateMonthlyCompletionPercentage()
                        HStack {
                            Text("Month")
                                .customFont("Quantico", .regular, 10)
                                .frame(width: 50, alignment: .trailing)
                            Spacer()
                            BeautifulProgressBar(
                                progress: monthlyCompletionPercentage,
                                color: accentColor,
                                height: 8,
                                showPercentage: false,
                                cornerRadius: 8,
                                totalWidth: 275
                            )
                            Text("\(Int(monthlyCompletionPercentage * 100))%")
                                .customFont("Quantico", .regular, 10)
                                .frame(width: 40)
                        }
                        .padding(.top, 8)
                    }
                    // Current week progress bar
                    HStack {
                        Text("CW\(getWeekOfYear(for: getStartOfWeek(for: weekOffset)))")
                            .customFont("Quantico", .regular, 10)
                            .frame(width: 50, alignment: .trailing)
                        Spacer()
                        BeautifulProgressBar(
                            progress: weeklyCompletionPercentage,
                            color: accentColor,
                            height: 8,
                            showPercentage: false,
                            cornerRadius: 8,
                            totalWidth: 275
                        )
                        Text("\(Int(weeklyCompletionPercentage * 100))%")
                            .customFont("Quantico", .regular, 10)
                            .frame(width: 40)
                    }
                    .padding(.top, (calendarType == .month) ? 5 : 8)
                    
                    // Daily progress bar
                    HStack {
                        Text(formatSelectedDateToDayOrFull(date: selectedDate))
                            .customFont("Quantico", .regular, 10)
                            .frame(width: 50, alignment: .trailing)
                        Spacer()
                        BeautifulProgressBar(
                            progress: dailyCompletionPercentage,
                            color: accentColor,
                            height: 8,
                            showPercentage: false,
                            cornerRadius: 8,
                            totalWidth: 275
                        )
                        Text("\(Int(dailyCompletionPercentage * 100))%")
                            .customFont("Quantico", .regular, 10)
                            .frame(width: 40)
                    }
                    .padding(.top, 5)
                }
                .padding(.horizontal)
                .padding(.bottom, 5)
            }
        }
        
        .onChange(of: selection) { _, newValue in
            if let newValue {
                selectedDate = newValue
                onDateSelected(newValue)
                
                // Update week offset based on the selected date
                let calendar = Calendar.current
                let currentDate = Date()
                let startOfCurrentWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: currentDate))!
                let startOfSelectedWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: newValue))!
                
                weekOffset = calendar.dateComponents([.weekOfYear], from: startOfCurrentWeek, to: startOfSelectedWeek).weekOfYear ?? 0
            }
        }
        
        .onChange(of: calendarType) { _, _ in
                    cacheManager.updateVisibleDates(
                        calendarType: calendarType,
                        selectedDate: selectedDate,
                        weekOffset: weekOffset
                    )
                }
                .onChange(of: weekOffset) { _, _ in
                    cacheManager.updateVisibleDates(
                        calendarType: calendarType,
                        selectedDate: selectedDate,
                        weekOffset: weekOffset
                    )
                }
                .onChange(of: selectedDate) { _, newValue in
                    // Update visible dates when the month changes
                    let calendar = Calendar.current
                    if calendar.component(.month, from: selectedDate) != calendar.component(.month, from: newValue) {
                        cacheManager.updateVisibleDates(
                            calendarType: calendarType,
                            selectedDate: newValue,
                            weekOffset: weekOffset
                        )
                    }
                }
                .onAppear {
                    if habitManager.isDateBeforeEarliest(selectedDate) {
                                    selectedDate = habitManager.earliestStartDate
                                    focusedWeek = habitManager.getEarliestValidWeek()
                                }
                    // Initialize visible dates
                    cacheManager.updateVisibleDates(
                        calendarType: calendarType,
                        selectedDate: selectedDate,
                        weekOffset: weekOffset
                    )
                    
                    
                }
    }
    
    // Add this method to update visible dates based on current view
    private func updateVisibleDates() {
        let calendar = Calendar.current
        
        switch calendarType {
        case .week:
            // Only get the 7 days of the current visible week
            visibleDates = (0..<7).map { getDayDate(for: $0, weekOffset: weekOffset) }
        case .month:
            // Get all days in the current visible month
            let selectedDateComponents = calendar.dateComponents([.year, .month], from: selectedDate)
            guard let startOfMonth = calendar.date(from: selectedDateComponents) else { return }
            guard let range = calendar.range(of: .day, in: .month, for: startOfMonth) else { return }
            
            visibleDates = range.compactMap { day -> Date? in
                var components = DateComponents()
                components.year = selectedDateComponents.year
                components.month = selectedDateComponents.month
                components.day = day
                return calendar.date(from: components)
            }
        }
        
        // Preload habit activity and completion status for visible dates
        preloadHabitData()
    }

    // Method to preload habit data for all visible dates
    private func preloadHabitData() {
        // Get habits that will be visible in the current view
        let allHabits = Set(visibleDates.flatMap { getFilteredHabits($0) })
        
        // Process each habit to efficiently preload activity and completion status
        for habit in allHabits {
            guard let habitID = habit.id?.uuidString else { continue }
            
            // Initialize cache entries for this habit if needed
            if activityCache[habitID] == nil {
                activityCache[habitID] = [:]
            }
            if completionCache[habitID] == nil {
                completionCache[habitID] = [:]
            }
            
            // Preload data for each visible date
            for date in visibleDates {
                let normalizedDate = calendar.startOfDay(for: date)
                let dateKey = normalizedDate.timeIntervalSince1970
                
                // Only calculate if not already cached
                if activityCache[habitID]?[dateKey] == nil {
                    let isActive = HabitUtilities.isHabitActive(habit: habit, on: date)
                    activityCache[habitID]?[dateKey] = isActive
                }
                
                // Only check completion status if the habit is active
                if activityCache[habitID]?[dateKey] == true && completionCache[habitID]?[dateKey] == nil {
                    let isCompleted = isHabitCompleted(habit, on: date)
                    completionCache[habitID]?[dateKey] = isCompleted
                }
            }
        }
    }

    // Optimized version of isHabitActive that uses cache
    func isHabitActiveOptimized(_ habit: Habit, on date: Date) -> Bool {
        guard let habitID = habit.id?.uuidString else {
            return HabitUtilities.isHabitActive(habit: habit, on: date)
        }
        
        let normalizedDate = calendar.startOfDay(for: date)
        let dateKey = normalizedDate.timeIntervalSince1970
        
        // Check cache first
        if let cachedValue = activityCache[habitID]?[dateKey] {
            return cachedValue
        }
        
        // If not in cache, compute and store
        let isActive = HabitUtilities.isHabitActive(habit: habit, on: date)
        
        // Update cache
        if activityCache[habitID] == nil {
            activityCache[habitID] = [:]
        }
        activityCache[habitID]?[dateKey] = isActive
        
        return isActive
    }

    // Optimized version of isHabitCompleted that uses cache
    func isHabitCompletedOptimized(_ habit: Habit, on date: Date) -> Bool {
        guard let habitID = habit.id?.uuidString else {
            return isHabitCompleted(habit, on: date)
        }
        
        let normalizedDate = calendar.startOfDay(for: date)
        let dateKey = normalizedDate.timeIntervalSince1970
        
        // Check cache first
        if let cachedValue = completionCache[habitID]?[dateKey] {
            return cachedValue
        }
        
        // If not in cache, compute and store
        let isCompleted = isHabitCompleted(habit, on: date)
        
        // Update cache
        if completionCache[habitID] == nil {
            completionCache[habitID] = [:]
        }
        completionCache[habitID]?[dateKey] = isCompleted
        
        return isCompleted
    }
    
    // Function to calculate habit completion percentage for a specific date
    private func calculateHabitCompletionPercentage(for date: Date, habits: [Habit]) -> Double {
        var totalActiveHabits = 0
        var completedHabits = 0
        
        for habit in habits {
            // Guard to ensure the habit has a start date
            guard let startDate = habit.startDate else {
                continue
            }
            
            // Skip bad habits if they shouldn't be included in stats
            if habit.isBadHabit && !includeBadHabitsInStats {
                continue
            }
            
            // Check if the habit is active on this date
            let isActive = HabitUtilities.isHabitActive(habit: habit, on: date)
            
            if isActive {
                totalActiveHabits += 1
                
                // Check if this habit was completed on this date
                let completionState = isHabitCompleted(habit, on: date)
                
                // For bad habits, NOT completed means success
                // For good habits, completed means success
                if habit.isBadHabit ? !completionState : completionState {
                    completedHabits += 1
                }
            }
        }
        
        return totalActiveHabits > 0 ? Double(completedHabits) / Double(totalActiveHabits) : 0.0
    }
    
    func debugHabitsForDay(date: Date) {
        let habits = getFilteredHabits(date)
        print("Date: \(date), Number of habits: \(habits.count)")
        
        for habit in habits {
            print("- Habit: \(habit.name ?? "Unnamed"), Completed: \(isHabitCompleted(habit, on: date))")
        }
    }
    
    // Function to calculate weekly completion percentage
    private func calculateWeeklyCompletionPercentage() -> Double {
        // Get the dates for the current week
        let weekDates = (0..<7).map { getDayDate(for: $0, weekOffset: weekOffset) }
        
        var totalActiveHabits = 0
        var totalCompletedHabits = 0
        
        // Keep track of follow-up habits that have been counted
        var countedFollowUpHabits = Set<NSManagedObjectID>()
        
        // Process each date in the week
        for date in weekDates {
            let habits = getFilteredHabits(date)
            
            for habit in habits {
                // Skip bad habits if they shouldn't be included in stats
                if habit.isBadHabit && !includeBadHabitsInStats {
                    continue
                }
                
                // Check if this habit is active on this date
                let isActive = HabitUtilities.isHabitActive(habit: habit, on: date)
                
                if isActive {
                    // Get the effective repeat pattern for this date
                    let effectivePattern = HabitUtilities.getEffectiveRepeatPattern(for: habit, on: date)
                    
                    // For follow-up habits, only count once per week
                    if effectivePattern?.followUp == true {
                        // Skip if we've already counted this follow-up habit
                        if countedFollowUpHabits.contains(habit.objectID) {
                            continue
                        }
                        
                        // Mark this follow-up habit as counted
                        countedFollowUpHabits.insert(habit.objectID)
                        
                        // Increment active count
                        totalActiveHabits += 1
                        
                        // Check if this habit was completed on any day in the week
                        // For bad habits, NOT completed means success
                        let isCompletedInWeek = weekDates.contains { weekDate in
                            let completionState = isHabitCompleted(habit, on: weekDate)
                            return habit.isBadHabit ? !completionState : completionState
                        }
                        
                        if isCompletedInWeek {
                            totalCompletedHabits += 1
                        }
                    } else {
                        // Regular habit (not follow-up)
                        totalActiveHabits += 1
                        
                        // Check if this specific occurrence was completed
                        // For bad habits, NOT completed means success
                        let completionState = isHabitCompleted(habit, on: date)
                        if habit.isBadHabit ? !completionState : completionState {
                            totalCompletedHabits += 1
                        }
                    }
                }
            }
        }
        
        // Calculate percentage
        return totalActiveHabits > 0 ?
            Double(totalCompletedHabits) / Double(totalActiveHabits) : 0.0
    }
    
    private func calculateMonthlyCompletionPercentage() -> Double {
        let calendar = Calendar.current
        let today = Date()
        
        // Get date components for selected date
        let selectedDateComponents = calendar.dateComponents([.year, .month], from: selectedDate)
        let todayComponents = calendar.dateComponents([.year, .month], from: today)
        
        // Determine if selected date is in current month
        let isCurrentMonth = selectedDateComponents.year == todayComponents.year &&
                             selectedDateComponents.month == todayComponents.month
        
        // Get start of month for selected date
        let startOfMonth = calendar.date(from: selectedDateComponents)!
        
        // Determine end date - either today (for current month) or end of month (for past months)
        let endDate: Date
        if isCurrentMonth {
            endDate = today
        } else {
            // Get the last day of the selected month
            let nextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
            endDate = calendar.date(byAdding: .day, value: -1, to: nextMonth)!
        }
        
        // Generate all dates in the month up to end date
        var monthDates: [Date] = []
        var currentDate = startOfMonth
        
        while currentDate <= endDate {
            monthDates.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        var totalActiveHabits = 0
        var totalCompletedHabits = 0
        
        // Keep track of follow-up habits that have been counted
        var countedFollowUpHabits = Set<NSManagedObjectID>()
        
        // Process each date in the month
        for date in monthDates {
            let habits = getFilteredHabits(date)
            
            for habit in habits {
                // Skip bad habits if they shouldn't be included in stats
                if habit.isBadHabit && !includeBadHabitsInStats {
                    continue
                }
                
                // Check if this habit is active on this date
                let isActive = HabitUtilities.isHabitActive(habit: habit, on: date)
                
                if isActive {
                    // Get the effective repeat pattern for this date
                    let effectivePattern = HabitUtilities.getEffectiveRepeatPattern(for: habit, on: date)
                    
                    // For follow-up habits, only count once per month
                    if effectivePattern?.followUp == true {
                        // Skip if we've already counted this follow-up habit
                        if countedFollowUpHabits.contains(habit.objectID) {
                            continue
                        }
                        
                        // Mark this follow-up habit as counted
                        countedFollowUpHabits.insert(habit.objectID)
                        
                        // Increment active count
                        totalActiveHabits += 1
                        
                        // Check if this habit was completed on any day in the month
                        // For bad habits, NOT completed means success
                        let isCompletedInMonth = monthDates.contains { monthDate in
                            let completionState = isHabitCompleted(habit, on: monthDate)
                            return habit.isBadHabit ? !completionState : completionState
                        }
                        
                        if isCompletedInMonth {
                            totalCompletedHabits += 1
                        }
                    } else {
                        // Regular habit (not follow-up)
                        totalActiveHabits += 1
                        
                        // Check if this specific occurrence was completed
                        // For bad habits, NOT completed means success
                        let completionState = isHabitCompleted(habit, on: date)
                        if habit.isBadHabit ? !completionState : completionState {
                            totalCompletedHabits += 1
                        }
                    }
                }
            }
        }
        
        // Calculate percentage
        return totalActiveHabits > 0 ?
            Double(totalCompletedHabits) / Double(totalActiveHabits) : 0.0
    }
    
    private func isHabitCompleted(_ habit: Habit, on date: Date) -> Bool {
        guard let completions = habit.completion as? Set<Completion> else {
            return false
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        return completions.contains { completion in
            guard let completionDate = completion.date else { return false }
            return calendar.isDate(completionDate, inSameDayAs: startOfDay) && completion.completed
        }
    }
    
    private func isHabitActive(on date: Date, startDate: Date, repeatPattern: Habit) -> Bool {
        return HabitUtilities.isHabitActive(on: date, startDate: startDate, repeatPattern: repeatPattern)
    }

    
    // Function to format the selected date to either day name or full date
    private func formatSelectedDateToDayOrFull(date: Date) -> String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let selectedDay = calendar.startOfDay(for: date)
        
        let daysDifference = abs(calendar.dateComponents([.day], from: today, to: selectedDay).day ?? 0)
        
        // Choose format based on how far the date is from today
        let formatter = DateFormatter()
        if daysDifference <= 6 {
            formatter.dateFormat = "EEEE"  // Day name (e.g., "Monday")
        } else {
            formatter.dateFormat = "dd. MMMM"  // Day and month (e.g., "15. April")
        }
        
        return formatter.string(from: date)
    }
    
    private func getStartOfWeek(for weekOffset: Int) -> Date {
        let calendar = Calendar.current
        let startOfCurrentWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        return calendar.date(byAdding: .weekOfYear, value: weekOffset, to: startOfCurrentWeek)!
    }
    
    private func getWeekOfYear(for date: Date) -> Int {
        Calendar.current.component(.weekOfYear, from: date)
    }
    
    private func getDayDate(for index: Int, weekOffset: Int) -> Date {
        let startOfWeek = getStartOfWeek(for: weekOffset)
        return Calendar.current.date(byAdding: .day, value: index, to: startOfWeek)!
    }
    
    private func dayName(for index: Int) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E"
        let date = getDayDate(for: index, weekOffset: 0)
        return String(dateFormatter.string(from: date).prefix(2))
    }
}

struct ModernDayHeaders: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<7, id: \.self) { index in
                Text(dayName(for: index))
                    //.font(.system(size: 9, weight: .medium, design: .rounded))
                    .customFont("Lexend", .semiBold, 9)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.secondary.opacity(0.8))
                    .textCase(.uppercase)
                    .tracking(0.5)
                    
            }
        }
        .padding(.top, 5)
        .padding(.bottom, 8)
        .padding(.horizontal, 11)
    }
    
    private func dayName(for index: Int) -> String {
        let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        return days[index]
    }
}

#Preview {
    WeekTimelineView(
        selectedDate: .constant(Date()),
        weekOffset: .constant(0)
    )
}
