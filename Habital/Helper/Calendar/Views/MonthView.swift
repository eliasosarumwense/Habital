import SwiftUI

enum Constants {
    static let dayHeight: CGFloat = 48
    static let monthHeight: CGFloat = 48 * 5
}

struct MonthView: View {
    let month: Month
    let dragProgress: CGFloat
    @Binding var isDragging: Bool
    
    // Add the new parameters
    let getFilteredHabits: (Date) -> [Habit]
    let animateRings: Bool
    let refreshTrigger: UUID // Add the refresh trigger parameter
    
    @Binding var focused: Week
    @Binding var selectedDate: Date?
    
    let isShownInHabitDetails: Bool?
    let habitColor: Color?
    
    var body: some View {
        VStack(spacing: .zero) {
            ForEach(month.weeks) { week in
                WeekView(
                    week: week,
                    selectedDate: $selectedDate,
                    dragProgress: dragProgress,
                    hideDifferentMonth: true,
                    getFilteredHabits: getFilteredHabits,
                    animateRings: animateRings,
                    isDragging: $isDragging,
                    refreshTrigger: refreshTrigger, // Pass the refresh trigger
                    isShownInHabitDetails: isShownInHabitDetails,
                    habitColor: habitColor
                )
                .opacity(focused == week ? 1 : dragProgress)
                .frame(height: Constants.monthHeight / CGFloat(month.weeks.count))
            }
        }
    }
}
