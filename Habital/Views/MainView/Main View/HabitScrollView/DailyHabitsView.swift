//
//  DailyHabitsView.swift
//  Habital
//
//  Created by Elias Osarumwense on 10.04.25.
//

import SwiftUI

struct DailyHabitsView: View {
    
    let date: Date
    @Binding var habits: [Habit] // This is already filtered by MainHabitsView based on the selected list
    let isHabitActive: (Habit) -> Bool
    let isHabitCompleted: (Habit) -> Bool
    let toggleCompletion: (Habit) -> Void
    let getNextOccurrenceText: (Habit) -> String
    var onHabitDeleted: () -> Void
    let completionVersion: UUID // Add this to track toggle changes
    let sortOption: HabitSortOption // Add this to check if delay is needed
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedHabit: Habit? = nil
    @State private var showEditHabitView = false
    @State private var showDeleteAlert = false
    @State private var showSettingsView = false
    @State private var showingCreateHabitView = false
    
    // State for debounced completion animation
    @State private var debouncedCompletionVersion: UUID = UUID()
    @State private var completionDebounceTimer: Timer?
    
    @Binding var showArchivedHabits: Bool
    
    let listChangeDirection: MainHabitsView.ListChangeDirection
    let listChangeID: Int
    
    // Add state to track the previous listChangeID to determine direction
    @State private var previousListChangeID: Int = 0
    @State private var actualDirection: MainHabitsView.ListChangeDirection = .none
    
    // Animation states - removed problematic triggers
    @State private var animationID = UUID()
    
    // App storage for settings
    @AppStorage("showInactiveHabits") private var showInactiveHabits = true
    @AppStorage("groupCompletedHabits") private var groupCompletedHabits = false
    @AppStorage("accentColorIndex") private var accentColorIndex: Int = 0
    
    @State private var habitRefreshID = UUID()
    
    private var accentColor: Color {
        return ColorPalette.color(at: accentColorIndex)
    }
    
    class ViewState: ObservableObject {
        @Published var activeHabits: [Habit] = []
        @Published var inactiveHabits: [Habit] = []
        @Published var animationTrigger = UUID()
        
