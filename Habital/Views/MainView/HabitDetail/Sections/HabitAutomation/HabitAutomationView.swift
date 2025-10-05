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
                    // Show automation analysis
                    AutomationSection(insight: insight, habit: habit)
                    
                    // Show predictive insights if available
                    if let predictions = insight.predictions {
                        PredictiveInsightsSection(predictions: predictions, currentAutomation: insight.automationPercentage)
                    }
                    
                    // Show minimal 30-day chart
                    //MinimalHabitChartView(habit: habit)
                    
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

// MARK: - Automation Section
struct AutomationSection: View {
    let insight: HabitAutomationInsight
    let habit: Habit
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(sectionTitle, systemImage: "brain")
                .font(.customFont("Lexend", .medium, 18))
            
            VStack(alignment: .leading, spacing: 8) {
                // Progress bar showing automation level
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.quaternary)
                            .frame(height: 40)
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(LinearGradient(
                                colors: automationColors(for: insight.automationPercentage),
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .frame(width: geometry.size.width * (insight.automationPercentage / 100.0), height: 40)
                        
                        HStack {
                            Text("\(Int(insight.automationPercentage))% \(habit.isBadHabit ? "Controlled" : "Automated")")
                                .font(.customFont("Lexend", .medium, 13))
                                .foregroundStyle(insight.automationPercentage > 20 ? .white : (colorScheme == .dark ? .white : .primary))
                                .padding(.horizontal, 12)
                            
                            Spacer()
                            
                            if let predictions = insight.predictions,
                               let daysTo95 = predictions.estimatedDaysTo95Percent {
                                Text(formatDaysToTarget(daysTo95))
                                    .font(.customFont("Lexend", .regular, 11))
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 12)
                            } else if insight.automationPercentage >= 95 {
                                Label(habit.isBadHabit ? "Fully Controlled!" : "Fully Automated!", systemImage: "star.fill")
                                    .font(.customFont("Lexend", .medium, 11))
                                    .foregroundStyle(.yellow)
                                    .padding(.horizontal, 12)
                            }
                        }
                    }
                }
                .frame(height: 40)
                
                Text(descriptionText)
                    .font(.customFont("Lexend", .regular, 12))
                    .foregroundStyle(.secondary)
                
                // Status indicators based on automation level
                HStack(spacing: 8) {
                    if insight.automationPercentage >= 70 {
                        Label(habit.isBadHabit ? "Breaking Free" : "Well Established", systemImage: "checkmark.seal.fill")
                            .font(.customFont("Lexend", .medium, 11))
                            .foregroundStyle(.green)
                    } else if insight.automationPercentage >= 40 {
                        Label(habit.isBadHabit ? "Gaining Control" : "Building Momentum", systemImage: "arrow.up.circle.fill")
                            .font(.customFont("Lexend", .medium, 11))
                            .foregroundStyle(.blue)
                    } else if insight.automationPercentage >= 20 {
                        Label(habit.isBadHabit ? "Making Progress" : "Early Stage", systemImage: "sparkles")
                            .font(.customFont("Lexend", .medium, 11))
                            .foregroundStyle(.orange)
                    } else {
                        Label("Just Starting", systemImage: "leaf.fill")
                            .font(.customFont("Lexend", .medium, 11))
                            .foregroundStyle(.yellow)
                    }
                    
                    if insight.currentStreak > 7 {
                        Label("\(insight.currentStreak) Day\(habit.isBadHabit ? "s Free!" : " Streak!")", systemImage: "flame.fill")
                            .font(.customFont("Lexend", .medium, 11))
                            .foregroundStyle(.orange)
                    }
                }
            }
        }
        .padding()
        .glassBackground()
    }
    
    private var sectionTitle: String {
        habit.isBadHabit ? "Habit Breaking Progress" : "Habit Automation Progress"
    }
    
    private var descriptionText: String {
        if habit.isBadHabit {
            return "Control level measures how automatic avoiding this habit has become. Higher values mean less temptation and easier resistance."
        } else {
            return "Automaticity measures how automatic this habit has become. Higher values mean less willpower needed."
        }
    }
    
    private func automationColors(for percentage: Double) -> [Color] {
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
}

// MARK: - Predictive Insights Section
struct PredictiveInsightsSection: View {
    let predictions: HabitPredictions
    let currentAutomation: Double
    @State private var showDetails = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Predictions", systemImage: "chart.line.uptrend.xyaxis")
                    .font(.customFont("Lexend", .medium, 18))
                
                Spacer()
                
                // Trend indicator
                Label(trendText, systemImage: predictions.trend.icon)
                    .font(.customFont("Lexend", .medium, 12))
                    .foregroundStyle(trendColor)
            }
            
            // Guidance message
            Text(predictions.guidanceMessage)
                .font(.customFont("Lexend", .regular, 14))
                .foregroundStyle(.primary)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(trendColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Future projections
            VStack(spacing: 4) {
                ProjectionRow(
                    timeframe: "1 Week",
                    current: currentAutomation,
                    projected: predictions.oneWeekAutomation
                )
                
                ProjectionRow(
                    timeframe: "2 Weeks",
                    current: currentAutomation,
                    projected: predictions.twoWeekAutomation
                )
                
                ProjectionRow(
                    timeframe: "1 Month",
                    current: currentAutomation,
                    projected: predictions.oneMonthAutomation
                )
            }
        }
        .padding()
        .glassBackground()
    }
    
    private var trendText: String {
        switch predictions.trend {
        case .improving: return "Improving"
        case .stable: return "Stable"
        case .declining: return "Needs Attention"
        }
    }
    
    private var trendColor: Color {
        switch predictions.trend {
        case .improving: return .green
        case .stable: return .blue
        case .declining: return .orange
        }
    }
}

