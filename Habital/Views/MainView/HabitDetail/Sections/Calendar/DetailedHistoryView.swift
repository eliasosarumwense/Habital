//
//  DetailedHistoryView.swift
//  Habital
//
//  Created by Assistant on 01.11.25.
//

import SwiftUI
import CoreData

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
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 0) {
                    if let completions = habit.completion as? Set<Completion>, !completions.isEmpty {
                        let groupedCompletions = groupCompletionsByDate(completions)
                        
                        ForEach(Array(groupedCompletions.keys.sorted(by: >)), id: \.self) { date in
                            if let dayCompletions = groupedCompletions[date] {
                                DateSectionView(
                                    date: date,
                                    completions: dayCompletions,
                                    habit: habit,
                                    habitColor: habitColor,
                                    onDeleteCompletion: { completion in
                                        completionToDelete = completion
                                        showingDeleteConfirmation = true
                                    }
                                )
                                
                                // Add divider between date sections
                                if date != groupedCompletions.keys.sorted(by: >).last {
                                    Divider()
                                        .padding(.horizontal)
                                        .padding(.vertical, 8)
                                }
                            }
                        }
                    } else {
                        // Empty state
                        VStack(spacing: 20) {
                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 60))
                                .foregroundColor(.gray.opacity(0.5))
                                .padding(.top, 60)
                            
                            VStack(spacing: 8) {
                                if !habit.isBadHabit {
                                    Text("No Completions Yet")
                                        .font(.customFont("Lexend", .semiBold, 20))
                                        .foregroundColor(.primary)
                                    
                                    Text("Complete this habit to see your progress history here")
                                        .font(.customFont("Lexend", .regular, 14))
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 40)
                                } else {
                                    Text("No Setbacks Recorded")
                                        .font(.customFont("Lexend", .semiBold, 20))
                                        .foregroundColor(.primary)
                                    
                                    Text("Keep going! Any setbacks will be recorded here")
                                        .font(.customFont("Lexend", .regular, 14))
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
                .padding(.vertical)
            }
            .navigationBarTitle(Text("\(habit.name ?? "Habit") History"), displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
            .glassBackground()
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
                Text("Are you sure you want to delete this setback record? This action cannot be undone.")
            }
        }
    }
    
    // Group completions by date
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

// MARK: - Date Section View
struct DateSectionView: View {
    let date: Date
    let completions: [Completion]
    let habit: Habit
    let habitColor: Color
    let onDeleteCompletion: (Completion) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Date Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(formatFullDate(date))
                        .font(.customFont("Lexend", .semiBold, 18))
                        .foregroundColor(.primary)
                    
                    Text(formatDayOfWeek(date))
                        .font(.customFont("Lexend", .regular, 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Summary badge showing completion count for the day
                HStack(spacing: 4) {
                    Image(systemName: habit.isBadHabit ? "x.circle.fill" : "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(habit.isBadHabit ? .red : .green)
                    
                    Text("\(completions.count) \(completions.count == 1 ? "entry" : "entries")")
                        .font(.customFont("Lexend", .medium, 12))
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(habitColor.opacity(0.12))
                )
            }
            .padding(.horizontal)
            .padding(.top, 16)
            
            // Completions for this date
            VStack(spacing: 0) {
                ForEach(completions, id: \.self) { completion in
                    CompletionDetailRowView(
                        completion: completion,
                        habit: habit,
                        habitColor: habitColor,
                        isLast: completion == completions.last,
                        onDelete: {
                            onDeleteCompletion(completion)
                        }
                    )
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .background(Color.clear)
    }
}

// MARK: - Completion Detail Row View
struct CompletionDetailRowView: View {
    let completion: Completion
    let habit: Habit
    let habitColor: Color
    let isLast: Bool
    let onDelete: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                // Status icon
                ZStack {
                    Circle()
                        .fill(completion.completed
                            ? (habit.isBadHabit ? Color.red.opacity(0.15) : Color.green.opacity(0.15))
                            : Color.gray.opacity(0.1))
                        .frame(width: 42, height: 42)
                    
                    Image(systemName: completion.completed
                        ? (habit.isBadHabit ? "x.circle.fill" : "checkmark.circle.fill")
                        : "circle")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(completion.completed
                            ? (habit.isBadHabit ? .red : .green)
                            : .gray)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    // Completion time and status
                    HStack {
                        if let loggedAt = completion.loggedAt {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Logged at \(formatTime(loggedAt))")
                                    .font(.customFont("Lexend", .medium, 14))
                                    .foregroundColor(.primary)
                                
                                Text("Completed on \(formatFullDateTime(completion.date))")
                                    .font(.customFont("Lexend", .regular, 11))
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            Text(habit.isBadHabit ? "Setback recorded" : "Completion recorded")
                                .font(.customFont("Lexend", .medium, 14))
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                    }
                    
                    // Duration information
                    if completion.duration > 0 {
                        HStack(spacing: 6) {
                            Image(systemName: "timer")
                                .font(.system(size: 12))
                                .foregroundColor(habitColor)
                            
                            Text("Duration: \(completion.duration) minutes")
                                .font(.customFont("Lexend", .regular, 12))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Notes if available
                    if let notes = completion.notes, !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "note.text")
                                .font(.system(size: 12))
                                .foregroundColor(habitColor)
                            
                            Text(notes)
                                .font(.customFont("Lexend", .regular, 12))
                                .foregroundColor(.secondary)
                                .lineLimit(3)
                        }
                        .padding(.top, 2)
                    }
                    
                    // Additional metadata
                    VStack(alignment: .leading, spacing: 2) {
                        // Show if time was tracked
                        if completion.duration > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.system(size: 10))
                                    .foregroundColor(.green)
                                
                                Text("Time tracked")
                                    .font(.customFont("Lexend", .regular, 10))
                                    .foregroundColor(.green)
                            }
                        }
                        
                        // Show creation vs completion time difference if available
                        if let loggedAt = completion.loggedAt,
                           let completionDate = completion.date,
                           !Calendar.current.isDate(loggedAt, inSameDayAs: completionDate) {
                            
                            HStack(spacing: 4) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 10))
                                    .foregroundColor(.orange)
                                
                                Text("Logged later")
                                    .font(.customFont("Lexend", .regular, 10))
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }
                
                Spacer(minLength: 8)
            }
            .padding(.vertical, 12)
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
            
            // Divider (except for last item)
            if !isLast {
                Divider()
                    .padding(.leading, 56)
            }
        }
    }
}

// MARK: - Date Formatting Extensions
extension DetailedHistoryView {
    private func formatFullDate(_ date: Date?) -> String {
        guard let date = date else { return "Unknown Date" }
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }
    
    private func formatDayOfWeek(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
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