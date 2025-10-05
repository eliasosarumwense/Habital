
import SwiftUI

enum TrackIndicatorStyle {
    case minimal     // Just a dot
    case compact     // Dot with short text
    case detailed    // Dot with detailed text
}

struct EnhancedHabitTrackIndicator: View {
    let habit: Habit
    let date: Date
    var style: TrackIndicatorStyle = .minimal
    @State private var trackStatus: TrackStatus = .unknown
    @State private var showTooltip: Bool = false
    
    // Use an enum to clearly represent tracking status
    enum TrackStatus {
        case onTrack
        case offTrack
        case unknown
    }
    
    var body: some View {
        HStack(spacing: style == .minimal ? 0 : 4) {
            if trackStatus != .unknown {
                // Status indicator dot with subtle glow effect
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(statusColor.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .blur(radius: 2)
                    
                    // Main dot
                    Circle()
                        .fill(statusColor)
                        .frame(width: style == .minimal ? 5 : 6, height: style == .minimal ? 5 : 6)
                }
                .frame(width: 10, height: 10)
                .padding(.leading, 2)
                .onTapGesture {
                    if style == .minimal {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showTooltip.toggle()
                        }
                    }
                }
                
                // Text based on selected style and status
                if style != .minimal || showTooltip {
                    Text(statusText)
                        .font(.system(size: style == .detailed ? 11 : 9, weight: .medium))
                        .foregroundColor(statusColor.opacity(0.9))
                        .padding(.leading, -2)
                        .transition(style == .minimal ? .slide : .identity)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showTooltip)
                }
            }
        }
        .opacity(trackStatus == .unknown ? 0 : 1)
        .animation(.easeOut(duration: 0.3), value: trackStatus != .unknown)
        .onAppear {
            calculateTrackStatus()
        }
        .onChange(of: date) { _ in
            calculateTrackStatus()
        }
    }
    
    // Dynamic color based on status
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
    
    // Dynamic text based on status and style
    private var statusText: String {
        let isBad = habit.isBadHabit
        
        switch (trackStatus, style) {
        case (.onTrack, .minimal), (.onTrack, .compact):
            return isBad ? "Avoided" : "On track"
            
        case (.offTrack, .minimal), (.offTrack, .compact):
            return isBad ? "Broken" : "Off track"
            
        case (.onTrack, .detailed):
            return isBad ? "Successfully avoided last time" : "Completed last time"
            
        case (.offTrack, .detailed):
            return isBad ? "Habit was broken last time" : "Missed last time"
            
        default:
            return ""
        }
    }
    
    private func calculateTrackStatus() {
        // We need to find the last active date before today
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: date)
        var currentDate = calendar.date(byAdding: .day, value: -1, to: today) ?? Date()
        var dayCounter = 0
        
        // Look back up to 30 days to find the most recent active date
        while dayCounter < 30 {
            if HabitUtilities.isHabitActive(habit: habit, on: currentDate) {
                // Found the most recent active date before today
                let wasCompleted = habit.isCompleted(on: currentDate)
                
                // For bad habits, being "on track" means you successfully avoided the habit
                // For good habits, being "on track" means you completed the habit
                self.trackStatus = (habit.isBadHabit ? wasCompleted : wasCompleted) ? .onTrack : .offTrack
                return
            }
            
            // Move to previous day
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            dayCounter += 1
        }
        
        // If we couldn't find any active dates in the past 30 days
        // or if the habit is new with no previous active days before today
        self.trackStatus = .unknown
    }
}

// Preview
struct EnhancedHabitTrackIndicator_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Create a sample good habit
            Group {
                Text("Good Habit")
                    .font(.headline)
                
                HStack {
                    Text("Minimal Style:")
                    EnhancedHabitTrackIndicator(habit: createSampleHabit(isBad: false), date: Date(), style: .minimal)
                }
                
                HStack {
                    Text("Compact Style:")
                    EnhancedHabitTrackIndicator(habit: createSampleHabit(isBad: false), date: Date(), style: .compact)
                }
                
                HStack {
                    Text("Detailed Style:")
                    EnhancedHabitTrackIndicator(habit: createSampleHabit(isBad: false), date: Date(), style: .detailed)
                }
            }
            
            Divider()
            
            // Create a sample bad habit
            Group {
                Text("Bad Habit")
                    .font(.headline)
                
                HStack {
                    Text("Minimal Style:")
                    EnhancedHabitTrackIndicator(habit: createSampleHabit(isBad: true), date: Date(), style: .minimal)
                }
                
                HStack {
                    Text("Compact Style:")
                    EnhancedHabitTrackIndicator(habit: createSampleHabit(isBad: true), date: Date(), style: .compact)
                }
                
                HStack {
                    Text("Detailed Style:")
                    EnhancedHabitTrackIndicator(habit: createSampleHabit(isBad: true), date: Date(), style: .detailed)
                }
            }
        }
        .padding()
    }
    
    // Helper to create a sample habit for previews
    static func createSampleHabit(isBad: Bool) -> Habit {
        let habit = Habit()
        habit.name = isBad ? "Quit Smoking" : "Daily Exercise"
        habit.isBadHabit = isBad
        habit.startDate = Date().addingTimeInterval(-86400 * 7) // 7 days ago
        return habit
    }
}
