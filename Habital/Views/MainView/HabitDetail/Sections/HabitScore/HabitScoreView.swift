//
//  HabitScoreSection.swift
//  Habital
//
//  Created by Elias Osarumwense on 12.08.25.
//  Enhanced with detailed breakdown and improved animations
//

import SwiftUI

struct HabitScoreSection: View {
    let habit: Habit
    @State private var animateProgress = false
    @State private var animateScore = false
    @State private var showBreakdown = false
    @State private var habitScore: Int = 0
    @State private var scoreBreakdown: HabitScoreBreakdown?
    
    private var habitColor: Color {
        if let colorData = habit.color,
           let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
            return Color(uiColor)
        }
        return .blue
    }
    
    private var scoreColor: Color {
        switch habitScore {
        case 90...100: return .green
        case 75..<90: return habitColor
        case 50..<75: return .orange
        case 25..<50: return .red
        default: return .gray
        }
    }
    
    private var performanceInfo: (text: String, description: String) {
        switch habitScore {
        case 90...100: return ("Excellent", "Outstanding consistency!")
        case 75..<90: return ("Good", "Strong habit formation")
        case 50..<75: return ("Fair", "Making progress")
        case 25..<50: return ("Needs Work", "Room for improvement")
        default: return ("Starting", "Beginning your journey")
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main Score Display
            mainScoreSection
            
            // Expandable Breakdown Section
            if showBreakdown {
                breakdownSection
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .offset(y: -10)),
                        removal: .opacity.combined(with: .offset(y: -5))
                    ))
            }
        }
        //.glassBackground(cornerRadius: 20)
        .glitterGlassBackground(
            cornerRadius: 30,
            tintColor: scoreColor,
            glitterIntensity: 0.9 // Subtle but noticeable
        )
        .onAppear {
            loadScore()
            startAnimations()
        }
        .onChange(of: habit.objectID) { _ in
            loadScore()
        }
    }
    
    // MARK: - Main Score Section
    
    private var mainScoreSection: some View {
        VStack(spacing: 16) {
            // Header with tap gesture
            Button(action: {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    showBreakdown.toggle()
                }
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Habit Score")
                            .customFont("Lexend", .semiBold, 16)
                            .foregroundColor(.primary)
                        
                        Text("Last 30 days")
                            .customFont("Lexend", .regular, 12)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Large score display
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(animateScore ? habitScore : 0)")
                            .customFont("Lexend", .bold, 32)
                            .foregroundColor(scoreColor)
                            .contentTransition(.numericText())
                            .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.3), value: animateScore)
                        
                        Text("/100")
                            .customFont("Lexend", .medium, 16)
                            .foregroundColor(.secondary)
                            .opacity(animateScore ? 1 : 0)
                            .animation(.easeInOut(duration: 0.5).delay(0.6), value: animateScore)
                    }
                    
                    // Expand/Collapse indicator
                    Image(systemName: showBreakdown ? "chevron.up.circle.fill" : "info.circle.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(scoreColor.opacity(0.7))
                        .rotationEffect(.degrees(showBreakdown ? 0 : 0))
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: showBreakdown)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Progress section
            VStack(spacing: 12) {
                // Habit name and performance
                HStack {
                    Text(habit.name ?? "Habit")
                        .customFont("Lexend", .medium, 14)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(performanceInfo.text)
                            .customFont("Lexend", .semiBold, 12)
                            .foregroundColor(scoreColor)
                        
                        if animateScore {
                            Text(performanceInfo.description)
                                .customFont("Lexend", .regular, 10)
                                .foregroundColor(.secondary)
                                .opacity(0.8)
                        }
                    }
                    .opacity(animateScore ? 1 : 0)
                    .animation(.easeInOut(duration: 0.5).delay(0.8), value: animateScore)
                }
                
                // Progress bar (original design)
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background track
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.15))
                            .frame(height: 8)
                        
                        // Progress fill
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        scoreColor,
                                        scoreColor.opacity(0.8)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(
                                width: animateProgress ? geometry.size.width * (Double(habitScore) / 100.0) : 0,
                                height: 8
                            )
                            .animation(.easeInOut(duration: 1.0).delay(0.5), value: animateProgress)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding()
    }
    
    // MARK: - Breakdown Section
    
    private var breakdownSection: some View {
        VStack(spacing: 16) {
            Divider()
                .background(Color.primary.opacity(0.1))
            
            if let breakdown = scoreBreakdown {
                VStack(spacing: 12) {
                    // Score components
                    HStack {
                        Text("Score Breakdown")
                            .customFont("Lexend", .semiBold, 14)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    
                    VStack(spacing: 8) {
                        // Base score row
                        ScoreComponentRow(
                            title: "Completion",
                            subtitle: "\(breakdown.completionPercentage)% complete",
                            score: breakdown.baseScore,
                            maxScore: 80,
                            color: scoreColor.opacity(0.8),
                            icon: "checkmark.circle.fill"
                        )
                        
                        // Streak bonus row
                        ScoreComponentRow(
                            title: "Streak Bonus",
                            subtitle: "\(breakdown.currentStreakDays) days",
                            score: breakdown.streakBonus,
                            maxScore: 20,
                            color: .orange,
                            icon: "flame.fill"
                        )
                    }
                    
                    // Performance stats
                    VStack(spacing: 6) {
                        HStack {
                            Text("Statistics")
                                .customFont("Lexend", .medium, 12)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        
                        HStack(spacing: 16) {
                            StatCard(
                                title: "Completed",
                                value: "\(breakdown.actualCount)/\(breakdown.expectedCount)",
                                color: scoreColor
                            )
                            
                            StatCard(
                                title: "Window",
                                value: "\(breakdown.windowDays) days",
                                color: .blue
                            )
                            
                            if breakdown.currentStreakDays > 0 {
                                StatCard(
                                    title: "Streak",
                                    value: "\(breakdown.streakPercentage)%",
                                    color: .orange
                                )
                            }
                        }
                    }
                }
            } else {
                // Loading state
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Calculating...")
                        .customFont("Lexend", .regular, 12)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
    
    // MARK: - Helper Methods
    
    private func loadScore() {
        habitScore = HabitScoreManager.calculateHabitScore(for: habit)
        scoreBreakdown = HabitScoreManager.getScoreBreakdown(for: habit)
    }
    
    private func startAnimations() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            animateProgress = true
            animateScore = true
        }
    }
}

// MARK: - Supporting Views

struct ScoreComponentRow: View {
    let title: String
    let subtitle: String
    let score: Int
    let maxScore: Int
    let color: Color
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(color)
                .frame(width: 20)
            
            // Title and subtitle
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .customFont("Lexend", .medium, 13)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .customFont("Lexend", .regular, 11)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Score display
            Text("\(score)/\(maxScore)")
                .customFont("Lexend", .semiBold, 13)
                .foregroundColor(color)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.08))
        )
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .customFont("Lexend", .semiBold, 14)
                .foregroundColor(color)
            
            Text(title)
                .customFont("Lexend", .regular, 10)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(color.opacity(0.05))
        )
    }
}

