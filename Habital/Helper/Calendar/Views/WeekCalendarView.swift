import SwiftUI

import SwiftUI

struct WeekCalendarView: View {
    @Binding var isDragging: Bool
    
    // Add EnvironmentObject for HabitPreloadManager
    @EnvironmentObject var habitManager: HabitPreloadManager
    
    let getFilteredHabits: (Date) -> [Habit]
    let animateRings: Bool

    @Binding var title: String
    @Binding var focused: Week
    @Binding var selection: Date?
    
    @AppStorage("changeSelectionOnWeekSwipe") private var changeSelectionOnWeekSwipe = true
    
    @State private var weeks: [Week]
    @State private var position: ScrollPosition
    @State private var calendarWidth: CGFloat = .zero
    @State private var isUpdatingFromWeekSwipe = false
    @State private var isUpdatingFromValidation = false // NEW: Prevent infinite loops
    
    let habitColor: Color?
    
    init(
        _ title: Binding<String>,
        selection: Binding<Date?>,
        focused: Binding<Week>,
        isDragging: Binding<Bool>,
        getFilteredHabits: @escaping (Date) -> [Habit] = { _ in [] },
        animateRings: Bool = false,
        habitColor: Color? = nil
    ) {
        _title = title
        _focused = focused
        _selection = selection
        _isDragging = isDragging
        self.getFilteredHabits = getFilteredHabits
        self.animateRings = animateRings
        self.habitColor = habitColor
        
        let theNearestMonday = Calendar.nearestMonday(from: focused.wrappedValue.days.first ?? .now)
        let currentWeek = Week(
            days: Calendar.currentWeek(from: theNearestMonday),
            order: .current
        )
        
        let previousWeek: Week = if let firstDay = currentWeek.days.first {
            Week(
                days: Calendar.previousWeek(from: firstDay),
                order: .previous
            )
        } else { Week(days: [], order: .previous) }
        
        let nextWeek: Week = if let lastDay = currentWeek.days.last {
            Week(
                days: Calendar.nextWeek(from: lastDay),
                order: .next
            )
        } else { Week(days: [], order: .next) }
        
        _weeks = .init(initialValue: [previousWeek, currentWeek, nextWeek])
        _position = State(initialValue: ScrollPosition(id: focused.id))
    }
    
    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: .zero) {
                ForEach(weeks) { week in
                    VStack {
                        WeekView(
                            week: week,
                            selectedDate: $selection,
                            dragProgress: .zero,
                            getFilteredHabits: getFilteredHabits,
                            animateRings: animateRings,
                            isDragging: $isDragging,
                            refreshTrigger: stableUUID(for: week),
                            isShownInHabitDetails: nil,
                            habitColor: habitColor
                        )
                        
                        .frame(width: calendarWidth, height: Constants.dayHeight)
                        .onAppear { loadWeek(from: week) }
                    }
                }
            }
            .scrollTargetLayout()
            .frame(height: Constants.dayHeight)
        }
        .scrollDisabled(isDragging)
        .scrollPosition($position)
        .scrollTargetBehavior(.viewAligned)
        .scrollIndicators(.hidden)
        
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { newValue in
            calendarWidth = newValue
        }
        .onChange(of: position) { oldValue, newValue in
            // Prevent infinite loops during position changes
            guard !isUpdatingFromValidation else { return }
            
            guard let viewID = newValue.viewID as? String,
                  let focusedWeek = weeks.first(where: { $0.id == viewID }) else {
                return
            }
            
            // Check if this week should be blocked BEFORE updating anything
            if habitManager.isLoaded && !habitManager.weekHasValidDays(focusedWeek) {
                // Block navigation to this week by resetting position
                isUpdatingFromValidation = true
                
                // Find the last valid week and reset position to it
                if let lastValidWeek = weeks.last(where: { habitManager.weekHasValidDays($0) }) {
                    DispatchQueue.main.async {
                        self.position = ScrollPosition(id: lastValidWeek.id)
                        self.isUpdatingFromValidation = false
                    }
                }
                return
            }
            
            // Determine if we've changed weeks
            let isNewWeekSelection = focused.id != focusedWeek.id
            
            // Update focused week and title
            if let lastDay = focusedWeek.days.last {
                focused = focusedWeek
                title = Calendar.monthAndYear(from: lastDay)
            } else {
                return
            }
            
            // Only update selection when the setting is enabled, not dragging, and we've changed weeks
            if !isDragging && isNewWeekSelection && changeSelectionOnWeekSwipe {
                isUpdatingFromWeekSwipe = true // Set flag before updating selection
                
                // Get the current day of week from the current selection
                if let currentSelection = selection,
                   let currentDayOfWeek = Calendar.current.dateComponents([.weekday], from: currentSelection).weekday {
                    
                    // Find the same day of week in the new week
                    let calendar = Calendar.current
                    if let newDayInWeek = focusedWeek.days.first(where: { date in
                        calendar.dateComponents([.weekday], from: date).weekday == currentDayOfWeek
                    }) {
                        // Only set selection if the new date is valid
                        if habitManager.canNavigateToDate(newDayInWeek) {
                            selection = newDayInWeek
                        }
                    } else {
                        // Fallback: determine week movement direction and set Monday/Sunday
                        if let oldWeek = weeks.first(where: { $0.id == (oldValue.viewID as? String) }),
                           let oldFirstDay = oldWeek.days.first,
                           let newFirstDay = focusedWeek.days.first {
                            if newFirstDay < oldFirstDay {
                                // Moving to previous week, select Sunday (if valid)
                                if let sunday = focusedWeek.days.last,
                                   habitManager.canNavigateToDate(sunday) {
                                    selection = sunday
                                }
                            } else if newFirstDay > oldFirstDay {
                                // Moving to next week, select Monday (if valid)
                                if let monday = focusedWeek.days.first,
                                   habitManager.canNavigateToDate(monday) {
                                    selection = monday
                                }
                            }
                        }
                    }
                } else {
                    // No current selection, default to Monday of new week (if valid)
                    if let monday = focusedWeek.days.first,
                       habitManager.canNavigateToDate(monday) {
                        selection = monday
                    }
                }
                
                // Reset flag after a brief delay to allow the selection change to process
                DispatchQueue.main.async {
                    isUpdatingFromWeekSwipe = false
                }
            }
        }
        .onChange(of: selection) { _, newValue in
            // Prevent infinite loops during selection validation
            guard !isUpdatingFromValidation, !isUpdatingFromWeekSwipe else { return }
            
            // Validate selection is not before earliest date
            if let date = newValue, habitManager.isLoaded && habitManager.isDateBeforeEarliest(date) {
                // Use the validation flag to prevent infinite loops
                isUpdatingFromValidation = true
                
                DispatchQueue.main.async {
                    self.selection = self.habitManager.earliestStartDate
                    self.isUpdatingFromValidation = false
                }
                return
            }
            
            // Only update focused week if we're not in the middle of updates
            guard let date = newValue,
                  let week = weeks.first(where: { $0.days.contains(date) })
            else { return }
            
            focused = week
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("CalendarConstraintsChanged"))) { _ in
            // Refresh the weeks/months arrays to reflect new constraints
            refreshWeeksForNewConstraints() // or refreshMonthsForNewConstraints()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ForceCalendarUpdate"))) { notification in
            guard let userInfo = notification.userInfo,
                  let newDate = userInfo["newDate"] as? Date else { return }
            
            // Find the week containing the new date
            if let targetWeek = weeks.first(where: { week in
                week.days.contains(where: { Calendar.current.isDate($0, inSameDayAs: newDate) })
            }) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    focused = targetWeek
                    selection = newDate
                }
                
                // Update the scroll position to show the correct week
                position.scrollTo(id: targetWeek.id, anchor: .center)
            } else {
                // If the target week isn't loaded, rebuild the weeks array
                let earliestDate = habitManager.getEarliestValidDate()
                let endDate = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
                
                // Create weeks starting from the earliest valid date
                var newWeeks: [Week] = []
                let calendar = Calendar.current
                let startMonday = Calendar.nearestMonday(from: earliestDate)
                
                var currentWeekStart = startMonday
                while currentWeekStart <= endDate {
                    let weekDays = Calendar.currentWeek(from: currentWeekStart)
                    let week = Week(days: weekDays, order: .current)
                    newWeeks.append(week)
                    
                    guard let nextWeekStart = calendar.date(byAdding: .weekOfYear, value: 1, to: currentWeekStart) else { break }
                    currentWeekStart = nextWeekStart
                }
                weeks = newWeeks
                
                // Try again to find the target week
                if let targetWeek = newWeeks.first(where: { week in
                    week.days.contains(where: { Calendar.current.isDate($0, inSameDayAs: newDate) })
                }) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        focused = targetWeek
                        selection = newDate
                    }
                    position.scrollTo(id: targetWeek.id, anchor: .center)
                }
            }
        }

    }
    
    private func stableUUID(for week: Week) -> UUID {
        // Create a consistent UUID based on the week's first day
        let firstDay = week.days.first ?? Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .weekOfYear], from: firstDay)
        let seedString = "\(components.year ?? 0)-\(components.weekOfYear ?? 0)"
        return UUID(uuidString: seedString.padding(toLength: 36, withPad: "0", startingAt: 0)) ?? UUID()
    }
    
    func refreshWeeksForNewConstraints() {
        guard habitManager.isLoaded else { return }
        
        let calendar = Calendar.current
        let currentWeekStart = focused.days.first ?? Date()
        
        // Check if we can now load more previous weeks
        var newWeeks = weeks
        var canLoadMore = true
        var checkDate = currentWeekStart
        
        // Try to add previous weeks that are now accessible
        while canLoadMore && newWeeks.count < 20 { // Reasonable limit
            if let previousWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: checkDate) {
                let previousWeek = Week(days: Calendar.currentWeek(from: Calendar.nearestMonday(from: previousWeekStart)), order: .previous)
                
                if habitManager.weekHasValidDays(previousWeek) {
                    newWeeks.insert(previousWeek, at: 0)
                    checkDate = previousWeekStart
                } else {
                    canLoadMore = false
                }
            } else {
                canLoadMore = false
            }
        }
        
        weeks = newWeeks
    }
}

