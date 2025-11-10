//
//  HabitAutomationBarCard.swift
//  Habital
//
//  Compact automation progress bar to pair with weekly pie chart
//

import SwiftUI
import CoreData

struct HabitAutomationBarCard: View {
    let habit: Habit
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var animatedProgress: CGFloat = 0
    @State private var animatedPercentage: Double = 0
    @State private var showingAnalytics: Bool = false
    @State private var automationInsight: HabitAutomationInsight?
    @State private var thirtyDayImprovement: Double?
    @State private var isDataLoaded: Bool = false
    @State private var showingInsightPopover: Bool = false
    @State private var showingPeakPopover: Bool = false
    @State private var showingFoundationPopover: Bool = false
    @State private var selectedInsight: InsightType?
    
    enum InsightType: String, CaseIterable {
        case recovery = "Recovery Potential"
        case peak = "Peak Performance"
        case foundation = "Baseline"
        
        var description: String {
            switch self {
            case .recovery:
                return "Recovery Potential measures how much habit strength you can quickly regain based on your peak performance. This represents the difference between your current strength and your personal best - essentially your 'muscle memory' that can be reactivated through consistent practice."
            case .peak:
                return "Peak Performance shows your current habit strength as a percentage of your personal best performance. This helps you understand whether you're operating at full capacity or have room to return to your previous peak level of automation."
            case .foundation:
                return "Baseline represents the minimum habit strength you've 'earned' through practice and can never lose. It starts at 5% and increases with total practice days (up to 50% max). This baseline protects you during breaks - your habit can decay but never below this earned baseline."
            }
        }
    }
    
