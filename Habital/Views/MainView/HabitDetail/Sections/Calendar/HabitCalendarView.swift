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
    
    // 🔄 Use shared toggleManager from environment
    @EnvironmentObject var toggleManager: HabitToggleManager
    
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
            VStack {
                
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
                        toggleManager: toggleManager,
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
            
            
            // History Button Section
            historyButtonSection
        }
        .padding(.horizontal)
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
    
    // MARK: - History Button Section
    private var historyButtonSection: some View {
        VStack(spacing: 0) {
            Button(action: {
                showingAllCompletions = true
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(habitColor)
                        .font(.system(size: 20, weight: .medium))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        if !habit.isBadHabit {
                            Text("View Completion History")
                                .font(.customFont("Lexend", .medium, 16))
                                .foregroundColor(.primary)
                        } else {
                            Text("View Setback History")
                                .font(.customFont("Lexend", .medium, 16))
                                .foregroundColor(.primary)
                        }
                        
                        if let completions = habit.completion as? Set<Completion>, !completions.isEmpty {
                            Text("\(completions.count) entries recorded")
                                .font(.customFont("Lexend", .regular, 12))
                                .foregroundColor(.secondary)
                        } else {
                            Text("No entries yet")
                                .font(.customFont("Lexend", .regular, 12))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding()
                .glassBackground()
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal)
        .sheet(isPresented: $showingAllCompletions) {
            DetailedHistoryView(
                habit: habit,
                habitColor: habitColor,
                onCompletionDeleted: {
                    // Refresh the main view when a completion is deleted
                    loadCompletedRepeats()
                    refreshCalendarView()
                }
            )
            
            .presentationCornerRadius(45)
            //.presentationDetents([.fraction(0.70)])
            .presentationDragIndicator(.visible)
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
