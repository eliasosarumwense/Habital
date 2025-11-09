//
//  OverallHabitScoreSection.swift
//  Habital
//
//  Created by Elias Osarumwense on 14.08.25.
//

import SwiftUI
import CoreData

struct OverallHabitScoreSection: View {
    let habits: [Habit]
    let date: Date
    
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("useGlassEffect") private var useGlassEffect = true
    
    @State private var animateProgress = false
    @State private var animateScore = false
    @State private var showBreakdown = false
    @State private var overallScore: Int = 0
    @State private var habitBreakdowns: [HabitBreakdown] = []
    
    private var scoreColor: Color {
        switch overallScore {
        case 90...100: return .green
        case 75..<90: return .blue
        case 50..<75: return .orange
        case 25..<50: return .red
        default: return .gray
        }
    }
    
    private var performanceInfo: (text: String, description: String) {
        switch overallScore {
        case 90...100: return ("Excellent", "Outstanding consistency!")
        case 75..<90: return ("Good", "Strong habit formation")
        case 50..<75: return ("Fair", "Making progress")
        case 25..<50: return ("Needs Work", "Room for improvement")
        default: return ("Starting", "Beginning your journey")
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            // Main Score Card
            mainScoreCard
            
            // Expandable Breakdown Section
            if showBreakdown {
                breakdownSection
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .offset(y: -10)),
                        removal: .opacity.combined(with: .offset(y: -5))
                    ))
            }
        }
        .onAppear {
            calculateOverallScore()
            startAnimations()
        }
        .onChange(of: date) { _ in
            calculateOverallScore()
        }
        .onChange(of: habits.count) { _ in
            calculateOverallScore()
        }
    }
    
    // MARK: - Header View
    
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
                
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 1) {
                Text("Overall Score")
                    .font(.customFont("Lexend", .semiBold, 20))
                    .foregroundColor(.primary)
                
                Text("30-day performance")
                    .font(.customFont("Lexend", .regular, 13))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
    }
    
    // MARK: - Main Score Card
    
    private var mainScoreCard: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showBreakdown.toggle()
            }
        }) {
            VStack(spacing: 20) {
                // Score Display Row
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 12) {
                        // Large Score
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(animateScore ? overallScore : 0)")
                                .font(.customFont("Lexend", .bold, 48))
                                .foregroundColor(scoreColor)
                                .contentTransition(.numericText())
                                .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.3), value: animateScore)
                            
                            Text("/100")
                                .font(.customFont("Lexend", .medium, 20))
                                .foregroundColor(.secondary)
                                .opacity(animateScore ? 1 : 0)
                                .animation(.easeInOut(duration: 0.5).delay(0.6), value: animateScore)
                        }
                        
                        // Performance Label
                        VStack(alignment: .leading, spacing: 2) {
                            Text(performanceInfo.text)
                                .font(.customFont("Lexend", .semiBold, 16))
                                .foregroundColor(.primary)
                            
                            Text(performanceInfo.description)
                                .font(.customFont("Lexend", .regular, 13))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Circular Progress Ring
                    ZStack {
                        // Background Ring
                        Circle()
                            .stroke(scoreColor.opacity(0.15), lineWidth: 8)
                            .frame(width: 80, height: 80)
                        
                        // Progress Ring
                        Circle()
                            .trim(from: 0, to: animateProgress ? Double(overallScore) / 100.0 : 0)
                            .stroke(
                                LinearGradient(
                                    colors: [scoreColor, scoreColor.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                            )
                            .frame(width: 80, height: 80)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 1.0).delay(0.5), value: animateProgress)
                        
                        // Center Icon
                        Image(systemName: showBreakdown ? "chevron.up" : "chevron.down")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(scoreColor)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: showBreakdown)
                    }
                }
                
                // Progress Bar (Linear)
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background track
                        RoundedRectangle(cornerRadius: 6)
                            .fill(scoreColor.opacity(0.12))
                            .frame(height: 6)
                        
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
                                width: animateProgress ? geometry.size.width * (Double(overallScore) / 100.0) : 0,
                                height: 6
                            )
                            .animation(.easeInOut(duration: 1.0).delay(0.7), value: animateProgress)
                    }
                }
                .frame(height: 6)
            }
            .padding(24)
        }
        .buttonStyle(PlainButtonStyle())
        //.background(cardBackground)
        .glassBackground()
        .padding(.horizontal, 20)
    }
    
    // MARK: - Breakdown Section
    
    private var breakdownSection: some View {
        VStack(spacing: 16) {
            // Divider with subtle styling
            HStack {
                RoundedRectangle(cornerRadius: 1)
                    .fill(.quaternary.opacity(0.5))
                    .frame(height: 1)
            }
            .padding(.horizontal, 20)
            
            // Habit breakdown list
            LazyVStack(spacing: 8) {
                ForEach(habitBreakdowns.indices, id: \.self) { index in
                    let breakdown = habitBreakdowns[index]
                    HabitBreakdownRow(breakdown: breakdown)
                        .opacity(animateScore ? 1 : 0)
                        .offset(y: animateScore ? 0 : 10)
                        .animation(
                            .spring(response: 0.6, dampingFraction: 0.8)
                            .delay(Double(index) * 0.05 + 0.3),
                            value: animateScore
                        )
                }
            }
            .padding(.horizontal, 20)
            
            Spacer(minLength: 16)
        }
    }
    
    // MARK: - Card Background
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [scoreColor.opacity(0.08), scoreColor.opacity(0.03)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(.quaternary.opacity(0.3), lineWidth: 0.5)
            )
            .shadow(
                color: colorScheme == .dark
                    ? Color.black.opacity(0.15)
                    : Color.gray.opacity(0.08),
                radius: 12,
                x: 0,
                y: 6
            )
    }
    
    // MARK: - Methods
    
    private func calculateOverallScore() {
        habitBreakdowns = habits.map { habit in
            let breakdown = HabitScoreManager.getScoreBreakdown(for: habit, today: date)
            let habitColor = getHabitColor(for: habit)
            return HabitBreakdown(
                id: habit.objectID,
                name: habit.name ?? "Unnamed Habit",
                score: breakdown.totalScore,
                completion: breakdown.completionPercentage,
                streak: breakdown.currentStreakDays,
                color: habitColor,
                impact: breakdown.totalScore > 70 ? .positive : breakdown.totalScore < 50 ? .negative : .neutral
            )
        }
        
        if !habitBreakdowns.isEmpty {
            overallScore = habitBreakdowns.map(\.score).reduce(0, +) / habitBreakdowns.count
        } else {
            overallScore = 0
        }
    }
    
    private func getHabitColor(for habit: Habit) -> Color {
        if let colorData = habit.color,
           let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
            return Color(uiColor)
        }
        return .blue
    }
    
    private func startAnimations() {
        withAnimation(.easeOut(duration: 0.3).delay(0.1)) {
            animateProgress = true
        }
        
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
            animateScore = true
        }
    }
}