// MARK: - Projection Row
struct ProjectionRow: View {
    let timeframe: String
    let current: Double
    let projected: Double
    
    private var improvement: Double {
        projected - current
    }
    
    private var improvementColor: Color {
        if improvement > 5 {
            return .green
        } else if improvement > 0 {
            return .blue
        } else {
            return .orange
        }
    }
    
    var body: some View {
        HStack {
            Text(timeframe)
                .font(.customFont("Lexend", .regular, 12))
                .foregroundStyle(.secondary)
            
            Spacer()
            
            HStack(spacing: 4) {
                Text(String(format: "%.0f%%", projected))
                    .font(.customFont("Lexend", .medium, 12))
                
                if improvement != 0 {
                    Text(String(format: "%+.0f", improvement))
                        .font(.customFont("Lexend", .medium, 10))
                        .foregroundStyle(improvementColor)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(improvementColor.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - Metrics Section
struct MetricsSection: View {
    let insight: HabitAutomationInsight
    let habit: Habit
    
    init(insight: HabitAutomationInsight, habit: Habit? = nil) {
        self.insight = insight
        // Get habit from insight if not provided
        if let habit = habit {
            self.habit = habit
        } else {
            // Fallback - create a temporary habit object
            let context = PersistenceController.shared.container.viewContext
            let tempHabit = Habit(context: context)
            tempHabit.isBadHabit = false
            self.habit = tempHabit
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Performance Metrics", systemImage: "chart.bar.fill")
                .font(.customFont("Lexend", .semiBold, 18))
            
            HStack(spacing: 12) {
                MetricCard(
                    title: habit.isBadHabit ? "Avoidance Rate" : "Completion Rate",
                    value: "\(Int(insight.rawCompletionRate * 100))%",
                    subtitle: habit.isBadHabit ?
                        "\(insight.actualCompletions) days avoided" :
                        "\(insight.actualCompletions)/\(insight.expectedCompletions) days",
                    icon: "checkmark.circle.fill",
                    color: completionRateColor(insight.rawCompletionRate)
                )
                
                MetricCard(
                    title: habit.isBadHabit ? "Days Free" : "Current Streak",
                    value: "\(insight.currentStreak)",
                    subtitle: insight.currentStreak == 1 ? "day" : "days",
                    icon: "flame.fill",
                    color: .orange
                )
            }
        }
        .padding()
        .glassBackground()
    }
    
    private func completionRateColor(_ rate: Double) -> Color {
        if rate >= 0.8 {
            return .green
        } else if rate >= 0.6 {
            return .blue
        } else if rate >= 0.4 {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - Component Breakdown Section (for debugging/advanced users)
struct ComponentBreakdownSection: View {
    let insight: HabitAutomationInsight
    @State private var showDetails = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: { withAnimation { showDetails.toggle() } }) {
                HStack {
                    Label("Formula Components", systemImage: "function")
                        .font(.customFont("Lexend", .semiBold, 18))
                    Spacer()
                    Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                        .font(.customFont("Lexend", .regular, 12))
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            
            if showDetails {
                VStack(alignment: .leading, spacing: 8) {
                    ComponentRow(
                        label: "Base Completion Rate",
                        value: String(format: "%.1f%%", insight.rawCompletionRate * 100),
                        description: "Actual completions / Expected completions"
                    )
                    
                    ComponentRow(
                        label: "Streak Multiplier",
                        value: String(format: "×%.2f", insight.streakMultiplier),
                        description: "Bonus from consecutive completions"
                    )
                    
                    ComponentRow(
                        label: "Intensity Weight",
                        value: String(format: "×%.2f", insight.intensityWeight),
                        description: "Adjustment for habit difficulty"
                    )
                    
                    ComponentRow(
                        label: "Time Factor",
                        value: String(format: "×%.2f", insight.timeFactor),
                        description: "Growth factor over time"
                    )
                    
                    Divider()
                    
                    ComponentRow(
                        label: "Final Automation",
                        value: String(format: "%.1f%%", insight.automationPercentage),
                        description: "Combined result (capped at 100%)"
                    )
                    .fontWeight(.bold)
                }
                .padding(.vertical, 8)
            }
        }
        .padding()
        .glassBackground()
    }
}

// MARK: - Component Row
struct ComponentRow: View {
    let label: String
    let value: String
    let description: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.customFont("Lexend", .medium, 12))
                Text(description)
                    .font(.customFont("Lexend", .regular, 10))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(value)
                .font(.customFont("Lexend", .medium, 12))
                .foregroundStyle(.blue)
        }
    }
}

// MARK: - Metric Card
struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.customFont("Lexend", .bold, 20))
            
            Text(subtitle)
                .font(.customFont("Lexend", .regular, 10))
                .foregroundStyle(.secondary)
            
            Text(title)
                .font(.customFont("Lexend", .regular, 12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
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
