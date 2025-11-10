//
//  HabitAnalyticsViews.swift
//  Habital
//
//  Created by Elias Osarumwense on 15.08.25.
//  Enhanced with minimal progress chart and Lexend fonts
//

import SwiftUI
import CoreData
import Foundation
import Charts

// MARK: - Main Analytics View Model
class HabitAnalyticsViewModel: ObservableObject {
    @Published var insight: HabitAutomationInsight?
    @Published var isLoading = false
    @Published var error: String?
    
    let habit: Habit
    
    init(habit: Habit) {
        self.habit = habit
    }
    
    func loadAnalytics(context: NSManagedObjectContext) async {
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        do {
            let backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            backgroundContext.parent = context
            
            let habitID = habit.objectID
            
            let analysisResult = await backgroundContext.perform {
                // Create engine in background context
                let config = HabitAutomationConfig()
                let engine = HabitAutomationEngine(config: config, context: backgroundContext)
                
                let backgroundHabit = backgroundContext.object(with: habitID) as! Habit
                return engine.calculateAutomationPercentage(habit: backgroundHabit)
            }
            
            // Update UI on main thread
            await MainActor.run {
                self.insight = analysisResult
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}

// MARK: - Main Analytics View
struct HabitAnalyticsView: View {
    let habit: Habit
    @StateObject private var viewModel: HabitAnalyticsViewModel
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    
    init(habit: Habit) {
        self.habit = habit
        self._viewModel = StateObject(wrappedValue: HabitAnalyticsViewModel(habit: habit))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                if let insight = viewModel.insight {
                    // Show automation card styled exactly like HabitAutomationBarCard
                    HabitAutomationView(insight: insight, habit: habit)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    // Show minimal 30-day chart
                    MinimalHabitChartView(habit: habit)
                        .padding(.horizontal)
                    
                } else if viewModel.isLoading {
                    ProgressView("Analyzing habit formation...")
                        .font(.customFont("Lexend", .medium, 16))
                        .padding()
                } else if viewModel.error != nil {
                    ContentUnavailableView(
                        "Analysis Error",
                        systemImage: "exclamationmark.triangle",
                        description: Text(viewModel.error ?? "Unknown error occurred")
                            .font(.customFont("Lexend", .regular, 14))
                    )
                } else {
                    ContentUnavailableView(
                        "No Formation Data Available",
                        systemImage: "brain",
                        description: Text("Complete more scheduled days to see formation progress")
                            .font(.customFont("Lexend", .regular, 14))
                    )
                }
            }
        }
        .task {
            await viewModel.loadAnalytics(context: viewContext)
        }
        .refreshable {
            await viewModel.loadAnalytics(context: viewContext)
        }
    }
}

// MARK: - Habit Automation View (styled like HabitAutomationBarCard)
struct HabitAutomationView: View {
    let insight: HabitAutomationInsight
    let habit: Habit
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var animatedProgress: CGFloat = 0
    @State private var animatedPercentage: Double = 0
    @State private var thirtyDayImprovement: Double?
    @State private var isDataLoaded: Bool = false
    
    enum InsightType: String, CaseIterable {
        case recovery = "Recovery Potential"
        case peak = "Peak Performance"
        case foundation = "Baseline"
    }
    
    var body: some View {
        let percentage = insight.automationPercentage
        let colors = getAutomationColors(for: percentage)
        
        VStack(alignment: .leading, spacing: 8) {
            // Title and percentage with 30-day improvement
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("Automation")
                    .font(.customFont("Lexend", .semibold, 15))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                // 30-day improvement indicator
                if let improvementValue = thirtyDayImprovement {
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
                        .font(.customFont("Lexend", .medium, 10))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .foregroundStyle(colors[0])
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(colors[0].opacity(0.15))
                .clipShape(Capsule())
                .opacity(isDataLoaded ? 1.0 : 0.3)
                .animation(.easeInOut(duration: 0.4), value: isDataLoaded)
                
                Spacer()
                
                // Days to 95% target
                if let predictions = insight.predictions,
                   let daysTo95 = predictions.estimatedDaysTo95Percent {
                    Text(formatDaysToTarget(daysTo95))
                        .font(.customFont("Lexend", .regular, 10))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                } else if percentage >= 95 {
                    HStack(spacing: 3) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(.yellow)
                        Text(habit.isBadHabit ? "Controlled!" : "Automated!")
                            .font(.customFont("Lexend", .medium, 10))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                    }
                }
            }
            .padding(.bottom, 4)
            
            // Bottom row with adaptive insight
            HStack(spacing: 1) {
                adaptiveInsightView
                
                Spacer()
            }
            .padding(.top, -1)
        }
        .padding(12)
        .glassBackground()
        .onAppear {
            Task {
                await loadAutomationData()
            }
        }
    }
    