    var body: some View {
        let percentage = automationInsight?.automationPercentage ?? 0
        let colors = getAutomationColors(for: percentage)
        
        Button(action: {
            // Only the arrow opens the sheet now
        }) {
            VStack(alignment: .leading, spacing: 8) {
            // Title and percentage with 30-day improvement
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("Automation")
                    .font(.customFont("Lexend", .semibold, 15))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                // 30-day improvement indicator only
                if let improvementValue = thirtyDayImprovement {
                    // Show 30-day improvement as fallback - appears after percentage animation
                    HStack(spacing: 3) {
                        Image(systemName: getImprovementIcon(for: improvementValue))
                            .font(.caption2)
                            .foregroundStyle(getImprovementColor(for: improvementValue))
                        Text("\(improvementValue >= 0 ? "+" : "")\(Int(improvementValue))%")
                            .font(.customFont("Lexend", .medium, 10))
                            .foregroundStyle(.secondary)
                    }
                    .opacity(isDataLoaded ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.4).delay(1.2), value: isDataLoaded)
                }
                
                Text("\(Int(animatedPercentage))%")
                    .font(.customFont("Lexend", .bold, 20))
                    .foregroundStyle(
                        LinearGradient(
                            colors: colors,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            
            // Main progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.secondary.opacity(0.15))
                        .frame(height: 20)
                    
                    // Animated progress fill
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: colors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: animatedProgress * geometry.size.width, height: 20)
                        .overlay(
                            // Shimmer effect for active progress
                            RoundedRectangle(cornerRadius: 10)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0),
                                            Color.white.opacity(0.3),
                                            Color.white.opacity(0)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: animatedProgress * geometry.size.width)
                        )
                }
            }
            .frame(height: 20)
            
            // Status and target info
            HStack(spacing: 8) {
                // Status badge
                HStack(spacing: 4) {
                    Image(systemName: getStatusIcon(for: percentage))
                        .font(.caption2)
                    Text(getStatusText(for: percentage))
                        .font(.customFont("Lexend", .medium, 9.7))
                        .lineLimit(1)
                        //.minimumScaleFactor(0.8)
                }
                .foregroundStyle(colors[0])
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(colors[0].opacity(0.15))
                .clipShape(Capsule())
                .opacity(isDataLoaded ? 1.0 : 0.3)
                .animation(.easeInOut(duration: 0.4), value: isDataLoaded)
                
                Spacer()
                
                // Days to 95% target
                if let insight = automationInsight,
                   let predictions = insight.predictions,
                   let daysTo95 = predictions.estimatedDaysTo95Percent {
                    Text(formatDaysToTarget(daysTo95))
                        .font(.customFont("Lexend", .regular, 9.5))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                } else if percentage >= 95 {
                    HStack(spacing: 3) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(.yellow)
                        Text(habit.isBadHabit ? "Controlled!" : "Automated!")
                            .font(.customFont("Lexend", .medium, 9.5))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                    }
                }
            }
            .padding(.bottom, 4) // Increased spacing before insights section
            
            // Bottom row with adaptive insight and chevron arrow
            HStack(spacing: 1) {
                Button(action: {
                    // Handle insight taps here - this will be updated below
                }) {
                    adaptiveInsightView
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button(action: {
                    showingAnalytics = true
                }) {
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .opacity(0.6)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, -1) // Adjusted top padding
        }
        .padding(12)
        .sheetGlassBackground()
        .contentShape(Rectangle()) // Makes the entire card tappable - but we'll override with buttons
        }
        .buttonStyle(.plain) // Removes button styling to keep card appearance
        .onAppear {
            Task {
                await loadAutomationData()
            }
        }
        .sheet(isPresented: $showingAnalytics) {
            HabitAnalyticsView(habit: habit)
                .presentationDetents([.fraction(0.75)])
        }
        .popover(isPresented: $showingInsightPopover) {
            InsightPopoverView(
                insight: selectedInsight,
                automationInsight: automationInsight,
                habit: habit
            )
            .presentationCompactAdaptation(.popover)
        }
    }
    
    // MARK: - Async Data Loading
    @MainActor
    private func loadAutomationData() async {
        // Load automation insight
        let insight = await Task.detached {
            let engine = HabitAutomationEngine(context: viewContext)
            return engine.calculateAutomationPercentage(habit: habit)
        }.value
        
        self.automationInsight = insight
        
        // Load 30-day improvement if habit is old enough
        let habitAge = Calendar.current.dateComponents([.day], from: habit.startDate ?? Date(), to: Date()).day ?? 0
        if habitAge >= 30 {
            let improvement = await Task.detached {
                return calculate30DayImprovement()
            }.value
            self.thirtyDayImprovement = improvement
        }
        
        // Mark data as loaded for smooth transition
        withAnimation(.easeInOut(duration: 0.3)) {
            self.isDataLoaded = true
        }
        
        // Wait for 0.3 seconds before animating progress bar and percentage
        try? await Task.sleep(nanoseconds: 300_000_000)
        
        // Animate percentage counter with custom timing curve
        animatePercentageCounter(to: insight.automationPercentage)
        
        // Animate progress bar after delay
        withAnimation(.spring(response: 0.8, dampingFraction: 0.85)) {
            self.animatedProgress = CGFloat(insight.automationPercentage / 100)
        }
    }
    
    // MARK: - 30-Day Improvement Helper
    private func calculate30DayImprovement() -> Double {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        
        // Calculate current automation percentage
        let currentEngine = HabitAutomationEngine(context: viewContext)
        let currentInsight = currentEngine.calculateAutomationPercentage(habit: habit)
        let currentPercentage = currentInsight.automationPercentage
        
        // Calculate automation percentage 30 days ago
        var oldConfig = HabitAutomationConfig()
        oldConfig.analysisEnd = thirtyDaysAgo
        let oldEngine = HabitAutomationEngine(config: oldConfig, context: viewContext)
        let oldInsight = oldEngine.calculateAutomationPercentage(habit: habit)
        let oldPercentage = oldInsight.automationPercentage
        
        return currentPercentage - oldPercentage
    }
    
    // MARK: - Percentage Animation
    @MainActor
    private func animatePercentageCounter(to targetPercentage: Double) {
        // Start from 0
        animatedPercentage = 0
        
        // Custom animation that counts fast initially and slows down at the end
        let totalDuration: TimeInterval = 0.88
        let updateInterval: TimeInterval = 0.016 // ~60fps for smoother animation
        let totalSteps = Int(totalDuration / updateInterval)
        
        // Create a smooth easing function that starts fast and slows down at the end
        func customEasingFunction(progress: Double) -> Double {
            // Ease-out cubic with smoother transition
            return 1 - pow(1 - progress, 2.5)
        }
        
        // Animate with discrete steps for counting effect
        Task {
            for step in 0...totalSteps {
                let progress = Double(step) / Double(totalSteps)
                let easedProgress = customEasingFunction(progress: progress)
                let currentValue = targetPercentage * easedProgress
                
                await MainActor.run {
                    // Round to avoid floating point precision issues
                    let roundedValue = round(currentValue * 10) / 10
                    self.animatedPercentage = min(targetPercentage, roundedValue)
                }
                
                // Consistent timing for smoother animation
                try? await Task.sleep(nanoseconds: UInt64(updateInterval * 1_000_000_000))
            }
            
            // Ensure we end exactly at the target with proper rounding
            await MainActor.run {
                self.animatedPercentage = round(targetPercentage * 10) / 10
            }
        }
    }
    // MARK: - Comprehensive Insight Options
    @ViewBuilder
    private var adaptiveInsightView: some View {
        if let insight = automationInsight {
            let historyAnalysis = insight.historyAnalysis
            let predictions = insight.predictions
            
            // Main row with recovery potential (preferred) or peak performance, always with baseline
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 0) {
                    // Recovery Potential (preferred when available and meaningful > 5%)
                    if let historyAnalysis = historyAnalysis, historyAnalysis.recoveryPotential > 0.05 {
                        Button(action: {
                            selectedInsight = .recovery
                            showingInsightPopover = true
                        }) {
                            recoveryPotentialBottomView(historyAnalysis: historyAnalysis)
                        }
                        .buttonStyle(.plain)
                        .opacity(isDataLoaded ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.4).delay(1.0), value: isDataLoaded)
                        .popover(isPresented: Binding<Bool>(
                            get: { showingInsightPopover && selectedInsight == .recovery },
                            set: { if !$0 { showingInsightPopover = false; selectedInsight = nil } }
                        )) {
                            InsightPopoverView(
                                insight: .recovery,
                                automationInsight: automationInsight,
                                habit: habit
                            )
                            .presentationCompactAdaptation(.popover)
                        }
                        
                        // Middle dot separator and Baseline (always shown)
                        Text(" • ")
                            .font(.customFont("Lexend", .medium, 9))
                            .foregroundStyle(.secondary.opacity(0.5))
                            .opacity(isDataLoaded ? 1.0 : 0.0)
                            .animation(.easeInOut(duration: 0.4).delay(1.1), value: isDataLoaded)
                        
                        Button(action: {
                            selectedInsight = .foundation
                            showingFoundationPopover = true
                        }) {
                            experienceFloorView(historyAnalysis: historyAnalysis)
                        }
                        .buttonStyle(.plain)
                        .opacity(isDataLoaded ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.4).delay(1.2), value: isDataLoaded)
                        .popover(isPresented: Binding<Bool>(
                            get: { showingFoundationPopover && selectedInsight == .foundation },
                            set: { if !$0 { showingFoundationPopover = false; selectedInsight = nil } }
                        )) {
                            InsightPopoverView(
                                insight: .foundation,
                                automationInsight: automationInsight,
                                habit: habit
                            )
                            .presentationCompactAdaptation(.popover)
                        }
                    }
                    // Peak Performance (fallback when recovery potential is low) + Baseline
                    else if let historyAnalysis = historyAnalysis, historyAnalysis.peakStrength > 0 {
                        Button(action: {
                            selectedInsight = .peak
                            showingPeakPopover = true
                        }) {
                            peakComparisonView(historyAnalysis: historyAnalysis)
                        }
                        .buttonStyle(.plain)
                        .opacity(isDataLoaded ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.4).delay(1.0), value: isDataLoaded)
                        .popover(isPresented: Binding<Bool>(
                            get: { showingPeakPopover && selectedInsight == .peak },
                            set: { if !$0 { showingPeakPopover = false; selectedInsight = nil } }
                        )) {
                            InsightPopoverView(
                                insight: .peak,
                                automationInsight: automationInsight,
                                habit: habit
                            )
                            .presentationCompactAdaptation(.popover)
                        }
                        
                        // Middle dot separator and Baseline (always shown)
                        Text(" • ")
                            .font(.customFont("Lexend", .medium, 9))
                            .foregroundStyle(.secondary.opacity(0.5))
                            .opacity(isDataLoaded ? 1.0 : 0.0)
                            .animation(.easeInOut(duration: 0.4).delay(1.1), value: isDataLoaded)
                        
                        Button(action: {
                            selectedInsight = .foundation
                            showingFoundationPopover = true
                        }) {
                            experienceFloorView(historyAnalysis: historyAnalysis)
                        }
                        .buttonStyle(.plain)
                        .opacity(isDataLoaded ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.4).delay(1.2), value: isDataLoaded)
                        .popover(isPresented: Binding<Bool>(
                            get: { showingFoundationPopover && selectedInsight == .foundation },
                            set: { if !$0 { showingFoundationPopover = false; selectedInsight = nil } }
                        )) {
                            InsightPopoverView(
                                insight: .foundation,
                                automationInsight: automationInsight,
                                habit: habit
                            )
                            .presentationCompactAdaptation(.popover)
                        }
                    } 
                    // Baseline only (always displayed when history analysis is available)
                    else if let historyAnalysis = historyAnalysis {
                        Button(action: {
                            selectedInsight = .foundation
                            showingFoundationPopover = true
                        }) {
                            experienceFloorView(historyAnalysis: historyAnalysis)
                        }
                        .buttonStyle(.plain)
                        .opacity(isDataLoaded ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.4).delay(1.0), value: isDataLoaded)
                        .popover(isPresented: Binding<Bool>(
                            get: { showingFoundationPopover && selectedInsight == .foundation },
                            set: { if !$0 { showingFoundationPopover = false; selectedInsight = nil } }
                        )) {
                            InsightPopoverView(
                                insight: .foundation,
                                automationInsight: automationInsight,
                                habit: habit
                            )
                            .presentationCompactAdaptation(.popover)
                        }
                    }
                    
                    Spacer()
                }
                
                // Recovery Potential (commented out for now)
