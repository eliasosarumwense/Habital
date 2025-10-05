import SwiftUI
import CoreData

// MARK: - Main AI Habit Generation View

struct AIHabitGenerationView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @StateObject private var viewModel: AIHabitViewModel
    @State private var selectedHabitList: HabitList?
    @State private var showingHabitListPicker = false
    @FocusState private var isInputFocused: Bool
    
    // Fetch habit lists for selection
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \HabitList.order, ascending: true)],
        animation: .default
    )
    private var habitLists: FetchedResults<HabitList>
    
    init(viewContext: NSManagedObjectContext) {
        self._viewModel = StateObject(wrappedValue: AIHabitViewModel(viewContext: viewContext))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    inputSection
                    providerInfoSection
                    
                    if viewModel.isGenerating {
                        loadingSection
                    } else if !viewModel.generatedHabits.isEmpty {
                        resultsSection
                    }
                    
                    if let errorMessage = viewModel.errorMessage {
                        errorSection(errorMessage)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .navigationTitle("AI Habit Generator")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                if !viewModel.generatedHabits.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save All") {
                            viewModel.saveAllHabits(to: selectedHabitList)
                            dismiss()
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingManualInput) {
                ManualInputSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $showingHabitListPicker) {
                HabitListPickerSheet(
                    habitLists: Array(habitLists),
                    selectedHabitList: $selectedHabitList
                )
            }
        }
    }
    
    // MARK: - UI Sections
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.blue)
                .padding(.bottom, 8)
            
            Text("Generate Smart Habits")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Tell me what you want to improve, and I'll suggest 5 personalized habits to help you achieve your goals.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
        }
        .padding(.horizontal)
    }
    
    private var inputSection: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "target")
                        .foregroundColor(.blue)
                        .font(.system(size: 16, weight: .medium))
                    
                    Text("What do you want to improve?")
                        .font(.headline)
                        .fontWeight(.medium)
                }
                
                Text("Be specific about your goals (e.g., \"reduce stress\", \"get fit\", \"learn new skills\")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            TextField("I want to reduce stress in my daily life...", text: $viewModel.userInput, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...6)
                .focused($isInputFocused)
            
            // Habit List Selection
            HStack {
                Image(systemName: "tray.2")
                    .foregroundColor(.orange)
                    .font(.system(size: 16, weight: .medium))
                
                Text("Save to habit list:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button(action: { showingHabitListPicker = true }) {
                    HStack(spacing: 4) {
                        Text(selectedHabitList?.name ?? "Default")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
            
            Button(action: {
                isInputFocused = false
                Task {
                    await viewModel.generateHabits()
                }
            }) {
                HStack {
                    if viewModel.isGenerating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "sparkles")
                            .font(.system(size: 16, weight: .medium))
                    }
                    
                    Text(viewModel.isGenerating ? "Generating..." : "Generate Habits")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    viewModel.userInput.isEmpty ? Color.gray : Color.blue
                )
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(viewModel.userInput.isEmpty || viewModel.isGenerating)
        }
        .padding(.horizontal)
    }
    
    private var providerInfoSection: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: providerStatusIcon)
                    .foregroundColor(providerStatusColor)
                
                Text("Using: \(viewModel.providerName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            // Show setup message if Apple Intelligence needs configuration
            if needsAppleIntelligenceSetup {
                HStack {
                    Image(systemName: "gear")
                        .foregroundColor(.orange)
                        .font(.caption)
                    
                    Text("Enable Apple Intelligence in Settings for direct AI generation")
                        .font(.caption2)
                        .foregroundColor(.orange)
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding(.horizontal)
    }
    
    private var providerStatusIcon: String {
        if viewModel.isAIDirectlyAvailable {
            return "checkmark.circle.fill"
        } else if needsAppleIntelligenceSetup {
            return "gear.circle"
        } else {
            return "info.circle"
        }
    }
    
    private var providerStatusColor: Color {
        if viewModel.isAIDirectlyAvailable {
            return .green
        } else if needsAppleIntelligenceSetup {
            return .orange
        } else {
            return .blue
        }
    }
    
    private var needsAppleIntelligenceSetup: Bool {
        return viewModel.providerName.contains("Setup Required") ||
               viewModel.providerName.contains("Unavailable")
    }
    
    private var loadingSection: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.2)
            
            Text("Analyzing your goals and generating personalized habits...")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private var resultsSection: some View {
        VStack(spacing: 20) {
            // Explanation section
            if !viewModel.explanation.isEmpty {
                ExplanationCard(
                    explanation: viewModel.explanation,
                    userAnalysis: viewModel.userAnalysis
                )
            }
            
            // Generated habits
            VStack(spacing: 16) {
                HStack {
                    Text("Generated Habits")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Text("\(viewModel.generatedHabits.count) habits")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray6))
                        .cornerRadius(6)
                }
                
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.generatedHabits) { habit in
                        GeneratedHabitCard(
                            habit: habit,
                            onSave: {
                                viewModel.saveHabitToCoreData(habit, habitList: selectedHabitList)
                                // Remove from generated list after saving
                                viewModel.generatedHabits.removeAll { $0.id == habit.id }
                            }
                        )
                    }
                }
            }
            
            // Action buttons
            HStack(spacing: 12) {
                Button("Clear Results") {
                    viewModel.clearData()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .foregroundColor(.primary)
                .cornerRadius(8)
                
                Spacer()
                
                Button("Generate More") {
                    Task {
                        await viewModel.generateHabits()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                .disabled(viewModel.userInput.isEmpty)
            }
        }
        .padding(.horizontal)
    }
    
    private func errorSection(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle")
                .foregroundColor(.red)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.red)
            
            Spacer()
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

// MARK: - Supporting Views

struct ExplanationCard: View {
    let explanation: String
    let userAnalysis: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb")
                    .foregroundColor(.yellow)
                
                Text("AI Insights")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            if !explanation.isEmpty {
                Text(explanation)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            
            if !userAnalysis.isEmpty {
                Divider()
                
                Text("Analysis:")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Text(userAnalysis)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct GeneratedHabitCard: View {
    let habit: AIGeneratedHabit
    let onSave: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var habitColor: Color {
        switch habit.color.lowercased() {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "red": return .red
        case "purple": return .purple
        case "pink": return .pink
        case "yellow": return .yellow
        default: return .blue
        }
    }
    
    private var intensityText: String {
        switch habit.intensityLevel {
        case 1: return "Light"
        case 2: return "Moderate"
        case 3: return "High"
        case 4: return "Extreme"
        default: return "Unknown"
        }
    }
    
    private var intensityColor: Color {
        switch habit.intensityLevel {
        case 1: return .green
        case 2: return .blue
        case 3: return .orange
        case 4: return .red
        default: return .gray
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                // Icon
                ZStack {
                    Circle()
                        .fill(habitColor.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: habit.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(habitColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(habit.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    
                    Text(habit.category.capitalized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color(.systemGray5))
                        .cornerRadius(6)
                }
                
                Spacer()
                
                Button(action: onSave) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                }
            }
            
            // Description
            Text(habit.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            // Details
            VStack(spacing: 8) {
                // Intensity and Repeats
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "gauge.medium")
                            .font(.caption)
                            .foregroundColor(intensityColor)
                        
                        Text(intensityText)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(intensityColor)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(intensityColor.opacity(0.1))
                    .cornerRadius(6)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "repeat")
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        Text("\(habit.repeatsPerDay)x/day")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text("\(habit.estimatedTimeMinutes)m")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.gray)
                    }
                }
                
                // Goal Type and Mood Impact
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundColor(.purple)
                        
                        Text(habit.goalType.capitalized)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.purple)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(6)
                    
                    if habit.moodImpact != 0 {
                        HStack(spacing: 4) {
                            Image(systemName: habit.moodImpact > 0 ? "face.smiling" : "face.dashed")
                                .font(.caption)
                                .foregroundColor(habit.moodImpact > 0 ? .green : .red)
                            
                            Text(habit.moodImpact > 0 ? "+\(String(format: "%.1f", habit.moodImpact))" : String(format: "%.1f", habit.moodImpact))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(habit.moodImpact > 0 ? .green : .red)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background((habit.moodImpact > 0 ? Color.green : Color.red).opacity(0.1))
                        .cornerRadius(6)
                    }
                    
                    Spacer()
                }
                
                // Recommended Days (if any)
                if let recommendedDays = habit.recommendedDays, !recommendedDays.isEmpty {
                    HStack {
                        Image(systemName: "calendar.badge.checkmark")
                            .font(.caption)
                            .foregroundColor(.orange)
                        
                        Text("Recommended: \(recommendedDays.joined(separator: ", "))")
                            .font(.caption)
                            .foregroundColor(.orange)
                        
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(
                    color: colorScheme == .dark ? .clear : .black.opacity(0.05),
                    radius: 2,
                    x: 0,
                    y: 1
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray5), lineWidth: 0.5)
        )
    }
}

struct ManualInputSheet: View {
    @ObservedObject var viewModel: AIHabitViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Instructions
                VStack(alignment: .leading, spacing: 12) {
                    Text("ChatGPT Integration")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Since Apple Intelligence isn't available, please follow these steps:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("1. Copy the prompt below")
                        Text("2. Paste it into ChatGPT")
                        Text("3. Copy ChatGPT's response")
                        Text("4. Paste the response in the text field")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                // Prompt to copy
                VStack(alignment: .leading, spacing: 8) {
                    Text("Prompt to copy:")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    ScrollView {
                        Text(viewModel.chatGPTPrompt)
                            .font(.caption)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    .frame(maxHeight: 200)
                    
                    Button("Copy Prompt") {
                        UIPasteboard.general.string = viewModel.chatGPTPrompt
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                
                // Response input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Paste ChatGPT's response:")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    TextEditor(text: $viewModel.chatGPTResponse)
                        .font(.caption)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .frame(minHeight: 150)
                }
                
                Spacer()
                
                // Process button
                Button("Process Response") {
                    viewModel.processManualResponse()
                    if viewModel.errorMessage == nil {
                        dismiss()
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(viewModel.chatGPTResponse.isEmpty ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(viewModel.chatGPTResponse.isEmpty)
                
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
            .navigationTitle("Manual Input")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct HabitListPickerSheet: View {
    let habitLists: [HabitList]
    @Binding var selectedHabitList: HabitList?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                // Default option (no list)
                Button(action: {
                    selectedHabitList = nil
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "tray")
                            .foregroundColor(.gray)
                            .frame(width: 24)
                        
                        Text("Default")
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if selectedHabitList == nil {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                // Habit lists
                ForEach(habitLists, id: \.id) { habitList in
                    Button(action: {
                        selectedHabitList = habitList
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: habitList.icon ?? "tray.2")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            
                            Text(habitList.name ?? "Unnamed")
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if selectedHabitList?.id == habitList.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Habit List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

struct AIHabitGenerationView_Previews: PreviewProvider {
    static var previews: some View {
        // You'll need to replace this with your actual persistence controller
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        AIHabitGenerationView(viewContext: context)
    }
}