// MARK: - Preview

struct HabitScoreSection_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            ForEach([92, 67, 34], id: \.self) { score in
                HabitScoreSectionPreview(mockScore: score)
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "1A1A1A"),
                    Color(hex: "2D2D2D")
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

struct HabitScoreSectionPreview: View {
    let mockScore: Int
    @State private var demoHabit: Habit?
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        Group {
            if let habit = demoHabit {
                MockHabitScoreSection(habit: habit, mockScore: mockScore)
            } else {
                ProgressView()
                    .onAppear {
                        createDemoHabit()
                    }
            }
        }
    }
    
    private func createDemoHabit() {
        let habit = Habit(context: viewContext)
        habit.id = UUID()
        habit.name = getHabitName(for: mockScore)
        habit.startDate = Date()
        habit.icon = "book.fill"
        
        let colors: [UIColor] = [.systemBlue, .systemGreen, .systemOrange, .systemPurple]
        if let colorData = try? NSKeyedArchiver.archivedData(
            withRootObject: colors.randomElement() ?? .systemBlue,
            requiringSecureCoding: false
        ) {
            habit.color = colorData
        }
        
        demoHabit = habit
    }
    
    private func getHabitName(for score: Int) -> String {
        switch score {
        case 90...100: return "Daily Exercise"
        case 60..<90: return "Reading 30min"
        default: return "Meditation"
        }
    }
}

// Enhanced Mock version for preview
struct MockHabitScoreSection: View {
    let habit: Habit
    let mockScore: Int
    @State private var animateProgress = false
    @State private var animateScore = false
    @State private var showBreakdown = false
    
