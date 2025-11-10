//
//  DetailedHistoryView.swift
//  Habital
//
//  Created by Assistant on 01.11.25.
//

import SwiftUI
import CoreData

// MARK: - Date Formatting Helpers
private func formatFullDate(_ date: Date?) -> String {
    guard let date = date else { return "Unknown Date" }
    let formatter = DateFormatter()
    formatter.dateStyle = .full
    return formatter.string(from: date)
}


private func formatTime(_ date: Date?) -> String {
    guard let date = date else { return "Unknown Time" }
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    return formatter.string(from: date)
}

private func formatFullDateTime(_ date: Date?) -> String {
    guard let date = date else { return "Unknown Date" }
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter.string(from: date)
}



private func formatYear(_ date: Date?) -> String {
    guard let date = date else { return "Unknown Year" }
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy"
    return formatter.string(from: date)
}

private func formatMonth(_ date: Date?) -> String {
    guard let date = date else { return "Unknown Month" }
    let formatter = DateFormatter()
    formatter.dateFormat = "MMMM yyyy"
    return formatter.string(from: date)
}


private func formatShortDate(_ date: Date?) -> String {
    guard let date = date else { return "Unknown" }
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d"
    return formatter.string(from: date)
}




private func formatDayNumber(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "d"
    return formatter.string(from: date)
}



private func isDayCompleted(completions: [Completion], habit: Habit) -> Bool {
    let validCompletions = completions.filter { $0.completed }
    let requiredRepetitions = habit.currentRepeatsPerDay(on: Date())
    return validCompletions.count >= max(1, requiredRepetitions)
}

private func isDaySkipped(completions: [Completion]) -> Bool {
    return completions.contains { $0.skipped }
}


