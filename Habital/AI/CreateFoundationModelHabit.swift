import Foundation
import SwiftUI
import CoreData
#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - Standalone Data Models (No dependencies on your project structs)

struct AIGeneratedHabit: Identifiable, Codable {
    let id = UUID()
    let name: String
    let description: String
    let category: String
    let intensityLevel: Int  // 1-4
    let repeatsPerDay: Int   // 1-10
    let isBadHabit: Bool
    let estimatedTimeMinutes: Int
    let icon: String
    let color: String
    let moodImpact: Double   // -1.0 to 1.0
    let recommendedDays: [String]? // Optional specific days
    let goalType: String     // "daily", "weekly", "monthly"
    let startDate: String    // ISO8601 date string
}

struct AIHabitResponse: Codable {
    let habits: [AIGeneratedHabit]
    let explanation: String?
    let userAnalysis: String?
}

// MARK: - AI Provider Protocol

protocol HabitAIProvider {
    func generateHabits(for input: String) async throws -> [AIGeneratedHabit]
    var isAvailable: Bool { get }
    var providerName: String { get }
}

// MARK: - Foundation Models Provider

#if canImport(FoundationModels)
@available(iOS 26.0, *)
struct FoundationModelsProvider: HabitAIProvider {
    var isAvailable: Bool {
        SystemLanguageModel.default.availability == .available
    }

    var availabilityStatus: String {
        switch SystemLanguageModel.default.availability {
        case .available:   return "ready"
        case .unavailable: return "unavailable"
        @unknown default:  return "unknown"
        }
    }

    var providerName: String { "Apple Intelligence" }

    // MARK: - Public API

    func generateHabits(for input: String) async throws -> [AIGeneratedHabit] {
        if Self.isSensitive(input) {
            #if DEBUG
            print("⚠️ Sensitive input flagged, using contextual fallback. Input: \(input)")
            #endif
            return createContextualHabits(for: input)
        }

        let instructions = Instructions("""
        You are a general wellness and lifestyle assistant.
        Provide everyday, non-medical ideas ONLY.
        Do NOT provide medical, psychological, therapeutic, diagnostic, or treatment advice.
        If asked for medical or mental-health guidance, politely decline.
        Keep suggestions practical and short (titles + brief descriptions).
        """)

        let userPrompt = Self.safeUserPrompt(for: input)
        let session = LanguageModelSession(instructions: instructions)

        do {
            let response = try await session.respond(to: userPrompt)
            #if DEBUG
            print("✅ Got AI content (\(response.content.count) chars)")
            #endif
            return parseNaturalLanguageToHabits(response.content, for: input)
        } catch let err as LanguageModelSession.GenerationError {
            #if DEBUG
            print("🧯 AI guardrail violation: \(err). Falling back to contextual suggestions.")
            #endif
            return createContextualHabits(for: input)
        } catch {
            #if DEBUG
            print("❌ AI error: \(error.localizedDescription). Falling back to contextual suggestions.")
            #endif
            return createContextualHabits(for: input)
        }
    }

    // MARK: - Guardrail helpers

    private static func isSensitive(_ text: String) -> Bool {
        // Terms that often route queries into regulated health/mental-health territory.
        // Tweak as you see usage in your app.
        let terms = [
            "stress", "anxiety", "panic", "depress", "ptsd", "trauma",
            "therapy", "therapeutic", "diagnosis", "treatment",
            "addiction", "self-harm", "self harm", "suicide"
        ]
        return terms.contains { text.localizedCaseInsensitiveContains($0) }
    }

    private static func safeUserPrompt(for input: String) -> String {
        return """
        Goal (user text): "\(input)"

        Task: Suggest exactly 5 everyday, non-medical habits that support general wellbeing,
        focus, and balanced routines.

        OUTPUT FORMAT (strict):
        Return EXACTLY 5 separate lines.
        Each line MUST be: Title: description
        Example:
        Short walk: Take a 10-minute walk after lunch.
        Evening plan: Spend 5 minutes planning tomorrow.

        Rules:
        - no medical/psychological/therapeutic claims or instructions
        - everyday activities only (light movement, journaling, planning, breaks, hydration)
        - keep each description under 120 characters
        """
    }

    // MARK: - Parsing (unchanged from your version, minor tweaks allowed)

