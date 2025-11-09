import SwiftUI
import CoreData

struct HabitTriggerSheet: View {
    let habit: Habit
    let date: Date
    let habitColor: Color
    @Binding var isPresented: Bool
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var selectedTrigger: String = ""
    @State private var customTrigger: String = ""
    @State private var showCustomInput: Bool = false
    @FocusState private var isTextFieldFocused: Bool
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
    
    // Predefined triggers with icons
    private let predefinedTriggers: [(icon: String, text: String)] = [
        ("person.2", "Social pressure"),
        ("face.dashed", "Stress/anxiety"),
        ("moon.zzz", "Boredom"),
        ("exclamationmark.triangle", "Peer pressure"),
        ("heart.slash", "Emotional distress"),
        ("clock.arrow.circlepath", "Routine disruption"),
        ("location", "Specific location"),
        ("calendar.badge.exclamationmark", "Special occasion"),
        ("brain.head.profile", "Habit craving"),
        ("exclamationmark.bubble", "Lack of willpower")
    ]
    
    var body: some View {
        VStack(spacing: 24) {
            // Minimal header
            headerSection
            
            // Trigger selection section
            triggerSelectionSection
            
            // Custom input section (if needed)
            if showCustomInput {
                customInputSection
            }
            
            // Clean action buttons
            actionButtonsSection
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 20)
        .onAppear {
            loadExistingTrigger()
        }
    }
    
    @ViewBuilder
    private var headerSection: some View {
        HStack(spacing: 12) {
            // Simple icon circle
            ZStack {
                Circle()
                    .fill(habitColor.opacity(0.12))
                    .frame(width: 36, height: 36)
                
                Image(systemName: "exclamationmark.triangle")
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
    private var triggerSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section label
            Text("What triggered this slip?")
                .font(.custom("Lexend-Medium", size: 14))
                .foregroundColor(.secondary)
            
            // Trigger options in a clean grid (2 columns)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 10) {
                ForEach(Array(predefinedTriggers.enumerated()), id: \.offset) { index, trigger in
                    MinimalTriggerButton(
                        icon: trigger.icon,
                        text: trigger.text,
                        isSelected: selectedTrigger == trigger.text,
                        habitColor: habitColor,
                        colorScheme: colorScheme
                    ) {
                        selectedTrigger = trigger.text
                        customTrigger = ""
                        showCustomInput = false
                    }
                }
                
                // Custom trigger option
                MinimalTriggerButton(
                    icon: "plus.circle",
                    text: "Custom",
                    isSelected: showCustomInput,
                    habitColor: habitColor,
                    colorScheme: colorScheme
                ) {
                    showCustomInput = true
                    selectedTrigger = ""
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isTextFieldFocused = true
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var customInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Custom Trigger")
                .font(.custom("Lexend-Medium", size: 14))
                .foregroundColor(.secondary)
            
            ZStack(alignment: .topLeading) {
                // Simple background without border
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        colorScheme == .dark
                            ? Color(UIColor.systemGray5).opacity(0.3)
                            : Color.gray.opacity(0.08)
                    )
                
                // Text Field
                TextField("", text: $customTrigger, axis: .vertical)
                    .font(.custom("Lexend", size: 16))
                    .padding(16)
                    .background(Color.clear)
                    .focused($isTextFieldFocused)
                    .lineLimit(2...4)
                
                // Placeholder
                if customTrigger.isEmpty {
                    Text("Describe what triggered this...")
                        .font(.custom("Lexend", size: 16))
                        .foregroundColor(.secondary.opacity(0.6))
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .allowsHitTesting(false)
                }
            }
            .frame(minHeight: 80)
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
                saveTrigger()
            }) {
                Text("Save")
                    .font(.custom("Lexend-Medium", size: 15))
                    .foregroundColor(canSave ? habitColor : .secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
            }
            .glassButton()
            .disabled(!canSave)
            .opacity(canSave ? 1.0 : 0.6)
        }
    }
    
