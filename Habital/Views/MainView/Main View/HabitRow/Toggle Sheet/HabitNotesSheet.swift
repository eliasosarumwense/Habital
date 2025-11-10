import SwiftUI
import CoreData

struct HabitNotesSheet: View {
    let habit: Habit
    let date: Date
    let habitColor: Color
    @Binding var isPresented: Bool
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    @State private var noteText: String = ""
    @State private var hasLoadedExistingNote: Bool = false
    @FocusState private var isTextEditorFocused: Bool
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Minimal header
            headerSection
            
            // Simple text editor
            textEditorSection
            
            // Clean action buttons
            actionButtonsSection
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 20)
        
        .onAppear {
            loadExistingNote()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isTextEditorFocused = true
            }
        }
    }
    
    // MARK: - Minimal Background (Matching your other views)
    private var minimalBackground: some View {
        ZStack {
            // Base background matching HabitRowView style
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    colorScheme == .dark
                        ? Color(red: 0.11, green: 0.11, blue: 0.12)
                        : Color(red: 0.97, green: 0.97, blue: 0.98)
                )
            
            // Subtle border
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(
                    habitColor.opacity(colorScheme == .dark ? 0.15 : 0.25),
                    lineWidth: 1
                )
        }
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.25 : 0.08),
            radius: 12,
            x: 0,
            y: 6
        )
    }
    
    @ViewBuilder
    private var headerSection: some View {
        HStack(spacing: 12) {
            // Simple icon circle
            ZStack {
                Circle()
                    .fill(habitColor.opacity(0.12))
                    .frame(width: 36, height: 36)
                
                Image(systemName: "note.text")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(habitColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name ?? "Habit")
                    .font(.custom("Lexend-SemiBold", size: 16))
                    .foregroundColor(.primary)
                
                Text(dateFormatter.string(from: date))
                    .font(.custom("Lexend", size: 13))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
    
    @ViewBuilder
    private var textEditorSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Simple section label
            HStack {
                Text("Notes")
                    .font(.custom("Lexend-Medium", size: 14))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if !noteText.isEmpty {
                    Text("\(noteText.count)")
                        .font(.custom("Lexend", size: 12))
                        .foregroundColor(.secondary.opacity(0.7))
                }
            }
            
            // Minimal text editor
            ZStack(alignment: .topLeading) {
                // Simple background without border
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        colorScheme == .dark
                            ? Color(UIColor.systemGray5).opacity(0.3)
                            : Color.gray.opacity(0.08)
                    )
                
                // Text Editor
                TextEditor(text: $noteText)
                    .font(.custom("Lexend", size: 16))
                    .padding(16)
                    .background(Color.clear)
                    .scrollContentBackground(.hidden)
                    .focused($isTextEditorFocused)
                
                // Placeholder
                if noteText.isEmpty {
                    Text("Add a note for this habit...")
                        .font(.custom("Lexend", size: 16))
                        .foregroundColor(.secondary.opacity(0.6))
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        .allowsHitTesting(false)
                }
            }
            .frame(minHeight: 100)
        }
    }
    
    @ViewBuilder
    private var actionButtonsSection: some View {
        HStack(spacing: 12) {
            // Cancel button
            Button(action: {
                isPresented = false
            }) {
                Text("Cancel")
                    .font(.custom("Lexend-Medium", size: 15))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
            }
            .glassButton()
            
            // Save button
            Button(action: {
                saveNote()
                isPresented = false
            }) {
                Text(noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Skip" : "Save")
                    .font(.custom("Lexend-Medium", size: 15))
                    .foregroundColor(noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .secondary : habitColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
            }
            .glassButton()
        }
    }

    
    private func loadExistingNote() {
        guard !hasLoadedExistingNote else { return }
        
        let calendar = Calendar.current
        guard let completions = habit.completion as? Set<Completion> else {
            hasLoadedExistingNote = true
            return
        }
        
        // Find completion for this date
        if let completion = completions.first(where: { completion in
            guard let completionDate = completion.date else { return false }
            return calendar.isDate(completionDate, inSameDayAs: date)
        }), let existingNote = completion.notes {
            noteText = existingNote
        }
        
        hasLoadedExistingNote = true
    }
    
    private func saveNote() {
        let calendar = Calendar.current
        guard let completions = habit.completion as? Set<Completion> else { return }
        
        let trimmedNote = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Find existing completion for this date
        let existingCompletion = completions.first { completion in
            guard let completionDate = completion.date else { return false }
            return calendar.isDate(completionDate, inSameDayAs: date)
        }
        
        if let completion = existingCompletion {
            // Update existing completion
            if trimmedNote.isEmpty {
                completion.notes = nil
            } else {
                completion.notes = trimmedNote
            }
        } else if !trimmedNote.isEmpty {
            // Create new completion with just a note (not marked as completed)
            let newCompletion = Completion(context: viewContext)
            newCompletion.date = date
            newCompletion.habit = habit
            newCompletion.completed = false
            newCompletion.skipped = false
            newCompletion.notes = trimmedNote
            newCompletion.loggedAt = Date()
            newCompletion.tracksTime = false
        }
        
        do {
            try viewContext.save()
            print("✅ Successfully saved note for habit: \(habit.name ?? "Unknown")")
        } catch {
            print("❌ Failed to save note: \(error)")
            viewContext.rollback()
        }
    }
}

// Helper function to check if a note exists for a given date
extension Habit {
    func hasNote(for date: Date) -> Bool {
        let calendar = Calendar.current
        guard let completions = completion as? Set<Completion> else { return false }
        
        return completions.contains { completion in
            guard let completionDate = completion.date else { return false }
            return calendar.isDate(completionDate, inSameDayAs: date) && 
                   completion.notes != nil && 
                   !completion.notes!.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
}

#Preview {
    // Create preview mock habit
    let context = PersistenceController.preview.container.viewContext
    let habit = Habit(context: context)
    habit.name = "Read Books"
    habit.id = UUID()
    
    return HabitNotesSheet(
        habit: habit,
        date: Date(),
        habitColor: .blue,
        isPresented: .constant(true)
    )
    .environment(\.managedObjectContext, context)
}