    private func parseNaturalLanguageToHabits(_ content: String, for input: String) -> [AIGeneratedHabit] {
        let baseHabits = createContextualHabits(for: input)

        let lines = content
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var extracted: [AIGeneratedHabit] = []
        for line in lines {
            if let habit = extractHabitFromLine(line, for: input) {
                extracted.append(habit)
                if extracted.count == 5 { break }
            }
        }

        #if DEBUG
        print("🧩 AI lines: \(lines.count), extracted: \(extracted.count)")
        if extracted.isEmpty { print("↪️ Falling back: no parsable lines") }
        #endif

        return extracted.isEmpty ? baseHabits : extracted
    }

    private func extractHabitFromLine(_ line: String, for input: String) -> AIGeneratedHabit? {
        let lower = line.lowercased()
        guard line.count > 10 && line.count < 240 else { return nil }
        guard !lower.contains("here are") && !lower.contains("suggestions") else { return nil }

        guard let (title, desc) = splitTitleDesc(line) else { return nil }

        let name = cleanTitle(title)
        let rawDesc = desc.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty && !rawDesc.isEmpty else { return nil }

        let description = Self.neutralizeClaims(String(rawDesc.prefix(150)))

        return AIGeneratedHabit(
            name: String(name.prefix(50)),
            description: description,
            category: inferCategory(from: name + " " + description, for: input),
            intensityLevel: inferIntensity(from: name + " " + description),
            repeatsPerDay: 1,
            isBadHabit: lower.contains("stop") || lower.contains("quit") || lower.contains("avoid"),
            estimatedTimeMinutes: inferDuration(from: name + " " + description),
            icon: inferIcon(from: name + " " + description),
            color: inferColor(from: name + " " + description),
            moodImpact: 0.5,
            recommendedDays: nil,
            goalType: "daily",
            startDate: ISO8601DateFormatter().string(from: Date())
        )
    }
    