    private var canSave: Bool {
        !selectedTrigger.isEmpty || !customTrigger.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func loadExistingTrigger() {
        guard let completions = habit.completion as? Set<Completion> else { return }
        let calendar = Calendar.current
        
        if let completion = completions.first(where: { completion in
            guard let completionDate = completion.date else { return false }
            return calendar.isDate(completionDate, inSameDayAs: date) && 
                   completion.completed &&
                   completion.trigger != nil
        }), let existingTrigger = completion.trigger, let triggerName = existingTrigger.name, !triggerName.isEmpty {
            
            // Check if it matches a predefined trigger
            if predefinedTriggers.contains(where: { $0.text == triggerName }) {
                selectedTrigger = triggerName
                showCustomInput = false
            } else {
                // It's a custom trigger
                customTrigger = triggerName
                showCustomInput = true
            }
        }
    }
    
    private func saveTrigger() {
        let triggerText = showCustomInput ? customTrigger.trimmingCharacters(in: .whitespacesAndNewlines) : selectedTrigger
        
        guard !triggerText.isEmpty else { return }
        
        // Find the completion for this date
        guard let completions = habit.completion as? Set<Completion> else { return }
        let calendar = Calendar.current
        
        if let completion = completions.first(where: { completion in
            guard let completionDate = completion.date else { return false }
            return calendar.isDate(completionDate, inSameDayAs: date) && completion.completed
        }) {
            
            // Create or update the Trigger entity
            let trigger: Trigger
            if let existingTrigger = completion.trigger {
                trigger = existingTrigger
            } else {
                trigger = Trigger(context: viewContext)
                trigger.id = UUID()
            }
            
            trigger.name = triggerText
            
            // Set icon based on predefined triggers or use default for custom
            if let predefinedTrigger = predefinedTriggers.first(where: { $0.text == triggerText }) {
                trigger.icon = predefinedTrigger.icon
            } else {
                trigger.icon = "plus.circle" // Default icon for custom triggers
            }
            
            // Link trigger to completion
            completion.trigger = trigger
            
            do {
                try viewContext.save()
                isPresented = false
                print("✅ Successfully saved trigger for habit: \(habit.name ?? "Unknown")")
                
                // Haptic feedback
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } catch {
                print("❌ Failed to save trigger: \(error)")
                viewContext.rollback()
            }
        }
    }
}

// MARK: - Minimal Trigger Button Component
struct MinimalTriggerButton: View {
    let icon: String
    let text: String
    let isSelected: Bool
    let habitColor: Color
    let colorScheme: ColorScheme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? habitColor : .primary)
                    .frame(width: 20)
                
                // Text
                Text(text)
                    .font(.custom("Lexend-Medium", size: 13))
                    .foregroundColor(isSelected ? habitColor : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(height: 42)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        colorScheme == .dark
                            ? Color(UIColor.systemGray5).opacity(isSelected ? 0.3 : 0.2)
                            : Color.gray.opacity(isSelected ? 0.12 : 0.06)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(
                                isSelected ? habitColor.opacity(0.4) : Color.clear,
                                lineWidth: 1.5
                            )
                    )
            )
            .scaleEffect(isSelected ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Extension to check if habit has trigger for a date
extension Habit {
    func hasTrigger(for date: Date) -> Bool {
        let calendar = Calendar.current
        guard let completions = completion as? Set<Completion> else { return false }
        
        return completions.contains { completion in
            guard let completionDate = completion.date else { return false }
            return calendar.isDate(completionDate, inSameDayAs: date) && 
                   completion.completed && 
                   completion.trigger != nil &&
                   completion.trigger?.name != nil &&
                   !completion.trigger!.name!.isEmpty
        }
    }
}

// MARK: - Preview
#Preview {
    let context = PersistenceController.preview.container.viewContext
    let habit = Habit(context: context)
    habit.name = "Quit Smoking"
    habit.id = UUID()
    habit.isBadHabit = true
    
    return HabitTriggerSheet(
        habit: habit,
        date: Date(),
        habitColor: .red,
        isPresented: .constant(true)
    )
    .environment(\.managedObjectContext, context)
    .presentationDetents([.fraction(0.65)])
}
