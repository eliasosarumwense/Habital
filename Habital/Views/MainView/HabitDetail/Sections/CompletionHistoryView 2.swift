//
//  CompletionHistoryView.swift
//  Habital
//
//  Created by Elias Osarumwense on 16.04.25.
//

import SwiftUI
import CoreData

struct CompletionHistoryView: View {
    let habit: Habit
    @Binding var refreshTrigger: Bool
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    
    @StateObject private var toggleManager = HabitToggleManager(context: PersistenceController.shared.container.viewContext)
    
    @State private var showingAllCompletions = false
    @State private var showingDeleteConfirmation = false
    @State private var completionToDelete: Completion?
    @State private var buttonRefreshID = UUID()
    
    // Extract the habit color or use a default
    private var habitColor: Color {
        if let colorData = habit.color,
           let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
            return Color(uiColor)
        }
        return .blue // Default color if not set
    }
    
    // Get sorted completions
    private var sortedCompletions: [Completion] {
        guard let completions = habit.completion as? Set<Completion> else { return [] }
        return completions
            .filter { $0.completed }
            .sorted { ($0.date ?? Date.distantPast) > ($1.date ?? Date.distantPast) }
    }
    
    // Get limited completions for display
    private var displayedCompletions: [Completion] {
        let completions = sortedCompletions
        return showingAllCompletions ? completions : Array(completions.prefix(10))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            HStack {
                Text("Completion History")
                    .font(.customFont("Lexend", .semiBold, 17))
                    .foregroundColor(.primary)
                
                Spacer()
                
                if sortedCompletions.count > 10 {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showingAllCompletions.toggle()
                        }
                    }) {
                        Text(showingAllCompletions ? "Show Less" : "Show All (\(sortedCompletions.count))")
                            .font(.customFont("Lexend", .medium, 12))
                            .foregroundColor(habitColor)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            
            // Completion List
            if displayedCompletions.isEmpty {
                emptyStateView
            } else {
                completionListView
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 12)
        .glassBackground()
        .alert("Delete Completion", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteCompletion()
            }
        } message: {
            Text("Are you sure you want to delete this completion? This action cannot be undone.")
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: habit.isBadHabit ? "checkmark.shield" : "checkmark.circle")
                .font(.system(size: 32))
                .foregroundColor(.secondary.opacity(0.6))
            
            Text(habit.isBadHabit ? "No slip-ups recorded" : "No completions yet")
                .font(.customFont("Lexend", .medium, 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Text(habit.isBadHabit ?
                 "Keep up the good work! Each day without this habit counts as success." :
                 "Start building your habit streak by completing it today!")
                .font(.customFont("Lexend", .regular, 12))
                .foregroundColor(.secondary.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }
    
    // MARK: - Completion List View
    private var completionListView: some View {
        VStack(spacing: 8) {
            ForEach(displayedCompletions, id: \.objectID) { completion in
                completionRowView(completion: completion)
            }
            
            // Show more button for long lists
            if sortedCompletions.count > 10 && !showingAllCompletions {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showingAllCompletions = true
                    }
                }) {
                    HStack {
                        Text("Show \(sortedCompletions.count - 10) more")
                            .font(.customFont("Lexend", .medium, 12))
                            .foregroundColor(habitColor)
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(habitColor)
                    }
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(habitColor.opacity(0.1))
                    .cornerRadius(8)
                }
                .padding(.horizontal, 10)
            }
        }
        .padding(.horizontal, 10)
        .id(buttonRefreshID)
    }
    
    // MARK: - Completion Row View
    private func completionRowView(completion: Completion) -> some View {
        HStack(spacing: 12) {
            // Completion indicator
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(habitColor)
            
            // Date and details
            VStack(alignment: .leading, spacing: 2) {
                Text(formatDate(completion.date ?? Date()))
                    .font(.customFont("Lexend", .medium, 13))
                    .foregroundColor(.primary)
                
                if let note = completion.notes, !note.isEmpty {
                    Text(note)
                        .font(.customFont("Lexend", .regular, 11))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                // Show time if available
                if let date = completion.date {
                    Text(formatTime(date))
                        .font(.customFont("Lexend", .regular, 10))
                        .foregroundColor(.secondary.opacity(0.7))
                }
            }
            
            Spacer()
            
            // Streak indicator if applicable
            if let streakDay = getStreakDay(for: completion.date ?? Date()) {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Day")
                        .font(.customFont("Lexend", .regular, 9))
                        .foregroundColor(.secondary.opacity(0.7))
                    
                    Text("\(streakDay)")
                        .font(.customFont("Lexend", .semiBold, 12))
                        .foregroundColor(habitColor)
                }
            }
            
            // Delete button
            Button(action: {
                completionToDelete = completion
                showingDeleteConfirmation = true
            }) {
                Image(systemName: "trash.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.red.opacity(0.7))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white.opacity(0.7))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(habitColor.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Helper Methods
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.component(.year, from: date) == calendar.component(.year, from: Date()) {
            formatter.dateFormat = "MMM d"
        } else {
            formatter.dateFormat = "MMM d, yyyy"
        }
        
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func getStreakDay(for date: Date) -> Int? {
        let streak = habit.calculateStreak(upTo: date)
        
        // Calculate which day of the streak this completion represents
        guard streak > 0 else { return nil }
        
        // For a simple approximation, we can show the streak number
        // You may want to implement more sophisticated logic here
        return streak
    }
    
    private func deleteCompletion() {
        guard let completion = completionToDelete else { return }
        
        // Delete the completion
        viewContext.delete(completion)
        
        // Update the habit's last completion date if this was the most recent
        updateHabitLastCompletionDate(after: completion)
        
        // Save changes
        do {
            try viewContext.save()
            
            // Refresh the view
            buttonRefreshID = UUID()
            refreshTrigger.toggle()
            
        } catch {
            print("Error deleting completion: \(error)")
        }
        
        // Clear the completion to delete
        completionToDelete = nil
    }
    
    private func updateHabitLastCompletionDate(after deletedCompletion: Completion) {
        // Update habit's last completion date
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

