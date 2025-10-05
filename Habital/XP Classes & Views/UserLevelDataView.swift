//
//  AchievementsView.swift
//  Habital
//
//  Created by Elias Osarumwense on 29.03.25.
//

//
//  XPLevelingSystemView.swift
//  Habital
//
//  Created by Elias Osarumwense on 25.04.25.
//

import SwiftUI
import CoreData

// MARK: - XP and Level Models

/// Model to store user XP data
class UserLevelData: ObservableObject {
    @Published var totalXP: Int
    @Published var currentLevel: Int
    @Published var previousLevelXP: Int
    @Published var currentLevelRequiredXP: Int
    @Published var progressInCurrentLevel: Int
    @Published var progressPercentage: Double
    @Published var animatingXP: Bool = false
    @Published var xpToAdd: Int = 0
    @Published var recentXPGains: [(habit: Habit, xp: Int, date: Date)] = []
    
    // XP per habit completion
    static let BASE_XP_PER_COMPLETION = 10
    
    init(totalXP: Int = 0) {
        // First, initialize all stored properties with placeholder values
        self.totalXP = totalXP
        self.currentLevel = 1
        self.previousLevelXP = 0
        self.currentLevelRequiredXP = 1000
        self.progressInCurrentLevel = 0
        self.progressPercentage = 0
        
        // Now that all properties are initialized, call updateCalculations to set the real values
        self.updateCalculations()
    }
    
    /// Calculate XP required for a specific level
    static func calculateRequiredXP(for level: Int) -> Int {
        switch level {
        case 1: return 1000
        case 2: return 2500
        case 3: return 4500
        case 4: return 7000
        case 5: return 10000
        case 6: return 13500
        case 7: return 17500
        case 8: return 22000
        case 9: return 27000
        case 10: return 32500
        default:
            // For levels beyond 10, increase by a larger amount
            if level > 10 {
                return 32500 + (level - 10) * 6000
            }
            return 1000 // Default fallback
        }
    }
    
    /// Calculate total XP required to reach a specific level
    static func calculateTotalXPForLevel(_ level: Int) -> Int {
        if level <= 0 { return 0 }
        
        var total = 0
        for i in 1..<level {
            total += calculateRequiredXP(for: i)
        }
        return total
    }
    
    /// Calculate the user's level based on their total XP
    static func calculateLevel(for xp: Int) -> Int {
        if xp < 1000 { return 1 }  // Level 1 is 0-999 XP
        
        var level = 1
        var xpRequired = 0
        
        // Check each level until we find where the XP falls
        while level < 30 {
            xpRequired += calculateRequiredXP(for: level)
            if xp < xpRequired {
                return level
            }
            level += 1
        }
        
        return 30  // Cap at level 30
    }
    
    /// Add XP with animation
    func addXP(_ amount: Int, habit: Habit, isReversing: Bool = false) {
        self.xpToAdd = amount
        self.animatingXP = true
        
        // Don't add to recent XP gains if we're reversing
        if !isReversing {
            // Add to recent XP gains
            let newGain = (habit: habit, xp: amount, date: Date())
            self.recentXPGains.insert(newGain, at: 0)
            
            // Keep only the last 5 entries
            if self.recentXPGains.count > 5 {
                self.recentXPGains = Array(self.recentXPGains.prefix(5))
            }
        }
        
        // Apply the XP change after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            self.totalXP += amount
            // Ensure XP doesn't go below 0
            self.totalXP = max(0, self.totalXP)
            self.updateCalculations()
            self.animatingXP = false
            self.xpToAdd = 0
        }
    }
    
    /// Update all calculations based on current totalXP
    func updateCalculations() {
        let calculatedLevel = Self.calculateLevel(for: totalXP)
        let oldLevel = self.currentLevel
        
        self.currentLevel = calculatedLevel
        self.previousLevelXP = Self.calculateTotalXPForLevel(calculatedLevel)
        self.currentLevelRequiredXP = Self.calculateRequiredXP(for: calculatedLevel)
        self.progressInCurrentLevel = totalXP - previousLevelXP
        self.progressPercentage = min(100, Double(progressInCurrentLevel) / Double(currentLevelRequiredXP) * 100)
        
        // If level increased, trigger haptic feedback
        if calculatedLevel > oldLevel {
            triggerHaptic(.impactRigid)
        }
    }
    
    /// Get color based on level
    func getLevelColor() -> Color {
        switch currentLevel {
        case 1...5:
            return Color.blue
        case 6...10:
            return Color.purple
        case 11...15:
            return Color.pink
        case 16...20:
            return Color.orange
        case 21...25:
            return Color.green
        case 26...30:
            return Color.indigo
        default:
            return Color.blue
        }
    }
    
    /// Get color for a specific level
    static func getColorForLevel(_ level: Int) -> Color {
        switch level {
        case 1...5:
            return Color.blue
        case 6...10:
            return Color.purple
        case 11...15:
            return Color.pink
        case 16...20:
            return Color.orange
        case 21...25:
            return Color.green
        case 26...30:
            return Color.indigo
        default:
            return Color.gray
        }
    }
}

