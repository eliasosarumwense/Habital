import SwiftUI

struct WeekCalendarView: View {
    @Binding var isDragging: Bool
    @EnvironmentObject var habitManager: HabitPreloadManager
    
    let getFilteredHabits: (Date) -> [Habit]
    let animateRings: Bool
    let refreshTrigger: UUID
    
    @ObservedObject var toggleManager: HabitToggleManager
    
    @Binding var title: String
    @Binding var focused: Week
    @Binding var selection: Date?
    
    @AppStorage("changeSelectionOnWeekSwipe") private var changeSelectionOnWeekSwipe = true
    
    @State private var weeks: [Week] = []
    @State private var calendarWidth: CGFloat = UIScreen.main.bounds.width
    @State private var isInternalUpdate = false
    
    let habitColor: Color?
    
    init(
        _ title: Binding<String>,
        selection: Binding<Date?>,
        focused: Binding<Week>,
        isDragging: Binding<Bool>,
        toggleManager: HabitToggleManager,
        getFilteredHabits: @escaping (Date) -> [Habit] = { _ in [] },
        animateRings: Bool = false,
        refreshTrigger: UUID = UUID(),
        habitColor: Color? = nil
    ) {
        _title = title
        _focused = focused
        _selection = selection
        _isDragging = isDragging
        self.toggleManager = toggleManager
        self.getFilteredHabits = getFilteredHabits
        self.animateRings = animateRings
        self.refreshTrigger = refreshTrigger
        self.habitColor = habitColor
    }
    
