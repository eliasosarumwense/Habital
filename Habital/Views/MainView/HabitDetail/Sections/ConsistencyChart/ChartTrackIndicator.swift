//
//  ChartTrackIndicator.swift
//  Habital
//
//  Created by Elias Osarumwense on 24.04.25.
//

import SwiftUI
import CoreData

struct EnhancedChartTrackIndicator: View {
    let habit: Habit
    let date: Date
    @State private var trackStatus: TrackStatus = .unknown
    @State private var animateIn: Bool = false
    @State private var showDetails: Bool = false
    @State private var hasCalculated: Bool = false  // New flag to track calculation
    
    // Styling options
    var textColor: Color? = nil
    var showBorder: Bool = true
    var condensed: Bool = false
    
    enum TrackStatus {
        case onTrack
        case offTrack
        case unknown
    }
    
    private var overdueDays: Int? {
        return habit.calculateOverdueDays(on: date)
    }

    
    var body: some View {
        Group {
            VStack (alignment: .leading, spacing: 5){
                // Remove the trackStatus != .unknown condition - always show something
                HStack(spacing: 8) {
                    // Indicator icon/dot with animation
                    ZStack {
                        // Background
                        Circle()
                            .fill(statusColor.opacity(0.15))
                            .frame(width: condensed ? 18 : 22, height: condensed ? 18 : 22)
                        
                        // Matching icon
                        Image(systemName: statusIcon)
                            .font(.system(size: condensed ? 10 : 12, weight: .semibold))
                            .foregroundColor(statusColor)
                    }
                    .scaleEffect(animateIn ? 1.0 : 0.01)
                    .opacity(animateIn ? 1.0 : 0.0)
                    
                    // Status text
                    Text(statusText)
                        .font(.customFont("Lexend", .medium, condensed ? 13 : 14))
                        .foregroundColor(textColor ?? statusColor.opacity(0.85))
                        .lineLimit(1)
                        .opacity(animateIn ? 1.0 : 0.0)
                        .offset(x: animateIn ? 0 : -10)
                }
                .padding(.vertical, condensed ? 2 : 4)
                .padding(.horizontal, condensed ? 6 : 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(statusColor.opacity(0.1))
                        .overlay(
                            showBorder ?
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(statusColor.opacity(0.2), lineWidth: 1) : nil
                        )
                )
                .opacity(hasCalculated ? 1.0 : 0.0) // Only show after calculation
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showDetails.toggle()
                    }
                }
                
                // Detailed explanation appears when tapped
                if showDetails {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(statusDetailText)
                            .font(.customFont("Lexend", .regular, condensed ? 10 : 11))
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        // Close button
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                showDetails = false
                            }
                        }) {
                            Text("Dismiss")
                                .font(.customFont("Lexend", .medium, 10))
                                .foregroundColor(statusColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(statusColor.opacity(0.1))
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.top, 3)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    )
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .padding(.vertical, 4)
                }
                /*
                if let days = overdueDays, days > 0,
                   let repeatPattern = HabitUtilities.getEffectiveRepeatPattern(for: habit, on: date),
                   repeatPattern.followUp {
                    
                    followUpSection
                        .opacity(hasCalculated && animateIn ? 1.0 : 0.0)
                        .animation(.easeIn.delay(0.3), value: hasCalculated && animateIn)
                }
                 */
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: showDetails)
        .task {
            // Calculate track status on appearance, with a delay to ensure data is ready
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms delay
            calculateTrackStatus()
            hasCalculated = true
            
            // Animate in with slight delay
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms additional delay
            await MainActor.run {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    animateIn = true
                }
            }
        }
    }
    private var followUpSection: some View {
        
            HStack(spacing: 8) {
                // Animated icon background + symbol
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.15))
                        .frame(width: condensed ? 16 : 20, height: condensed ? 16 : 20)
                    
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: condensed ? 8 : 10, weight: .semibold))
                        .foregroundColor(.yellow)
                }
                .scaleEffect(animateIn ? 1.0 : 0.01)
                .opacity(animateIn ? 1.0 : 0.0)
                
                // Animated status text
                Text("Overdue by \(overdueDays ?? 0) days")
                    .font(.customFont("Lexend", .medium, condensed ? 10 : 11))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .opacity(animateIn ? 1.0 : 0.0)
                    .offset(x: animateIn ? 0 : -10)
            }
            .padding(.vertical, condensed ? 2 : 4)
            .padding(.horizontal, condensed ? 6 : 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(statusColor.opacity(0.1))
                    .overlay(
                        showBorder ?
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(statusColor.opacity(0.2), lineWidth: 1) : nil
                    )
            )
            .opacity(hasCalculated ? 1.0 : 0.0)
            .onAppear {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    animateIn = true
                }
            }
        
    }
    // Return appropriate color based on status
    private var statusColor: Color {
        switch trackStatus {
        case .onTrack:
            return Color.green
        case .offTrack:
            return Color.red
        case .unknown:
            return Color.gray
        }
    }
    
    // Return appropriate icon based on status and habit type
    private var statusIcon: String {
        // Safely access isBadHabit property
        let isBadHabit = (try? habit.value(forKey: "isBadHabit") as? Bool) ?? false
        
        if isBadHabit {
            return trackStatus == .onTrack ? "hand.thumbsup.fill" : "hand.thumbsdown.fill"
        } else {
            return trackStatus == .onTrack ? "arrow.up.forward" : trackStatus == .unknown ? "calendar" : "arrow.down.forward"
        }
    }
    
    // Return appropriate text based on status and habit type
    private var statusText: String {
        // Safely access isBadHabit property
        let isBadHabit = (try? habit.value(forKey: "isBadHabit") as? Bool) ?? false
        
        if isBadHabit {
            return trackStatus == .onTrack ? "On Track" : "Off Track"
        } else {
            return trackStatus == .onTrack ? "On Track" : trackStatus == .unknown ? "Not completed before" : "Off Track"
        }
    }
    
    // Return detailed explanation based on status and habit type
    private var statusDetailText: String {
        // Safely access isBadHabit property
        let isBadHabit = (try? habit.value(forKey: "isBadHabit") as? Bool) ?? false
        
        if isBadHabit {
            return trackStatus == .onTrack
                ? "You successfully avoided this habit the last time it was scheduled. Keep it up!"
                : "You engaged in this habit the last time it was scheduled. Try to avoid it next time."
        } else {
            return trackStatus == .onTrack
                ? "You completed this habit the last time it was scheduled. Great job maintaining consistency!"
                : "You missed this habit the last time it was scheduled. Try to maintain consistency next time."
        }
    }
    
    // Calculate if habit is on track
    private func calculateTrackStatus() {
        // Access properties safely to prevent crashes
        guard habit.managedObjectContext != nil else {
            // If habit doesn't have a valid context, set to unknown
            self.trackStatus = .unknown
            return
        }
        
        do {
            // Get the current calendar
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: date)
            var currentDate = calendar.date(byAdding: .day, value: -1, to: today) ?? Date()
            var dayCounter = 0
            
            // Look back up to 30 days to find the most recent active date
            while dayCounter < 30 {
                // Safely check if habit is active
                if HabitUtilities.isHabitActive(habit: habit, on: currentDate) {
                    // Found the most recent active date before today
                    let wasCompleted = habit.isCompleted(on: currentDate)
                    
                    // For bad habits, being "on track" means you successfully avoided the habit
                    // For good habits, being "on track" means you completed the habit
                    self.trackStatus = habit.isBadHabit ?
                        (!wasCompleted ? .offTrack : .onTrack) :
                        (wasCompleted ? .onTrack : .offTrack)
                    return
                }
                
                // Move back one day
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
                dayCounter += 1
            }
            
            // If we couldn't find any active dates in the past 30 days
            self.trackStatus = .unknown
        } catch {
            print("Error calculating track status: \(error)")
            self.trackStatus = .unknown
        }
    }
}