    private func splitTitleDesc(_ line: String) -> (String, String)? {
        // Try several separators in order of strictness
        let seps: [String] = [":", " — ", " – ", " - ", "—", "–", "-"]
        for sep in seps {
            if let r = line.range(of: sep) {
                let title = String(line[..<r.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                let desc  = String(line[r.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
                if !title.isEmpty && !desc.isEmpty { return (title, desc) }
            }
        }
        return nil
    }

    private func cleanTitle(_ raw: String) -> String {
        var t = raw
        // Remove bullets/numbers like "•", "-", "1.", "1)", "*"
        t = t.replacingOccurrences(of: "•", with: "")
             .replacingOccurrences(of: "*", with: "")
             .replacingOccurrences(of: "-", with: "")
             .trimmingCharacters(in: .whitespacesAndNewlines)
        t = t.replacingOccurrences(of: #"^\d+[\.\)]\s*"#, with: "", options: .regularExpression)
        return t
    }

    private static func neutralizeClaims(_ text: String) -> String {
        // Soft replacement to avoid therapeutic/medical phrasing if it slips in.
        let replacements: [(String, String)] = [
            ("reduce stress", "feel calmer"),
            ("reduce anxiety", "feel more at ease"),
            ("anxiety", "tension"),
            ("depress", "low mood"),
            ("therapy", "supportive routine"),
            ("treat", "support"),
            ("diagnos", "identify patterns"),
            ("mental health", "wellbeing")
        ]
        return replacements.reduce(text) { acc, pair in
            acc.replacingOccurrences(of: pair.0, with: pair.1, options: .caseInsensitive)
        }
    }

    private func createContextualHabits(for input: String) -> [AIGeneratedHabit] {
        let lowercased = input.lowercased()
        let currentDate = ISO8601DateFormatter().string(from: Date())
        
        // Create habits based on common improvement goals
        if lowercased.contains("stress") || lowercased.contains("anxiety") || lowercased.contains("relax") {
            return [
                AIGeneratedHabit(name: "Deep breathing", description: "Practice 5-minute breathing exercises to reduce stress and promote calm", category: "mindfulness", intensityLevel: 1, repeatsPerDay: 2, isBadHabit: false, estimatedTimeMinutes: 5, icon: "lungs.fill", color: "blue", moodImpact: 0.7, recommendedDays: nil, goalType: "daily", startDate: currentDate),
                AIGeneratedHabit(name: "Short walk", description: "Take a 15-minute walk to clear your mind and reduce tension", category: "health", intensityLevel: 1, repeatsPerDay: 1, isBadHabit: false, estimatedTimeMinutes: 15, icon: "figure.walk", color: "green", moodImpact: 0.5, recommendedDays: nil, goalType: "daily", startDate: currentDate),
                AIGeneratedHabit(name: "Gratitude journal", description: "Write down three things you're grateful for each day", category: "mindfulness", intensityLevel: 1, repeatsPerDay: 1, isBadHabit: false, estimatedTimeMinutes: 10, icon: "book.fill", color: "purple", moodImpact: 0.6, recommendedDays: nil, goalType: "daily", startDate: currentDate)
            ]
        } else if lowercased.contains("fitness") || lowercased.contains("exercise") || lowercased.contains("health") {
            return [
                AIGeneratedHabit(name: "Morning stretch", description: "Start each day with 10 minutes of gentle stretching", category: "health", intensityLevel: 1, repeatsPerDay: 1, isBadHabit: false, estimatedTimeMinutes: 10, icon: "figure.flexibility", color: "green", moodImpact: 0.4, recommendedDays: nil, goalType: "daily", startDate: currentDate),
                AIGeneratedHabit(name: "Walk 8000 steps", description: "Aim for 8000 steps throughout the day for cardiovascular health", category: "health", intensityLevel: 2, repeatsPerDay: 1, isBadHabit: false, estimatedTimeMinutes: 45, icon: "figure.walk", color: "blue", moodImpact: 0.5, recommendedDays: nil, goalType: "daily", startDate: currentDate),
                AIGeneratedHabit(name: "Drink water", description: "Drink a glass of water every 2 hours to stay hydrated", category: "health", intensityLevel: 1, repeatsPerDay: 4, isBadHabit: false, estimatedTimeMinutes: 2, icon: "drop.fill", color: "blue", moodImpact: 0.3, recommendedDays: nil, goalType: "daily", startDate: currentDate)
            ]
        } else {
            // Generic improvement habits
            return [
                AIGeneratedHabit(name: "Read 20 pages", description: "Read for personal growth and knowledge expansion", category: "learning", intensityLevel: 2, repeatsPerDay: 1, isBadHabit: false, estimatedTimeMinutes: 25, icon: "book.fill", color: "purple", moodImpact: 0.4, recommendedDays: nil, goalType: "daily", startDate: currentDate),
                AIGeneratedHabit(name: "Plan tomorrow", description: "Spend 10 minutes planning the next day for better organization", category: "productivity", intensityLevel: 1, repeatsPerDay: 1, isBadHabit: false, estimatedTimeMinutes: 10, icon: "calendar", color: "orange", moodImpact: 0.3, recommendedDays: nil, goalType: "daily", startDate: currentDate),
                AIGeneratedHabit(name: "Tidy workspace", description: "Keep your environment organized for improved focus", category: "productivity", intensityLevel: 1, repeatsPerDay: 1, isBadHabit: false, estimatedTimeMinutes: 10, icon: "archivebox.fill", color: "green", moodImpact: 0.3, recommendedDays: nil, goalType: "daily", startDate: currentDate)
            ]
        }
    }

    // Helper functions for inference
    private func inferCategory(from text: String, for input: String) -> String {
        let lowercased = text.lowercased()
        if lowercased.contains("exercise") || lowercased.contains("walk") || lowercased.contains("fitness") { return "health" }
        if lowercased.contains("read") || lowercased.contains("study") || lowercased.contains("learn") { return "learning" }
        if lowercased.contains("meditat") || lowercased.contains("breath") || lowercased.contains("mindful") { return "mindfulness" }
        if lowercased.contains("work") || lowercased.contains("plan") || lowercased.contains("organize") { return "productivity" }
        return "lifestyle"
    }

    private func inferIntensity(from text: String) -> Int {
        let lowercased = text.lowercased()
        if lowercased.contains("quick") || lowercased.contains("5 min") || lowercased.contains("brief") { return 1 }
        if lowercased.contains("30 min") || lowercased.contains("moderate") { return 2 }
        if lowercased.contains("60 min") || lowercased.contains("hour") || lowercased.contains("intense") { return 3 }
        return 1
    }

    private func inferDuration(from text: String) -> Int {
        if text.contains("5 min") { return 5 }
        if text.contains("10 min") { return 10 }
        if text.contains("15 min") { return 15 }
        if text.contains("30 min") { return 30 }
        if text.contains("hour") { return 60 }
        return 15 // default
    }

    private func inferIcon(from text: String) -> String {
        let lowercased = text.lowercased()
        if lowercased.contains("walk") { return "figure.walk" }
        if lowercased.contains("read") { return "book.fill" }
        if lowercased.contains("breath") { return "lungs.fill" }
        if lowercased.contains("water") { return "drop.fill" }
        if lowercased.contains("exercise") { return "figure.run" }
        if lowercased.contains("meditat") { return "brain.head.profile" }
        if lowercased.contains("write") || lowercased.contains("journal") { return "pencil" }
        return "heart.fill"
    }

    private func inferColor(from text: String) -> String {
        let lowercased = text.lowercased()
        if lowercased.contains("health") || lowercased.contains("exercise") { return "green" }
        if lowercased.contains("mindful") || lowercased.contains("meditat") { return "purple" }
        if lowercased.contains("learn") || lowercased.contains("read") { return "blue" }
        if lowercased.contains("work") || lowercased.contains("productive") { return "orange" }
        return "blue"
    }
}
#endif

// MARK: - ChatGPT Fallback Provider

struct ChatGPTProvider: HabitAIProvider {
    var isAvailable: Bool { true }
    var providerName: String { "ChatGPT (Manual)" }
    
    func generateHabits(for input: String) async throws -> [AIGeneratedHabit] {
        throw AIProviderError.manualInputRequired
    }
    
    func generatePrompt(for input: String) -> String {
        return """
        I want to create habits to help me: \(input)
        
        Please respond with EXACTLY this JSON format (copy and paste the response):

        {
          "habits": [
            {
              "name": "Walk 8000 steps",
              "description": "Daily walking improves cardiovascular health and reduces stress",
              "category": "health",
              "intensityLevel": 2,
              "repeatsPerDay": 1,
              "isBadHabit": false,
              "estimatedTimeMinutes": 30,
              "icon": "figure.walk",
              "color": "blue",
              "moodImpact": 0.6,
              "recommendedDays": null,
              "goalType": "daily",
              "startDate": "\(ISO8601DateFormatter().string(from: Date()))"
            }
          ],
          "explanation": "Why these habits help",
          "userAnalysis": "Analysis of the user's needs"
        }

        Create 5 specific, measurable habits for: \(input)
        
        Rules:
        - name: Be specific and measurable
        - category: health, productivity, learning, social, creativity, mindfulness, finance, lifestyle
        - intensityLevel: 1=Light(5-15min), 2=Moderate(15-30min), 3=High(30-60min), 4=Extreme(60min+)
        - icon: Use SF Symbols (figure.walk, book.fill, brain.head.profile, etc.)
        - color: blue, green, orange, red, purple, pink, yellow, primary
        - moodImpact: -1.0 to 1.0 (negative for bad habits, positive for good habits)
        - goalType: daily, weekly, or monthly
        """
    }
}

// MARK: - AI Provider Errors

enum AIProviderError: LocalizedError {
    case invalidResponse
    case manualInputRequired
    case providerUnavailable
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from AI provider"
        case .manualInputRequired:
            return "Manual input required"
        case .providerUnavailable:
            return "AI provider is not available"
        case .networkError:
            return "Network error occurred"
        }
    }
}

// MARK: - AI Habit Generation ViewModel

class AIHabitViewModel: ObservableObject {
    @Published var userInput = ""
    @Published var generatedHabits: [AIGeneratedHabit] = []
    @Published var isGenerating = false
    @Published var errorMessage: String?
    @Published var showingManualInput = false
    @Published var chatGPTPrompt = ""
    @Published var chatGPTResponse = ""
    @Published var explanation = ""
    @Published var userAnalysis = ""
    
    private var currentProvider: HabitAIProvider?
    
    // Core Data context for saving habits
    private let viewContext: NSManagedObjectContext
    
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
        setupProvider()
    }
    
    /// Sets up the best available AI provider
    private func setupProvider() {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            let foundationProvider = FoundationModelsProvider()
            print("🔍 Foundation Models Debug:")
            print("- iOS Version: \(ProcessInfo.processInfo.operatingSystemVersionString)")
            print("- Can import FoundationModels: true")
            print("- Foundation Models available: \(foundationProvider.isAvailable)")
            
            let model = SystemLanguageModel.default
            print("- Model availability: \(model.availability)")
            
            if foundationProvider.isAvailable {
                print("✅ Using Foundation Models Provider")
                currentProvider = foundationProvider
                return
            } else {
                print("❌ Foundation Models not available, falling back to ChatGPT")
            }
        } else {
            print("❌ iOS version not supported for Foundation Models")
        }
        #else
        print("❌ FoundationModels framework not available")
        #endif
        
        // Fallback to manual ChatGPT
        print("🔄 Using ChatGPT Provider as fallback")
        currentProvider = ChatGPTProvider()
    }
    
    var providerName: String {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            if let foundationProvider = currentProvider as? FoundationModelsProvider {
                switch foundationProvider.availabilityStatus {
                case "ready":
                    return "Apple Intelligence"
                case "setup_required":
                    return "Apple Intelligence (Setup Required)"
                case "unavailable":
                    return "Apple Intelligence (Unavailable)"
                default:
                    return "Apple Intelligence (Unknown Status)"
                }
            }
        }
        #endif
        return currentProvider?.providerName ?? "Unknown"
    }
    
