//
//  CalendarAndToogleView.swift
//  Habital
//
//  Created by Elias Osarumwense on 04.08.25.
//

import SwiftUI
import CoreData

struct CalendarAndToggleView: View {
    let habit: Habit
    let date: Date
    @State private var completedRepeats: Int = 0
    @State private var repeatsPerDay: Int = 1
    @State private var todayCompleted: Bool = false // Add this
    @State private var refreshTrigger = UUID() // Add this for forcing updates
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    
    @StateObject private var toggleManager = HabitToggleManager(context: PersistenceController.shared.container.viewContext)
    
    @State private var isToggling = false
    
    // Find the last completed date
    private var lastCompletedDate: Date? {
        guard let completions = habit.completion as? Set<Completion> else { return nil }
        
        return completions
            .filter { $0.completed }
            .compactMap { $0.date }
            .max()
    }
    
    // Extract the habit color
    private var habitColor: Color {
        if let colorData = habit.color,
           let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
            return Color(uiColor)
        }
        return .blue
    }
    
    // Check if today is completed
    private var isTodayCompleted: Bool {
        return habit.isCompleted(on: date)
    }
    
    // Toggle completion for today
    private func toggleTodayCompletion() {
        // Only allow toggling for today's date
        let today = Calendar.current.startOfDay(for: Date())
        let selectedDay = Calendar.current.startOfDay(for: date)
        
        guard Calendar.current.isDate(today, inSameDayAs: selectedDay) else {
            return // Don't allow toggling if not today
        }
        
        guard !isToggling else { return }
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isToggling = true
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Use toggle manager for TODAY only
        toggleManager.toggleCompletion(for: habit, on: Date()) // Always use today's date
        //toggleManager.toggleCompletionWithStatsSummaryUpdate(for: habit, on: Date())
        // Update completed repeats count
        DispatchQueue.main.async {
            self.completedRepeats = self.toggleManager.getCompletedRepeatsCount(for: habit, on: Date())
        }
        
        // Reset toggling state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isToggling = false
            }
        }
    }
    
    private var lastCompletionText: String {
        if habit.isBadHabit {
            // For bad habits: completed = broken, not completed = avoided
            if todayCompleted {
                return "Broken today" // Bad - habit was done
            } else {
                return "Avoided today" // Good - habit was avoided
            }
        } else {
            // For good habits: normal logic
            if todayCompleted {
                return "Completed today"
            } else if completedRepeats > 0 {
                return "In progress (\(completedRepeats)/\(repeatsPerDay))"
            }
        }
        
        // If not completed today, show the last actual completion
        guard let lastCompleted = lastCompletedDate else {
            return habit.isBadHabit ? "Never broken" : "Never completed"
        }
        
        let daysDifference = Calendar.current.dateComponents([.day], from: lastCompleted, to: Date()).day ?? 0
        
        if daysDifference == 1 {
            return "Yesterday"
        } else {
            return "\(daysDifference) days ago"
        }
    }

    private var statusColor: Color {
        if habit.isBadHabit {
            // For bad habits: completed = broken (red), not completed = avoided (green)
            if todayCompleted {
                return Color.red.opacity(0.8) // Red when habit was broken (done) today
            } else {
                return Color.green.opacity(0.8) // Green when habit was avoided today
            }
        } else {
            // For good habits: normal logic
            if todayCompleted {
                return Color.green.opacity(0.8) // Green when fully completed today
            } else if completedRepeats > 0 {
                return Color.orange // Orange when partially completed today
            }
        }
        
        // If not completed today, base color on last completion
        guard let lastCompleted = lastCompletedDate else { return .gray }
        
        let daysDifference = Calendar.current.dateComponents([.day], from: lastCompleted, to: Date()).day ?? 0
        
        if daysDifference == 1 {
            return .orange
        } else {
            return .red
        }
    }

    private var isHabitCompleted: Bool {
        return todayCompleted
    }
    
    // Calculate current streak
    private var currentStreak: Int {
        return habit.calculateStreak(upTo: Date())
    }
    
    var body: some View {
        HStack(spacing: 20) {
            // Left side - Last completion info
            VStack(alignment: .leading, spacing: 8) {
                Text("Last completed")
                    .font(.customFont("Lexend", .medium, 12))
                    .foregroundColor(.secondary)
                
                Text(lastCompletionText)
                    .font(.customFont("Lexend", .semiBold, 16))
                    .foregroundColor(statusColor)
                    .id(refreshTrigger)
                
                // Quick visual indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 6, height: 6)
                    
                    if let lastCompleted = lastCompletedDate {
                        Text(habit.isBadHabit ? "Since \(formatShortDate(lastCompleted))" : formatShortDate(lastCompleted))
                            .font(.customFont("Lexend", .medium, 11))
                            .foregroundColor(.primary)
                    } else {
                        Text("No data")
                            .font(.customFont("Lexend", .medium, 11))
                            .foregroundColor(.primary)
                    }
                }
                .id(refreshTrigger)
            }
            
            Spacer()
            
            // Right side - Today's toggle with modern structure
            VStack(spacing: 8) {
                // Toggle button with glass background
                ZStack {
                    // Modern glass background
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 64, height: 64)
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(colorScheme == .dark ? 0.2 : 0.4),
                                            habitColor.opacity(0.3),
                                            Color.clear
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                        //.shadow(color: habitColor.opacity(0.15), radius: 8, x: 0, y: 4)
                    
                    // Use BadHabitButton for bad habits, RingFillCheckmarkButton for good habits
                    if !habit.isBadHabit {
                        // Good habit - use RingFillCheckmarkButton
                        RingFillCheckmarkButton(
                            habitColor: habitColor,
                            isCompleted: Binding(
                                get: { isHabitCompleted },
                                set: { _ in toggleTodayCompletion() }
                            ),
                            onTap: {},
                            repeatsPerDay: repeatsPerDay,
                            completedRepeats: completedRepeats
                        )
                        .scaleEffect(1.5) // Make it bigger (32px -> 48px)
                        .scaleEffect(isToggling ? 0.95 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isToggling)
                    } else {
                        // Bad habit - use BadHabitButton
                        BadHabitButton(
                            successColor: .green,
                            failureColor: .red,
                            isBroken: Binding(
                                get: { isHabitCompleted }, // For bad habits, isBroken = completed (habit was done)
                                set: { _ in toggleTodayCompletion() }
                            ),
                            streakCount: currentStreak
                        ) {
                            // Empty because it's handled by binding
                        }
                        .scaleEffect(1.5) // Make it bigger to match RingFillCheckmarkButton
                        .scaleEffect(isToggling ? 0.95 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isToggling)
                    }
                }
                
                Text("Today")
                    .font(.customFont("Lexend", .semiBold, 12))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .glassBackground()
        .onAppear {
            loadRepeatsPerDay()
            loadCompletedRepeats()
        }
        
        .onChange(of: habit.completion?.count ?? 0) { _, _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                loadCompletedRepeats()
            }
        }
        .onChange(of: habit.lastCompletionDate) { _, _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                loadCompletedRepeats()
            }
        }
        .onChange(of: habit.completion) { _, _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                loadCompletedRepeats()
            }
        }
    }
    private func loadRepeatsPerDay() {
        repeatsPerDay = HabitUtilities.getRepeatsPerDay(for: habit, on: Date())
    }

    private func loadCompletedRepeats() {
        let today = Date()
        completedRepeats = toggleManager.getCompletedRepeatsCount(for: habit, on: today)
        todayCompleted = toggleManager.isHabitCompletedForDate(habit, on: today)
        refreshTrigger = UUID() // Force view refresh
    }