struct DetailedHistoryView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    
    let habit: Habit
    let habitColor: Color
    let onCompletionDeleted: () -> Void
    
    // State for managing deletion
    @State private var showingDeleteConfirmation = false
    @State private var completionToDelete: Completion?
    
    // Cache for grouped completions to improve performance
    @State private var cachedGroupedCompletions: [String: [String: [Date: [Completion]]]]? = nil
    @State private var lastCompletionCount: Int = 0
    

    
    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        if let completions = habit.completion as? Set<Completion>, !completions.isEmpty {
                            let groupedCompletions = getGroupedCompletions(completions)
                            
                            ForEach(Array(groupedCompletions.keys.sorted(by: >)), id: \.self) { year in
                                if let yearData = groupedCompletions[year] {
                                    // Year Header (not sticky anymore)
                                    YearHeaderView(year: year)
                                        .id("year-\(year)")
                                    
                                    ForEach(Array(yearData.keys.sorted(by: { month1, month2 in
                                        // Sort months chronologically within each year
                                        let formatter = DateFormatter()
                                        formatter.dateFormat = "MMMM yyyy"
                                        let date1 = formatter.date(from: month1) ?? Date.distantPast
                                        let date2 = formatter.date(from: month2) ?? Date.distantPast
                                        return date1 > date2
                                    })), id: \.self) { month in
                                        if let monthData = yearData[month] {
                                            Section {
                                                // Timeline container for the month
                                                TimelineContainerView(
                                                    yearData: monthData,
                                                    habit: habit,
                                                    habitColor: habitColor,
                                                    onDeleteCompletion: { completion in
                                                        completionToDelete = completion
                                                        showingDeleteConfirmation = true
                                                    }
                                                )
                                            } header: {
                                                MonthHeaderView(month: month)
                                                    .id("month-\(year)-\(month)")
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        else {
                            // Empty state
                            VStack(spacing: 24) {
                                // Empty state icon
                                ZStack {
                                    Circle()
                                        .fill(habitColor.opacity(0.1))
                                        .frame(width: 120, height: 120)
                                    
                                    Image(systemName: habit.isBadHabit ? "shield.checkered" : "calendar.badge.plus")
                                        .font(.system(size: 40, weight: .light))
                                        .foregroundColor(habitColor.opacity(0.6))
                                }
                                .padding(.top, 60)
                                
                                VStack(spacing: 12) {
                                    if !habit.isBadHabit {
                                        Text("No Completions Yet")
                                            .font(.customFont("Lexend", .semiBold, 24))
                                            .foregroundColor(.primary)
                                        
                                        Text("Complete this habit to see your progress history here")
                                            .font(.customFont("Lexend", .regular, 16))
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal, 40)
                                    } else {
                                        Text("Clean Slate")
                                            .font(.customFont("Lexend", .semiBold, 24))
                                            .foregroundColor(.primary)
                                        
                                        Text("Keep going strong! Any lapses will be recorded here")
                                            .font(.customFont("Lexend", .regular, 16))
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal, 40)
                                    }
                                }
                                
                                Spacer()
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 10)
                }
            }
            .navigationBarTitle(Text("\(habit.name ?? "Habit") History"), displayMode: .inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Back")
                                .font(.customFont("Lexend", .medium, 17))
                        }
                        .foregroundColor(.primary)
                    }
                }
            }
        }
        
        .alert("Delete Entry", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                completionToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let completion = completionToDelete {
                    deleteCompletion(completion)
                }
                completionToDelete = nil
            }
        } message: {
            if !habit.isBadHabit {
                Text("Are you sure you want to delete this completion? This action cannot be undone.")
            } else {
                Text("Are you sure you want to delete this lapse record? This action cannot be undone.")
            }
        }
    }
    
    // Cached grouping method for better performance
    private func getGroupedCompletions(_ completions: Set<Completion>) -> [String: [String: [Date: [Completion]]]] {
        let currentCount = completions.count
        
        // Return cached result if completions haven't changed
        if let cached = cachedGroupedCompletions, lastCompletionCount == currentCount {
            return cached
        }
        
        // Recalculate and cache
        let grouped = groupCompletionsByYearAndDate(completions)
        cachedGroupedCompletions = grouped
        lastCompletionCount = currentCount
        
        return grouped
    }
    
    // Group completions by year, month, and date, including missed days
    private func groupCompletionsByYearAndDate(_ completions: Set<Completion>) -> [String: [String: [Date: [Completion]]]] {
        let calendar = Calendar.current
        var yearGroups: [String: [String: [Date: [Completion]]]] = [:]
        
        // First, add all actual completions
        for completion in completions {
            guard let completionDate = completion.date else { continue }
            
            let year = formatYear(completionDate)
            let month = formatMonth(completionDate)
            let dayStart = calendar.startOfDay(for: completionDate)
            
            if yearGroups[year] == nil {
                yearGroups[year] = [:]
            }
            
            if yearGroups[year]![month] == nil {
                yearGroups[year]![month] = [:]
            }
            
            if yearGroups[year]![month]![dayStart] == nil {
                yearGroups[year]![month]![dayStart] = []
            }
            
            yearGroups[year]![month]![dayStart]?.append(completion)
        }
        
        // Add missed days for active habits (excluding bad habits)
        if !habit.isBadHabit {
            addMissedDaysToGroups(&yearGroups, calendar: calendar)
        }
        
        // Sort completions within each day by time
        for (year, monthGroups) in yearGroups {
            for (month, dateGroups) in monthGroups {
                for (day, completionsForDay) in dateGroups {
                    yearGroups[year]![month]![day] = completionsForDay.sorted { completion1, completion2 in
                        let date1 = completion1.loggedAt ?? completion1.date ?? Date.distantPast
                        let date2 = completion2.loggedAt ?? completion2.date ?? Date.distantPast
                        return date1 > date2 // Most recent first
                    }
                }
            }
        }
        
        return yearGroups
    }
    
    // Add missed days to the groups for active habits
    private func addMissedDaysToGroups(_ yearGroups: inout [String: [String: [Date: [Completion]]]], calendar: Calendar) {
        // Only show dates with actual completions
        return
    }
    
    // Check if habit should have been completed on a specific date
    private func shouldHabitBeCompletedOnDate(_ date: Date) -> Bool {
        guard let createdDate = habit.startDate,
              date >= Calendar.current.startOfDay(for: createdDate),
              date <= Calendar.current.startOfDay(for: Date()) else {
            return false
        }
        
        // Check if habit was active on this date based on active days
        return HabitUtilities.isHabitActive(habit: habit, on: date)
    }
    
    // Group completions by date (legacy method, kept for compatibility)
    private func groupCompletionsByDate(_ completions: Set<Completion>) -> [Date: [Completion]] {
        let calendar = Calendar.current
        var grouped: [Date: [Completion]] = [:]
        
        for completion in completions {
            guard let completionDate = completion.date else { continue }
            let dayStart = calendar.startOfDay(for: completionDate)
            
            if grouped[dayStart] == nil {
                grouped[dayStart] = []
            }
            grouped[dayStart]?.append(completion)
        }
        
        // Sort completions within each day by time
        for (day, completionsForDay) in grouped {
            grouped[day] = completionsForDay.sorted { completion1, completion2 in
                let date1 = completion1.loggedAt ?? completion1.date ?? Date.distantPast
                let date2 = completion2.loggedAt ?? completion2.date ?? Date.distantPast
                return date1 > date2 // Most recent first
            }
        }
        
        return grouped
    }
    
    // Delete a completion
    private func deleteCompletion(_ completion: Completion) {
        withAnimation(.easeOut(duration: 0.3)) {
            viewContext.delete(completion)
            
            // Clear cache since completions changed
            cachedGroupedCompletions = nil
            
            // Update habit's total completions count
            habit.totalCompletions = max(0, habit.totalCompletions - 1)
            
            // Update habit's last completion date if needed
            updateLastCompletionDateIfNeeded(deletedCompletion: completion)
            
            do {
                try viewContext.save()
                onCompletionDeleted()
                
                // Send notifications for UI updates
                NotificationCenter.default.post(
                    name: NSNotification.Name("HabitUIRefreshNeeded"),
                    object: habit,
                    userInfo: ["completionDeleted": true]
                )
            } catch {
                print("Failed to delete completion: \(error)")
                viewContext.rollback()
            }
        }
    }
    
    // Helper method to update last completion date when needed
    private func updateLastCompletionDateIfNeeded(deletedCompletion: Completion) {
        guard let deletedDate = deletedCompletion.date else { return }
        
        if let currentLastDate = habit.lastCompletionDate,
           Calendar.current.isDate(deletedDate, inSameDayAs: currentLastDate) {
            
            if let completions = habit.completion as? Set<Completion>,
               !completions.isEmpty {
                let remainingCompletions = completions.filter { $0 != deletedCompletion && $0.completed }
                
                if let newLastDate = remainingCompletions.compactMap({ $0.date }).max() {
                    habit.lastCompletionDate = newLastDate
                } else {
                    habit.lastCompletionDate = nil
                }
            } else {
                habit.lastCompletionDate = nil
            }
        }
    }
}