        // Function to trigger animation with a delay
        func triggerAnimation() {
            // Generate a new UUID to force view update
            DispatchQueue.main.async {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    self.animationTrigger = UUID()
                }
            }
        }
    }
    
    private class Cache {
        var filteredHabits: [Habit] = []
        var lastUpdateTime: Date = .distantPast
        var lastHabitCount: Int = 0
        var lastHabitIDs: Set<UUID> = []
        var lastShowInactiveHabits: Bool = true
        var lastGroupCompletedHabits: Bool = false
    }
    
    // Use a constant reference type instead of @State
    private let cache = Cache()
    
    // PERFORMANCE FIX: Cached filteredHabits computation
    private var filteredHabits: [Habit] {
        // Add a simple cache check to prevent excessive recalculations
        let currentHabitIDs = Set(habits.compactMap { $0.id })
        let now = Date()
        
        // Only recalculate if habits changed, settings changed, or if 5 seconds passed
        if cache.lastHabitIDs != currentHabitIDs ||
           cache.lastShowInactiveHabits != showInactiveHabits ||
           cache.lastGroupCompletedHabits != groupCompletedHabits ||
           now.timeIntervalSince(cache.lastUpdateTime) > 5.0 {
            
            cache.filteredHabits = habits.filter { habit in
                // Skip the isHabitActive check temporarily
                let passesActiveFilter = true // showInactiveHabits ? true : isHabitActive(habit)
                let passesCompletionFilter = groupCompletedHabits ? !isHabitCompleted(habit) : true
                return passesActiveFilter && passesCompletionFilter
            }
            
            cache.lastUpdateTime = now
            cache.lastHabitIDs = currentHabitIDs
            cache.lastShowInactiveHabits = showInactiveHabits
            cache.lastGroupCompletedHabits = groupCompletedHabits
        }
        
        return cache.filteredHabits
    }

    
    // Function to get all habits including completed ones
    private func getCompletedHabits() -> [Habit] {
        // For the completed habits stack, we want all habits regardless of active status
        // but we still respect the list filtering that happened in MainHabitsView
        return habits.filter { habit in
            // Only include habits that have a start date on or before today
            if let startDate = habit.startDate {
                let normalizedStartDate = Calendar.current.startOfDay(for: startDate)
                let normalizedSelectedDate = Calendar.current.startOfDay(for: date)
                return normalizedStartDate <= normalizedSelectedDate && isHabitCompleted(habit)
            }
            return isHabitCompleted(habit)
        }
    }
    
    @State private var animationInProgress = false
    @State private var lastDateChangeTime = Date()
    @State private var rapidChangeTimer: Timer?
    @State private var shouldAnimateChanges = true
    
    // PERFORMANCE FIX: Add debouncing for toggle operations
    @State private var toggleDebouncer: Timer?
    @State private var isToggling = false
    @State private var lastToggleTime = Date.distantPast
    @State private var suppressAnimations = false

    // ✅ NEW: Rate limiting and debouncing for date changes
    private func handleDateChange() {
        let now = Date()
        let timeSinceLastChange = now.timeIntervalSince(lastDateChangeTime)
        lastDateChangeTime = now
        
        // If changes are happening rapidly (< 0.3 seconds apart), disable animations
        if timeSinceLastChange < 0.3 {
            shouldAnimateChanges = false
            
            // Cancel existing timer
            rapidChangeTimer?.invalidate()
            
            // Set timer to re-enable animations after rapid changes stop
            rapidChangeTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    shouldAnimateChanges = true
                }
            }
        } else {
            shouldAnimateChanges = true
        }
    }
    
    // PERFORMANCE FIX: Debounced toggle function
    private func debouncedToggle(habit: Habit) {
        // Prevent multiple rapid toggles
        guard !isToggling else { return }
        
        isToggling = true
        toggleDebouncer?.invalidate()
        
        // Handle animation suppression for rapid toggles
        handleToggleAnimation()
        
        // Execute the toggle immediately but prevent rapid subsequent calls
        toggleCompletion(habit)
        
        // Reset the toggle flag after a short delay
        toggleDebouncer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
            isToggling = false
        }
    }
    
    // PERFORMANCE FIX: Manage animation state during rapid toggles
    private func handleToggleAnimation() {
        let now = Date()
        
        // If toggles are happening rapidly (within 0.5 seconds), suppress animations
        if now.timeIntervalSince(lastToggleTime) < 0.5 {
            suppressAnimations = true
            
            // Re-enable animations after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                suppressAnimations = false
            }
        }
        
        lastToggleTime = now
    }
    
    private struct CombinedAnimationState: Equatable {
        let listChangeID: Int
        let dateTimeInterval: TimeInterval
        // PERFORMANCE FIX: Removed filteredHabitsCount to prevent toggle-triggered animations
        
        static func == (lhs: CombinedAnimationState, rhs: CombinedAnimationState) -> Bool {
            return lhs.listChangeID == rhs.listChangeID &&
                   lhs.dateTimeInterval == rhs.dateTimeInterval
        }
    }
    
    
    var body: some View {
        // PERFORMANCE FIX: Only print during actual debugging, comment out for production
        // let _ = print("🔄 DailyHabitsView body called - habits count: \(habits.count)")
        VStack(spacing: 0) {
            // Use proper transition logic based on list index changes
            
            habitContentView
                .id("habitsList-\(listChangeID)")
                /*.transition(.asymmetric(
                    insertion: getInsertionTransition(),
                    removal: getRemovalTransition()
                ))*/
        }
        // PERFORMANCE FIX: Simplified animation with suppression for rapid interactions
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: listChangeID)
        .animation(
            suppressAnimations ? nil : (shouldAnimateChanges ? .spring(response: 0.25, dampingFraction: 0.90) : nil),
            value: CombinedAnimationState(
                listChangeID: listChangeID,
                dateTimeInterval: date.timeIntervalSince1970
            )
        )
        //.animation(.spring(response: 0.4, dampingFraction: 0.9), value: listChangeID)
        //.animation(.spring(response: 0.35, dampingFraction: 0.9), value: listChangeID)
        //.animation(.spring(response: 0.35, dampingFraction: 0.9), value: filteredHabits.count)
        //.animation(.spring(response: 0.35, dampingFraction: 0.9), value: date)
        //.animation(.spring(response: 0.4, dampingFraction: 0.8), value: dateAnimationTrigger)
        /*
        .onChange(of: date) { _, _ in
            updateDisplayedHabits()
        }
         */
        
        .sheet(isPresented: $showEditHabitView, onDismiss: {
            selectedHabit = nil
        }) {
            if let habitToEdit = selectedHabit {
                EditHabitView(habit: habitToEdit)
                    .environment(\.managedObjectContext, viewContext)
            }
        }
        .sheet(isPresented: $showingCreateHabitView) {
            CreateHabitView()
                .presentationCornerRadius(50)
                .environment(\.managedObjectContext, viewContext)
                .presentationBackground(.clear)     // iOS 17+
                        .background(
                            Rectangle().fill(.thickMaterial).ignoresSafeArea()
                        )
                
        }
        .sheet(isPresented: $showSettingsView) {
            SettingsView()
        }
        .alert("Delete Habit", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let habitToDelete = selectedHabit {
                    deleteHabit(habitToDelete)
                }
            }
        } message: {
            Text("Are you sure you want to delete this habit? This cannot be undone.")
        }
        .onAppear {
            // Initialize previous ID on first appearance
            previousListChangeID = listChangeID
        }
        .onChange(of: listChangeID) { oldValue, newValue in
            // Better animation direction logic
            determineAnimationDirection(from: oldValue, to: newValue)
            
            previousListChangeID = oldValue

            
            print("DailyHabitsView: List index changed from \(oldValue) to \(newValue), direction: \(actualDirection)")
        }
        .onChange(of: date) { _, _ in
                // ✅ NEW: Handle rapid date changes
                handleDateChange()
            }
            .onChange(of: completionVersion) { oldValue, newValue in
                // Only apply delay for sort options that need reordering on toggle
                let shouldDelay = sortOption == .completion || sortOption == .streak
                
                if shouldDelay {
                    // Debounce completion version changes with 1 second delay
                    completionDebounceTimer?.invalidate()
                    completionDebounceTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            debouncedCompletionVersion = newValue
                        }
                    }
                } else {
                    // For other sort options, update immediately (no reordering needed)
                    debouncedCompletionVersion = newValue
                }
            }
            .onDisappear {
                // Clean up timers
                rapidChangeTimer?.invalidate()
                toggleDebouncer?.invalidate()
                completionDebounceTimer?.invalidate()
            }
        
    }
    
    // Improved direction determination logic
    private func determineAnimationDirection(from oldValue: Int, to newValue: Int) {
        // Think of it like a horizontal tab view:
        // Index 0 (All Habits) is on the left
        // Higher indices are to the right
        // When moving to a higher index (moving right in the tab layout)
        // The direction should be RIGHT
        // When moving to a lower index (moving left in the tab layout)
        // The direction should be LEFT
        
        if newValue > oldValue {
            // Moving to higher index (moving right in the tab layout)
            actualDirection = .right
        } else if newValue < oldValue {
            // Moving to lower index (moving left in the tab layout)
            actualDirection = .left
        } else {
            // No change
            actualDirection = .none
        }
    }

    // Also update the transition functions to match the corrected logic
    private func getInsertionTransition() -> AnyTransition {
        switch actualDirection {
        case .right:
            // Moving right: new content slides in from the right edge
            return .move(edge: .trailing).combined(with: .opacity)
        case .left:
            // Moving left: new content slides in from the left edge
            return .move(edge: .leading).combined(with: .opacity)
        case .none:
            return .opacity.combined(with: .scale(scale: 0.95))
        }
    }

    private func getRemovalTransition() -> AnyTransition {
        switch actualDirection {
        case .right:
            // Moving right: old content slides out to the left edge
            return .move(edge: .leading).combined(with: .opacity)
        case .left:
            // Moving left: old content slides out to the right edge
            return .move(edge: .trailing).combined(with: .opacity)
        case .none:
            return .opacity.combined(with: .scale(scale: 0.95))
        }
    }
    
    // SIMPLE FIX: Replace LazyVStack with VStack in your DailyHabitsView

    private var habitContentView: some View {
        VStack(spacing: 0) {
            ScrollView {
                // ✅ CHANGE: LazyVStack → VStack for smooth animations
                VStack {
                    if groupCompletedHabits {
                        AnimatedCompletedHabitsStack(
                            habits: getCompletedHabits(),
                            date: date,
                            isHabitCompleted: isHabitCompleted,
                            toggleCompletion: { habit in
                                // PERFORMANCE FIX: Use debounced toggle instead of direct withAnimation
                                debouncedToggle(habit: habit)
                            }
                        )
                        //.padding(.horizontal, 3)
                        .padding(.top, 10)
                        //.drawingGroup()
                    }
                    
                    Color.clear.frame(height: 2)
                    
                    ForEach(habits, id: \.objectID) { habit in
                        HabitRowView(
                            habit: habit,
                            isActive: isHabitActive(habit),
                            isCompleted: isHabitCompleted(habit),
                            nextOccurrence: getNextOccurrenceText(habit),
                            toggleCompletion: {
                                // PERFORMANCE FIX: Remove withAnimation wrapper and use debounced toggle
                                //debouncedToggle(habit: habit)
                                toggleCompletion(habit)
                                
                            },
                            editHabit: {
                                selectedHabit = habit
                                showEditHabitView = true
                            },
                            deleteHabit: {
                                selectedHabit = habit
                                showDeleteAlert = true
                            },
                            date: date
                        )
                        .padding(.bottom, 4)
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .move(edge: .bottom).combined(with: .opacity)
                        ))
                    }
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: habits.map { $0.objectID })
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: debouncedCompletionVersion)
                    
                    if filteredHabits.isEmpty && !showArchivedHabits {
                        EmptyHabitsView(
                            showArchivedHabits: showArchivedHabits,
                            groupCompletedHabits: groupCompletedHabits,
                            accentColor: accentColor,
                            onAddHabit: { showingCreateHabitView = true },
                            completedHabitsCount: getCompletedHabits().count
                        )
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }
                    
                    Color.clear.frame(height: 8)
                }
                .padding(.horizontal, 10)
                .padding(.top, 3)
                //.animation(.spring(response: 0.4, dampingFraction: 0.8), value: filteredHabits.count)
            }
            .scrollIndicators(.hidden)
        }
    }
    
    struct EmptyHabitsView: View {
        let showArchivedHabits: Bool
        let groupCompletedHabits: Bool
        let accentColor: Color
        let onAddHabit: () -> Void
        let completedHabitsCount: Int
        
        var body: some View {
            VStack(spacing: 0) {
                Spacer()
                
                if groupCompletedHabits && completedHabitsCount > 0 {
                    // All habits completed state
                    VStack(spacing: 22) {
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.15))
                                .frame(width: 100, height: 100)
                                .shadow(color: Color.green.opacity(0.2), radius: 10, x: 0, y: 4)
                            
                            Image(systemName: "star.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.green)
                        }
                        .padding(.bottom, 8)
                        
                        Text("All habits completed!")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text("Great job! You've completed all your habits for today.")
                            .font(.system(size: 17))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .padding(.top, 4)
                    }
                } else {
                    // No habits state
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(accentColor.opacity(0.12))
                                .frame(width: 110, height: 110)
                                .shadow(color: accentColor.opacity(0.15), radius: 10, x: 0, y: 4)
                            
                            Image(systemName: showArchivedHabits ? "archivebox" : "checklist")
                                .font(.system(size: 42, weight: .light))
                                .foregroundColor(accentColor)
                        }
                        .padding(.bottom, 10)
                        
                        Text(showArchivedHabits ? "No archived habits" : "No habits for this day")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text(showArchivedHabits
                            ? "Archived habits will appear here"
                            : "Start building great habits by adding your first one")
                            .font(.system(size: 17))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 40)
                            .padding(.top, 4)
                        
                        if !showArchivedHabits {
                            Button(action: onAddHabit) {
                                HStack(spacing: 10) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 18))
                                    
                                    Text("Add a habit")
                                        .font(.system(size: 17, weight: .medium))
                                }
                                .padding(.vertical, 14)
                                .padding(.horizontal, 28)
                                .background(
                                    Capsule()
                                        .fill(accentColor)
                                        .shadow(color: accentColor.opacity(0.3), radius: 5, x: 0, y: 3)
                                )
                                .foregroundColor(.white)
                            }
                            .padding(.top, 20)
                        }
                    }
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 30)
            .padding(.vertical, 40)
        }
    }

    private func deleteHabit(_ habit: Habit) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            // Delete from Core Data
            viewContext.delete(habit)
            
            do {
                try viewContext.save()
                
                // Call the callback to notify parent view
                onHabitDeleted()
                
                // Provide haptic feedback
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
            } catch {
                print("❌ Error deleting habit: \(error)")
            }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
