//
//  HabitCompletionForCalenderView.swift
//  Habital
//
//  Created by Elias Osarumwense on 16.04.25.
//

import SwiftUI

struct HabitCompletionAnimation: View {
    let habit: Habit
    let date: Date
    let toggleCompletion: () -> Void
    
    // Environment values
    @Environment(\.colorScheme) private var colorScheme
    
    // Animation states
    @State private var scale: CGFloat = 1
    @State private var ringFillTrim: CGFloat = 0
    @State private var crossTrim: CGFloat = 0
    @State private var checkmarkTrim: CGFloat = 0
    @State private var markOpacity: Double = 0
    @State private var hasInitialized: Bool = false
    
    // Extract the habit color or use a default
    private var habitColor: Color {
        if let colorData = habit.color,
           let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
            return Color(uiColor)
        }
        return .blue // Default color if not set
    }
    
    // Computed properties
    private var isCompleted: Bool {
        return habit.isCompleted(on: date)
    }
    
    private var repeatsPerDay: Int {
        return habit.currentRepeatsPerDay(on: date)
    }
    
    private var completedRepeats: Int {
        return habit.completedCount(on: date)
    }
    
    private var completionProgress: CGFloat {
        if repeatsPerDay <= 1 {
            return isCompleted ? 1.0 : 0.0
        } else {
            return CGFloat(completedRepeats) / CGFloat(repeatsPerDay)
        }
    }
    
    var body: some View {
        Button(action: {
            // Button press animation
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                scale = 0.92
            }
            
            // Toggle completion
            toggleCompletion()
            
            // Reset scale after button press
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    scale = 1
                }
            }
            
            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }) {
            ZStack {
                if habit.isBadHabit {
                    // Bad Habit UI - Cross animation
                    badHabitView
                } else {
                    // Good Habit UI - Checkmark animation
                    goodHabitView
                }
            }
            .scaleEffect(scale)
            .frame(width: 36, height: 36)
            .contentShape(Circle()) // Ensure tap area is the full circle
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            // Initialize states based on current completion without animation
            if !hasInitialized {
                updateAnimationStates(animated: false)
                hasInitialized = true
            }
        }
        .onChange(of: isCompleted) { _, _ in
            // Update the animation states whenever completion state changes
            updateAnimationStates(animated: true)
        }
        .onChange(of: completedRepeats) { _, _ in
            // Update for partial completions in multi-repeat scenarios
            updateAnimationStates(animated: true)
        }
    }
    
    // Good habit view with checkmark animation
    private var goodHabitView: some View {
        ZStack {
            // Empty circle border
            Circle()
                .strokeBorder(
                    Color.gray.opacity(0.3),
                    lineWidth: 2
                )
                .frame(width: 32, height: 32)
            
            // Progress ring fill
            Circle()
                .trim(from: 0, to: ringFillTrim)
                .stroke(
                    habitColor,
                    style: StrokeStyle(
                        lineWidth: 3,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
                .frame(width: 32, height: 32)
                .rotationEffect(.degrees(-90)) // Start from top
            
            // Show repeats number for multi-repeat habits
            if repeatsPerDay > 1 && completedRepeats < repeatsPerDay {
                Text("\(completedRepeats)/\(repeatsPerDay)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(habitColor)
                    .opacity(markOpacity < 0.5 ? 1.0 : 0.0) // Hide when checkmark is visible
            }
            
            // Checkmark
            CheckmarkShape()
                .trim(from: 0, to: checkmarkTrim)
                .stroke(
                    habitColor,
                    style: StrokeStyle(
                        lineWidth: 3,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
                .frame(width: 16, height: 16)
                .opacity(markOpacity)
            
            // Display count at bottom right when checkmark is shown
            if repeatsPerDay > 1 && isCompleted && markOpacity > 0.5 {
                Text("\(completedRepeats)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(habitColor)
                    .frame(width: 15, height: 15)
                    .background(Circle()
                        .fill(.ultraThinMaterial))
                    .offset(x: 10, y: 10) // Position at bottom right
            }
        }
    }
    
    // Bad habit view with cross animation
    private var badHabitView: some View {
        ZStack {
            // Success state when habit not broken
            if !isCompleted {
                // Green circle for "good" state
                Circle()
                    .stroke(
                        Color.green,
                        style: StrokeStyle(
                            lineWidth: 3,
                            lineCap: .round
                        )
                    )
                    .frame(width: 32, height: 32)
                
                // Show streak if we have one
                if let lastCompletionDate = habit.lastCompletionDate {
                    let streak = habit.calculateStreak(upTo: date)
                    if streak > 0 {
                        Text("\(streak)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.green)
                    }
                }
                
            } else {
                // Failure state when habit is broken
                Circle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 32, height: 32)
                
                // Red ring for broken habit
                Circle()
                    .trim(from: 0, to: ringFillTrim)
                    .stroke(
                        Color.red,
                        style: StrokeStyle(
                            lineWidth: 3,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                    .frame(width: 32, height: 32)
                    .rotationEffect(.degrees(90)) // Start from bottom for "bad" effect
                
                // X mark
                CrossShape()
                    .trim(from: 0, to: crossTrim)
                    .stroke(
                        Color.red,
                        style: StrokeStyle(
                            lineWidth: 3,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                    .frame(width: 16, height: 16)
                    .opacity(markOpacity)
            }
        }
    }
    
    private func updateAnimationStates(animated: Bool) {
        let animationBlock = {
            if habit.isBadHabit {
                // Bad habit animation states
                if isCompleted {
                    // Habit broken (bad)
                    ringFillTrim = 1.0
                    crossTrim = 1.0
                    markOpacity = 1.0
                } else {
                    // Habit not broken (good)
                    ringFillTrim = 0.0
                    crossTrim = 0.0
                    markOpacity = 0.0
                }
            } else {
                // Good habit animation states
                if repeatsPerDay > 1 {
                    // Multi-repeat habit
                    ringFillTrim = completionProgress
                    checkmarkTrim = isCompleted ? 1.0 : 0.0
                    markOpacity = isCompleted ? 1.0 : 0.0
                } else {
                    // Single-repeat habit
                    ringFillTrim = isCompleted ? 1.0 : 0.0
                    checkmarkTrim = isCompleted ? 1.0 : 0.0
                    markOpacity = isCompleted ? 1.0 : 0.0
                }
            }
        }
        
        if animated {
            if habit.isBadHabit {
                // For bad habits, animate breaking with a sequence
                if isCompleted {
                    // Animate to broken state
                    withAnimation(Animation.easeInOut(duration: 0.4)) {
                        ringFillTrim = 1.0
                    }
                    
                    withAnimation(Animation.easeOut(duration: 0.5).delay(0.3)) {
                        markOpacity = 1.0
                    }
                    
                    withAnimation(Animation.easeInOut(duration: 0.6).delay(0.35)) {
                        crossTrim = 1.0
                    }
                } else {
                    // Animate back to good state
                    withAnimation(.easeIn(duration: 0.3)) {
                        ringFillTrim = 0.0
                        crossTrim = 0.0
                        markOpacity = 0.0
                    }
                }
            } else {
                // For good habits
                withAnimation(Animation.easeInOut(duration: 0.75)) {
                    ringFillTrim = repeatsPerDay > 1 ? completionProgress : (isCompleted ? 1.0 : 0.0)
                }
                
                if isCompleted {
                    withAnimation(Animation.easeOut(duration: 0.5).delay(0.6)) {
                        markOpacity = 1.0
                    }
                    
                    withAnimation(Animation.easeInOut(duration: 0.6).delay(0.65)) {
                        checkmarkTrim = 1.0
                    }
                } else {
                    withAnimation(.easeIn(duration: 0.3)) {
                        checkmarkTrim = 0.0
                        markOpacity = 0.0
                    }
                }
            }
        } else {
            // Apply without animation for initial state
            animationBlock()
        }
    }
}

