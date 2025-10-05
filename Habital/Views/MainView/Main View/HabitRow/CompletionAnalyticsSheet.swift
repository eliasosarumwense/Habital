//
//  CompletionAnalyticsSheet.swift
//  Habital
//
//  Created by Elias Osarumwense on 15.08.25.
//

import SwiftUI
import CoreData

struct CompletionAnalyticsSheet: View {
    let habit: Habit
    let date: Date
    let onComplete: (AnalyticsData) -> Void
    let onDismiss: () -> Void
    
    @State private var selectedMetrics: Set<AnalyticsMetric> = []
    @State private var perceivedDifficulty: Double = 3
    @State private var selfEfficacy: Double = 3
    @State private var notes: String = ""
    
    @Environment(\.colorScheme) private var colorScheme
    
    // Extract habit color
    private var habitColor: Color {
        if let colorData = habit.color,
           let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
            return Color(uiColor)
        }
        return .blue
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Compact header
            headerSection
            
            // Quick metrics selector
            metricsSelector
            
            // Selected metrics controls
            selectedMetricsView
            
            // Bottom action
            actionSection
        }
        .background(.ultraThinMaterial)
        .presentationDetents([.fraction(0.5), .medium])
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            // Drag indicator replacement
            Capsule()
                .fill(.tertiary)
                .frame(width: 36, height: 4)
                .padding(.top, 8)
            
            HStack(spacing: 12) {
                // Habit icon
                ZStack {
                    Circle()
                        .fill(habitColor.opacity(0.12))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: habit.icon ?? "star.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(habitColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(habit.name ?? "Habit")
                        .font(.customFont("Lexend", .semiBold, 16))
                        .foregroundColor(.primary)
                    
                    Text("Quick completion tracking")
                        .font(.customFont("Lexend", .medium, 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Skip button
                Button("Skip") {
                    onComplete(AnalyticsData())
                }
                .font(.customFont("Lexend", .medium, 14))
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 16)
    }
    
    // MARK: - Metrics Selector
    private var metricsSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Track metrics (optional)")
                .font(.customFont("Lexend", .medium, 13))
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(AnalyticsMetric.allCases, id: \.self) { metric in
                        MetricChip(
                            metric: metric,
                            isSelected: selectedMetrics.contains(metric),
                            habitColor: habitColor
                        ) {
                            toggleMetric(metric)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Selected Metrics View
    private var selectedMetricsView: some View {
        VStack(spacing: 16) {
            if !selectedMetrics.isEmpty {
                ForEach(Array(selectedMetrics).sorted(by: { $0.order < $1.order }), id: \.self) { metric in
                    CompactMetricControl(
                        metric: metric,
                        value: bindingForMetric(metric),
                        habitColor: habitColor
                    )
                }
                .padding(.horizontal, 20)
            }
            
            // Quick notes if any metric is selected
            if !selectedMetrics.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes")
                        .font(.customFont("Lexend", .medium, 13))
                        .foregroundColor(.secondary)
                    
                    TextField("Optional notes...", text: $notes)
                        .font(.customFont("Lexend", .regular, 14))
                        .padding(12)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 20)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedMetrics)
    }
    
    // MARK: - Action Section
    private var actionSection: some View {
        VStack(spacing: 16) {
            // Complete button
            Button(action: completeWithData) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .medium))
                    
                    Text("Complete")
                        .font(.customFont("Lexend", .semiBold, 16))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(habitColor)
                )
            }
            .buttonStyle(SpringButtonStyle())
            .padding(.horizontal, 20)
        }
        .padding(.top, 24)
        .padding(.bottom, 32)
    }
    
    // MARK: - Helper Methods
    
    private func toggleMetric(_ metric: AnalyticsMetric) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if selectedMetrics.contains(metric) {
                selectedMetrics.remove(metric)
            } else {
                selectedMetrics.insert(metric)
            }
        }
    }
    
    private func bindingForMetric(_ metric: AnalyticsMetric) -> Binding<Double> {
        switch metric {
        case .difficulty:
            return $perceivedDifficulty
        case .selfEfficacy:
            return $selfEfficacy
        }
    }
    
    private func completeWithData() {
        let analyticsData = AnalyticsData(
            perceivedDifficulty: selectedMetrics.contains(.difficulty) ? Int16(perceivedDifficulty) : nil,
            selfEfficacy: selectedMetrics.contains(.selfEfficacy) ? Int16(selfEfficacy) : nil,
            moodImpact: nil,
            energyImpact: nil,
            duration: nil,
            notes: notes.isEmpty ? nil : notes
        )
        
        onComplete(analyticsData)
    }
}