    var isAIDirectlyAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return currentProvider is FoundationModelsProvider
        }
        #endif
        return false
    }
    
    @MainActor
    func generateHabits() async {
        guard !userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please enter what you want to improve"
            return
        }
        
        guard let provider = currentProvider else {
            errorMessage = "No AI provider available"
            return
        }
        
        isGenerating = true
        errorMessage = nil
        generatedHabits = []
        explanation = ""
        userAnalysis = ""
        
        do {
            if provider is ChatGPTProvider {
                // Handle manual ChatGPT flow
                let chatGPTProvider = provider as! ChatGPTProvider
                chatGPTPrompt = chatGPTProvider.generatePrompt(for: userInput)
                showingManualInput = true
            } else {
                // Direct AI generation
                let habits = try await provider.generateHabits(for: userInput)
                generatedHabits = habits
                explanation = "AI-generated habits to help with: \(userInput)"
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isGenerating = false
    }
    
    @MainActor
    func processManualResponse() {
        guard !chatGPTResponse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please paste the ChatGPT response"
            return
        }
        
        do {
            let decoder = JSONDecoder()
            guard let data = chatGPTResponse.data(using: .utf8) else {
                throw AIProviderError.invalidResponse
            }
            
            let response = try decoder.decode(AIHabitResponse.self, from: data)
            generatedHabits = response.habits
            explanation = response.explanation ?? ""
            userAnalysis = response.userAnalysis ?? ""
            
            showingManualInput = false
            chatGPTResponse = ""
            errorMessage = nil
        } catch {
            errorMessage = "Invalid JSON format. Please check the response format."
        }
    }
    
    /// Save a generated habit to your Core Data Habit entity
    @MainActor
    func saveHabitToCoreData(_ generatedHabit: AIGeneratedHabit, habitList: HabitList? = nil) {
        let habit = generatedHabit.createCoreDataHabit(in: viewContext, habitList: habitList)
        
        do {
            try viewContext.save()
            print("✅ Saved habit: \(habit.name ?? "Unknown")")
        } catch {
            print("❌ Error saving habit: \(error)")
            errorMessage = "Failed to save habit: \(error.localizedDescription)"
        }
    }
    
    /// Save all generated habits to Core Data
    @MainActor
    func saveAllHabits(to habitList: HabitList? = nil) {
        for generatedHabit in generatedHabits {
            saveHabitToCoreData(generatedHabit, habitList: habitList)
        }
        
        // Clear generated habits after saving
        generatedHabits.removeAll()
        explanation = ""
        userAnalysis = ""
    }
    
    func clearData() {
        userInput = ""
        generatedHabits = []
        errorMessage = nil
        explanation = ""
        userAnalysis = ""
        chatGPTPrompt = ""
        chatGPTResponse = ""
        showingManualInput = false
    }
}