// MARK: - Year Header View
struct YearHeaderView: View {
    let year: String
    
    var body: some View {
        HStack {
            Text(year)
                .font(.customFont("Lexend", .bold, 20))
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.clear)
    }
}

// MARK: - Month Header View
struct MonthHeaderView: View {
    let month: String
    
    var body: some View {
        HStack {
            Text(month)
                .font(.customFont("Lexend", .semiBold, 16))
                .foregroundColor(.primary)
                .padding(.leading, 10)
            
            Spacer()
        }
        //.padding(.horizontal, 16)
        .padding(.vertical, 8)
        .glassBackground()
    }
}

// MARK: - Timeline Container View
struct TimelineContainerView: View {
    let yearData: [Date: [Completion]]
    let habit: Habit
    let habitColor: Color
    let onDeleteCompletion: (Completion) -> Void
    
    var body: some View {
        let sortedDates = Array(yearData.keys.sorted(by: >))
        
        ZStack(alignment: .leading) {
            // Continuous timeline line
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.secondary.opacity(0.15))
                    .frame(width: 1)
            }
            .padding(.leading, 20) // Align with dot centers (16 + 4 for dot center)
            
            // Content with timeline dots
            LazyVStack(spacing: 0) {
                ForEach(Array(sortedDates.enumerated()), id: \.element) { index, date in
                    if let dayCompletions = yearData[date] {
                        TimelineDateSectionView(
                            date: date,
                            completions: dayCompletions,
                            habit: habit,
                            habitColor: habitColor,
                            isFirst: index == 0,
                            isLast: index == sortedDates.count - 1,
                            onDeleteCompletion: onDeleteCompletion
                        )
                        .id("date-\(date.timeIntervalSince1970)")
                    }
                }
            }
        }
        .padding(.vertical)
    }
}

