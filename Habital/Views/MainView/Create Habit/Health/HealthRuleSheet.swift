//
//  HealthRuleSheet.swift
//  Habital
//
//  Created by Elias Osarumwense on 20.08.25.
//

//
//  MetricRuleSheet.swift
//  Habital
//
//  Created by AI Assistant on 20.08.25.
//

import SwiftUI

struct MetricRuleSheet: View {
    let metric: HealthKitManager.Metric
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var selectedComparison: String
    @State private var threshold: Double
    @State private var smoothingDays: Int = 1
    @State private var showAdvancedOptions = false
    
    init(metric: HealthKitManager.Metric) {
        self.metric = metric
        self._selectedComparison = State(initialValue: metric.defaultComparison)
        self._threshold = State(initialValue: metric.defaultThreshold)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                headerSection
                ruleConfiguration
                
                if showAdvancedOptions {
                    advancedOptions
                }
                
                Spacer()
                
                actionButtons
            }
            .padding()
            .navigationTitle("Link Health Metric")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(metricColor.opacity(0.1))
                    .frame(width: 64, height: 64)
                
                Image(systemName: metric.icon)
                    .font(.system(size: 28))
                    .foregroundColor(metricColor)
            }
            
            Text("Link \(metric.displayName) to Habit")
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            Text("Create an automatic completion rule based on your \(metric.displayName.lowercased()) data")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var ruleConfiguration: some View {
        VStack(spacing: 16) {
            Text("Rule Configuration")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                rulePreview
                thresholdSelector
                comparisonSelector
            }
            .padding(16)
            .background(.ultraThinMaterial)
            .cornerRadius(12)
        }
    }
    
    private var rulePreview: some View {
        VStack(spacing: 8) {
            Text("Rule Preview")
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(ruleDescription)
                .font(.body)
                .foregroundStyle(.primary)
                .padding(12)
                .background(metricColor.opacity(0.1))
                .cornerRadius(8)
        }
    }
    
    private var thresholdSelector: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Target Value")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(formattedThreshold) \(metric.unit)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            HStack {
                Text(thresholdRange.lowerBound.formatted())
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                
                Slider(value: $threshold, in: thresholdRange, step: thresholdStep)
                    .accentColor(metricColor)
                
                Text(thresholdRange.upperBound.formatted())
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }
    
    private var comparisonSelector: some View {
        VStack(spacing: 8) {
            Text("Comparison")
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Picker("Comparison", selection: $selectedComparison) {
                ForEach(availableComparisons, id: \.self) { comparison in
                    Text(comparisonDisplayName(comparison))
                        .tag(comparison)
                }
            }
            .pickerStyle(.segmented)
        }
    }
    
    private var advancedOptions: some View {
        VStack(spacing: 16) {
            Text("Advanced Options")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                HStack {
                    Text("Smoothing Period")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("\(smoothingDays) day\(smoothingDays == 1 ? "" : "s")")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Text("1")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    
                    Slider(value: Binding(
                        get: { Double(smoothingDays) },
                        set: { smoothingDays = Int($0) }
                    ), in: 1...7, step: 1)
                    .accentColor(metricColor)
                    
                    Text("7")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                
                Text("Use average of last \(smoothingDays) day\(smoothingDays == 1 ? "" : "s") instead of single day value")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(.ultraThinMaterial)
            .cornerRadius(12)
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                showAdvancedOptions.toggle()
            } label: {
                Label(
                    showAdvancedOptions ? "Hide Advanced Options" : "Show Advanced Options",
                    systemImage: showAdvancedOptions ? "chevron.up" : "chevron.down"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            
            Button {
                createHealthLink()
            } label: {
                Text("Create Rule")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }
    
    // MARK: - Computed Properties
    private var ruleDescription: String {
        "Complete habit if \(metric.displayName) \(comparisonDisplayName(selectedComparison)) \(formattedThreshold) \(metric.unit)"
    }
    
    private var formattedThreshold: String {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = metric.unit == "h" ? 1 : 0
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: threshold)) ?? "\(threshold)"
    }
    
    private var thresholdRange: ClosedRange<Double> {
        switch metric {
        case .sleep: return 4.0...12.0
        case .steps: return 1000...30000
        case .walkingHeartRateAvg: return 80...180
        case .restingHeartRate: return 40...100
        case .mindfulMinutes: return 1...120
        case .activeEnergy: return 50...2000
        case .workouts: return 1...5
        }
    }
    
    private var thresholdStep: Double {
        switch metric {
        case .sleep: return 0.5
        case .steps: return 500
        case .walkingHeartRateAvg, .restingHeartRate: return 5
        case .mindfulMinutes: return 5
        case .activeEnergy: return 50
        case .workouts: return 1
        }
    }
    
    private var availableComparisons: [String] {
        switch metric {
        case .restingHeartRate, .walkingHeartRateAvg:
            return ["<=", ">=", "<", ">"]
        default:
            return [">=", "<=", ">", "<"]
        }
    }
    
    private var metricColor: Color {
        switch metric {
        case .sleep: return .purple
        case .steps: return .green
        case .walkingHeartRateAvg, .restingHeartRate: return .red
        case .mindfulMinutes: return .blue
        case .activeEnergy: return .orange
        case .workouts: return .pink
        }
    }
    
    // MARK: - Helper Methods
    private func comparisonDisplayName(_ comparison: String) -> String {
        switch comparison {
        case ">=": return "≥"
        case "<=": return "≤"
        case ">": return ">"
        case "<": return "<"
        case "==": return "="
        default: return comparison
        }
    }
    
    private func createHealthLink() {
            // For now, we'll just store the rule data and dismiss
            // In a real implementation, you'd pass this back to CreateHabitView
            // or store it temporarily until a habit is created
            
            // You can either:
            // 1. Create the Core Data entity first, or
            // 2. Pass this data back to the parent view
            
            // Option 2: Store rule data for later use
            let ruleData = HealthLinkData(
                metric: metric,
                comparison: selectedComparison,
                threshold: threshold,
                unit: metric.unit,
                smoothingDays: smoothingDays
            )
            
            // TODO: Pass this data back to parent view
            // For now, just print the rule that would be created
            print("Health rule created: \(ruleData.ruleDescription)")
            
            dismiss()
        }
}
struct HealthLinkData {
    let metric: HealthKitManager.Metric
    let comparison: String
    let threshold: Double
    let unit: String
    let smoothingDays: Int
    
    var ruleDescription: String {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = unit == "h" ? 1 : 0
        formatter.numberStyle = .decimal
        let thresholdStr = formatter.string(from: NSNumber(value: threshold)) ?? "\(threshold)"
        
        return "Complete habit if \(metric.displayName) \(comparisonSymbol) \(thresholdStr) \(unit)"
    }
    
    private var comparisonSymbol: String {
        switch comparison {
        case ">=": return "≥"
        case "<=": return "≤"
        case ">": return ">"
        case "<": return "<"
        case "==": return "="
        default: return comparison
        }
    }
}
