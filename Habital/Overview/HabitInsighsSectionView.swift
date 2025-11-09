//
//  HabitInsightsSection.swift
//  Habital
//
//  Redesigned for modern minimalist aesthetics - 2025
//
import SwiftUI

// MARK: - Habit Insights Section

struct HabitInsightsSection: View {
    let habits: [Habit]
    @Environment(\.colorScheme) private var colorScheme
    @State private var animateCards = false
    
    private var habitInsights: HabitInsights {
        return calculateHabitInsights(from: habits)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Minimalist Header
            headerView
            
            // Insights Cards Grid
            insightsGrid
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.1)) {
                animateCards = true
            }
        }
    }
    
    private var headerView: some View {
        HStack(alignment: .center, spacing: 12) {
            // Subtle accent circle with icon
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Circle()
                            .strokeBorder(.quaternary.opacity(0.6), lineWidth: 0.5)
                    )
                
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 1) {
                Text("Insights")
                    .font(.customFont("Lexend", .semiBold, 20))
                    .foregroundColor(.primary)
                
                Text("Your habit performance")
                    .font(.customFont("Lexend", .regular, 13))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
    
    private var insightsGrid: some View {
        VStack(spacing: 12) {
            // Top Performer - Full Width
            if let bestHabit = habitInsights.bestScoringHabit {
                InsightCard(
                    type: .topPerformer,
                    habit: bestHabit.habit,
                    primaryValue: "\(bestHabit.score)",
                    secondaryValue: "100",
                    description: "Highest scoring habit",
                    animationDelay: 0.0
                )
                .opacity(animateCards ? 1 : 0)
                .offset(y: animateCards ? 0 : 20)
            }
            
            // Bottom Row - Two Cards Side by Side
            HStack(spacing: 10) {
                // Rising Star
                if let improvingHabit = habitInsights.mostImprovedHabit {
                    InsightCard(
                        type: .improvement,
                        habit: improvingHabit.habit,
                        primaryValue: "\(HabitScoreManager.calculateHabitScore(for: improvingHabit.habit, today: Date()))",
                        secondaryValue: "+\(Int(improvingHabit.improvement))%",
                        description: "7-day improvement",
                        animationDelay: 0.1
                    )
                    .opacity(animateCards ? 1 : 0)
                    .offset(y: animateCards ? 0 : 20)
                }
                
                // Needs Attention
                if let decliningHabit = habitInsights.mostDeclinedHabit {
                    InsightCard(
                        type: .attention,
                        habit: decliningHabit.habit,
                        primaryValue: "\(HabitScoreManager.calculateHabitScore(for: decliningHabit.habit, today: Date()))",
                        secondaryValue: "-\(Int(decliningHabit.decline))%",
                        description: "Needs focus",
                        animationDelay: 0.2
                    )
                    .opacity(animateCards ? 1 : 0)
                    .offset(y: animateCards ? 0 : 20)
                }
            }
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Insight Card Component

struct InsightCard: View {
    enum CardType {
        case topPerformer
        case improvement
        case attention
        
        var iconName: String {
            switch self {
            case .topPerformer: return "star.fill"
            case .improvement: return "arrow.up.right"
            case .attention: return "exclamationmark.circle.fill"
            }
        }
        
        var accentColor: Color {
            switch self {
            case .topPerformer: return .yellow
            case .improvement: return .green
            case .attention: return .orange
            }
        }
        
        var gradientColors: (Color, Color) {
            switch self {
            case .topPerformer: return (.yellow.opacity(0.06), .orange.opacity(0.03))
            case .improvement: return (.green.opacity(0.06), .mint.opacity(0.03))
            case .attention: return (.orange.opacity(0.06), .red.opacity(0.03))
            }
        }
    }
    
    let type: CardType
    let habit: Habit
    let primaryValue: String
    let secondaryValue: String
    let description: String
    let animationDelay: Double
    
    @State private var isPressed = false
    @State private var showContent = false
    @Environment(\.colorScheme) private var colorScheme
    
    private var habitColor: Color {
        if let colorData = habit.color,
           let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
            return Color(uiColor)
        }
        return .blue
    }
    
    private var isFullWidth: Bool {
        type == .topPerformer
    }
    
    var body: some View {
        Button(action: handleTap) {
            VStack(spacing: 0) {
                // Main Content
                VStack(alignment: .leading, spacing: isFullWidth ? 14 : 12) {
                    // Header Row
                    HStack {
                        // Habit Icon
                        HabitIconView(
                            iconName: habit.icon,
                            isActive: true,
                            habitColor: habitColor,
                            streak: habit.calculateStreak(upTo: Date()),
                            showStreaks: false,
                            useModernBadges: false,
                            isFutureDate: false,
                            isBadHabit: habit.isBadHabit,
                            intensityLevel: habit.intensityLevel
                        )
                        .scaleEffect(isFullWidth ? 1.1 : 0.9)
                        .frame(width: isFullWidth ? 36 : 32, height: isFullWidth ? 36 : 32)
                        
                        Spacer()
                        
                        // Accent Icon
                        ZStack {
                            Circle()
                                .fill(type.accentColor.opacity(0.12))
                                .frame(width: isFullWidth ? 26 : 24, height: isFullWidth ? 26 : 24)
                            
                            Image(systemName: type.iconName)
                                .font(.system(size: isFullWidth ? 11 : 10, weight: .semibold, design: .rounded))
                                .foregroundColor(type.accentColor)
                        }
                    }
                    
                    // Metrics Row
                    HStack(alignment: .bottom, spacing: 4) {
                        // Primary Metric (Score)
                        Text(primaryValue)
                            .font(.customFont("Lexend", .bold, isFullWidth ? 24 : 20))
                            .foregroundColor(.primary)
                        
                        if !secondaryValue.isEmpty {
                            if isFullWidth {
                                // For top performer card, show /100
                                Text("/\(secondaryValue)")
                                    .font(.customFont("Lexend", .medium, isFullWidth ? 14 : 12))
                                    .foregroundColor(.secondary)
                                    .offset(y: -1)
                                
                                Spacer()
                            } else {
                                Spacer()
                                
                                // Secondary Metric (Percentage with Arrow) - no background
                                HStack(spacing: 2) {
                                    Image(systemName: secondaryValue.hasPrefix("+") ? "arrow.up" : "arrow.down")
                                        .font(.system(size: isFullWidth ? 10 : 8, weight: .bold, design: .rounded))
                                        .foregroundColor(secondaryValue.hasPrefix("+") ? .green : .red)
                                    
                                    Text(secondaryValue)
                                        .font(.customFont("Lexend", .semiBold, isFullWidth ? 12 : 10))
                                        .foregroundColor(secondaryValue.hasPrefix("+") ? .green : .red)
                                }
                            }
                        }
                    }
                    
                    // Info Row
                    VStack(alignment: .leading, spacing: 3) {
                        Text(habit.name ?? "Unknown Habit")
                            .font(.customFont("Lexend", .medium, isFullWidth ? 14 : 13))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Text(description)
                            .font(.customFont("Lexend", .regular, isFullWidth ? 12 : 11))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(isFullWidth ? 18 : 16)
            }
        }
        .buttonStyle(PlainButtonStyle())
        //.background(cardBackground)
        .glassBackground(tintColor: type.gradientColors.1)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 10)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(animationDelay)) {
                showContent = true
            }
        }
        .onTapGesture {
            handleTap()
        }
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: isFullWidth ? 18 : 14)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: isFullWidth ? 18 : 14)
                    .fill(
                        LinearGradient(
                            colors: [type.gradientColors.0, type.gradientColors.1],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: isFullWidth ? 18 : 14)
                    .strokeBorder(.quaternary.opacity(0.3), lineWidth: 0.5)
            )
            .shadow(
                color: colorScheme == .dark
                    ? Color.black.opacity(0.12)
                    : Color.gray.opacity(0.06),
                radius: isPressed ? 4 : 8,
                x: 0,
                y: isPressed ? 2 : 4
            )
    }
    
    private func handleTap() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        withAnimation(.easeInOut(duration: 0.15)) {
            isPressed = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeInOut(duration: 0.15)) {
                isPressed = false
            }
        }
        
        // Handle navigation or action here
    }
}