// MARK: - Timeline Date Section View
struct TimelineDateSectionView: View {
    let date: Date
    let completions: [Completion]
    let habit: Habit
    let habitColor: Color
    let isFirst: Bool
    let isLast: Bool
    let onDeleteCompletion: (Completion) -> Void
    
    private var dayCompleted: Bool {
        isDayCompleted(completions: completions, habit: habit)
    }
    
    private var daySkipped: Bool {
        isDaySkipped(completions: completions)
    }
    
    private var dayMissed: Bool {
        // Since we're only showing dates with actual completions, this should always be false
        return false
    }
    
    private var hasTriggersForDay: Bool {
        guard habit.isBadHabit else { return false }
        return completions.contains { completion in
            guard completion.completed else { return false }
            guard let trigger = completion.trigger else { return false }
            guard let triggerName = trigger.name else { return false }
            return !triggerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Date header with dot and status - all aligned horizontally
            HStack(alignment: .center, spacing: 0) {
                // Timeline dot - always centered in a fixed frame
                ZStack {
                    Circle()
                        .fill(
                            dayCompleted ? (habit.isBadHabit ? Color.red : Color.green) :
                            daySkipped ? Color.orange :
                            dayMissed ? Color.red :
                            Color.secondary.opacity(0.3)
                        )
                        .frame(width: dayCompleted ? 8 : (dayMissed ? 6 : 6), height: dayCompleted ? 8 : (dayMissed ? 6 : 6))
                        .scaleEffect(dayCompleted ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: dayCompleted)
                }
                .frame(width: 8, height: 8) // Fixed frame to center all dots consistently
                
                // Date text aligned with dot
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(formatShortDate(date))
                            .font(.customFont("Lexend", .medium, 15))
                            .foregroundColor(.primary)
                        
                        Text(formatDayOfWeek(date))
                            .font(.customFont("Lexend", .regular, 11))
                            .foregroundColor(.secondary)
                    }
                    .padding(.leading, 16) // Space between dot and text
                    
                    Spacer()
                    
                    // Status indicator
                    if dayCompleted {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(habit.isBadHabit ? Color.red : Color.green)
                                .frame(width: 6, height: 6)
                            
                            if habit.isBadHabit {
                                Text("Lapsed")
                                    .font(.customFont("Lexend", .medium, 11))
                                    .foregroundColor(.red)
                            } else {
                                Text("Complete")
                                    .font(.customFont("Lexend", .medium, 11))
                                    .foregroundColor(.green)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill((habit.isBadHabit ? Color.red : Color.green).opacity(0.1))
                        )
                    } else if daySkipped {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 6, height: 6)
                            Text("Skipped")
                                .font(.customFont("Lexend", .medium, 11))
                                .foregroundColor(.orange)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.orange.opacity(0.1))
                        )
                    } else if dayMissed {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 6, height: 6)
                            Text("Not completed")
                                .font(.customFont("Lexend", .medium, 11))
                                .foregroundColor(.red)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.red.opacity(0.1))
                        )
                    }
                }
                .padding(.trailing, 16)
            }
            .padding(.leading, 16) // Left padding for the entire row
            .padding(.top, isFirst ? 0 : (dayCompleted ? 6 : 10)) // Padding applied to entire section
            
            // Completions
            if !completions.isEmpty {
                // Regular completion cards
                VStack(spacing: 6) {
                    ForEach(Array(completions.enumerated()), id: \.element.id) { index, completion in
                        CompletionCardView(
                            completion: completion,
                            habit: habit,
                            habitColor: habitColor,
                            repetitionNumber: completions.count - index, // Show newest first
                            onDelete: {
                                onDeleteCompletion(completion)
                            }
                        )
                        .id("completion-\(completion.objectID)")
                    }
                }
                .padding(.leading, 36) // Align cards with text content (20 for dot center + 16 for spacing)
                .padding(.trailing, 16)
                .padding(.bottom, isLast ? 0 : 12)
            }
        }
    }
}