struct EnhancedChartTrackIndicator_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Create good habit examples
            Group {
                Text("Good Habit")
                    .font(.headline)
                
                EnhancedChartTrackIndicator(
                    habit: createPreviewHabit(isBad: false, isCompleted: true),
                    date: Date()
                )
                
                EnhancedChartTrackIndicator(
                    habit: createPreviewHabit(isBad: false, isCompleted: false),
                    date: Date()
                )
                
                EnhancedChartTrackIndicator(
                    habit: createPreviewHabit(isBad: false, isCompleted: true),
                    date: Date(),
                    condensed: true
                )
            }
            
            Divider()
            
            // Create bad habit examples
            Group {
                Text("Bad Habit")
                    .font(.headline)
                
                EnhancedChartTrackIndicator(
                    habit: createPreviewHabit(isBad: true, isCompleted: false),
                    date: Date()
                )
                
                EnhancedChartTrackIndicator(
                    habit: createPreviewHabit(isBad: true, isCompleted: true),
                    date: Date()
                )
                
                EnhancedChartTrackIndicator(
                    habit: createPreviewHabit(isBad: true, isCompleted: false),
                    date: Date(),
                    condensed: true
                )
            }
        }
        .padding()
    }
    
    // Create a preview habit for testing
    static func createPreviewHabit(isBad: Bool, isCompleted: Bool) -> Habit {
        let context = PersistenceController.preview.container.viewContext
        let habit = Habit(context: context)
        habit.name = isBad ? "Quit Smoking" : "Daily Exercise"
        habit.isBadHabit = isBad
        habit.startDate = Date().addingTimeInterval(-86400 * 7) // 7 days ago
        
        return habit
    }
}