// MARK: - Data Models (Unchanged)

struct HabitInsights {
    let bestScoringHabit: (habit: Habit, score: Int)?
    let mostImprovedHabit: (habit: Habit, improvement: Double)?
    let mostDeclinedHabit: (habit: Habit, decline: Double)?
}

// MARK: - Calculation Functions (Unchanged)

private func calculateHabitInsights(from habits: [Habit]) -> HabitInsights {
    let today = Date()
    let calendar = Calendar.current
    let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: today) ?? today
    
    // Filter out habits that don't have enough data
    let validHabits = habits.filter { habit in
        guard let startDate = habit.startDate else { return false }
        return startDate <= sevenDaysAgo // Habit must be at least 7 days old
    }
    
    // Calculate current scores
    var habitScores: [(habit: Habit, score: Int)] = []
    var habitProgressChanges: [(habit: Habit, change: Double)] = []
    
    for habit in validHabits {
        // Current score
        let currentScore = HabitScoreManager.calculateHabitScore(for: habit, today: today)
        habitScores.append((habit: habit, score: currentScore))
        
        // 7-day progress calculation
        let currentCompletion = calculateCompletionRate(for: habit, endDate: today, days: 7)
        let pastCompletion = calculateCompletionRate(for: habit, endDate: sevenDaysAgo, days: 7)
        
        let progressChange = currentCompletion - pastCompletion
        habitProgressChanges.append((habit: habit, change: progressChange))
    }
    
    // Find insights
    let bestScoringHabit = habitScores.max { $0.score < $1.score }
    let mostImprovedHabit = habitProgressChanges.filter { $0.change > 0 }.max { $0.change < $1.change }
    let mostDeclinedHabit = habitProgressChanges.filter { $0.change < 0 }.min { $0.change < $1.change }
    
    return HabitInsights(
        bestScoringHabit: bestScoringHabit,
        mostImprovedHabit: mostImprovedHabit.map { (habit: $0.habit, improvement: $0.change * 100) },
        mostDeclinedHabit: mostDeclinedHabit.map { (habit: $0.habit, decline: abs($0.change) * 100) }
    )
}

private func calculateCompletionRate(for habit: Habit, endDate: Date, days: Int) -> Double {
    let calendar = Calendar.current
    let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) ?? endDate
    
    var activeDays = 0
    var completedDays = 0
    var currentDate = startDate
    
    while currentDate <= endDate {
        if HabitUtilities.isHabitActive(habit: habit, on: currentDate) {
            activeDays += 1
            if habit.isCompleted(on: currentDate) {
                completedDays += 1
            }
        }
        
        guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
            break
        }
        currentDate = nextDate
    }
    
    return activeDays > 0 ? Double(completedDays) / Double(activeDays) : 0.0
}