/*
    private var isHabitCompleted: Bool {
        return toggleManager.isHabitCompletedForDate(habit, on: Date()) // Always use today
    }
 */
    // Helper to format short date
    private func formatShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Preview
struct CalendarAndToggleView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Light mode previews
            VStack(spacing: 30) {
                Text("Calendar & Toggle - Minimal")
                    .font(.title.bold())
                    .padding()
                
                // Good habit - Completed today
                CalendarAndToggleView(
                    habit: sampleHabit(completed: true, color: .blue, lastCompletedDaysAgo: 0, isBadHabit: false),
                    date: Date()
                )
                
                // Good habit - Not completed, last completed yesterday
                CalendarAndToggleView(
                    habit: sampleHabit(completed: false, color: .green, lastCompletedDaysAgo: 1, isBadHabit: false),
                    date: Date()
                )
                
                // Bad habit - Avoided today (not completed = good)
                CalendarAndToggleView(
                    habit: sampleHabit(completed: false, color: .orange, lastCompletedDaysAgo: 0, isBadHabit: true),
                    date: Date()
                )
                
                // Bad habit - Broken today (completed = bad)
                CalendarAndToggleView(
                    habit: sampleHabit(completed: true, color: .red, lastCompletedDaysAgo: 3, isBadHabit: true),
                    date: Date()
                )
                
                // Never completed
                CalendarAndToggleView(
                    habit: sampleHabit(completed: false, color: .purple, lastCompletedDaysAgo: nil, isBadHabit: false),
                    date: Date()
                )
            }
            .padding()
            .background(Color(.systemGroupedBackground))
            .preferredColorScheme(.light)
            .previewDisplayName("Light Mode")
            
            // Dark mode preview
            VStack(spacing: 30) {
                Text("Calendar & Toggle - Minimal")
                    .font(.title.bold())
                    .padding()
                
                // Good habit - Completed today
                CalendarAndToggleView(
                    habit: sampleHabit(completed: true, color: .blue, lastCompletedDaysAgo: 0, isBadHabit: false),
                    date: Date()
                )
                
                // Bad habit - Avoided today (not completed = good)
                CalendarAndToggleView(
                    habit: sampleHabit(completed: false, color: .green, lastCompletedDaysAgo: 0, isBadHabit: true),
                    date: Date()
                )
            }
            .padding()
            .background(Color(.systemGroupedBackground))
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
        }
    }
    
    // Sample habit for preview
    static func sampleHabit(completed: Bool, color: Color, lastCompletedDaysAgo: Int?, isBadHabit: Bool = false) -> Habit {
        let context = PersistenceController.preview.container.viewContext
        let habit = Habit(context: context)
        habit.name = "Sample Habit"
        habit.icon = "dumbbell.fill"
        habit.isBadHabit = isBadHabit
        
        // Set color
        if let colorData = try? NSKeyedArchiver.archivedData(withRootObject: UIColor(color), requiringSecureCoding: false) {
            habit.color = colorData
        }
        
        let calendar = Calendar.current
        
        // Add completion for today if needed
        if completed {
            let completion = Completion(context: context)
            completion.date = Date()
            completion.completed = true
            completion.habit = habit
        }
        
        // Add last completion if specified
        if let daysAgo = lastCompletedDaysAgo, daysAgo > 0 {
            if let pastDate = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) {
                let completion = Completion(context: context)
                completion.date = pastDate
                completion.completed = true
                completion.habit = habit
            }
        }
        
        return habit
    }
}