//                if let recoveryPotential = historyAnalysis?.recoveryPotential, recoveryPotential > 0.1 {
//                    Button(action: {
//                        selectedInsight = .recovery
//                        showingInsightPopover = true
//                    }) {
//                        recoveryPotentialView(historyAnalysis: historyAnalysis)
//                    }
//                    .buttonStyle(.plain)
//                }
            }
            
        } else {
            loadingStateView
        }
    }
    
    // MARK: - Individual Insight Views (Choose Your Favorite!)
    
    // 1. Habit Strength - Core neural pathway strength
    @ViewBuilder
    private func habitStrengthView(strength: Double) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "brain.head.profile")
                .font(.caption2)
                .foregroundStyle(.blue)
            
            Text("Strength: \(Int(strength * 100))%")
                .font(.customFont("Lexend", .medium, 10))
                .foregroundStyle(.secondary)
        }
    }
    
    // 2. Recovery Potential - How much can be quickly recovered (with capsule style for bottom row)
    @ViewBuilder
    private func recoveryPotentialBottomView(historyAnalysis: HabitHistoryAnalysis?) -> some View {
        if let historyAnalysis = historyAnalysis, historyAnalysis.recoveryPotential > 0.05 {
            let recoveryPotential = historyAnalysis.recoveryPotential
            HStack(spacing: 4) {
                Image(systemName: "arrow.up.heart.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(.green.opacity(0.5))
                
                Text("Recovery +\(Int(recoveryPotential * 100))%")
                    .font(.customFont("Lexend", .medium, 10))
                    .foregroundStyle(.primary.opacity(0.8))
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(.secondary.opacity(0.1))
            .clipShape(Capsule())
        }
    }
    
    // 2b. Recovery Potential - Original style (kept for reference)
    @ViewBuilder
    private func recoveryPotentialView(historyAnalysis: HabitHistoryAnalysis?) -> some View {
        if let historyAnalysis = historyAnalysis, historyAnalysis.recoveryPotential > 0.1 {
            let recoveryPotential = historyAnalysis.recoveryPotential
            HStack(spacing: 3) {
                Image(systemName: "arrow.up.heart")
                    .font(.system(size: 8))
                    .foregroundStyle(.green.opacity(0.3))
                
                Text("Recovery +\(Int(recoveryPotential * 100))%")
                    .font(.customFont("Lexend", .medium, 10))
                    .foregroundStyle(.secondary)
            }
            .overlay(
                // Subtle tap indicator
                RoundedRectangle(cornerRadius: 6)
                    .stroke(.secondary.opacity(0.15), lineWidth: 0.5)
                    .padding(-4)
            )
        }
    }
    
    // 3. Peak Performance - Current vs personal best (capsule style)
    @ViewBuilder
    private func peakComparisonView(historyAnalysis: HabitHistoryAnalysis?) -> some View {
        if let historyAnalysis = historyAnalysis, historyAnalysis.peakStrength > 0 {
            let currentStrength = historyAnalysis.currentStrength
            let peakStrength = historyAnalysis.peakStrength
            let percentageOfPeak = (currentStrength / peakStrength) * 100
            HStack(spacing: 4) {
                Image(systemName: percentageOfPeak >= 80 ? "mountain.2.fill" : "mountain.2")
                    .font(.system(size: 9))
                    .foregroundStyle(.purple.opacity(0.5))
                
                Text("\(Int(percentageOfPeak))% Peak")
                    .font(.customFont("Lexend", .medium, 10))
                    .foregroundStyle(.primary.opacity(0.8))
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(.secondary.opacity(0.1))
            .clipShape(Capsule())
        }
    }
    
    // 4. Habit Foundation - Earned minimum strength (capsule style)
    @ViewBuilder
    private func experienceFloorView(historyAnalysis: HabitHistoryAnalysis?) -> some View {
        if let historyAnalysis = historyAnalysis {
            let experienceFloor = historyAnalysis.experienceFloor
            HStack(spacing: 4) {
                Image(systemName: "flag.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(.orange.opacity(0.5))
                
                Text("Baseline \(Int(experienceFloor * 100))%")
                    .font(.customFont("Lexend", .medium, 10))
                    .foregroundStyle(.primary.opacity(0.8))
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(.secondary.opacity(0.1))
            .clipShape(Capsule())
        }
    }
    
    // 5. Trend Direction - Is habit getting stronger/weaker?
    @ViewBuilder
    private func trendView(predictions: HabitPredictions?) -> some View {
        if let trend = predictions?.trend {
            HStack(spacing: 4) {
                Image(systemName: trend.icon)
                    .font(.caption2)
                    .foregroundStyle(Color(trend.color))
                
                Text("Trend: \(getTrendText(trend))")
                    .font(.customFont("Lexend", .medium, 10))
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // 6. Intensity Level - Difficulty setting
    @ViewBuilder
    private func intensityView() -> some View {
        HStack(spacing: 4) {
            Image(systemName: getIntensityIcon(level: Int(habit.intensityLevel)))
                .font(.caption2)
                .foregroundStyle(getIntensityColor(level: Int(habit.intensityLevel)))
            
            Text("Level \(habit.intensityLevel) \(getIntensityText(level: Int(habit.intensityLevel)))")
                .font(.customFont("Lexend", .medium, 10))
                .foregroundStyle(.secondary)
        }
    }
    
    // 7. Total Experience - Days of practice
    @ViewBuilder
    private func totalExperienceView(historyAnalysis: HabitHistoryAnalysis?) -> some View {
        if let historyAnalysis = historyAnalysis {
            let totalStreakDays = historyAnalysis.totalStreakDays
            HStack(spacing: 4) {
                Image(systemName: "calendar.badge.checkmark")
                    .font(.caption2)
                    .foregroundStyle(.green)
                
                Text("\(totalStreakDays) days practiced")
                    .font(.customFont("Lexend", .medium, 10))
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // 8. Streak Performance - Current vs best
    @ViewBuilder
    private func streakPerformanceView(historyAnalysis: HabitHistoryAnalysis?) -> some View {
        if let historyAnalysis = historyAnalysis, historyAnalysis.bestStreakEver > 0 {
            let currentStreak = historyAnalysis.currentStreak
            let bestStreak = historyAnalysis.bestStreakEver
            HStack(spacing: 4) {
                Image(systemName: currentStreak >= bestStreak ? "flame.fill" : "flame")
                    .font(.caption2)
                    .foregroundStyle(currentStreak >= bestStreak ? .orange : .gray)
                
                Text("\(currentStreak)/\(bestStreak) best")
                    .font(.customFont("Lexend", .medium, 10))
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // 9. Residual Memory - What remains after breaks
    @ViewBuilder
    private func residualMemoryView(historyAnalysis: HabitHistoryAnalysis?) -> some View {
        if let historyAnalysis = historyAnalysis, historyAnalysis.peakStrength > 0 {
            let currentStrength = historyAnalysis.currentStrength
            let peakStrength = historyAnalysis.peakStrength
            let residualPercentage = getResidualMemoryPercentage(intensity: Int(habit.intensityLevel))
            let expectedResidual = peakStrength * residualPercentage
            let actualResidual = currentStrength
            
            if actualResidual >= expectedResidual {
                HStack(spacing: 4) {
                    Image(systemName: "memorychip")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                    
                    Text("Memory intact")
                        .font(.customFont("Lexend", .medium, 10))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    // 10. Automation Progress - Time to reach targets
    @ViewBuilder
    private func automationProgressView(predictions: HabitPredictions?) -> some View {
        if let daysTo95 = predictions?.estimatedDaysTo95Percent, daysTo95 <= 30 {
            HStack(spacing: 4) {
                Image(systemName: "target")
                    .font(.caption2)
                    .foregroundStyle(.blue)
                
                Text("\(daysTo95) days to 95%")
                    .font(.customFont("Lexend", .medium, 10))
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // Loading state
    @ViewBuilder
    private var loadingStateView: some View {
        HStack(spacing: 4) {
            Text("Analyzing...")
                .font(.customFont("Lexend", .medium, 8))
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Helper Functions for Insights
    private func getTrendText(_ trend: CompletionTrend) -> String {
        switch trend {
        case .improving: return "Strengthening"
        case .stable: return "Stable"
        case .declining: return "Weakening"
        }
    }
    
    private func getIntensityIcon(level: Int) -> String {
        switch level {
        case 1: return "speedometer"
        case 2: return "gauge.medium"
        case 3: return "gauge.high"
        case 4: return "flame.fill"
        default: return "speedometer"
        }
    }
    
    private func getIntensityColor(level: Int) -> Color {
        switch level {
        case 1: return .green
        case 2: return .yellow
        case 3: return .orange
        case 4: return .red
        default: return .gray
        }
    }
    
    private func getIntensityText(level: Int) -> String {
        switch level {
        case 1: return "Easy"
        case 2: return "Medium"
        case 3: return "Hard"
        case 4: return "Extreme"
        default: return "Unknown"
        }
    }
    
    private func getResidualMemoryPercentage(intensity: Int) -> Double {
        // Based on I_rho function from intensity mapping
        let values = [0.20, 0.17, 0.15, 0.12]
        let index = max(0, min(3, intensity - 1))
        return values[index]
    }
    
    // MARK: - Helper Functions for Advanced Status
    private func getPercentageOfPeak() -> Double {
        guard let historyAnalysis = automationInsight?.historyAnalysis,
              historyAnalysis.peakStrength > 0 else {
            return 100 // If no peak data, assume we're at peak
        }
        
        let currentStrength = historyAnalysis.currentStrength
        let peakStrength = historyAnalysis.peakStrength
        return (currentStrength / peakStrength) * 100
    }
    
    /*
     ADVANCED STATUS SYSTEM - 15+ Different Status Messages & Icons
     
     The status considers multiple factors for realistic assessment:
     
     📊 PERFORMANCE INDICATORS:
     • Peak Performance: How close to personal best (100% = "Peak", 85-99% = "Near Peak Form")
     • Recovery Potential: Available muscle memory (30%+ = "Muscle Memory")
     • Foundation Strength: Earned baseline protection (25%+ = strong)
     • Trend Analysis: 30-day improvement/decline patterns
     • Streak Performance: Current vs best streak comparisons
     
     🎯 STATUS CATEGORIES (Good Habits):
     1. "Peak Automation" - At 95%+ automation AND at 100% of personal best
     2. "Fully Automated" - 95%+ automation achieved
     3. "Near Peak Form" - 80%+ and 85-99% of personal best
     4. "Best Streak Ever" - Currently on best streak
     5. "Muscle Memory" - High recovery potential available
     6. "Major Growth" - Big improvement trend
     7. "Well Automated" - Strong 80%+ performance
     8. "Rebuilding" - Has recovery potential, making comeback
     9. "Getting Stronger" - Steady improvement trend
     10. "Accelerating" - Good improvement in 60-80% range
     11. "Solid Progress" - Has foundation, making progress
     12. "Building Habit" - Actively improving in 40-60% range
     13. "Foundation Built" - Strong foundation established
     14. "Taking Shape" - Habit forming in 40-60% range
     15. "Early Foundation" - Low percentage but strong base
     
     🛡️ STATUS CATEGORIES (Bad Habits - Control):
     Similar structure but focused on "control" rather than "automation"
     • "Peak Control" - At 95%+ control AND at 100% of personal best
     
     ⚠️ DECLINE INDICATORS:
     • "Control Slipping" / "Automation Fading" - Significant decline
     • "Losing Ground" / "Losing Momentum" - Moderate decline
     • "Struggling" - Early stage decline
     • "Failing Control" / "Habit Failing" - Severe decline
     
     🔄 RECOVERY INDICATORS:
     • Uses recovery potential to show "Rebuilding" or "Has Potential"
     • Foundation strength provides stability during low periods
     • Peak comparison shows realistic achievement targets
     
     📏 PEAK PERFORMANCE LOGIC:
     • isAtPeak: 100% of personal best (exactly at peak)
     • isNearPeak: 85-99% of personal best (approaching peak)
     • This prevents showing "Near Peak" when someone is actually AT their peak
     */
    
    // MARK: - Helper Functions
    private func getImprovementIcon(for improvement: Double) -> String {
        if improvement > 0 {
            return "arrow.up.right"
        } else if improvement < 0 {
            return "arrow.down.right"
        } else {
            return "" // Flat line icon for 0% change
        }
    }
    
    private func getImprovementColor(for improvement: Double) -> Color {
        if improvement > 0 {
            return .green
        } else if improvement < 0 {
            return .red
        } else {
            return .gray // Gray color for 0% change
        }
    }
    
    private func formatDaysToTarget(_ days: Int) -> String {
        let targetText = habit.isBadHabit ? "95% control" : "95%"
        
        if days <= 7 {
            return "~\(days) days to \(targetText)"
        } else if days <= 14 {
            return "~2 weeks to \(targetText)"
        } else if days <= 30 {
            return "~\(days / 7) weeks to \(targetText)"
        } else if days <= 90 {
            return "~\(days / 30) months to \(targetText)"
        } else {
            return "3+ months to \(targetText)"
        }
    }
    
    private func getAutomationColors(for percentage: Double) -> [Color] {
        if habit.isBadHabit {
            // For bad habits: red = still doing it, green = successfully avoiding
            if percentage < 30 {
                return [.red, .orange]
            } else if percentage < 70 {
                return [.orange, .yellow]
            } else {
                return [.green, .mint]
            }
        } else {
            // For good habits: standard progression
            if percentage < 30 {
                return [.red, .orange]
            } else if percentage < 70 {
                return [.orange, .yellow]
            } else {
                return [.green, .blue]
            }
        }
    }
    
    private func getStatusIcon(for percentage: Double) -> String {
        // Show neutral icon when data is not loaded
        guard isDataLoaded else {
            return "clock.fill"
        }
        
        let improvement = thirtyDayImprovement
        let isImproving = improvement != nil && improvement! > 0
        let isDecline = improvement != nil && improvement! < -5
        let isBigImprovement = improvement != nil && improvement! > 10
        let isSignificantDecline = improvement != nil && improvement! < -15
        
        // Get advanced insights
        let historyAnalysis = automationInsight?.historyAnalysis
        let hasRecoveryPotential = historyAnalysis?.recoveryPotential ?? 0 > 0.15
        let hasHighRecoveryPotential = historyAnalysis?.recoveryPotential ?? 0 > 0.30
        let percentageOfPeak = getPercentageOfPeak()
        let isAtPeak = percentageOfPeak >= 100
        let isNearPeak = percentageOfPeak >= 85 && percentageOfPeak < 100
        let hasStrongFoundation = historyAnalysis?.experienceFloor ?? 0 > 0.25
        
        if habit.isBadHabit {
            // For bad habits - higher percentage = better control
            if percentage >= 95 {
                return isAtPeak ? "crown.fill" : "shield.fill"
            } else if percentage >= 80 {
                if isSignificantDecline {
                    return "exclamationmark.triangle.fill"
                } else if hasHighRecoveryPotential {
                    return "arrow.up.heart.fill"
                } else if isBigImprovement {
                    return "arrow.up.circle.fill"
                } else if isNearPeak {
                    return "mountain.2.fill"
                } else {
                    return "hand.raised.fill"
                }
            } else if percentage >= 60 {
                if isSignificantDecline {
                    return "arrow.down.circle.fill"
                } else if hasRecoveryPotential {
                    return "arrow.up.heart"
                } else if isBigImprovement {
                    return "arrow.up.right.circle.fill"
                } else if isImproving {
                    return "plus.circle.fill"
                } else {
                    return "pause.circle.fill"
                }
            } else if percentage >= 40 {
                if isDecline {
                    return "arrow.down.circle.fill"
                } else if hasRecoveryPotential {
                    return "memorychip.fill"
                } else if isImproving {
                    return "arrow.up.right.circle.fill"
                } else {
                    return "clock.fill"
                }
            } else if percentage >= 20 {
                return hasStrongFoundation ? "building.columns.fill" : (isDecline ? "minus.circle.fill" : "plus.circle.fill")
            } else {
                return isDecline ? "xmark.circle.fill" : "circle.dashed"
            }
        } else {
            // For good habits - higher percentage = better automation
            if percentage >= 95 {
                return isAtPeak ? "crown.fill" : "checkmark.seal.fill"
            } else if percentage >= 80 {
                if isSignificantDecline {
                    return "exclamationmark.triangle.fill"
                } else if hasHighRecoveryPotential {
                    return "arrow.up.heart.fill"
                } else if isBigImprovement {
                    return "arrow.up.circle.fill"
                } else if isNearPeak {
                    return "mountain.2.fill"
                } else {
                    return "checkmark.circle.fill"
                }
            } else if percentage >= 60 {
                if isSignificantDecline {
                    return "arrow.down.circle.fill"
                } else if hasRecoveryPotential {
                    return "arrow.up.heart"
                } else if isBigImprovement {
                    return "arrow.up.right.circle.fill"
                } else if isImproving {
                    return "plus.circle.fill"
                } else {
                    return "pause.circle.fill"
                }
            } else if percentage >= 40 {
                if isDecline {
                    return "arrow.down.circle.fill"
                } else if hasRecoveryPotential {
                    return "memorychip.fill"
                } else if isImproving {
                    return "arrow.up.right.circle.fill"
                } else {
                    return "clock.fill"
                }
            } else if percentage >= 20 {
                return hasStrongFoundation ? "building.columns.fill" : (isDecline ? "minus.circle.fill" : "plus.circle.fill")
            } else {
                return isDecline ? "xmark.circle.fill" : "circle.dashed"
            }
        }
    }
    
    private func getStatusText(for percentage: Double) -> String {
        // Show loading state text when data is not loaded
        guard isDataLoaded else {
            return "Loading..."
        }
        
        let improvement = thirtyDayImprovement
        let isImproving = improvement != nil && improvement! > 0
        let isDecline = improvement != nil && improvement! < -5
        let isBigImprovement = improvement != nil && improvement! > 10
        let isSignificantDecline = improvement != nil && improvement! < -15
        
        // Get advanced insights for more sophisticated status messages
        let historyAnalysis = automationInsight?.historyAnalysis
        let recoveryPotential = historyAnalysis?.recoveryPotential ?? 0
        let hasRecoveryPotential = recoveryPotential > 0.15
        let hasHighRecoveryPotential = recoveryPotential > 0.30
        let percentageOfPeak = getPercentageOfPeak()
        let isAtPeak = percentageOfPeak >= 100
        let isNearPeak = percentageOfPeak >= 85 && percentageOfPeak < 100
        let hasStrongFoundation = historyAnalysis?.experienceFloor ?? 0 > 0.25
        let currentStreak = historyAnalysis?.currentStreak ?? 0
        let bestStreak = historyAnalysis?.bestStreakEver ?? 0
        let isOnBestStreak = currentStreak >= bestStreak && bestStreak > 0
        
        if habit.isBadHabit {
            if percentage >= 95 {
                return isAtPeak ? "Peak Control" : "Fully Controlled"
            } else if percentage >= 80 {
                if isSignificantDecline {
                    return "Control Slipping"
                } else if hasHighRecoveryPotential {
                    return "Muscle Memory"
                } else if isBigImprovement {
                    return "Major Progress"
                } else if isNearPeak {
                    return "Near Peak Form"
                } else if isOnBestStreak {
                    return "Best Streak Ever"
                } else {
                    return "Strong Control"
                }
            } else if percentage >= 60 {
                if isSignificantDecline {
                    return "Losing Ground"
                } else if hasRecoveryPotential {
                    return "Rebuilding"
                } else if isBigImprovement {
                    return "Making Progress"
                } else if isImproving {
                    return "Gaining Control"
                } else if hasStrongFoundation {
                    return "Solid Base"
                } else {
                    return "Inconsistent"
                }
            } else if percentage >= 40 {
                if isDecline {
                    return "Weakening"
                } else if hasRecoveryPotential {
                    return "Has Potential"
                } else if isImproving {
                    return "Building Up"
                } else if hasStrongFoundation {
                    return "Foundation Set"
                } else {
                    return "Developing"
                }
            } else if percentage >= 20 {
                return hasStrongFoundation ? "Early Foundation" : (isDecline ? "Struggling" : "Starting Out")
            } else {
                return isDecline ? "Failing Control" : "Just Beginning"
            }
        } else {
            if percentage >= 95 {
                return isAtPeak ? "Peak Automation" : "Fully Automated"
            } else if percentage >= 80 {
                if isSignificantDecline {
                    return "Automation Fading"
                } else if hasHighRecoveryPotential {
                    return "Muscle Memory"
                } else if isBigImprovement {
                    return "Major Growth"
                } else if isNearPeak {
                    return "Near Peak Form"
                } else if isOnBestStreak {
                    return "Best Streak Ever"
                } else {
                    return "Well Automated"
                }
            } else if percentage >= 60 {
                if isSignificantDecline {
                    return "Losing Momentum"
                } else if hasRecoveryPotential {
                    return "Rebuilding"
                } else if isBigImprovement {
                    return "Accelerating"
                } else if isImproving {
                    return "Getting Stronger"
                } else if hasStrongFoundation {
                    return "Solid Progress"
                } else {
                    return "Moderately Set"
                }
            } else if percentage >= 40 {
                if isDecline {
                    return "Weakening"
                } else if hasRecoveryPotential {
                    return "Has Potential"
                } else if isImproving {
                    return "Building Habit"
                } else if hasStrongFoundation {
                    return "Foundation Built"
                } else {
                    return "Taking Shape"
                }
            } else if percentage >= 20 {
                return hasStrongFoundation ? "Early Foundation" : (isDecline ? "Struggling" : "Early Stage")
            } else {
                return isDecline ? "Habit Failing" : "Just Starting"
            }
        }
    }
}

// MARK: - Insight Popover View
struct InsightPopoverView: View {
    let insight: HabitAutomationBarCard.InsightType?
    let automationInsight: HabitAutomationInsight?
    let habit: Habit
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let insight = insight, let automationInsight = automationInsight {
                // Header with icon and title
                HStack(spacing: 8) {
                    Image(systemName: getInsightIcon(for: insight))
                        .font(.title2)
                        .foregroundStyle(getInsightColor(for: insight))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(insight.rawValue)
                            .font(.customFont("Lexend", .semibold, 14))
                            .foregroundStyle(.primary)
                        
                        Text(getInsightSubtitle(for: insight))
                            .font(.customFont("Lexend", .regular, 11))
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
                
                Divider()
                
                // Current values section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current Values")
                        .font(.customFont("Lexend", .semibold, 12))
                        .foregroundStyle(.primary)
                    
                    getInsightValues(for: insight, automationInsight: automationInsight)
                }
                
                Divider()
                
                // Explanation section
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "info.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.blue)
                        
                        Text("What This Means")
                            .font(.customFont("Lexend", .semibold, 12))
                            .foregroundStyle(.primary)
                    }
                    
                    Text(getDetailedExplanation(for: insight, automationInsight: automationInsight))
                        .font(.customFont("Lexend", .regular, 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                // Action tips section
                if let actionTip = getActionTip(for: insight, automationInsight: automationInsight) {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 4) {
                            Image(systemName: "lightbulb.fill")
                                .font(.caption)
                                .foregroundStyle(.yellow)
                            
                            Text("Insight")
                                .font(.customFont("Lexend", .semibold, 12))
                                .foregroundStyle(.primary)
                        }
                        
                        Text(actionTip)
                            .font(.customFont("Lexend", .regular, 11))
                            .foregroundStyle(.secondary)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title2)
                        .foregroundStyle(.orange)
                    
                    Text("No insight data available")
                        .font(.customFont("Lexend", .regular, 12))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .frame(width: 280)
        .frame(maxHeight: 400)
        .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.quaternary, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 8)
    }
    
    // MARK: - Helper Functions for Popover
    
    private func getInsightIcon(for insight: HabitAutomationBarCard.InsightType) -> String {
        switch insight {
        case .recovery:
            return "arrow.up.heart.fill"
        case .peak:
            return "mountain.2.fill"
        case .foundation:
            return "flag.checkered"
        }
    }
    
    private func getInsightColor(for insight: HabitAutomationBarCard.InsightType) -> Color {
        switch insight {
        case .recovery:
            return .green
        case .peak:
            return .purple
        case .foundation:
            return .orange
        }
    }
    
    private func getInsightSubtitle(for insight: HabitAutomationBarCard.InsightType) -> String {
        switch insight {
        case .recovery:
            return "How much you can quickly regain"
        case .peak:
            return "Current vs your personal best"
        case .foundation:
            return "Your earned minimum baseline"
        }
    }
    
    @ViewBuilder
    private func getInsightValues(for insight: HabitAutomationBarCard.InsightType, automationInsight: HabitAutomationInsight) -> some View {
        let historyAnalysis = automationInsight.historyAnalysis
        
        switch insight {
        case .recovery:
            if let historyAnalysis = historyAnalysis {
                let recoveryPotential = historyAnalysis.recoveryPotential
                let currentStrength = historyAnalysis.currentStrength
                let peakStrength = historyAnalysis.peakStrength
                
                VStack(spacing: 6) {
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.caption2)
                                .foregroundStyle(.blue)
                            Text("Current Strength:")
                                .font(.customFont("Lexend", .medium, 11))
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("\(Int(currentStrength * 100))%")
                            .font(.customFont("Lexend", .semibold, 11))
                            .foregroundStyle(.primary)
                    }
                    
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "crown.fill")
                                .font(.caption2)
                                .foregroundStyle(.yellow)
                            Text("Peak Strength:")
                                .font(.customFont("Lexend", .medium, 11))
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("\(Int(peakStrength * 100))%")
                            .font(.customFont("Lexend", .semibold, 11))
                            .foregroundStyle(.primary)
                    }
                    
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.heart.fill")
                                .font(.caption2)
                                .foregroundStyle(.green)
                            Text("Recovery Potential:")
                                .font(.customFont("Lexend", .medium, 11))
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("+\(Int(recoveryPotential * 100))%")
                            .font(.customFont("Lexend", .bold, 11))
                            .foregroundStyle(.green)
                    }
                }
            }
            
        case .peak:
            if let historyAnalysis = historyAnalysis {
                let currentStrength = historyAnalysis.currentStrength
                let peakStrength = historyAnalysis.peakStrength
                let percentageOfPeak = (currentStrength / peakStrength) * 100
                
                VStack(spacing: 6) {
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.caption2)
                                .foregroundStyle(.blue)
                            Text("Current Strength:")
                                .font(.customFont("Lexend", .medium, 11))
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("\(Int(currentStrength * 100))%")
                            .font(.customFont("Lexend", .semibold, 11))
                            .foregroundStyle(.primary)
                    }
                    
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "crown.fill")
                                .font(.caption2)
                                .foregroundStyle(.yellow)
                            Text("Personal Best:")
                                .font(.customFont("Lexend", .medium, 11))
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("\(Int(peakStrength * 100))%")
                            .font(.customFont("Lexend", .semibold, 11))
                            .foregroundStyle(.primary)
                    }
                    
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "mountain.2.fill")
                                .font(.caption2)
                                .foregroundStyle(.purple)
                            Text("Peak Performance:")
                                .font(.customFont("Lexend", .medium, 11))
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("\(Int(percentageOfPeak))%")
                            .font(.customFont("Lexend", .bold, 11))
                            .foregroundStyle(percentageOfPeak >= 80 ? .green : percentageOfPeak >= 50 ? .orange : .red)
                    }
                }
            }
            
        case .foundation:
            if let historyAnalysis = historyAnalysis {
                let experienceFloor = historyAnalysis.experienceFloor
                let totalStreakDays = historyAnalysis.totalStreakDays
                let currentStrength = historyAnalysis.currentStrength
                
                VStack(spacing: 6) {
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar.badge.checkmark")
                                .font(.caption2)
                                .foregroundStyle(.green)
                            Text("Practice Days:")
                                .font(.customFont("Lexend", .medium, 11))
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("\(totalStreakDays) days")
                            .font(.customFont("Lexend", .semibold, 11))
                            .foregroundStyle(.primary)
                    }
                    
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "building.columns.fill")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                            Text("Baseline Level:")
                                .font(.customFont("Lexend", .medium, 11))
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("\(Int(experienceFloor * 100))%")
                            .font(.customFont("Lexend", .bold, 11))
                            .foregroundStyle(.orange)
                    }
                    
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.caption2)
                                .foregroundStyle(.blue)
                            Text("Current Strength:")
                                .font(.customFont("Lexend", .medium, 11))
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("\(Int(currentStrength * 100))%")
                            .font(.customFont("Lexend", .semibold, 11))
                            .foregroundStyle(.primary)
                    }
                    
                    // Protection status
                    let protectionLevel = (experienceFloor / currentStrength) * 100
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "lock.shield.fill")
                                .font(.caption2)
                                .foregroundStyle(.blue)
                            Text("Protection:")
                                .font(.customFont("Lexend", .medium, 11))
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("\(Int(protectionLevel))% secured")
                            .font(.customFont("Lexend", .semibold, 11))
                            .foregroundStyle(.blue)
                    }
                }
            }
        }
    }
    
    private func getDetailedExplanation(for insight: HabitAutomationBarCard.InsightType, automationInsight: HabitAutomationInsight) -> String {
        let historyAnalysis = automationInsight.historyAnalysis
        
        switch insight {
        case .recovery:
            if let historyAnalysis = historyAnalysis {
                let recoveryPotential = historyAnalysis.recoveryPotential
                let recoveryPercent = Int(recoveryPotential * 100)
                if recoveryPercent > 30 {
                    return "You have significant recovery potential! Your brain still remembers this habit strongly. With consistent practice, you can quickly regain \(recoveryPercent)% more automation from your muscle memory."
                } else if recoveryPercent > 10 {
                    return "You have moderate recovery potential. Your brain retains some memory of this habit, allowing you to rebuild \(recoveryPercent)% faster than starting from scratch."
                } else {
                    return "Your current strength is close to your peak. There's limited recovery potential because you're already performing near your best level."
                }
            }
            return "Recovery potential measures how much habit strength you can quickly regain based on your peak performance."
            
        case .peak:
            if let historyAnalysis = historyAnalysis {
                let currentStrength = historyAnalysis.currentStrength
                let peakStrength = historyAnalysis.peakStrength
                let percentageOfPeak = (currentStrength / peakStrength) * 100
                let currentPercent = Int(currentStrength * 100)
                let peakPercent = Int(peakStrength * 100)
                
                if percentageOfPeak >= 90 {
                    return "Excellent! You're operating at \(Int(percentageOfPeak))% of your peak performance (\(peakPercent)%). You're maintaining your habit at nearly optimal levels."
                } else if percentageOfPeak >= 70 {
                    return "Good progress. You're at \(Int(percentageOfPeak))% of your personal best. You previously reached \(peakPercent)% automation, so there's room to improve back to that level."
                } else if percentageOfPeak >= 50 {
                    return "You're at \(Int(percentageOfPeak))% of your peak strength. Your best was \(peakPercent)% - this shows you have the potential to significantly improve with consistent effort."
                } else {
                    return "You're currently at \(currentPercent)% strength compared to your peak of \(peakPercent)%. This represents a significant opportunity for recovery and growth."
                }
            }
            return "Peak comparison shows your current habit strength relative to your personal best performance."
            
        case .foundation:
            if let historyAnalysis = historyAnalysis {
                let experienceFloor = historyAnalysis.experienceFloor
                let totalStreakDays = historyAnalysis.totalStreakDays
                let floorPercent = Int(experienceFloor * 100)
                
                if floorPercent >= 40 {
                    return "Outstanding! Through \(totalStreakDays) days of practice, you've built a \(floorPercent)% permanent baseline. This means even during long breaks, your habit strength can never fall below this level."
                } else if floorPercent >= 20 {
                    return "Great progress! Your \(totalStreakDays) practice days have built a \(floorPercent)% habit baseline. This protects your habit during breaks and provides a strong base for rebuilding."
                } else if floorPercent >= 10 {
                    return "Building momentum! With \(totalStreakDays) days practiced, you've established a \(floorPercent)% baseline. Each additional practice day strengthens this permanent protection."
                } else {
                    return "Starting strong! You have a \(floorPercent)% base baseline that grows with every practice day. This baseline will protect your progress during any future breaks."
                }
            }
            return "Baseline represents the minimum habit strength you've earned through practice."
        }
    }
    
    private func getActionTip(for insight: HabitAutomationBarCard.InsightType, automationInsight: HabitAutomationInsight) -> String? {
        let historyAnalysis = automationInsight.historyAnalysis
        
        switch insight {
        case .recovery:
            if let historyAnalysis = historyAnalysis, historyAnalysis.recoveryPotential > 0.2 {
                let recoveryPotential = historyAnalysis.recoveryPotential
                return "💪 Focus on consistency over intensity. Your brain remembers this habit - even small daily actions will quickly reactivate your neural pathways."
            }
            return nil
            
        case .peak:
            if let historyAnalysis = historyAnalysis {
                let currentStrength = historyAnalysis.currentStrength
                let peakStrength = historyAnalysis.peakStrength
                let percentageOfPeak = (currentStrength / peakStrength) * 100
                if percentageOfPeak < 70 {
                    return "🎯 You've achieved \(Int(peakStrength * 100))% automation before - you can do it again! Review what worked during your strongest period."
                }
            }
            return nil
            
        case .foundation:
            if let historyAnalysis = historyAnalysis, historyAnalysis.experienceFloor < 0.3 {
                let experienceFloor = historyAnalysis.experienceFloor
                return "🏗️ Every practice day strengthens your permanent baseline. Aim for consistency to build unshakeable habit security."
            }
            return nil
        }
    }
}

// MARK: - Combined View (Pie + Automation Bar)
struct WeeklyStatsRow: View {
    let habit: Habit
    
    var body: some View {
        HStack(spacing: 12) {
            // Pie chart on the left
            WeeklyCompletionPieCard(habit: habit)
                .frame(maxWidth: .infinity)
            
            // Automation bar on the right
            HabitAutomationBarCard(habit: habit)
                .frame(maxWidth: .infinity)
        }
    }
}

#if DEBUG
struct HabitAutomationBarCard_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let habit = Habit(context: context)
        habit.name = "Sample Habit"
        
        return VStack(spacing: 16) {
            HabitAutomationBarCard(habit: habit)
            
            Divider()
            
            WeeklyStatsRow(habit: habit)
        }
        .padding()
    }
}
#endif