    // MARK: - Async Data Loading
    @MainActor
    private func loadAutomationData() async {
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
        let currentConfig = HabitAutomationConfig()
        let currentEngine = HabitAutomationEngine(config: currentConfig, context: viewContext)
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
    
    private func animatePercentageCounter(to targetPercentage: Double) {
        animatedPercentage = 0
        let totalDuration: TimeInterval = 0.88
        let updateInterval: TimeInterval = 0.016
        let totalSteps = Int(totalDuration / updateInterval)
        
        func customEasingFunction(progress: Double) -> Double {
            return 1 - pow(1 - progress, 2.5)
        }
        
        Task {
            for step in 0...totalSteps {
                let progress = Double(step) / Double(totalSteps)
                let easedProgress = customEasingFunction(progress: progress)
                let currentValue = targetPercentage * easedProgress
                
                await MainActor.run {
                    let roundedValue = round(currentValue * 10) / 10
                    self.animatedPercentage = min(targetPercentage, roundedValue)
                }
                
                try? await Task.sleep(nanoseconds: UInt64(updateInterval * 1_000_000_000))
            }
            
            await MainActor.run {
                self.animatedPercentage = round(targetPercentage * 10) / 10
            }
        }
    }
    
    @ViewBuilder
    private var adaptiveInsightView: some View {
        let historyAnalysis = insight.historyAnalysis
        
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 0) {
                // Recovery Potential (preferred when available and meaningful > 5%)
                if let historyAnalysis = historyAnalysis, historyAnalysis.recoveryPotential > 0.05 {
                    recoveryPotentialBottomView(historyAnalysis: historyAnalysis)
                    
                    // Middle dot separator and Baseline
                    Text(" • ")
                        .font(.customFont("Lexend", .medium, 9))
                        .foregroundStyle(.secondary.opacity(0.5))
                        .opacity(isDataLoaded ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.4).delay(1.1), value: isDataLoaded)
                    
                    experienceFloorView(historyAnalysis: historyAnalysis)
                }
                // Peak Performance (fallback when recovery potential is low) + Baseline
                else if let historyAnalysis = historyAnalysis, historyAnalysis.peakStrength > 0 {
                    peakComparisonView(historyAnalysis: historyAnalysis)
                    
                    // Middle dot separator and Baseline
                    Text(" • ")
                        .font(.customFont("Lexend", .medium, 9))
                        .foregroundStyle(.secondary.opacity(0.5))
                        .opacity(isDataLoaded ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.4).delay(1.1), value: isDataLoaded)
                    
                    experienceFloorView(historyAnalysis: historyAnalysis)
                } 
                // Baseline only
                else if let historyAnalysis = historyAnalysis {
                    experienceFloorView(historyAnalysis: historyAnalysis)
                }
                
