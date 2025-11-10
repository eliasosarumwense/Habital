import SwiftUI

struct MonthCalendarView: View {
    @Binding var isDragging: Bool
    let dragProgress: CGFloat
    @EnvironmentObject var habitManager: HabitPreloadManager
    
    @ObservedObject var toggleManager: HabitToggleManager
    
    let getFilteredHabits: (Date) -> [Habit]
    let animateRings: Bool
    let isShownInHabitDetails: Bool?
    
    @Binding var title: String
    @Binding var focused: Week
    @Binding var selection: Date?
    
    @State private var months: [Month] = []
    @State private var focusedMonth: Month?
    @State private var calendarWidth: CGFloat = .zero
    @State private var isInternalUpdate = false
    
    @AppStorage("changeSelectionOnWeekSwipe") private var changeSelectionOnWeekSwipe = true
    
    let habitColor: Color?
    let refreshTrigger: UUID
    
    init(
        _ title: Binding<String>,
        selection: Binding<Date?>,
        focused: Binding<Week>,
        isDragging: Binding<Bool>,
        dragProgress: CGFloat,
        toggleManager: HabitToggleManager,
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
        self.toggleManager = toggleManager
        self.getFilteredHabits = getFilteredHabits
        self.animateRings = animateRings
        self.isShownInHabitDetails = isShownInHabitDetails
        self.refreshTrigger = refreshTrigger
        self.habitColor = habitColor
    }
    
