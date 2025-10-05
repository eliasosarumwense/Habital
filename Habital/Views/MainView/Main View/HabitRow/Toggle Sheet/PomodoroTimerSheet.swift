//
//  PomodoroTimerSheet.swift
//  Habital
//
//  Created by Elias Osarumwense on 29.08.25.
//

import SwiftUI

struct PomodoroTimerSheet: View {
    let habit: Habit
    let date: Date
    let habitColor: Color
    let targetDuration: Int
    let onComplete: (Int) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var timeRemaining: Int
    @State private var isRunning: Bool = false
    @State private var totalMinutesCompleted: Int = 0
    @State private var timer: Timer?
    
    init(habit: Habit, date: Date, habitColor: Color, targetDuration: Int, onComplete: @escaping (Int) -> Void) {
        self.habit = habit
        self.date = date
        self.habitColor = habitColor
        self.targetDuration = targetDuration
        self.onComplete = onComplete
        self._timeRemaining = State(initialValue: targetDuration * 60) // Convert minutes to seconds
    }
    
    private var progressPercentage: Double {
        let totalSeconds = targetDuration * 60
        return 1.0 - (Double(timeRemaining) / Double(totalSeconds))
    }
    
    private var formattedTime: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var body: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 8) {
                Text(habit.name ?? "Focus Session")
                    .font(.custom("Lexend-Medium", size: 22))
                    .foregroundColor(.primary)
                
                Text("Stay focused for \(targetDuration) minutes")
                    .font(.custom("Lexend-Regular", size: 14))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 20)
            
            // Timer Display
            ZStack {
                // Progress Ring
                Circle()
                    .stroke(habitColor.opacity(0.2), lineWidth: 12)
                    .frame(width: 180, height: 180)
                
                Circle()
                    .trim(from: 0, to: progressPercentage)
                    .stroke(
                        LinearGradient(
                            colors: [habitColor.opacity(0.8), habitColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 180, height: 180)
                    .animation(.smooth(duration: 0.3), value: progressPercentage)
                
                // Time Text
                VStack(spacing: 4) {
                    Text(formattedTime)
                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                        .foregroundColor(.primary)
                    
                    Text(isRunning ? "Focus time" : timeRemaining <= 0 ? "Complete!" : "Ready to start")
                        .font(.custom("Lexend-Medium", size: 14))
                        .foregroundColor(.secondary)
                }
            }
            
            // Control Buttons
            HStack(spacing: 20) {
                // Stop/Reset Button
                if isRunning || timeRemaining < targetDuration * 60 {
                    Button(action: resetTimer) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 16, weight: .medium))
                            Text("Reset")
                                .font(.custom("Lexend-Medium", size: 16))
                        }
                        .foregroundColor(.secondary)
                        .frame(width: 100, height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.secondary.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Start/Pause Button
                Button(action: toggleTimer) {
                    HStack(spacing: 8) {
                        Image(systemName: getTimerButtonIcon())
                            .font(.system(size: 18, weight: .medium))
                        Text(getTimerButtonText())
                            .font(.custom("Lexend-Medium", size: 16))
                    }
                    .foregroundColor(.white)
                    .frame(width: isRunning ? 100 : 140, height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [habitColor.opacity(0.9), habitColor.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: habitColor.opacity(0.3), radius: 6, x: 0, y: 3)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Complete Session Button (shown when timer finishes or user wants to complete early)
            if timeRemaining <= 0 || (!isRunning && timeRemaining < targetDuration * 60) {
                Button(action: completeSession) {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18, weight: .medium))
                        Text("Complete Session")
                            .font(.custom("Lexend-Medium", size: 16))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.green.opacity(0.9), Color.green.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color.green.opacity(0.3), radius: 6, x: 0, y: 3)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 20)
            }
            
            Spacer()
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    private func getTimerButtonIcon() -> String {
        if timeRemaining <= 0 {
            return "checkmark.circle"
        } else if isRunning {
            return "pause.circle"
        } else {
            return "play.circle"
        }
    }
    
    private func getTimerButtonText() -> String {
        if timeRemaining <= 0 {
            return "Done!"
        } else if isRunning {
            return "Pause"
        } else {
            return "Start Focus"
        }
    }
    
    private func toggleTimer() {
        if timeRemaining <= 0 {
            completeSession()
            return
        }
        
        if isRunning {
            stopTimer()
        } else {
            startTimer()
        }
    }
    
    private func startTimer() {
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                stopTimer()
                // Timer completed - vibrate and show completion state
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }
    
    private func stopTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }
    
    private func resetTimer() {
        stopTimer()
        timeRemaining = targetDuration * 60
    }
    
    private func completeSession() {
        let minutesCompleted = targetDuration - (timeRemaining / 60)
        stopTimer()
        onComplete(max(1, minutesCompleted)) // Ensure at least 1 minute is recorded
    }
}