    private var habitColor: Color {
        if let colorData = habit.color,
           let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
            return Color(uiColor)
        }
        return .blue
    }
    
    private var scoreColor: Color {
        switch mockScore {
        case 90...100: return .green
        case 75..<90: return habitColor
        case 50..<75: return .orange
        case 25..<50: return .red
        default: return .gray
        }
    }
    
    private var performanceInfo: (text: String, description: String) {
        switch mockScore {
        case 90...100: return ("Excellent", "Outstanding consistency!")
        case 75..<90: return ("Good", "Strong habit formation")
        case 50..<75: return ("Fair", "Making progress")
        case 25..<50: return ("Needs Work", "Room for improvement")
        default: return ("Starting", "Beginning your journey")
        }
    }
    
    private var mockBreakdown: HabitScoreBreakdown {
        let baseScore = Int(Double(mockScore) * 0.8)
        let streakBonus = mockScore - baseScore
        let expectedCount = 30
        let actualCount = Int(Double(expectedCount) * (Double(mockScore) / 100.0))
        
        return HabitScoreBreakdown(
            totalScore: mockScore,
            baseScore: baseScore,
            streakBonus: streakBonus,
            expectedCount: expectedCount,
            actualCount: actualCount,
            completionRatio: Double(actualCount) / Double(expectedCount),
            currentStreakDays: max(0, (streakBonus * 30) / 20),
            windowDays: 30,
            streakRatio: Double(streakBonus) / 20.0
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main section
            VStack(spacing: 16) {
                Button(action: {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        showBreakdown.toggle()
                    }
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Habit Score")
                                .customFont("Lexend", .semiBold, 16)
                                .foregroundColor(.primary)
                            
                            Text("Last 30 days")
                                .customFont("Lexend", .regular, 12)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text("\(animateScore ? mockScore : 0)")
                                .customFont("Lexend", .bold, 32)
                                .foregroundColor(scoreColor)
                                .contentTransition(.numericText())
                                .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.3), value: animateScore)
                            
                            Text("/100")
                                .customFont("Lexend", .medium, 16)
                                .foregroundColor(.secondary)
                                .opacity(animateScore ? 1 : 0)
                                .animation(.easeInOut(duration: 0.5).delay(0.6), value: animateScore)
                        }
                        
                        Image(systemName: showBreakdown ? "chevron.up.circle.fill" : "info.circle.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(scoreColor.opacity(0.7))
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                VStack(spacing: 12) {
                    HStack {
                        Text(habit.name ?? "Habit")
                            .customFont("Lexend", .medium, 14)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 1) {
                            Text(performanceInfo.text)
                                .customFont("Lexend", .semiBold, 12)
                                .foregroundColor(scoreColor)
                            
                            if animateScore {
                                Text(performanceInfo.description)
                                    .customFont("Lexend", .regular, 10)
                                    .foregroundColor(.secondary)
                                    .opacity(0.8)
                            }
                        }
                        .opacity(animateScore ? 1 : 0)
                        .animation(.easeInOut(duration: 0.5).delay(0.8), value: animateScore)
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.gray.opacity(0.15))
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            scoreColor,
                                            scoreColor.opacity(0.8)
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(
                                    width: animateProgress ? geometry.size.width * (Double(mockScore) / 100.0) : 0,
                                    height: 8
                                )
                                .animation(.easeInOut(duration: 1.0).delay(0.5), value: animateProgress)
                        }
                    }
                    .frame(height: 8)
                }
            }
            .padding(16)
            
            // Breakdown section
            if showBreakdown {
                VStack(spacing: 16) {
                    Divider()
                        .background(Color.primary.opacity(0.1))
                    
                    VStack(spacing: 12) {
                        HStack {
                            Text("Score Breakdown")
                                .customFont("Lexend", .semiBold, 14)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        
                        VStack(spacing: 8) {
                            ScoreComponentRow(
                                title: "Completion",
                                subtitle: "\(mockBreakdown.completionPercentage)% complete",
                                score: mockBreakdown.baseScore,
                                maxScore: 80,
                                color: scoreColor.opacity(0.8),
                                icon: "checkmark.circle.fill"
                            )
                            
                            ScoreComponentRow(
                                title: "Streak Bonus",
                                subtitle: "\(mockBreakdown.currentStreakDays) days",
                                score: mockBreakdown.streakBonus,
                                maxScore: 20,
                                color: .orange,
                                icon: "flame.fill"
                            )
                        }
                        
                        VStack(spacing: 6) {
                            HStack {
                                Text("Statistics")
                                    .customFont("Lexend", .medium, 12)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            
                            HStack(spacing: 16) {
                                StatCard(
                                    title: "Completed",
                                    value: "\(mockBreakdown.actualCount)/\(mockBreakdown.expectedCount)",
                                    color: scoreColor
                                )
                                
                                StatCard(
                                    title: "Window",
                                    value: "\(mockBreakdown.windowDays) days",
                                    color: .blue
                                )
                                
                                if mockBreakdown.currentStreakDays > 0 {
                                    StatCard(
                                        title: "Streak",
                                        value: "\(mockBreakdown.streakPercentage)%",
                                        color: .orange
                                    )
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .offset(y: -10)),
                    removal: .opacity.combined(with: .offset(y: -5))
                ))
            }
        }
        .glassBackground(cornerRadius: 20)
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            animateProgress = true
            animateScore = true
        }
    }
}