extension WeekCalendarView {
    func loadWeek(from week: Week) {
        // Prevent loading during validation updates
        guard !isUpdatingFromValidation else { return }
        
        guard habitManager.isLoaded else {
            // If habitManager not loaded, load normally
            if week.order == .previous, weeks.first == week, let firstDay = week.days.first {
                let previousWeek = Week(days: Calendar.previousWeek(from: firstDay), order: .previous)
                var weeks = self.weeks
                weeks.insert(previousWeek, at: 0)
                self.weeks = weeks
            } else if week.order == .next, weeks.last == week, let lastDay = week.days.last {
                let nextWeek = Week(days: Calendar.nextWeek(from: lastDay), order: .next)
                var weeks = self.weeks
                weeks.append(nextWeek)
                self.weeks = weeks
            }
            return
        }
        
        // Only restrict previous weeks, allow all next weeks
        if week.order == .previous, weeks.first == week, let firstDay = week.days.first {
            let previousWeekDays = Calendar.previousWeek(from: firstDay)
            let previousWeek = Week(days: previousWeekDays, order: .previous)
            
            // Only add previous week if it has valid days
            if habitManager.weekHasValidDays(previousWeek) {
                var weeks = self.weeks
                weeks.insert(previousWeek, at: 0)
                self.weeks = weeks
            }
        } else if week.order == .next, weeks.last == week, let lastDay = week.days.last {
            // Always allow loading next weeks
            let nextWeek = Week(days: Calendar.nextWeek(from: lastDay), order: .next)
            var weeks = self.weeks
            weeks.append(nextWeek)
            self.weeks = weeks
        }
    }
}
