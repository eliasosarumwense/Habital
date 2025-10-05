import SwiftUI

import SwiftUI

struct WeekView: View {
    let week: Week
    let dragProgress: CGFloat
    let hideDifferentMonth: Bool
    
    // Add the new parameters
    let getFilteredHabits: (Date) -> [Habit]
    let animateRings: Bool
    let refreshTrigger: UUID // Add refresh trigger parameter
    @Binding var isDragging: Bool
    
    @Binding var selectedDate: Date?
    
    let isShownInHabitDetails: Bool?
    let habitColor: Color?
    
    init(
        week: Week,
        selectedDate: Binding<Date?>,
        dragProgress: CGFloat,
        hideDifferentMonth: Bool = false,
        getFilteredHabits: @escaping (Date) -> [Habit] = { _ in [] },
        animateRings: Bool = false,
        isDragging: Binding<Bool>,
        refreshTrigger: UUID = UUID(), // Add parameter with default value
        isShownInHabitDetails: Bool? = nil,
        habitColor: Color? = nil
    ) {
        self.week = week
        self.dragProgress = dragProgress
        self.hideDifferentMonth = hideDifferentMonth
        self.getFilteredHabits = getFilteredHabits
        self.animateRings = animateRings
        self.refreshTrigger = refreshTrigger // Store the refresh trigger
        _selectedDate = selectedDate
        _isDragging = isDragging
        self.isShownInHabitDetails = isShownInHabitDetails
        self.habitColor = habitColor
    }
    
    var body: some View {
        HStack(spacing: .zero) {
            ForEach(week.days, id: \.self) { date in
                DayView(
                    date: date,
                    selectedDate: $selectedDate,
                    getFilteredHabits: getFilteredHabits,
                    animateRings: animateRings,
                    isDragging: $isDragging,
                    refreshTrigger: refreshTrigger, // Pass the refresh trigger
                    isShownInHabitDetails: isShownInHabitDetails,
                    habitColor: habitColor
                )
                .opacity(isDayVisible(for: date) ? 1 : (1 - dragProgress))
                .frame(maxWidth: .infinity)
                
                if week.days.last != date {
                    Spacer()
                }
            }
        }
        .padding(.horizontal)
    }
    
    private func isDayVisible(for date: Date) -> Bool {
        guard hideDifferentMonth else { return true }
        
        switch week.order {
        case .previous, .current:
            guard let last = week.days.last else { return true }
            return Calendar.isSameMonth(date, last)
        case .next:
            guard let first = week.days.first else { return true }
            return Calendar.isSameMonth(date, first)
        }
    }
}