                Spacer()
            }
        }
    }
    
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
            .opacity(isDataLoaded ? 1.0 : 0.0)
            .animation(.easeInOut(duration: 0.4).delay(1.0), value: isDataLoaded)
        }
    }
    
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
            .opacity(isDataLoaded ? 1.0 : 0.0)
            .animation(.easeInOut(duration: 0.4).delay(1.0), value: isDataLoaded)
        }
    }
    
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
            .opacity(isDataLoaded ? 1.0 : 0.0)
            .animation(.easeInOut(duration: 0.4).delay(1.2), value: isDataLoaded)
        }
    }
    
    // MARK: - Helper Functions
    private func getImprovementIcon(for improvement: Double) -> String {
        if improvement > 0 {
            return "arrow.up.right"
        } else if improvement < 0 {
            return "arrow.down.right"
        } else {
            return ""
        }
    }
    
    private func getImprovementColor(for improvement: Double) -> Color {
        if improvement > 0 {
            return .green
        } else if improvement < 0 {
            return .red
        } else {
            return .gray
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
        guard isDataLoaded else {
            return "clock.fill"
        }
        
        let improvement = thirtyDayImprovement
        let isImproving = improvement != nil && improvement! > 0
        let isDecline = improvement != nil && improvement! < -5
        let isBigImprovement = improvement != nil && improvement! > 10
        let isSignificantDecline = improvement != nil && improvement! < -15
        
        let historyAnalysis = insight.historyAnalysis
        let hasRecoveryPotential = historyAnalysis?.recoveryPotential ?? 0 > 0.15
        let hasHighRecoveryPotential = historyAnalysis?.recoveryPotential ?? 0 > 0.30
        let hasStrongFoundation = historyAnalysis?.experienceFloor ?? 0 > 0.25
        
        if habit.isBadHabit {
            if percentage >= 95 {
                return "shield.fill"
            } else if percentage >= 80 {
                if isSignificantDecline {
                    return "exclamationmark.triangle.fill"
                } else if hasHighRecoveryPotential {
                    return "arrow.up.heart.fill"
                } else if isBigImprovement {
                    return "arrow.up.circle.fill"
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
            if percentage >= 95 {
                return "checkmark.seal.fill"
            } else if percentage >= 80 {
                if isSignificantDecline {
                    return "exclamationmark.triangle.fill"
                } else if hasHighRecoveryPotential {
                    return "arrow.up.heart.fill"
                } else if isBigImprovement {
                    return "arrow.up.circle.fill"
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
        guard isDataLoaded else {
            return "Loading..."
        }
        
        let improvement = thirtyDayImprovement
        let isImproving = improvement != nil && improvement! > 0
        let isDecline = improvement != nil && improvement! < -5
        let isBigImprovement = improvement != nil && improvement! > 10
        let isSignificantDecline = improvement != nil && improvement! < -15
        
        let historyAnalysis = insight.historyAnalysis
        let recoveryPotential = historyAnalysis?.recoveryPotential ?? 0
        let hasRecoveryPotential = recoveryPotential > 0.15
        let hasHighRecoveryPotential = recoveryPotential > 0.30
        let hasStrongFoundation = historyAnalysis?.experienceFloor ?? 0 > 0.25
        
        if habit.isBadHabit {
            if percentage >= 95 {
                return "Fully Controlled"
            } else if percentage >= 80 {
                if isSignificantDecline {
                    return "Control Slipping"
                } else if hasHighRecoveryPotential {
                    return "Muscle Memory"
                } else if isBigImprovement {
                    return "Major Progress"
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
                return "Fully Automated"
            } else if percentage >= 80 {
                if isSignificantDecline {
                    return "Automation Fading"
                } else if hasHighRecoveryPotential {
                    return "Muscle Memory"
                } else if isBigImprovement {
                    return "Major Growth"
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


// MARK: - Automation Info Sheet
struct AutomationInfoSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "brain.filled.head.profile")
                                .font(.title2)
                                .foregroundStyle(.blue)
                            
                            Text("How Automation Works")
                                .font(.customFont("Lexend", .bold, 24))
                                .foregroundStyle(.primary)
                            
                            Spacer()
                        }
                        
                        Text("Understanding your habit automation percentage")
                            .font(.customFont("Lexend", .regular, 16))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    
                    // Info sections
                    VStack(spacing: 20) {
                        infoSection(
                            emoji: "🧠",
                            title: "How Automation is calculated",
                            description: "Your Automation % shows how automatic (or in control) a habit feels — from 0% to 100%.\nIt's based on your schedule, streaks, completions, and habit intensity."
                        )
                        
                        infoSection(
                            emoji: "📅",
                            title: "Custom day start",
                            description: "You can choose when your day begins (default 4:00).\nHabital uses this to decide which day completions belong to — so late-night actions count correctly."
                        )
                        
                        infoSection(
                            emoji: "✅",
                            title: "Good habits",
                            description: "Completing on a scheduled day increases automation toward 100%.\nMissing a scheduled day reduces it, but progress never fully resets.\nOn non-scheduled days, automation drifts only slightly."
                        )
                        
                        infoSection(
                            emoji: "🚫",
                            title: "Bad habits",
                            description: "If it's something you're trying to avoid, automation means self-control:\nEach day you resist strengthens control.\nEach lapse reduces it, but some control always remains."
                        )
                        
                        infoSection(
                            emoji: "⚙️",
                            title: "Intensity",
                            description: "Higher-intensity habits (harder goals) grow slower and decay faster, reflecting their challenge."
                        )
                        
                        infoSection(
                            emoji: "📈",
                            title: "Baseline (Floor)",
                            description: "Every habit keeps a minimum baseline — your brain's memory of past effort.\nThe more total days you've practiced, the higher this floor gets, making recovery faster after breaks."
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.customFont("Lexend", .medium, 16))
                }
            }
        }
    }
    
    @ViewBuilder
    private func infoSection(emoji: String, title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Text(emoji)
                    .font(.title2)
                
                Text(title)
                    .font(.customFont("Lexend", .semibold, 18))
                    .foregroundStyle(.primary)
                
                Spacer()
            }
            
            Text(description)
                .font(.customFont("Lexend", .regular, 15))
                .foregroundStyle(.primary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .glassBackground()
    }
}


// MARK: - Preview
struct HabitAnalyticsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            HabitAnalyticsView(habit: mockHabit())
        }
    }
    
    static func mockHabit() -> Habit {
        // Create a mock habit for preview
        let context = PersistenceController.preview.container.viewContext
        let habit = Habit(context: context)
        habit.id = UUID()
        habit.name = "Morning Meditation"
        habit.startDate = Date().addingTimeInterval(-30 * 24 * 60 * 60) // 30 days ago
        habit.intensityLevel = 2
        
        // Add some mock completions
        for i in 0..<25 {
            let completion = Completion(context: context)
            completion.date = Date().addingTimeInterval(TimeInterval(-i * 24 * 60 * 60))
            completion.loggedAt = completion.date
            completion.completed = true
            completion.habit = habit
        }
        
        return habit
    }
}

// MARK: - Extensions
extension Habit {
    /// Calculate the age of the habit in days
    var ageInDays: Int {
        guard let startDate = startDate else { return 0 }
        return Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
    }
}
