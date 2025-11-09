import SwiftUI
import CoreData

struct HabitNotesSheet: View {
    let habit: Habit
    let date: Date
    let habitColor: Color
    @Binding var isPresented: Bool
    
    @Environment(\.managedObjectContext) private var viewContext
    @State private var noteText: String = ""
    @State private var hasLoadedExistingNote: Bool = false
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with date info
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Note for")
                            .font(.custom("Lexend-Medium", size: 16))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    
                    Text(dateFormatter.string(from: date))
                        .font(.custom("Lexend-SemiBold", size: 20))
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 16)
                
                // Text Editor
                TextEditor(text: $noteText)
                    .font(.custom("Lexend", size: 16))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.regularMaterial)
                            .stroke(habitColor.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                    .scrollContentBackground(.hidden) // Hide default background
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 12) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .font(.custom("Lexend-Medium", size: 16))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    
                    Button("Save") {
                        saveNote()
                        isPresented = false
                    }
                    .font(.custom("Lexend-Medium", size: 16))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(habitColor, in: RoundedRectangle(cornerRadius: 12))
                    .disabled(noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationTitle(habit.name ?? "Habit")
            .navigationBarTitleDisplayMode(.inline)
            .background(.regularMaterial)
        }
        .onAppear {
            loadExistingNote()
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
            newCompletion.id = UUID()
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