// MARK: - Completion Card View
struct CompletionCardView: View {
    let completion: Completion
    let habit: Habit
    let habitColor: Color
    let repetitionNumber: Int
    let onDelete: () -> Void
    
    private var completionTime: String {
        // Show when the habit was actually completed (date field)
        if let date = completion.date {
            return formatTime(date)
        }
        return "Unknown"
    }
    
    private var displayTime: String {
        // Show appropriate status text based on completion state
        if completion.skipped {
            return "Skipped"
        } else if completion.completed {
            // Show time only if tracksTime is true and date is available
            if completion.tracksTime && completion.date != nil {
                return completionTime
            } else {
                return habit.isBadHabit ? "Lapsed" : "Completed"
            }
        }
        return "Unknown"
    }
    
    private var loggedTime: String {
        // Show when the user logged this completion
        if let loggedAt = completion.loggedAt {
            return formatTime(loggedAt)
        }
        return ""
    }
    
    private var isLoggedOnDifferentDay: Bool {
        guard let completionDate = completion.date,
              let loggedDate = completion.loggedAt else { return false }
        
        let calendar = Calendar.current
        return !calendar.isDate(completionDate, inSameDayAs: loggedDate)
    }
    
    private var loggedDateString: String {
        guard let loggedAt = completion.loggedAt else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: loggedAt)
    }
    
    private var isTimeTracked: Bool {
        completion.duration > 0
    }
    
    private var shouldShowTimeStyle: Bool {
        // Show time-style formatting when we're displaying an actual time (based on tracksTime)
        return completion.completed && completion.tracksTime && completion.date != nil && !completion.skipped
    }
    
    private var hasNotes: Bool {
        if let notes = completion.notes {
            return !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return false
    }
    
    private var hasTrigger: Bool {
        guard let trigger = completion.trigger else { return false }
        guard let triggerName = trigger.name else { return false }
        return !triggerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var triggerText: String? {
        guard let trigger = completion.trigger else { return nil }
        guard let triggerName = trigger.name else { return nil }
        let trimmedTrigger = triggerName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedTrigger.isEmpty ? nil : trimmedTrigger
    }
    
    private var triggerIcon: String {
        return completion.trigger?.icon ?? "exclamationmark.triangle.fill"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Status indicator
                ZStack {
                    let circleColor: Color = {
                        if completion.completed {
                            // Use secondary for both time-tracked and regular completions
                            if shouldShowTimeStyle || !habit.isBadHabit {
                                return Color.secondary.opacity(0.12)
                            }
                            // Only use red for bad habit lapses
                            return Color.red.opacity(0.12)
                        }
                        if completion.skipped {
                            return Color.orange.opacity(0.12)
                        }
                        return Color.secondary.opacity(0.08)
                    }()
                    
                    let iconName: String = {
                        if completion.completed {
                            // Show time icon if displaying actual time
                            if shouldShowTimeStyle {
                                return "clock.fill"
                            }
                            return habit.isBadHabit ? "xmark" : "checkmark"
                        }
                        if completion.skipped {
                            return "forward.fill"
                        }
                        return "circle"
                    }()
                    
                    let iconColor: Color = {
                        if completion.completed {
                            // Use secondary color for both time-tracked and regular completions
                            if shouldShowTimeStyle || !habit.isBadHabit {
                                return .secondary
                            }
                            // Only use red for bad habit lapses
                            return .red
                        }
                        if completion.skipped {
                            return .orange
                        }
                        return .secondary
                    }()
                    
                    Circle()
                        .fill(circleColor)
                        .frame(width: 28, height: 28)
                    
                    Image(systemName: iconName)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(iconColor)
                }
                
                // Main content
                VStack(alignment: .leading, spacing: 6) {
                    // Time and repetition info
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(displayTime)
                                .font(.customFont("Lexend", shouldShowTimeStyle ? .semiBold : .medium, shouldShowTimeStyle ? 17 : 16))
                                .foregroundColor(
                                    shouldShowTimeStyle ? .primary :
                                    completion.skipped ? Color.orange :
                                    (habit.isBadHabit && completion.completed) ? Color.red :
                                        Color.primary
                                )
                            
                            // Always show logged info underneath the main time/status
                            if isLoggedOnDifferentDay {
                                Text("Logged \(loggedDateString) at \(loggedTime)")
                                    .font(.customFont("Lexend", .regular, 12))
                                    .foregroundColor(.secondary.opacity(0.7))
                            } else if !loggedTime.isEmpty {
                                Text("Logged at \(loggedTime)")
                                    .font(.customFont("Lexend", .regular, 12))
                                    .foregroundColor(.secondary.opacity(0.7))
                            }
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 8) {
                            // Duration/Quantity display - minimal capsule
                            if completion.duration > 0 {
                                if isTimeTracked {
                                    // Time tracked habit - show duration with "min"
                                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                                        Text("\(completion.duration)")
                                            .font(.customFont("Lexend", .medium, 12))
                                            .foregroundColor(.secondary)
                                        
                                        Text("min")
                                            .font(.customFont("Lexend", .regular, 10))
                                            .foregroundColor(.secondary.opacity(0.7))
                                    }
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(
                                        Capsule()
                                            .fill(.ultraThinMaterial)
                                    )
                                } else {
                                    // Quantity habit - show the quantity number with capsule styling
                                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                                        Text("\(completion.duration)")
                                            .font(.customFont("Lexend", .medium, 12))
                                            .foregroundColor(.secondary)
                                        
                                        Text("qty")
                                            .font(.customFont("Lexend", .regular, 10))
                                            .foregroundColor(.secondary.opacity(0.7))
                                    }
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(
                                        Capsule()
                                            .fill(.ultraThinMaterial)
                                    )
                                }
                            }
                            
                            // Repetition number - minimal style
                            Text("#\(repetitionNumber)")
                                .font(.customFont("Lexend", .regular, 11))
                                .foregroundColor(.secondary.opacity(0.6))
                        }
                    }
                    
                    // Notes display moved to separate section
                }
            }
            
            // Notes and Triggers section (if available)
            if hasNotes || (hasTrigger && habit.isBadHabit) {
                VStack(spacing: 0) {
                    Divider()
                        .padding(.vertical, 6)
                    
                    HStack(alignment: .top, spacing: 12) {
                        // Trigger section (compact capsule on the left)
                        if hasTrigger && habit.isBadHabit && completion.completed,
                           let trigger = triggerText {
                            HStack(spacing: 4) {
                                Image(systemName: triggerIcon)
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(.red)
                                
                                Text(trigger)
                                    .font(.customFont("Lexend", .medium, 10))
                                    .foregroundColor(.red)
                                    .lineLimit(2)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.red.opacity(0.08))
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(Color.red.opacity(0.2), lineWidth: 1)
                                    )
                            )
                            .fixedSize()
                        }
                        
                        // Notes section (takes up available space)
                        if hasNotes, let notes = completion.notes {
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "text.alignleft")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .frame(width: 16, height: 16, alignment: .top)
                                    .padding(.top, 1)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Note")
                                        .font(.customFont("Lexend", .medium, 11))
                                        .foregroundColor(.secondary)
                                    
                                    Text(notes)
                                        .font(.customFont("Lexend", .regular, 13))
                                        .foregroundColor(.primary)
                                        .lineLimit(nil)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                
                                Spacer(minLength: 0)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.secondary.opacity(0.06))
                            )
                        }
                    }
                }
            }
        }
        .padding(12)
        .glassBackground()
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete Entry", systemImage: "trash")
            }
        }
    }
}

struct DetailedHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let habit = Habit(context: context)
        habit.name = "Example Habit"
        habit.id = UUID()
        
        let uiColor = UIColor.systemBlue
        if let colorData = try? NSKeyedArchiver.archivedData(withRootObject: uiColor, requiringSecureCoding: false) {
            habit.color = colorData
        }
        
        return DetailedHistoryView(
            habit: habit,
            habitColor: .blue,
            onCompletionDeleted: {}
        )
        .environment(\.managedObjectContext, context)
    }
}
