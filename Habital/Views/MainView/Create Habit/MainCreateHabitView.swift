//
//  MainCreateHabitView.swift
//  Habital
//
//  Created by Elias Osarumwense on 09.06.25.
//

import SwiftUI
import HealthKit

struct MainCreateHabitView: View {
    @State private var selectedMetric: HealthKitManager.Metric?
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var showCreateHabitView = false
    @State private var showAIHabitView = false
    
    // Completion closure for when habit is created
    let onHabitCreated: (() -> Void)?
    
    // Initializer with optional completion closure
    init(onHabitCreated: (() -> Void)? = nil) {
        self.onHabitCreated = onHabitCreated
    }
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 32) {
                    // Clean Header
                    VStack(spacing: 16) {
                        // Simple icon
                        Image(systemName: "plus.circle")
                            .font(.system(size: 44, weight: .medium))
                            .foregroundColor(.blue)
                        
                        VStack(spacing: 6) {
                            Text("Create New Habit")
                                .font(.custom("Lexend-Bold", size: 28))
                                .foregroundColor(.primary)
                            
                            Text("Choose your preferred method")
                                .font(.custom("Lexend-Regular", size: 15))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Habit Creation Section
                    VStack(spacing: 20) {
                        // Section Title
                        HStack {
                            Text("Create Habit")
                                .font(.custom("Lexend-SemiBold", size: 20))
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        
                        // Creation Buttons
                        VStack(spacing: 14) {
                            createHabitButton
                            aiHabitButton
                        }
                    }
                    
                    // Apple Health Section
                    VStack(spacing: 16) {
                        HStack {
                            Text("Apple Health")
                                .font(.custom("Lexend-SemiBold", size: 20))
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        
                        if !HealthKitManager.shared.isAvailable {
                            VStack(spacing: 12) {
                                Image(systemName: "heart.slash")
                                    .font(.system(size: 28))
                                    .foregroundColor(.secondary)
                                
                                Text("Health not available on this device.")
                                    .font(.custom("Lexend-Regular", size: 14))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 28)
                            .background(Color(.systemGray6))
                            .cornerRadius(16)
                            .padding(.horizontal, 20)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(HealthKitManager.Metric.allCases) { metric in
                                        Button {
                                            selectedMetric = metric
                                        } label: {
                                            VStack(spacing: 8) {
                                                Circle()
                                                    .fill(healthMetricColor(metric).opacity(0.15))
                                                    .frame(width: 44, height: 44)
                                                    .overlay(
                                                        Image(systemName: healthMetricIcon(metric))
                                                            .font(.system(size: 18, weight: .medium))
                                                            .foregroundColor(healthMetricColor(metric))
                                                    )
                                                
                                                Text(healthMetricTitle(metric))
                                                    .font(.custom("Lexend-Medium", size: 12))
                                                    .foregroundColor(.primary)
                                                    .multilineTextAlignment(.center)
                                                    .lineLimit(2)
                                            }
                                            .frame(width: 80, height: 80)
                                            .background(Color(.systemBackground))
                                            .cornerRadius(16)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(Color(.systemGray4), lineWidth: 0.5)
                                            )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                    }
                    
                    Spacer(minLength: 60)
                }
            }
        }
        .sheet(isPresented: $showCreateHabitView) {
            CreateHabitView(
                onHabitCreated: {
                    onHabitCreated?()
                    dismiss()
                }
            )
            .presentationCornerRadius(50)
            .environment(\.managedObjectContext, viewContext)
            .presentationBackground(.clear)     // iOS 17+
                    .background(
                        Rectangle().fill(.thickMaterial).ignoresSafeArea()
                    )
        }
        .sheet(isPresented: $showAIHabitView) {
            AIHabitGenerationView(viewContext: viewContext)
                .onDisappear {
                    onHabitCreated?()
                    dismiss()
                }
        }
        .sheet(item: $selectedMetric) { metric in
            HealthMetricSheet(metric: metric)
                .presentationDetents([.medium, .large])
                .presentationCornerRadius(50)
        }
    }
    
    // MARK: - Custom Habit Creation Button
    private var createHabitButton: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            showCreateHabitView = true
        }) {
            HStack(spacing: 16) {
                // Simple icon container
                Circle()
                    .fill(.blue.opacity(0.12))
                    .frame(width: 52, height: 52)
                    .overlay(
                        Image(systemName: "plus.app")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.blue)
                    )
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text("Create Custom Habit")
                        .font(.custom("Lexend-SemiBold", size: 17))
                        .foregroundColor(.primary)
                    
                    Text("Design your own habit with custom settings")
                        .font(.custom("Lexend-Regular", size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Simple chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .background(Color(.systemGray6))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color(.systemGray4), lineWidth: 0.5)
            )
        }
        .buttonStyle(MinimalButtonStyle())
        .padding(.horizontal, 20)
    }
    
    // MARK: - AI Habit Generation Button
    private var aiHabitButton: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            showAIHabitView = true
        }) {
            HStack(spacing: 16) {
                // Simple icon container
                Circle()
                    .fill(.purple.opacity(0.12))
                    .frame(width: 52, height: 52)
                    .overlay(
                        Image(systemName: "sparkles")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.purple)
                    )
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("AI Habit Generator")
                            .font(.custom("Lexend-SemiBold", size: 17))
                            .foregroundColor(.primary)
                        
                        // Simple AI badge
                        Text("AI")
                            .font(.custom("Lexend-Bold", size: 10))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.purple)
                            .cornerRadius(4)
                    }
                    
                    Text("Let AI suggest personalized habits for you")
                        .font(.custom("Lexend-Regular", size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Simple chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .background(Color(.systemGray6))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color(.systemGray4), lineWidth: 0.5)
            )
        }
        .buttonStyle(MinimalButtonStyle())
        .padding(.horizontal, 20)
    }
    
    private func healthMetricTitle(_ metric: HealthKitManager.Metric) -> String {
        switch metric {
        case .sleep: return "Sleep"
        case .steps: return "Steps"
        case .walkingHeartRateAvg: return "Walking HR"
        case .restingHeartRate: return "Resting HR"
        case .mindfulMinutes: return "Mindful"
        case .activeEnergy: return "Active Energy"
        case .workouts: return "Workouts"
        }
    }

    private func healthMetricIcon(_ metric: HealthKitManager.Metric) -> String {
        switch metric {
        case .sleep: return "bed.double.fill"
        case .steps: return "figure.walk"
        case .walkingHeartRateAvg, .restingHeartRate: return "heart.fill"
        case .mindfulMinutes: return "sparkles"
        case .activeEnergy: return "flame.fill"
        case .workouts: return "figure.run"
        }
    }

    private func healthMetricColor(_ metric: HealthKitManager.Metric) -> Color {
        switch metric {
        case .sleep: return .purple
        case .steps: return .green
        case .walkingHeartRateAvg, .restingHeartRate: return .red
        case .mindfulMinutes: return .blue
        case .activeEnergy: return .orange
        case .workouts: return .pink
        }
    }
}

// MARK: - Minimal Button Style
struct MinimalButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