// MARK: - Completion Record Model

struct CompletionRecord: Identifiable {
    var id = UUID()
    var habit: Habit
    var date: Date
    var whenCompleted: Date
    var streak: Int
    var baseXP: Int
    var streakMultiplier: Double
    var intensityMultiplier: Double
    var totalMultiplier: Double
    var totalXP: Int
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    var formattedWhenDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: whenCompleted)
    }
}

enum XPTimeFilter: String, CaseIterable, Identifiable {
    case today = "Today"
    case yesterday = "Yesterday"
    case thisWeek = "This Week"
    //case last7Days = "Last 7 Days"
    case allTime = "All Time"
    
    var id: String { self.rawValue }
}
// MARK: - Main Leveling System View

struct XPLevelingSystemView: View {
    @State private var selectedTimeFilter: XPTimeFilter = .today
    @State private var filteredCompletionRecords: [CompletionRecord] = []
    @State private var showingAllTimeXP = false

    // Define the time filter enum
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var sharedLevelData: SharedLevelData
    
    // Fetch all habits to calculate total completions
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Habit.order, ascending: true)],
        animation: .default
    ) private var habits: FetchedResults<Habit>
    
    // State for tracking recent completions
    @State private var completionRecords: [CompletionRecord] = []
    
    // State for progress bar animation
    @State private var animateProgress = false
    @State private var dataLoaded = false
    
    @State private var isLoading = true
    
    @State private var todayXPGained: Int = 0
    @State private var todayMaxPotentialXP: Int = 0
    
    @State private var todayPotentialBadHabitLoss: Int = 0
    
    private func getIntensityColor(for multiplier: Int16) -> Color {
        switch multiplier {
        case 10:  // 1.0x (Light)
            return .green
        case 15:  // 1.5x (Moderate)
            return .blue
        case 20:  // 2.0x (High)
            return .orange
        case 30:  // 3.0x (Extreme)
            return .red
        default:
            return .gray
        }
    }
    
    // Constant values
    private let milestones = [5, 10, 15, 20, 25, 30]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // MARK: - Header with level info
                    VStack(spacing: 12) {
                        // Level Header Section
                        levelHeaderSection
                            .padding(10)
                        
                        // MARK: - Progress Section
                        progressSection
                            .padding(10)
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                                        animateProgress = true
                                    }
                                }
                            }
                    }
                    //.padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(colorScheme == .dark ? Color(UIColor.systemGray6) : Color.white)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    )
                    .padding(.horizontal)
                    
                    // MARK: - Recent XP Gains
                    recentXPGainsSection
                        .padding(.horizontal)
                    
                    // MARK: - Level Milestone Badges
                    milestonesSection
                        .padding(.horizontal)
                    
                    // MARK: - XP Multipliers Explanation (Enhanced)
                    multiplierExplanationSection
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                }
                .padding(.vertical)
            }
            .background(colorScheme == .dark ? Color(hex: "121212") : Color(UIColor.systemGroupedBackground).opacity(0.85))
            .onAppear {
                let context = viewContext
                let request = NSFetchRequest<Habit>(entityName: "Habit")
                
                do {
                    let habits = try context.fetch(request)
                    updateCompletionRecords(from: habits)
                    calculateTodayXP()
                    
                    isLoading = false
                } catch {
                    print("Error fetching habits: \(error)")
                }
            }
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Header Section
    
    private func updateCompletionRecords(from habits: [Habit]) {
        var newCompletionRecords: [CompletionRecord] = []
        
        for habit in habits {
            guard let completions = habit.completion as? Set<Completion>,
                  !completions.isEmpty else { continue }
            
            // Process each completion
            for completion in completions {
                guard let completionDate = completion.date, completion.completed else { continue }
                
                // Get the actual completion timestamp for display purposes
                let displayDate = (completionDate ?? completion.loggedAt) ?? Date()
                let whenCompleted = completion.loggedAt ?? displayDate
                
                // Get the streak at the time of completion (using the scheduled date)
                let streak = habit.calculateStreak(upTo: completionDate)
                
                // Calculate streak multiplier based on streak
                let streakMultiplier: Double
                if streak >= 100 {
                    streakMultiplier = 10.0
                } else if streak >= 50 {
                    streakMultiplier = 5.0
                } else if streak >= 40 {
                    streakMultiplier = 4.0
                } else if streak >= 30 {
                    streakMultiplier = 3.0
                } else if streak >= 20 {
                    streakMultiplier = 2.0
                } else if streak >= 10 {
                    streakMultiplier = 1.5
                } else {
                    streakMultiplier = 1.0
                }
                
                // Calculate intensity multiplier
                let intensityMultiplier: Double
                switch habit.intensityLevel {
                case 1: // Light
                    intensityMultiplier = 1.0
                case 2: // Moderate
                    intensityMultiplier = 1.5
                case 3: // High
                    intensityMultiplier = 2.0
                case 4: // Extreme
                    intensityMultiplier = 3.0
                default:
                    intensityMultiplier = 1.0
                }
                
                // Combined multiplier
                let totalMultiplier = streakMultiplier * intensityMultiplier
                
                // Calculate XP for this completion
                let baseXP = UserLevelData.BASE_XP_PER_COMPLETION
                
                // For bad habits, apply a penalty of -100 XP when "completed" (i.e., broken)
                let xpEarned: Int
                if habit.isBadHabit {
                    // When a bad habit is marked as completed, it means the habit was broken
                    // Apply intensity multiplier to the penalty
                    xpEarned = -100 * Int(intensityMultiplier)
                } else {
                    // For good habits, apply the combined multiplier
                    xpEarned = Int(Double(baseXP) * totalMultiplier)
                }
                
                // Add to completion records for display
                let record = CompletionRecord(
                    habit: habit,
                    date: displayDate,
                    whenCompleted: whenCompleted,
                    streak: streak,
                    baseXP: baseXP,
                    streakMultiplier: habit.isBadHabit ? -1.0 : streakMultiplier,
                    intensityMultiplier: intensityMultiplier,
                    totalMultiplier: habit.isBadHabit ? -intensityMultiplier : totalMultiplier,
                    totalXP: xpEarned
                )
                newCompletionRecords.append(record)
            }
        }
        
        // Sort records by the display date (whenCompleted), most recent first
        newCompletionRecords.sort { $0.whenCompleted > $1.whenCompleted }
        
        completionRecords = newCompletionRecords
    }
    
    private var levelHeaderSection: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top) {
                // Level badge
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    sharedLevelData.levelData.getLevelColor().opacity(0.6),
                                    sharedLevelData.levelData.getLevelColor().opacity(0.8)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .shadow(color: sharedLevelData.levelData.getLevelColor().opacity(0.5), radius: 8, x: 0, y: 2)
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            sharedLevelData.levelData.getLevelColor().opacity(0.1),
                                            sharedLevelData.levelData.getLevelColor().opacity(0.4),
                                            sharedLevelData.levelData.getLevelColor().opacity(0.1)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                    
                    Text("\(sharedLevelData.levelData.currentLevel)")
                        .customFont("Lexend", .bold, 36)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                    
                    // Star decoration
                    ZStack {
                        Circle()
                            .fill(colorScheme == .dark ? Color(UIColor.systemGray5) : .white)
                            .frame(width: 28, height: 28)
                            .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                        
                        Image(systemName: "star.fill")
                            .font(.system(size: 18))
                            .foregroundColor(sharedLevelData.levelData.getLevelColor())
                    }
                    .offset(x: 30, y: -30)
                }
                .padding(.trailing, 12)
                
                // Level info
                VStack(alignment: .leading, spacing: 4) {
                    Text("Level \(sharedLevelData.levelData.currentLevel)")
                        .customFont("Lexend", .bold, 24)
                        .foregroundColor(.primary)
                        .shadow(color: colorScheme == .dark ? .white.opacity(0.33) : .black.opacity(0.33), radius: 0.5)
                    
                    /*Text("Keep completing habits to level up!")
                        .customFont("Lexend", .medium, 14)
                        .foregroundColor(.secondary)
                    */
                    HStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 14))
                                .foregroundColor(sharedLevelData.levelData.getLevelColor())
                            
                            Text("\(getTotalCompletions()) completions")
                                .customFont("Lexend", .medium, 14)
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(sharedLevelData.levelData.getLevelColor().opacity(0.1))
                        )
                    }
                    .padding(.top, 4)
                }
                
                Spacer()
            }
            
            // XP Counter
            HStack {
                Text("Total XP:")
                    .customFont("Lexend", .medium, 14)
                    .foregroundColor(.secondary)
                
                Text("\(sharedLevelData.levelData.totalXP.formatted())")
                    .customFont("Lexend", .bold, 18)
                    .foregroundColor(.primary)
                /*
                if sharedLevelData.levelData.animatingXP {
                    Text("+\(sharedLevelData.levelData.xpToAdd)")
                        .customFont("Lexend", .medium, 16)
                        .foregroundColor(.green)
                        .transition(.scale.combined(with: .opacity))
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: sharedLevelData.levelData.animatingXP)
                 
                }
                */
                Spacer()
                
                Text("\(sharedLevelData.levelData.progressInCurrentLevel.formatted()) / \(sharedLevelData.levelData.currentLevelRequiredXP.formatted())")
                    .customFont("Lexend", .medium, 13)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 4)
        }
    }
    
    private func calculateTodayXPGained() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var xpGained = 0
        
        // Calculate XP gained today from completion records
        for record in completionRecords {
            if calendar.isDate(record.date, inSameDayAs: today) {
                xpGained += record.totalXP
            }
        }
        
        todayXPGained = xpGained
    }
    
    private func calculateTodayXPPercentage() -> CGFloat {
        let basePercentage = CGFloat(sharedLevelData.levelData.progressPercentage) -
                            (CGFloat(todayXPGained) / CGFloat(sharedLevelData.levelData.currentLevelRequiredXP) * 100)
        
        // Keep within valid range
        return max(0, min(basePercentage, 100))
    }
    
    private func calculateTodayXP() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var xpGained = 0
        var potentialXP = 0
        var potentialBadHabitLoss = 0
        
        // Calculate XP gained today from completion records
        for record in completionRecords {
            if calendar.isDate(record.date, inSameDayAs: today) {
                xpGained += record.totalXP
            }
        }
        
        // Calculate potential XP from remaining active habits
        for habit in habits {
            if HabitUtilities.isHabitActive(habit: habit, on: today) {
                if habit.isBadHabit {
                    // For bad habits: if not completed, no penalty risk
                    // If already completed (broken), the XP loss is already counted in xpGained
                    if !habit.isCompleted(on: today) {
                        // This is the potential loss if user completes (breaks) this bad habit
                        potentialBadHabitLoss += 100
                    }
                } else {
                    // For good habits: if not completed, there's potential XP to gain
                    if !habit.isCompleted(on: today) {
                        // Base XP per completion
                        let baseXP = UserLevelData.BASE_XP_PER_COMPLETION
                        
                        // Calculate streak for multiplier
                        let streak = habit.calculateStreak(upTo: today)
                        
                        // Apply streak multiplier
                        var multiplier = 1.0
                        if streak >= 100 {
                            multiplier = 10.0
                        } else if streak >= 50 {
                            multiplier = 5.0
                        } else if streak >= 40 {
                            multiplier = 4.0
                        } else if streak >= 30 {
                            multiplier = 3.0
                        } else if streak >= 20 {
                            multiplier = 2.0
                        } else if streak >= 10 {
                            multiplier = 1.5
                        }
                        
                        // Add potential XP from this habit
                        potentialXP += Int(Double(baseXP) * multiplier)
                    }
                }
            }
        }
        
        todayXPGained = xpGained
        todayMaxPotentialXP = potentialXP
        
        // Let's save the potential loss from bad habits for the updated progress section
        todayPotentialBadHabitLoss = potentialBadHabitLoss
    }
    // MARK: - Progress Section (Enhanced)
    
    private var progressSection: some View {
        VStack(spacing: 8) {
            // Progress Bar with animation
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(UIColor.systemGray6).opacity(0.3) : Color(.systemGray5).opacity(0.3))
                    .frame(height: 24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        sharedLevelData.levelData.getLevelColor().opacity(0.2),
                                        sharedLevelData.levelData.getLevelColor().opacity(0.4)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 1
                            )
                    )
                
                // Foreground progress with gradient
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                sharedLevelData.levelData.getLevelColor(),
                                sharedLevelData.levelData.getLevelColor().opacity(0.8),
                                sharedLevelData.levelData.getLevelColor().opacity(0.7)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: animateProgress ? max(20, UIScreen.main.bounds.width * CGFloat(sharedLevelData.levelData.progressPercentage) / 100 - 32) : 0, height: 24)
                    .overlay(
                        // Add shine effect
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        .white.opacity(0.1),
                                        .white.opacity(0.3),
                                        .white.opacity(0.05)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .scaleEffect(x: 1, y: 0.5, anchor: .center)
                            .offset(y: -4)
                    )
                    .shadow(color: sharedLevelData.levelData.getLevelColor().opacity(0.4), radius: 3, x: 0, y: 1)
                
                // Percentage text
                Text("\(Int(sharedLevelData.levelData.progressPercentage))%")
                    .customFont("Lexend", .semiBold, 12)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                    .padding(.horizontal, 10)
                    .opacity(sharedLevelData.levelData.progressPercentage > 10 ? 1 : 0)
                    .animation(.easeInOut, value: sharedLevelData.levelData.progressPercentage)
            }
            
            // Today's XP info
            VStack(spacing: 10) {
                // Today's XP - Clean and minimal
                HStack(alignment: .center) {
                    HStack(spacing: 5) {
                        Image(systemName: todayXPGained >= 0 ? "arrow.up.forward.circle.fill" : "arrow.down.forward.circle.fill")
                            .foregroundStyle(todayXPGained >= 0 ? .green : .red)
                            .font(.system(size: 15))
                        
                        Text("Today:")
                            .customFont("Lexend", .medium, 13)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("\(todayXPGained >= 0 ? "+" : "")\(todayXPGained) XP")
                        .customFont("Lexend", .bold, 15)
                        .foregroundColor(todayXPGained >= 0 ? .green : .red)
                }
                .padding(.vertical, 2)
                
                // Potential XP & Risk - Elegant cards
                if todayMaxPotentialXP > 0 || todayPotentialBadHabitLoss > 0 {
                    HStack(spacing: 8) {
                        if todayMaxPotentialXP > 0 {
                            // Potential XP Card
                            HStack(spacing: 4) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 11))
                                    .foregroundColor(.green)
                                
                                Text("+\(todayMaxPotentialXP) Potential")
                                    .customFont("Lexend", .medium, 12)
                                    .foregroundColor(.green)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.green.opacity(0.15))
                            )
                            
                            Spacer()
                        }
                        
                        if todayPotentialBadHabitLoss > 0 {
                            // Risk XP Card
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 11))
                                    .foregroundColor(.red)
                                
                                Text("-\(todayPotentialBadHabitLoss) XP Lost")
                                    .customFont("Lexend", .medium, 12)
                                    .foregroundColor(.red)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.red.opacity(0.15))
                            )
                        }
                    }
                    
                    // Subtle tip text
                    HStack(alignment: .center, spacing: 3) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary.opacity(0.7))
                        
                        Text("Complete habits to earn potential XP")
                            .customFont("Lexend", .regular, 10)
                            .foregroundColor(.secondary.opacity(0.8))
                            .lineLimit(1)
                    }
                    .padding(.top, 1)
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            }
        }
    
    // MARK: - Recent XP Gains Section
    
    private var recentXPGainsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Simple header without time filter
            Text("Recent XP Gains")
                .customFont("Lexend", .bold, 18)
                .foregroundColor(.primary)
            
            if completionRecords.isEmpty {
                HStack {
                    Spacer()
                    Text("No recent XP gains")
                        .customFont("Lexend", .medium, 14)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 20)
                    Spacer()
                }
            } else {
                // Show only the 5 most recent records
                let recordsToShow = Array(completionRecords.prefix(5))
                
                VStack(spacing: 12) {
                    ForEach(recordsToShow) { record in
                        HStack(alignment: .center) {
                            // Habit icon
                            ZStack {
                                Circle()
                                    .fill(getHabitColor(record.habit).opacity(0.2))
                                    .frame(width: 40, height: 40)
                                
                                if let icon = record.habit.icon {
                                    if isEmoji(icon) {
                                        Text(icon)
                                            .font(.system(size: 18))
                                    } else {
                                        Image(systemName: icon)
                                            .font(.system(size: 18))
                                            .foregroundColor(getHabitColor(record.habit))
                                    }
                                } else {
                                    Image(systemName: "star")
                                        .font(.system(size: 18))
                                        .foregroundColor(getHabitColor(record.habit))
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(record.habit.name ?? "Unnamed Habit")
                                    .customFont("Lexend", .medium, 15)
                                    .foregroundColor(.primary)
                                
                                HStack(spacing: 6) {
                                    Text(record.formattedWhenDate)
                                        .customFont("Lexend", .regular, 12)
                                        .foregroundColor(.secondary)
                                    
                                    if record.streak > 1 {
                                        HStack(spacing: 2) {
                                            Image(systemName: "flame.fill")
                                                .font(.system(size: 10))
                                                .foregroundColor(.orange)
                                            
                                            Text("\(record.streak)")
                                                .customFont("Lexend", .medium, 12)
                                                .foregroundColor(.orange)
                                        }
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 1)
                                        .background(
                                            Capsule()
                                                .fill(Color.orange.opacity(0.15))
                                        )
                                    }
                                }
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                // Show XP value
                                if record.totalXP < 0 {
                                    Text("\(record.totalXP) XP")
                                        .customFont("Lexend", .semiBold, 16)
                                        .foregroundColor(.red)
                                } else {
                                    Text("+\(record.totalXP) XP")
                                        .customFont("Lexend", .semiBold, 16)
                                        //.foregroundColor(sharedLevelData.levelData.getLevelColor())
                                        .foregroundColor(.green.opacity(0.6))
                                }
                                
                                if record.streakMultiplier != 1.0 || record.intensityMultiplier != 1.0 {
                                    HStack(spacing: 5) {
                                        if record.streakMultiplier != 1.0 && record.streakMultiplier > 0 {
                                            Text("×\(String(format: "%.1f", abs(record.streakMultiplier)))")
                                                .customFont("Lexend", .medium, 12)
                                                .foregroundColor(.orange)
                                                .padding(.horizontal, 4)
                                                .padding(.vertical, 1)
                                                .background(
                                                    Capsule()
                                                        .fill(Color.orange.opacity(0.15))
                                                )
                                        }
                                        
                                        if record.intensityMultiplier != 1.0 {
                                            Text("×\(String(format: "%.1f", record.intensityMultiplier))")
                                                .customFont("Lexend", .medium, 12)
                                                .foregroundColor(getIntensityColor(for: Int16(record.intensityMultiplier * 10)))
                                                .padding(.horizontal, 4)
                                                .padding(.vertical, 1)
                                                .background(
                                                    Capsule()
                                                        .fill(getIntensityColor(for: Int16(record.intensityMultiplier * 10)).opacity(0.15))
                                                )
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 8)
                        
                        if record.id != recordsToShow.last?.id {
                            Divider()
                        }
                    }
                    
                    // Button to see all XP history
                    Button(action: {
                        showingAllTimeXP = true
                    }) {
                        HStack {
                            Spacer()
                            Text("See XP History")
                                .customFont("Lexend", .medium, 14)
                                .foregroundColor(sharedLevelData.levelData.getLevelColor())
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundColor(sharedLevelData.levelData.getLevelColor())
                            Spacer()
                        }
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(sharedLevelData.levelData.getLevelColor().opacity(0.1))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.top, 4)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(UIColor.systemGray6) : Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
        .sheet(isPresented: $showingAllTimeXP) {
            AllXPHistoryView(completionRecords: completionRecords)
        }
    }
    
    private func filterCompletionRecords() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // First filter based on the selected time period
        var timeFilteredRecords: [CompletionRecord] = []
        
        switch selectedTimeFilter {
        case .today:
            // Filter records from today
            timeFilteredRecords = completionRecords.filter { record in
                calendar.isDate(record.date, inSameDayAs: today)
            }
            
        case .yesterday:
            // Filter records from yesterday
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else {
                filteredCompletionRecords = []
                return
            }
            
            timeFilteredRecords = completionRecords.filter { record in
                calendar.isDate(record.date, inSameDayAs: yesterday)
            }
            
        case .thisWeek:
            // Filter records from this week (starting Monday)
            let weekday = calendar.component(.weekday, from: today)
            let daysToSubtract = (weekday + 5) % 7 // Convert to Monday = 0
            
            guard let startOfWeek = calendar.date(byAdding: .day, value: -daysToSubtract, to: today) else {
                filteredCompletionRecords = []
                return
            }
            
            timeFilteredRecords = completionRecords.filter { record in
                return record.date >= startOfWeek && record.date <= today
            }
            
        
            
        // Support for potential future All Time option
        default:
            timeFilteredRecords = completionRecords
        }
        
        // Sort by most recent first and update the filtered records
        filteredCompletionRecords = timeFilteredRecords.sorted { $0.date > $1.date }
    }
    
    // MARK: - Milestones Section
    
    private var milestonesSection: some View {
        VStack(spacing: 8) {
            Text("Achievement Milestones")
                .customFont("Lexend", .bold, 16)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
            
            HStack(spacing: 0) {
                ForEach(milestones, id: \.self) { level in
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(sharedLevelData.levelData.currentLevel >= level ?
                                      UserLevelData.getColorForLevel(level) :
                                        Color.gray.opacity(0.2))
                                .frame(width: 36, height: 36)
                                .shadow(color: sharedLevelData.levelData.currentLevel >= level ?
                                        UserLevelData.getColorForLevel(level).opacity(0.5) :
                                            Color.clear,
                                        radius: 3, x: 0, y: 1)
                            
                            Image(systemName: "star.fill")
                                .font(.system(size: 16))
                                .foregroundColor(sharedLevelData.levelData.currentLevel >= level ? .white : .gray.opacity(0.5))
                        }
                        
                        Text("\(level)")
                            .customFont("Lexend", sharedLevelData.levelData.currentLevel >= level ? .medium : .regular, 12)
                            .foregroundColor(sharedLevelData.levelData.currentLevel >= level ? .primary : .secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(UIColor.systemGray5).opacity(0.2) : Color(.systemGray6).opacity(0.5))
                    .shadow(color: Color.black.opacity(0.02), radius: 2, x: 0, y: 1)
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(UIColor.systemGray6) : Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    // MARK: - Enhanced XP Multipliers Section
    
    private var multiplierExplanationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("XP Multipliers")
                .customFont("Lexend", .bold, 18)
                .foregroundColor(.primary)
            
            VStack(spacing: 14) {
                // Base XP
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(sharedLevelData.levelData.getLevelColor().opacity(0.2))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "star.fill")
                            .font(.system(size: 20))
                            .foregroundColor(sharedLevelData.levelData.getLevelColor())
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Base XP")
                            .customFont("Lexend", .semiBold, 16)
                            .foregroundColor(.primary)
                        
                        Text("Each habit completion")
                            .customFont("Lexend", .regular, 14)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("+10 XP")
                        .customFont("Lexend", .bold, 16)
                        .foregroundColor(sharedLevelData.levelData.getLevelColor())
                }
                
                Divider()
                
                // Streak multipliers - ENHANCED with additional tiers
                VStack(spacing: 10) {
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        
                        Text("Streak Multipliers")
                            .customFont("Lexend", .semiBold, 16)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    
                    // Original multipliers
                    HStack {
                        Text("10+ day streak")
                            .customFont("Lexend", .medium, 14)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("×1.5")
                            .customFont("Lexend", .bold, 16)
                            .foregroundColor(.orange)
                    }
                    
                    HStack {
                        Text("20+ day streak")
                            .customFont("Lexend", .medium, 14)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("×2.0")
                            .customFont("Lexend", .bold, 16)
                            .foregroundColor(.orange)
                    }
                    
                    HStack {
                        Text("30+ day streak")
                            .customFont("Lexend", .medium, 14)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("×3.0")
                            .customFont("Lexend", .bold, 16)
                            .foregroundColor(.orange)
                    }
                    
                    // NEW additional multipliers
                    HStack {
                        Text("40+ day streak")
                            .customFont("Lexend", .medium, 14)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("×4.0")
                            .customFont("Lexend", .bold, 16)
                            .foregroundColor(.orange)
                    }
                    
                    HStack {
                        Text("50+ day streak")
                            .customFont("Lexend", .medium, 14)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("×5.0")
                            .customFont("Lexend", .bold, 16)
                            .foregroundColor(.orange)
                    }
                    
                    HStack {
                        Text("100+ day streak")
                            .customFont("Lexend", .medium, 14)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("×10.0")
                            .customFont("Lexend", .bold, 16)
                            .foregroundColor(.orange)
                    }
                }
                Divider()

                // Intensity multipliers
                VStack(spacing: 10) {
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.blue)
                        
                        Text("Intensity Multipliers")
                            .customFont("Lexend", .semiBold, 16)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    
                    HStack {
                        Text("Light intensity")
                            .customFont("Lexend", .medium, 14)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("×1.0")
                            .customFont("Lexend", .bold, 16)
                            .foregroundColor(.green)
                    }
                    
                    HStack {
                        Text("Moderate intensity")
                            .customFont("Lexend", .medium, 14)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("×1.5")
                            .customFont("Lexend", .bold, 16)
                            .foregroundColor(.blue)
                    }
                    
                    HStack {
                        Text("High intensity")
                            .customFont("Lexend", .medium, 14)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("×2.0")
                            .customFont("Lexend", .bold, 16)
                            .foregroundColor(.orange)
                    }
                    
                    HStack {
                        Text("Extreme intensity")
                            .customFont("Lexend", .medium, 14)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("×3.0")
                            .customFont("Lexend", .bold, 16)
                            .foregroundColor(.red)
                    }
                    
                    // Explanation
                    Text("Habits with higher intensity levels earn more XP per completion, reflecting the greater effort required.")
                        .customFont("Lexend", .regular, 13)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                Divider()
                
                // NEW: Bad Habit Penalty
                VStack(spacing: 10) {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                        
                        Text("Bad Habit Penalties")
                            .customFont("Lexend", .semiBold, 16)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    
                    HStack {
                        Text("Breaking a bad habit")
                            .customFont("Lexend", .medium, 14)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("-100 XP")
                            .customFont("Lexend", .bold, 16)
                            .foregroundColor(.red)
                    }
                    
                    // Explanation
                    Text("When you mark a bad habit as completed, you receive a penalty of -100 XP. Stay disciplined and avoid your bad habits to maintain your progress!")
                        .customFont("Lexend", .regular, 13)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(UIColor.systemGray6) : Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    private func getTotalCompletions() -> Int {
        var totalCompletions = 0
        
        for habit in habits {
            guard let completions = habit.completion as? Set<Completion> else { continue }
            
            // Count all completed completions
            totalCompletions += completions.filter { $0.completed }.count
        }
        
        return totalCompletions
    }
    
    /// Get color for a habit
    private func getHabitColor(_ habit: Habit) -> Color {
        if let colorData = habit.color,
           let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
            return Color(uiColor)
        }
        return .blue // Default color
    }
    
    /// Check if a string is an emoji
    private func isEmoji(_ text: String) -> Bool {
        for scalar in text.unicodeScalars {
            if scalar.properties.isEmoji {
                return true
            }
        }
        return false
    }
    
    // Helper to trigger haptic feedback
    func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}

    // MARK: - Preview

struct XPLevelingSystemView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            XPLevelingSystemView()
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        }
        .preferredColorScheme(.light)
        
        NavigationView {
            XPLevelingSystemView()
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        }
        .preferredColorScheme(.dark)
    }
}