// MARK: - Core Data Integration Extension

extension AIGeneratedHabit {
    /// Creates a Core Data Habit entity from AIGeneratedHabit using your existing Habit entity
    func createCoreDataHabit(in context: NSManagedObjectContext, habitList: HabitList? = nil) -> Habit {
        let habit = Habit(context: context)
        
        // Basic properties matching your Habit entity
        habit.id = UUID()
        habit.name = self.name
        habit.habitDescription = self.description
        habit.isBadHabit = self.isBadHabit
        habit.isArchived = false
        habit.startDate = ISO8601DateFormatter().date(from: self.startDate) ?? Date()
        habit.intensityLevel = Int16(self.intensityLevel)
        
        // Impact scores (AI generates moodImpact, we set health and energy to 0 as requested)
        habit.moodImpact = self.moodImpact
        //habit.healthImpact = 0.0  // Not generated by AI as requested
        //habit.energyImpact = 0.0  // Not generated by AI as requested
        
        // Icon
        habit.icon = self.icon
        
        // Convert color string to your Color Data format
        let color = colorFromString(self.color)
        if let colorData = try? NSKeyedArchiver.archivedData(withRootObject: UIColor(color), requiringSecureCoding: false) {
            habit.color = colorData
        }
        
        // Order - place at the end of existing habits
        let fetchRequest: NSFetchRequest<Habit> = Habit.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Habit.order, ascending: false)]
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try context.fetch(fetchRequest)
            let highestOrder = results.first?.order ?? -1
            habit.order = highestOrder + 1
        } catch {
            habit.order = 0
        }
        
        // Assign to habit list if provided
        if let habitList = habitList {
            habit.habitList = habitList
        }
        
        // Create repeat pattern using your existing RepeatPattern entity
        let repeatPattern = RepeatPattern(context: context)
        repeatPattern.effectiveFrom = habit.startDate
        repeatPattern.followUp = false
        repeatPattern.repeatsPerDay = Int16(self.repeatsPerDay)
        repeatPattern.creationDate = Date()
        repeatPattern.duration = Int16(self.estimatedTimeMinutes)
        repeatPattern.habit = habit
        
        // Create goal based on goalType using your existing entities
        switch self.goalType.lowercased() {
        case "daily":
            createDailyGoal(for: repeatPattern, in: context)
        case "weekly":
            createWeeklyGoal(for: repeatPattern, in: context)
        case "monthly":
            createMonthlyGoal(for: repeatPattern, in: context)
        default:
            createDailyGoal(for: repeatPattern, in: context) // Default to daily
        }
        
        // Establish relationships
        habit.addToRepeatPattern(repeatPattern)
        
        return habit
    }
    
    private func createDailyGoal(for repeatPattern: RepeatPattern, in context: NSManagedObjectContext) {
        let dailyGoal = DailyGoal(context: context)
        
        if let recommendedDays = self.recommendedDays, !recommendedDays.isEmpty {
            // Specific days
            dailyGoal.everyDay = false
            let weekDays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
            var specificDays = Array(repeating: false, count: 7)
            
            for day in recommendedDays {
                if let index = weekDays.firstIndex(of: day) {
                    specificDays[index] = true
                }
            }
            dailyGoal.specificDays = specificDays as NSObject
        } else {
            // Every day
            dailyGoal.everyDay = true
        }
        
        dailyGoal.repeatPattern = repeatPattern
        repeatPattern.dailyGoal = dailyGoal
    }
    
    private func createWeeklyGoal(for repeatPattern: RepeatPattern, in context: NSManagedObjectContext) {
        let weeklyGoal = WeeklyGoal(context: context)
        weeklyGoal.everyWeek = true
        
        if let recommendedDays = self.recommendedDays, !recommendedDays.isEmpty {
            let weekDays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
            var specificDays = Array(repeating: false, count: 7)
            
            for day in recommendedDays {
                if let index = weekDays.firstIndex(of: day) {
                    specificDays[index] = true
                }
            }
            weeklyGoal.specificDays = specificDays as NSObject
        } else {
            // Default to all days for weekly
            weeklyGoal.specificDays = Array(repeating: true, count: 7) as NSObject
        }
        
        weeklyGoal.repeatPattern = repeatPattern
        repeatPattern.weeklyGoal = weeklyGoal
    }
    
    private func createMonthlyGoal(for repeatPattern: RepeatPattern, in context: NSManagedObjectContext) {
        let monthlyGoal = MonthlyGoal(context: context)
        monthlyGoal.everyMonth = true
        
        // For monthly goals, we keep it simple and just set everyMonth = true
        monthlyGoal.repeatPattern = repeatPattern
        repeatPattern.monthlyGoal = monthlyGoal
    }
    
    private func colorFromString(_ colorString: String) -> Color {
        switch colorString.lowercased() {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "red": return .red
        case "purple": return .purple
        case "pink": return .pink
        case "yellow": return .yellow
        case "primary": return .primary
        default: return .blue
        }
    }
}

