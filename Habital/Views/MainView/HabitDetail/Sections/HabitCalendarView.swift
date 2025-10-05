//
//  HabitDetailCalendarView.swift
//  Habital
//
//  Created by Elias Osarumwense on 16.04.25.
//

import SwiftUI
import CoreData

struct CalendarAndCompletionView: View {
    let habit: Habit
    @Binding var selectedCalendarDate: Date?
    @Binding var calendarTitle: String
    @Binding var focusedWeek: Week
    @Binding var isDraggingCalendar: Bool
    @Binding var calendarDragProgress: CGFloat
    
    let getFilteredHabitsForDate: (Date) -> [Habit]
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    
    @StateObject private var toggleManager = HabitToggleManager(context: PersistenceController.shared.container.viewContext)
    
    // State for tracking completions when repeatsPerDay > 1
    @State private var completedRepeats: Int = 0
    @State private var refreshID = UUID() // For forcing UI updates
    
    @State private var buttonRefreshID = UUID()
    @State private var showingAllCompletions = false
    
    @State private var calendarRefreshTrigger = UUID()
    
    @Binding var refreshTrigger: Bool
    
    // NEW: State for managing deletion confirmations
    @State private var showingDeleteConfirmation = false
    @State private var completionToDelete: Completion?
    
    // Extract the habit color or use a default
    private var habitColor: Color {
        if let colorData = habit.color,
           let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
            return Color(uiColor)
        }
        return .blue // Default color if not set
    }
    
    // Get the repeats per day from the effective repeat pattern
    private var repeatsPerDay: Int {
        guard let repeatPattern = HabitUtilities.getEffectiveRepeatPattern(for: habit, on: selectedCalendarDate ?? Date()) else {
            return 1
        }
        
        let value = max(1, Int(repeatPattern.repeatsPerDay))
        return value
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Calendar Section
            VStack(alignment: .leading, spacing: 12) {
                
                VStack(spacing: 10) {
                    // Title with month/year
                    HStack {
                        Text(calendarTitle)
                            .font(.customFont("Lexend", .semiBold, 17))
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    HStack(spacing: 2) {
                        ForEach(0..<7, id: \.self) { index in
                            Text("\(dayName(for: index)).")
                                .font(.customFont("Lexend", .medium, 10))
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.secondary.opacity(0.7))
                                
                                //.textCase(.uppercase)
                        }
                    }
                                .padding(.top, 2)
                                
                                .padding(.horizontal, 12)
                    MonthCalendarView(
                        $calendarTitle,
                        selection: $selectedCalendarDate,
                        focused: $focusedWeek,
                        isDragging: $isDraggingCalendar,
                        dragProgress: calendarDragProgress,
                        getFilteredHabits: getFilteredHabitsForDate,
                        animateRings: true,
                        refreshTrigger: calendarRefreshTrigger,
                        habitColor: habitColor
                        
                    )
                    .frame(height: Constants.monthHeight + 20)
                    .onChange(of: isDraggingCalendar) { _, newValue in
                        // When dragging stops, force a refresh with a small animation
                        if !newValue {
                            // This acts as a signal to refresh the rings
                            withAnimation(.easeInOut(duration: 0.3)) {
                                calendarDragProgress = 0.99
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        calendarDragProgress = 1.0
                                    }
                                }
                            }
                        }
                    }
                    
                    // Selected date info
                    if let selectedDate = selectedCalendarDate {
                        HStack(spacing: 12) {
                            // Date display with custom formatting
                            VStack(alignment: .leading, spacing: 2) {
                                Text(formatDayOfWeek(selectedDate))
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.secondary)
                                
                                Text(formatDayAndMonth(selectedDate))
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.primary)
                            }
                            
                            Spacer()
                            
                            // Completion button with animation
                            HStack(spacing: 10) {
                                // Using ZStack for potential badge overlay
                                ZStack(alignment: .topTrailing) {
                                    if !habit.isBadHabit {
                                        // Use RingFillCheckmarkButton with repeatsPerDay support
                                        RingFillCheckmarkButton(
                                            habitColor: .green,
                                            isCompleted: Binding(
                                                get: { repeatsPerDay <= 1 ? habit.isCompleted(on: selectedDate) : completedRepeats >= repeatsPerDay },
                                                set: { _ in
                                                    // Use withAnimation to ensure the toggle animates smoothly
                                                    withAnimation {
                                                        handleCompletionTap()
                                                    }
                                                }
                                            ),
                                            onTap: { /* handled by binding */ },
                                            repeatsPerDay: repeatsPerDay,
                                            completedRepeats: completedRepeats
                                        )
                                        // Remove the id modifier - it prevents animations
                                    } else {
                                        // Bad habit button
                                        BadHabitButton(
                                            successColor: .green,
                                            failureColor: .red,
                                            isBroken: Binding(
                                                get: { !habit.isCompleted(on: selectedDate) },
                                                set: { _ in
                                                    // Use withAnimation to ensure the toggle animates smoothly
                                                    withAnimation {
                                                        handleCompletionTap()
                                                    }
                                                }
                                            ),
                                            streakCount: habit.calculateStreak(upTo: selectedDate)
                                        ) {
                                            // Empty because it's handled by binding
                                        }
                                        // Remove the id modifier - it prevents animations
                                    }
                                }
                                
                                // Button text
                                let isCompleted = habit.isCompleted(on: selectedDate)
                                Text(isCompleted ?
                                     (habit.isBadHabit ? "Avoided" : "Completed") :
                                        (habit.isBadHabit ? "Mark as Avoided?" :"Mark as Completed?"))
                                .font(.customFont("Lexend", .semiBold, 14))
                                    .foregroundColor(isCompleted ?
                                                     (habit.isBadHabit ? .green : .green) :
                                                    .primary)
                            }
                            .frame(width: 120, height: 40)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .glassBackground()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                    }
                }
                .glassBackground()
            }
            //.padding(.horizontal)
            
            // Recent Completions Section
            
            completionHistorySection
                .padding(.bottom)
             
        }
        
        .onAppear {
            loadCompletedRepeats()
        }
        .onChange(of: selectedCalendarDate) { _, _ in
            loadCompletedRepeats()
        }
        .onChange(of: habit.completion) { _, _ in
            loadCompletedRepeats()
        }
        // ADD THESE NEW ONES:
        .onChange(of: habit.completion?.count ?? 0) { _, _ in
            loadCompletedRepeats()
        }
        .onChange(of: habit.lastCompletionDate) { _, _ in
            loadCompletedRepeats()
        }
        // NEW: Alert for deletion confirmation
        .alert("Delete Completion", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                completionToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let completion = completionToDelete {
                    deleteSingleCompletion(completion)
                }
                completionToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete this completion? This action cannot be undone.")
        }
    }
    
    // MARK: - Completion History Section
    private var completionHistorySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(.secondary)
                    .font(.system(size: 18))
                if !habit.isBadHabit {
                    Text("Recent Completions")
                        .font(.customFont("Lexend", .medium, 16))
                        .foregroundColor(.primary)
                }
                else {
                    Text("Recent Setbacks")
                        .font(.customFont("Lexend", .medium, 16))
                        .foregroundColor(.primary)
                }
            }
            .padding(.leading, 5)
            
            VStack(alignment: .leading, spacing: 0) {
                if let completions = habit.completion as? Set<Completion>, !completions.isEmpty {
                    let sortedCompletions = completions.sorted {
                        ($0.date ?? Date.distantPast) > ($1.date ?? Date.distantPast)
                    }
                    
                    let limitedCompletions = Array(sortedCompletions.prefix(5))
                    
                    // NEW: Using ForEach with swipe actions for deletion
                    ForEach(limitedCompletions, id: \.self) { completion in
                        CompletionRowView(
                            completion: completion,
                            habit: habit,
                            habitColor: habitColor,
                            isLast: completion == limitedCompletions.last
                        )
                        // NEW: Swipe to delete functionality
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                completionToDelete = completion
                                showingDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        // NEW: Context menu as alternative to swipe
                        .contextMenu {
                            Button(role: .destructive) {
                                completionToDelete = completion
                                showingDeleteConfirmation = true
                            } label: {
                                Label("Delete Completion", systemImage: "trash")
                            }
                        }
                    }
                    
                    // More completions counter
                    if completions.count > 5 {
                        Divider()
                            .padding(.leading, 48)
                        
                        Button(action: {
                            // Show the sheet with all completions
                            showingAllCompletions = true
                        }) {
                            HStack {
                                Spacer()
                                
                                Text("View all \(completions.count) completions")
                                    .font(.customFont("Lexend", .medium, 12))
                                    .foregroundColor(.primary)
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                            }
                            .padding(.top, 12)
                            .padding(.bottom, 8)
                        }
                        .sheet(isPresented: $showingAllCompletions) {
                            AllCompletionsView(
                                habit: habit,
                                habitColor: habitColor,
                                onCompletionDeleted: {
                                    // Refresh the main view when a completion is deleted in the sheet
                                    loadCompletedRepeats()
                                    refreshCalendarView()
                                }
                            )
                        }
                    }
                } else {
                    // Empty state with illustration
                    VStack(spacing: 12) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 40))
                            .foregroundColor(.gray.opacity(0.6))
                            .padding(.top, 8)
                        if !habit.isBadHabit {
                            Text("No completions recorded yet")
                                .foregroundColor(.secondary)
                                .font(.customFont("Lexend", .medium, 12))
                            
                            Text("Complete this habit to see your history here")
                                .font(.customFont("Lexend", .regular, 10))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.bottom, 8)
                        }
                        else {
                            Text("Habit not broken yet")
                                .font(.customFont("Lexend", .medium, 12))
                                .font(.system(.body, design: .rounded))
                            
                            Text("Here you can see all your setbacks")
                                .font(.customFont("Lexend", .regular, 9))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.bottom, 8)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
            }
            .padding()
            .glassBackground()
        }
        .padding(.horizontal)
    }

    // NEW: Separate view for completion rows to handle swipe actions properly
    private struct CompletionRowView: View {
        let completion: Completion
        let habit: Habit
        let habitColor: Color
        let isLast: Bool
        
        var body: some View {
            HStack(spacing: 12) {
                // Checkmark or X icon with improved styling
                ZStack {
                    Circle()
                        .fill(completion.completed
                            ? (habit.isBadHabit ? Color.red.opacity(0.15) : Color.green.opacity(0.15))
                            : Color.gray.opacity(0.1))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: completion.completed
                        ? (habit.isBadHabit ? "x.circle.fill" : "checkmark.circle.fill")
                        : "circle")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(completion.completed
                            ? (habit.isBadHabit ? .red : .green)
                            : .gray)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    // Show date of the entry first (formatted as day)
                    Text(formatDateOnly(completion.date))
                        .foregroundColor(.primary)
                        .font(.customFont("Lexend", .medium, 14))
                    
                    // Add smaller text with exact completion time
                    if let loggedAt = completion.loggedAt {
                        Text("Logged at: \(formatFullDateTime(loggedAt))")
                            .font(.customFont("Lexend", .regular, 11))
                            .foregroundColor(.secondary)
                    } else {
                        
                        // Day of week as fallback if no exact completion time
                        Text(formatDayOfWeek(completion.date))
                            .font(.caption)
                            .foregroundColor(.secondary)
                         
                    }
                }
                
                Spacer()
                
                // Duration badge with improved styling
                if completion.duration > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "timer")
                            .font(.system(size: 10))
                        
                        Text("\(completion.duration) min")
                            .fontWeight(.medium)
                    }
                    .foregroundColor(habitColor.opacity(0.8))
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(habitColor.opacity(0.12))
                    )
                }
            }
            .padding(.vertical, 8)
            
            if !isLast {
                Divider()
                    .padding(.leading, 48) // Align with the text, not the icon
            }
        }
    }

    // NEW: Method to delete a single completion
    private func deleteSingleCompletion(_ completion: Completion) {
        withAnimation(.easeOut(duration: 0.3)) {
            // Delete the completion using Core Data
            viewContext.delete(completion)
            
            // Update habit's total completions count
            habit.totalCompletions = max(0, habit.totalCompletions - 1)
            
            // Update habit's last completion date if this was the most recent
            updateLastCompletionDateIfNeeded(deletedCompletion: completion)
            
            do {
                try viewContext.save()
                
                // Refresh UI
                loadCompletedRepeats()
                refreshCalendarView()
                
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
    
    // NEW: Helper method to update last completion date when needed
    private func updateLastCompletionDateIfNeeded(deletedCompletion: Completion) {
        guard let deletedDate = deletedCompletion.date else { return }
        
        // Check if the deleted completion was the most recent
        if let currentLastDate = habit.lastCompletionDate,
           Calendar.current.isDate(deletedDate, inSameDayAs: currentLastDate) {
            
            // Find the new most recent completion
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
    
    private func loadCompletedRepeats() {
            guard let selectedDate = selectedCalendarDate else { return }
            
            // Use the toggle manager to get completed repeats count
            completedRepeats = toggleManager.getCompletedRepeatsCount(for: habit, on: selectedDate)
            
            // Force UI refresh
            refreshID = UUID()
        }
        
        // UPDATED: Handle completion tap using toggle manager
    private func handleCompletionTap() {
        guard let selectedDate = selectedCalendarDate else { return }
        
        let rpd = repeatsPerDay
        
        if rpd > 1 {
            // Multi-repeat habit logic
            if completedRepeats < rpd {
                // Add one completion at a time
                let newCompletedCount = toggleManager.addSingleCompletion(for: habit, on: selectedDate)
                
                withAnimation {
                    self.completedRepeats = newCompletedCount
                }
            } else {
                // We're at max completions, so reset to 0
                withAnimation {
                    completedRepeats = 0
                }
                toggleManager.deleteAllCompletions(for: habit, on: selectedDate)
            }
            
            // ADDED: Send notifications for multi-repeat habits too
            let isCompletedAfter = completedRepeats >= rpd
            sendToggleNotifications(for: selectedDate, isCompleted: isCompletedAfter)
            
        } else {
            // Single completion habit - use toggle manager
            toggleManager.toggleCompletion(for: habit, on: selectedDate)
            // Note: toggleCompletion already sends notifications, so we don't need to send them again
        }
        
        HabitUtilities.clearHabitActivityCache()
        refreshTrigger.toggle()
        refreshCalendarView()
    }

    // ADDED: Helper function to send toggle notifications
    private func sendToggleNotifications(for date: Date, isCompleted: Bool) {
        DispatchQueue.main.async {
            // Send the same notifications that HabitToggleManager sends
            NotificationCenter.default.post(
                name: NSNotification.Name("HabitUIRefreshNeeded"),
                object: habit,
                userInfo: [
                    "completionDate": date,
                    "isCompleted": isCompleted
                ]
            )
            
            NotificationCenter.default.post(
                name: NSNotification.Name("HabitToggled"),
                object: habit,
                userInfo: [
                    "date": date,
                    "isCompleted": isCompleted
                ]
            )
            
            NotificationCenter.default.post(
                name: NSNotification.Name("StreakUpdated"),
                object: habit,
                userInfo: ["date": date]
            )
        }
    }
    
    // Helper function to force refresh the calendar view
    private func refreshCalendarView() {
        // Force UI refresh for both button and calendar
        self.buttonRefreshID = UUID()
        self.refreshID = UUID()
        
        // Trigger the refresh binding to parent
        refreshTrigger.toggle()
        
        // Force calendar refresh for major state changes
        withAnimation {
            calendarRefreshTrigger = UUID()
        }
    }
}

// UPDATED: AllCompletionsView with deletion functionality
struct AllCompletionsView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    
    let habit: Habit
    let habitColor: Color
    let onCompletionDeleted: () -> Void // NEW: Callback for when completions are deleted
    
    // NEW: State for managing deletion
    @State private var showingDeleteConfirmation = false
    @State private var completionToDelete: Completion?
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    if let completions = habit.completion as? Set<Completion>, !completions.isEmpty {
                        let sortedCompletions = completions.sorted {
                            ($0.date ?? Date.distantPast) > ($1.date ?? Date.distantPast)
                        }
                        
                        ForEach(sortedCompletions, id: \.self) { completion in
                            HStack(spacing: 12) {
                                // Checkmark or X icon with improved styling
                                ZStack {
                                    Circle()
                                        .fill(completion.completed
                                            ? (habit.isBadHabit ? Color.red.opacity(0.15) : Color.green.opacity(0.15))
                                            : Color.gray.opacity(0.1))
                                        .frame(width: 36, height: 36)
                                    
                                    Image(systemName: completion.completed
                                        ? (habit.isBadHabit ? "x.circle.fill" : "checkmark.circle.fill")
                                        : "circle")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(completion.completed
                                            ? (habit.isBadHabit ? .red : .green)
                                            : .gray)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    // Show date of the entry first (formatted as day)
                                    Text(formatDateOnly(completion.date))
                                        .foregroundColor(.primary)
                                        .font(.system(.body, design: .rounded))
                                    
                                    // Add smaller text with exact completion time
                                    if let loggedAt = completion.loggedAt {
                                        Text("\(formatFullDateTime(loggedAt)) completed")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    } else {
                                        // Day of week as fallback if no exact completion time
                                        Text(formatDayOfWeek(completion.date))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                // Duration badge with improved styling
                                if completion.duration > 0 {
                                    HStack(spacing: 4) {
                                        Image(systemName: "timer")
                                            .font(.system(size: 10))
                                        
                                        Text("\(completion.duration) min")
                                            .fontWeight(.medium)
                                    }
                                    .foregroundColor(habitColor.opacity(0.8))
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(habitColor.opacity(0.12))
                                    )
                                }
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal)
                            // NEW: Swipe to delete functionality
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    completionToDelete = completion
                                    showingDeleteConfirmation = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            // NEW: Context menu as alternative to swipe
                            .contextMenu {
                                Button(role: .destructive) {
                                    completionToDelete = completion
                                    showingDeleteConfirmation = true
                                } label: {
                                    Label("Delete Completion", systemImage: "trash")
                                }
                            }
                            
                            if completion != sortedCompletions.last {
                                Divider()
                                    .padding(.leading, 60) // Align with the text, not the icon
                            }
                        }
                    }
                }
            }
            .navigationBarTitle(Text("\(habit.name ?? "Habit") History"), displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
            .glassBackground()
        }
        // NEW: Alert for deletion confirmation
        .alert("Delete Completion", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                completionToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let completion = completionToDelete {
                    deleteSingleCompletion(completion)
                }
                completionToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete this completion? This action cannot be undone.")
        }
    }
    
    // NEW: Method to delete a single completion
    private func deleteSingleCompletion(_ completion: Completion) {
        withAnimation(.easeOut(duration: 0.3)) {
            // Delete the completion using Core Data
            viewContext.delete(completion)
            
            // Update habit's total completions count
            habit.totalCompletions = max(0, habit.totalCompletions - 1)
            
            // Update habit's last completion date if this was the most recent
            updateLastCompletionDateIfNeeded(deletedCompletion: completion)
            
            do {
                try viewContext.save()
                
                // Notify the parent view that a completion was deleted
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
    
    // NEW: Helper method to update last completion date when needed
    private func updateLastCompletionDateIfNeeded(deletedCompletion: Completion) {
        guard let deletedDate = deletedCompletion.date else { return }
        
        // Check if the deleted completion was the most recent
        if let currentLastDate = habit.lastCompletionDate,
           Calendar.current.isDate(deletedDate, inSameDayAs: currentLastDate) {
            
            // Find the new most recent completion
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

struct CalendarAndCompletionView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a mock Habit for preview
        let context = PersistenceController.preview.container.viewContext
        let habit = Habit(context: context)
        habit.name = "Example Habit"
        habit.id = UUID()
        habit.startDate = Date().addingTimeInterval(-60 * 60 * 24 * 7) // 7 days ago
        habit.icon = "star.fill"
        
        // Create a color for the habit
        let uiColor = UIColor.systemBlue
        if let colorData = try? NSKeyedArchiver.archivedData(withRootObject: uiColor, requiringSecureCoding: false) {
            habit.color = colorData
        }
        
        // Create a repeat pattern
        let repeatPattern = RepeatPattern(context: context)
        repeatPattern.repeatsPerDay = 1
        repeatPattern.effectiveFrom = habit.startDate
        
        // Create a daily goal
        let dailyGoal = DailyGoal(context: context)
        dailyGoal.everyDay = true
        dailyGoal.repeatPattern = repeatPattern
        repeatPattern.dailyGoal = dailyGoal
        repeatPattern.habit = habit
        habit.addToRepeatPattern(repeatPattern)
        
        // State bindings for preview
        @State var selectedDate = Date()
        @State var calendarTitle = Calendar.monthAndYear(from: Date())
        @State var focusedWeek = Week(days: Calendar.currentWeek(from: Date()), order: .current)
        @State var isDragging = false
        @State var dragProgress: CGFloat = 1.0
        @State var refreshTrigger: Bool = false
        
        return CalendarAndCompletionView(
            habit: habit,
            selectedCalendarDate: .constant(Date()),
            calendarTitle: .constant(Calendar.monthAndYear(from: Date())),
            focusedWeek: .constant(Week(days: Calendar.currentWeek(from: Date()), order: .current)),
            isDraggingCalendar: .constant(false),
            calendarDragProgress: .constant(1.0),
            getFilteredHabitsForDate: { _ in [habit] },
            refreshTrigger: $refreshTrigger
        )
        .previewLayout(.sizeThatFits)
        .padding()
        .previewDisplayName("Calendar and Completion View")
        .environment(\.managedObjectContext, context)
    }
}