    var body: some View {
        TabView(selection: $focused) {
            ForEach(weeks) { week in
                WeekView(
                    week: week,
                    selectedDate: $selection,
                    dragProgress: .zero,
                    getFilteredHabits: getFilteredHabits,
                    animateRings: animateRings,
                    isDragging: $isDragging,
                    toggleManager: toggleManager,
                    refreshTrigger: refreshTrigger,
                    isShownInHabitDetails: nil,
                    habitColor: habitColor
                )
                .frame(height: Constants.dayHeight)
                .tag(week)
                .onAppear { loadWeek(from: week) }
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .disabled(isDragging)
        .frame(height: Constants.dayHeight)
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { newValue in
            calendarWidth = newValue
        }
        .onChange(of: focused) { oldValue, newValue in
            guard !isInternalUpdate else { return }
            handleFocusedWeekChange(oldValue: oldValue, newValue: newValue)
        }
        .onChange(of: selection) { oldValue, newValue in
            guard !isInternalUpdate else { return }
            handleSelectionChange(newValue: newValue)
        }
        .onAppear {
            initializeWeeks()
        }
    }
    
    // MARK: - Initialization
    
    private func initializeWeeks() {
        let calendar = Calendar.current
        let initialDate = selection ?? Date()
        
        // Create the current week
        let nearestMonday = Calendar.nearestMonday(from: initialDate)
        let currentWeekDays = Calendar.currentWeek(from: nearestMonday)
        let currentWeek = Week(days: currentWeekDays, order: .current)
        
        // Create previous and next weeks
        let previousWeek: Week
        if let firstDay = currentWeekDays.first,
           let prevWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: firstDay) {
            previousWeek = Week(days: Calendar.currentWeek(from: Calendar.nearestMonday(from: prevWeekStart)), order: .previous)
        } else {
            // Fallback
            let fallbackDate = calendar.date(byAdding: .weekOfYear, value: -1, to: initialDate) ?? initialDate
            previousWeek = Week(days: Calendar.currentWeek(from: Calendar.nearestMonday(from: fallbackDate)), order: .previous)
        }
        
        let nextWeek: Week
        if let lastDay = currentWeekDays.last,
           let nextWeekStart = calendar.date(byAdding: .weekOfYear, value: 1, to: lastDay) {
            nextWeek = Week(days: Calendar.currentWeek(from: Calendar.nearestMonday(from: nextWeekStart)), order: .next)
        } else {
            // Fallback
            let fallbackDate = calendar.date(byAdding: .weekOfYear, value: 1, to: initialDate) ?? initialDate
            nextWeek = Week(days: Calendar.currentWeek(from: Calendar.nearestMonday(from: fallbackDate)), order: .next)
        }
        
        weeks = [previousWeek, currentWeek, nextWeek]
        
        // Set initial focused week
        isInternalUpdate = true
        focused = currentWeek
        
        // Update title
        if let lastDay = currentWeekDays.last {
            title = Calendar.monthAndYear(from: lastDay)
        }
        
        // Ensure we have a valid selection
        if selection == nil {
            selection = initialDate
        }
        
        isInternalUpdate = false
    }
    
    // MARK: - Focused Week Change Handler
    
    private func handleFocusedWeekChange(oldValue: Week, newValue: Week) {
        guard oldValue.id != newValue.id else { return }
        
        isInternalUpdate = true
        
        // Update title
        if let lastDay = newValue.days.last {
            title = Calendar.monthAndYear(from: lastDay)
        }
        
        // Update selection if enabled - always try to maintain same weekday when setting changes
        if changeSelectionOnWeekSwipe {
            updateSelectionForNewWeek(newWeek: newValue, oldWeek: oldValue)
        }
        
        isInternalUpdate = false
    }
    
    private func updateSelectionForNewWeek(newWeek: Week, oldWeek: Week) {
        let calendar = Calendar.current
        
        // Try to maintain the same day of week (weekday)
        if let currentSelection = selection,
           let currentWeekday = calendar.dateComponents([.weekday], from: currentSelection).weekday,
           let matchingDay = newWeek.days.first(where: { 
               calendar.dateComponents([.weekday], from: $0).weekday == currentWeekday 
           }) {
            // Found matching weekday in new week
            selection = matchingDay
        } else {
            // Fallback: determine direction and select Monday or Sunday
            if let oldFirstDay = oldWeek.days.first,
               let newFirstDay = newWeek.days.first {
                if newFirstDay < oldFirstDay {
                    // Moving backward, select Sunday
                    selection = newWeek.days.last
                } else {
                    // Moving forward, select Monday
                    selection = newWeek.days.first
                }
            } else {
                // Default to Monday
                selection = newWeek.days.first
            }
        }
    }
    
    // MARK: - Selection Change Handler
    
    private func handleSelectionChange(newValue: Date?) {
        guard let date = newValue else { return }
        
        // Find the week containing this date
        if let week = weeks.first(where: { $0.days.contains(where: { Calendar.current.isDate($0, inSameDayAs: date) }) }) {
            if focused.id != week.id {
                isInternalUpdate = true
                focused = week
                
                if let lastDay = week.days.last {
                    title = Calendar.monthAndYear(from: lastDay)
                }
                isInternalUpdate = false
            }
        }
    }
    
    // MARK: - Dynamic Week Loading
    
    private func loadWeek(from week: Week) {
        let calendar = Calendar.current
        
        // Load previous week
        if week.order == .previous, weeks.first?.id == week.id {
            if let firstDay = week.days.first,
               let prevWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: firstDay) {
                let previousWeek = Week(
                    days: Calendar.currentWeek(from: Calendar.nearestMonday(from: prevWeekStart)),
                    order: .previous
                )
                
                // Check if valid (if habitManager is loaded)
                if !habitManager.isLoaded || habitManager.weekHasValidDays(previousWeek) {
                    weeks.insert(previousWeek, at: 0)
                }
            }
        }
        
        // Load next week
        if week.order == .next, weeks.last?.id == week.id {
            if let lastDay = week.days.last,
               let nextWeekStart = calendar.date(byAdding: .weekOfYear, value: 1, to: lastDay) {
                let nextWeek = Week(
                    days: Calendar.currentWeek(from: Calendar.nearestMonday(from: nextWeekStart)),
                    order: .next
                )
                weeks.append(nextWeek)
            }
        }
    }
}