// MARK: - Analytics Metric Enum
enum AnalyticsMetric: String, CaseIterable {
    case difficulty = "Difficulty"
    case selfEfficacy = "Self Efficacy"
    
    var icon: String {
        switch self {
        case .difficulty: return "gauge"
        case .selfEfficacy: return "figure.walk"
        }
    }
    
    var order: Int {
        switch self {
        case .difficulty: return 0
        case .selfEfficacy: return 1
        }
    }
}

// MARK: - Metric Chip
struct MetricChip: View {
    let metric: AnalyticsMetric
    let isSelected: Bool
    let habitColor: Color
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: metric.icon)
                    .font(.system(size: 12, weight: .medium))
                
                Text(metric.rawValue)
                    .font(.customFont("Lexend", .medium, 12))
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(
                                isSelected ? habitColor.opacity(0.3) : .clear,
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(SpringButtonStyle(scale: 0.95))
    }
}

// MARK: - Compact Metric Control
struct CompactMetricControl: View {
    let metric: AnalyticsMetric
    @Binding var value: Double
    let habitColor: Color
    
    private var range: ClosedRange<Double> {
        switch metric {
        case .difficulty, .selfEfficacy:
            return 1...5
        }
    }
    
    private var step: Double {
        switch metric {
        case .difficulty, .selfEfficacy:
            return 1
        }
    }
    
    private var displayValue: String {
        switch metric {
        case .difficulty, .selfEfficacy:
            return String(format: "%.0f", value)
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Label(metric.rawValue, systemImage: metric.icon)
                    .font(.customFont("Lexend", .medium, 13))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(displayValue)
                    .font(.customFont("Lexend", .semiBold, 14))
                    .foregroundColor(habitColor)
            }
            
            Slider(value: $value, in: range, step: step)
                .tint(habitColor)
        }
        .padding(16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Spring Button Style
struct SpringButtonStyle: ButtonStyle {
    let scale: CGFloat
    
    init(scale: CGFloat = 0.96) {
        self.scale = scale
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Font Extension (if not already defined)
extension Font {
    static func customFont(_ name: String, _ weight: Font.Weight, _ size: CGFloat) -> Font {
        return .system(size: size, weight: weight, design: .default)
    }
}

// MARK: - Data Structure (keeping your original)
struct AnalyticsData {
    let perceivedDifficulty: Int16?
    let selfEfficacy: Int16?
    let moodImpact: Double?
    let energyImpact: Double?
    let duration: Int16?
    let notes: String?
    
    init(
        perceivedDifficulty: Int16? = nil,
        selfEfficacy: Int16? = nil,
        moodImpact: Double? = nil,
        energyImpact: Double? = nil,
        duration: Int16? = nil,
        notes: String? = nil
    ) {
        self.perceivedDifficulty = perceivedDifficulty
        self.selfEfficacy = selfEfficacy
        self.moodImpact = moodImpact
        self.energyImpact = energyImpact
        self.duration = duration
        self.notes = notes
    }
}

// MARK: - Preview
struct CompletionAnalyticsSheet_Previews: PreviewProvider {
    static var previews: some View {
        CompletionAnalyticsSheet(
            habit: mockHabit(),
            date: Date(),
            onComplete: { _ in },
            onDismiss: { }
        )
    }
    
    static func mockHabit() -> Habit {
        let context = PersistenceController.preview.container.viewContext
        let habit = Habit(context: context)
        habit.name = "Morning Meditation"
        habit.icon = "brain"
        return habit
    }
}