    var body: some View {
        TabView(selection: $focusedMonth) {
            ForEach(months) { month in
                monthViewContainer(for: month)
                    .tag(month as Month?)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .disabled(isDragging)
        .frame(height: Constants.monthHeight)
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { newValue in
            calendarWidth = newValue
        }
        .onChange(of: focusedMonth) { oldValue, newValue in
            guard !isInternalUpdate else { return }
            handleMonthChange(newValue: newValue)
        }
        .onChange(of: selection) { oldValue, newValue in
            guard !isInternalUpdate else { return }
            handleSelectionChange(newValue: newValue)
        }
        .onChange(of: dragProgress) { oldValue, newValue in
            handleDragProgressChange(newValue: newValue)
        }
        .onAppear {
            initializeMonths()
        }
    }
    
    // MARK: - Initialization
    
    private func initializeMonths() {
        let initialDate = selection ?? Date()
        
        // Create current month based on the focused week or selection
        let creationDate = focused.days.last ?? initialDate
        let currentMonth = Month(from: creationDate, order: .current)
        
        // Create previous and next months
        let previousMonth = currentMonth.previousMonth
        let nextMonth = currentMonth.nextMonth
        
        months = [previousMonth, currentMonth, nextMonth].compactMap { $0 }
        
        // Set initial focused month
        isInternalUpdate = true
        focusedMonth = currentMonth
        
        // Update title
        title = Calendar.monthAndYear(from: creationDate)
        
        // Ensure we have a valid selection
        if selection == nil {
            selection = initialDate
        }
        
        isInternalUpdate = false
    }
    
    // MARK: - Month Change Handler
    
    private func handleMonthChange(newValue: Month?) {
        guard let newMonth = newValue else { return }
        
        isInternalUpdate = true
        
        // Update title with a date from the middle of the month to avoid confusion
        let calendar = Calendar.current
        let titleDate = newMonth.weeks.flatMap(\.days).first { date in
            let day = calendar.component(.day, from: date)
            return day >= 10 && day <= 20
        } ?? newMonth.weeks.first?.days.first ?? Date()
        
        title = Calendar.monthAndYear(from: titleDate)
        
        // Update selection if enabled
        if changeSelectionOnWeekSwipe && !isDragging {
            updateSelectionForNewMonth(newMonth)
        }
        
        // Update focused week to match the selection or the first week of the month
        if let selection = selection,
           let matchingWeek = newMonth.weeks.first(where: { $0.days.contains(where: { calendar.isDate($0, inSameDayAs: selection) }) }) {
            focused = matchingWeek
        } else if let firstWeek = newMonth.weeks.first {
            focused = firstWeek
        }
        
        isInternalUpdate = false
    }
    
    private func updateSelectionForNewMonth(_ newMonth: Month) {
        let calendar = Calendar.current
        
        // Try to maintain the same day of month
        if let currentSelection = selection {
            let currentDay = calendar.component(.day, from: currentSelection)
            
            // Find the same day number in the new month
            if let sameDay = newMonth.weeks.flatMap(\.days).first(where: { date in
                calendar.component(.day, from: date) == currentDay
            }) {
                selection = sameDay
            } else {
                // If the day doesn't exist (e.g., Feb 30), use the last day of the month
                let monthDays = newMonth.weeks.flatMap(\.days)
                let middleMonthDate = monthDays.first { date in
                    calendar.component(.day, from: date) == 15
                } ?? monthDays.first
                
                if let middleMonthDate = middleMonthDate {
                    let lastDayOfMonth = monthDays.filter { date in
                        calendar.component(.month, from: date) == calendar.component(.month, from: middleMonthDate)
                    }.max()
                    selection = lastDayOfMonth ?? middleMonthDate
                }
            }
        }
    }
    
    // MARK: - Selection Change Handler
    
    private func handleSelectionChange(newValue: Date?) {
        guard let date = newValue else { return }
        
        let calendar = Calendar.current
        
        // Find the week containing this date
        if let week = months.flatMap(\.weeks).first(where: { $0.days.contains(where: { calendar.isDate($0, inSameDayAs: date) }) }) {
            if focused.id != week.id {
                isInternalUpdate = true
                focused = week
                
                // Update title if needed
                title = Calendar.monthAndYear(from: date)
                
                isInternalUpdate = false
            }
        }
    }
    
    // MARK: - Drag Progress Handler
    
    private func handleDragProgressChange(newValue: CGFloat) {
        guard newValue == 1 else { return }
        
        // When drag is complete, sync focused week with selection
        if let selection = selection,
           let currentMonth = focusedMonth,
           currentMonth.weeks.flatMap(\.days).contains(where: { Calendar.current.isDate($0, inSameDayAs: selection) }),
           let newFocus = currentMonth.weeks.first(where: { $0.days.contains(where: { Calendar.current.isDate($0, inSameDayAs: selection) }) }) {
            focused = newFocus
        }
    }
    
    // MARK: - Dynamic Month Loading
    
    private func loadMonth(from month: Month) {
        // Load previous month
        if month.order == .previous, months.first?.id == month.id, let previousMonth = month.previousMonth {
            // Check if valid (if habitManager is loaded)
            if !habitManager.isLoaded {
                months.insert(previousMonth, at: 0)
            } else {
                let allDaysInPreviousMonth = previousMonth.weeks.flatMap(\.days)
                let hasValidDays = allDaysInPreviousMonth.contains { !habitManager.isDateBeforeEarliest($0) }
                
                if hasValidDays {
                    months.insert(previousMonth, at: 0)
                }
            }
        }
        
        // Load next month
        if month.order == .next, months.last?.id == month.id, let nextMonth = month.nextMonth {
            months.append(nextMonth)
        }
    }
    
    // MARK: - View Helpers
    
    @ViewBuilder
    private func monthViewContainer(for month: Month) -> some View {
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
                toggleManager: toggleManager,
                isShownInHabitDetails: isShownInHabitDetails,
                habitColor: habitColor
            )
            .offset(y: (1 - dragProgress) * verticalOffset(for: month))
            .frame(width: calendarWidth, height: Constants.monthHeight)
            .onAppear { loadMonth(from: month) }
        }
    }
    
    private func verticalOffset(for month: Month) -> CGFloat {
        guard let index = month.weeks.firstIndex(where: { $0 == focused }) else { return .zero }
        let height = Constants.monthHeight / CGFloat(month.weeks.count)
        return CGFloat(month.weeks.count - 1) / 2 * height - CGFloat(index) * height
    }
}