// MARK: - Supporting Types

struct HabitBreakdown {
    let id: NSManagedObjectID
    let name: String
    let score: Int
    let completion: Int
    let streak: Int
    let color: Color
    let impact: ImpactType
    
    enum ImpactType {
        case positive, negative, neutral
        
        var color: Color {
            switch self {
            case .positive: return .green
            case .negative: return .red
            case .neutral: return .secondary
            }
        }
        
        var icon: String {
            switch self {
            case .positive: return "arrow.up"
            case .negative: return "arrow.down"
            case .neutral: return "minus"
            }
        }
        
        var description: String {
            switch self {
            case .positive: return "boosting overall"
            case .negative: return "lowering overall"
            case .neutral: return "neutral impact"
            }
        }
    }
}

struct HabitBreakdownRow: View {
    let breakdown: HabitBreakdown
    
    var body: some View {
        HStack(spacing: 12) {
            // Habit Color Indicator
            Circle()
                .fill(breakdown.color)
                .frame(width: 10, height: 10)
            
            // Habit name
            Text(breakdown.name)
                .font(.customFont("Lexend", .medium, 14))
                .foregroundColor(.primary)
                .lineLimit(1)
            
            Spacer()
            
            // Metrics Row
            HStack(spacing: 8) {
                // Score
                Text("\(breakdown.score)")
                    .font(.customFont("Lexend", .bold, 14))
                    .foregroundColor(breakdown.score >= 70 ? .green : breakdown.score >= 50 ? .orange : .red)
                
                // Impact indicator
                ZStack {
                    Circle()
                        .fill(breakdown.impact.color.opacity(0.12))
                        .frame(width: 20, height: 20)
                    
                    Image(systemName: breakdown.impact.icon)
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                        .foregroundColor(breakdown.impact.color)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(breakdown.color.opacity(0.2), lineWidth: 0.5)
                )
        )
    }
}
