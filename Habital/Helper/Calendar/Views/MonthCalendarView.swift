import SwiftUI

struct MonthCalendarView: View {
    @Binding var isDragging: Bool
    let dragProgress: CGFloat
    @EnvironmentObject var habitManager: HabitPreloadManager
    // Add parameters for habit data
    let getFilteredHabits: (Date) -> [Habit]
    let animateRings: Bool
    let isShownInHabitDetails: Bool?
    
    @Binding var title: String
    @Binding var focused: Week
    @Binding var selection: Date?
    
    @State private var months: [Month]
    @State private var position: ScrollPosition
    @State private var calendarWidth: CGFloat = .zero
    @State private var currentMonthId: String?
    @State private var isUpdatingFromMonthSwipe = false // Track if we're updating from month swipe
    
    @AppStorage("changeSelectionOnWeekSwipe") private var changeSelectionOnWeekSwipe = true
    
    let habitColor: Color?
    let refreshTrigger: UUID
    
    init(
        _ title: Binding<String>,
        selection: Binding<Date?>,
        focused: Binding<Week>,
        isDragging: Binding<Bool>,
        dragProgress: CGFloat,
        getFilteredHabits: @escaping (Date) -> [Habit] = { _ in [] },
        animateRings: Bool = false,
        isShownInHabitDetails: Bool? = nil,
        refreshTrigger: UUID = UUID(),
        habitColor: Color? = nil
    ) {
        _title = title
        _focused = focused
        _selection = selection
        _isDragging = isDragging
        self.dragProgress = dragProgress
        self.getFilteredHabits = getFilteredHabits
        self.animateRings = animateRings
        self.isShownInHabitDetails = isShownInHabitDetails
        self.refreshTrigger = refreshTrigger
        self.habitColor = habitColor
        
        let creationDate = focused.wrappedValue.days.last
        var currentMonth = Month(from: creationDate ?? .now, order: .current)
        
        if let selection = selection.wrappedValue,
           let lastDayOfTheMonth = currentMonth.weeks.first?.days.last,
           !Calendar.isSameMonth(lastDayOfTheMonth, selection),
           let previousMonth = currentMonth.previousMonth
        {
            if focused.wrappedValue.days.contains(selection) {
                currentMonth = previousMonth
            }
        }
        
        _months = State(
            initialValue: [
                currentMonth.previousMonth,
                currentMonth,
                currentMonth.nextMonth
            ].compactMap(\.self)
        )
        _position = State(initialValue: ScrollPosition(id: currentMonth.id))
        _currentMonthId = State(initialValue: currentMonth.id)
    }
    
    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: .zero) {
                ForEach(months) { month in
                    VStack {
                        MonthView(
                            month: month,
                            dragProgress: dragProgress,
                            isDragging: $isDragging,
                            getFilteredHabits: getFilteredHabits,
                            animateRings: animateRings,
                            refreshTrigger: refreshTrigger,
                            focused: $focused,
                            selectedDate: $selection,
                            isShownInHabitDetails: isShownInHabitDetails,
                            habitColor: habitColor
                        )
                        .offset(y: (1 - dragProgress) * verticalOffset(for: month))
                        .frame(width: calendarWidth, height: Constants.monthHeight)
                        .onAppear { loadMonth(from: month) }
                    }
                }
            }
            .scrollTargetLayout()
            .frame(height: Constants.monthHeight)
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
            guard let focusedMonth = months.first(where: { $0.id == (newValue.viewID as? String) }),
                  let focusedWeek = focusedMonth.weeks.first
            else { return }
            
            // ✅ NEW: Check if this month should be blocked BEFORE updating anything
            if habitManager.isLoaded && !habitManager.monthHasValidDays(focusedMonth) {
                // Block navigation to this month by resetting position
                // Find the last valid month and reset position to it
                if let lastValidMonth = months.last(where: { habitManager.monthHasValidDays($0) }) {
                    DispatchQueue.main.async {
                        self.position = ScrollPosition(id: lastValidMonth.id)
                    }
                }
                return
            }
            
            // Rest of existing logic...
            // Determine if we've changed months
            let isNewMonth = currentMonthId != focusedMonth.id
            
            // Update the current month ID
            currentMonthId = focusedMonth.id
            
            // FIXED: Always use a date from the focused month for the title, not the selected date
            let titleDate = focusedMonth.weeks.flatMap(\.days).first { date in
                let calendar = Calendar.current
                let day = calendar.component(.day, from: date)
                return day >= 10 && day <= 20  // Use a middle day of the month
            } ?? focusedWeek.days.first!
            
            title = Calendar.monthAndYear(from: titleDate)
            
            // Only update selection if we've actually changed months AND setting is enabled
            if isNewMonth && changeSelectionOnWeekSwipe {
                isUpdatingFromMonthSwipe = true
                
                // Try to maintain the same day of month
                if let currentSelection = selection {
                    let calendar = Calendar.current
                    let currentDay = calendar.component(.day, from: currentSelection)
                    
                    let targetMonthDate = focusedMonth.weeks.flatMap(\.days).first { date in
                        calendar.component(.day, from: date) == 15
                    } ?? focusedWeek.days.first!
                    
                    // Try to find the same day in the new month
                    if let sameDay = focusedMonth.weeks.flatMap(\.days).first(where: { date in
                        calendar.component(.day, from: date) == currentDay
                    }) {
                        selection = sameDay
                    } else {
                        // If the day doesn't exist in the new month (e.g., Feb 30), use the last valid day
                        let lastDayOfMonth = focusedMonth.weeks.flatMap(\.days).filter { date in
                            calendar.component(.month, from: date) == calendar.component(.month, from: targetMonthDate)
                        }.max()
                        selection = lastDayOfMonth ?? targetMonthDate
                    }
                }
                
                focused = focusedWeek
                isUpdatingFromMonthSwipe = false
            } else if isNewMonth {
                // If setting is disabled, only update the focused week, not the selection
                focused = focusedWeek
            }
        }
        .onChange(of: selection) { _, newValue in
            // Only update focused week if we're not in the middle of a month swipe update
            guard !isUpdatingFromMonthSwipe,
                  let date = newValue,
                  let week = months.flatMap(\.weeks).first(where: { (week) -> Bool in
                      week.days.contains(date)
                  })
            else { return }
            focused = week
        }
        .onChange(of: dragProgress) { _, newValue in
            guard newValue == 1 else { return }
            if let selection,
               let currentMonth = months.first(where: { $0.id == (position.viewID as? String) }),
               currentMonth.weeks.flatMap(\.days).contains(selection),
               let newFocus = currentMonth.weeks.first(where: { $0.days.contains(selection) })
            {
                focused = newFocus
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("CalendarConstraintsChanged"))) { _ in
            // Refresh the weeks/months arrays to reflect new constraints
            refreshMonthsForNewConstraints() // or refreshMonthsForNewConstraints()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ForceCalendarUpdate"))) { notification in
            guard let userInfo = notification.userInfo,
                  let newDate = userInfo["newDate"] as? Date else { return }
            
            // Find the month containing the new date
            let calendar = Calendar.current
            let targetMonth = months.first { month in
                month.theSameMonth(as: newDate)
            }
            
            if let targetMonth = targetMonth {
                // Found the target month, navigate to it
                if let targetWeek = targetMonth.weeks.first(where: { week in
                    week.days.contains(where: { calendar.isDate($0, inSameDayAs: newDate) })
                }) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        focused = targetWeek
                        selection = newDate
                    }
                    
                    // Update scroll position to show the correct month
                    position.scrollTo(id: targetMonth.id, anchor: .center)
                }
            } else {
                // Target month not loaded, rebuild months array starting from the earliest valid month
                let earliestMonth = habitManager.getEarliestValidMonth()
                let newMonths: [Month] = (0..<12).compactMap { monthOffset in
                    guard let monthDate = calendar.date(byAdding: .month, value: monthOffset, to: earliestMonth) else { return nil }
                    return Month(from: monthDate, order: monthOffset == 0 ? .current : .next)
                }
                
                months = newMonths
                
                // Try again to find the target month
                if let targetMonth = newMonths.first(where: { $0.theSameMonth(as: newDate) }),
                   let targetWeek = targetMonth.weeks.first(where: { week in
                       week.days.contains(where: { calendar.isDate($0, inSameDayAs: newDate) })
                   }) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        focused = targetWeek
                        selection = newDate
                    }
                    position.scrollTo(id: targetMonth.id, anchor: .center)
                }
            }
        }
    }
    
    func refreshMonthsForNewConstraints() {
        guard habitManager.isLoaded else { return }
        
        let calendar = Calendar.current
        let currentMonthDate = months.first(where: { $0.id == (position.viewID as? String) })?.initializedDate ?? Date()
        
        // Check if we can now load more previous months
        var newMonths = months
        var canLoadMore = true
        var checkDate = currentMonthDate
        
        // Try to add previous months that are now accessible
        while canLoadMore && newMonths.count < 12 { // Reasonable limit
            if let previousMonthDate = calendar.date(byAdding: .month, value: -1, to: checkDate) {
                let previousMonth = Month(from: previousMonthDate, order: .previous)
                
                // Check if this month has any valid days
                let allDaysInMonth = previousMonth.weeks.flatMap(\.days)
                let hasValidDays = allDaysInMonth.contains { !habitManager.isDateBeforeEarliest($0) }
                
                if hasValidDays {
                    newMonths.insert(previousMonth, at: 0)
                    checkDate = previousMonthDate
                } else {
                    canLoadMore = false
                }
            } else {
                canLoadMore = false
            }
        }
        
        months = newMonths
    }
}

extension MonthCalendarView {
    func loadMonth(from month: Month) {
        if month.order == .previous, months.first == month, let previousMonth = month.previousMonth {
            // Check if previous month has ANY valid days
            let allDaysInPreviousMonth = previousMonth.weeks.flatMap(\.days)
            let hasValidDays = allDaysInPreviousMonth.contains { !habitManager.isDateBeforeEarliest($0) }
            
            if hasValidDays {
                var months = self.months
                months.insert(previousMonth, at: 0)
                self.months = months
            }
        } else if month.order == .next, months.last == month, let nextMonth = month.nextMonth {
            var months = months
            months.append(nextMonth)
            self.months = months
        }
    }
    
    func verticalOffset(for month: Month) -> CGFloat {
        guard let index = month.weeks.firstIndex(where: { $0 == focused }) else { return .zero }
        let height = Constants.monthHeight/CGFloat(month.weeks.count)
        return CGFloat(month.weeks.count - 1)/2 * height - CGFloat(index) * height
    }
}
