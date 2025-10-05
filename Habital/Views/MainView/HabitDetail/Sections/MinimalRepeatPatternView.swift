//
//  RepeatPatternView.swift
//  Habital
//
//  Created by Elias Osarumwense on 04.08.25.
//

import SwiftUI

struct MinimalRepeatPatternView: View {
    let habit: Habit
    let date: Date
    
    @Environment(\.colorScheme) private var colorScheme
    
    // Extract the habit color
    private var habitColor: Color {
        if let colorData = habit.color,
           let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
            return Color(uiColor)
        }
        return .blue
    }
    
    // Get the repeat pattern text
    private var repeatPatternText: String {
        guard let repeatPattern = HabitUtilities.getEffectiveRepeatPattern(for: habit, on: date) else {
            return "Not scheduled"
        }
        
        // Add repeats per day to the pattern text if > 1
        let repeatsText = repeatPattern.repeatsPerDay > 1 ? " (\(repeatPattern.repeatsPerDay)x per day)" : ""
        
        // Check for daily goal
        if let dailyGoal = repeatPattern.dailyGoal {
            if dailyGoal.everyDay {
                return "Daily" + repeatsText
            } else if dailyGoal.daysInterval > 0 {
                return "Every \(dailyGoal.daysInterval) days" + repeatsText
            } else if let specificDays = dailyGoal.specificDays as? [Bool] {
                // Check if we have multiple weeks
                let weekCount = specificDays.count / 7
                
                if weekCount > 1 && specificDays.count % 7 == 0 {
                    return "\(weekCount) weeks rotation" + repeatsText
                } else if specificDays.count == 7 {
                    // Single week pattern
                    let dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
                    let selectedDays = zip(dayNames, specificDays)
                        .filter { $0.1 }
                        .map { $0.0 }
                    
                    if selectedDays.isEmpty {
                        return "No days selected" + repeatsText
                    } else if selectedDays.count == 1 {
                        let fullDayNames = ["Mondays", "Tuesdays", "Wednesdays", "Thursdays", "Fridays", "Saturdays", "Sundays"]
                        let dayIndex = dayNames.firstIndex(of: selectedDays[0]) ?? 0
                        return "On \(fullDayNames[dayIndex])" + repeatsText
                    } else {
                        return "On \(selectedDays.joined(separator: ", "))" + repeatsText
                    }
                } else {
                    return "Custom daily pattern" + repeatsText
                }
            }
        }
        
        // Check for weekly goal
        if let weeklyGoal = repeatPattern.weeklyGoal {
            let baseText = weeklyGoal.everyWeek ? "Weekly" : "Every \(weeklyGoal.weekInterval) weeks"
            return baseText + repeatsText
        }
        
        // Check for monthly goal
        if let monthlyGoal = repeatPattern.monthlyGoal {
            let baseText = monthlyGoal.everyMonth ? "Monthly" : "Every \(monthlyGoal.monthInterval) months"
            return baseText + repeatsText
        }
        
        return "Not scheduled"
    }
    
    // Get the appropriate icon for the pattern
    private var patternIcon: String {
        guard let repeatPattern = HabitUtilities.getEffectiveRepeatPattern(for: habit, on: date) else {
            return "calendar.badge.exclamationmark"
        }
        
        // Check for daily goal
        if let dailyGoal = repeatPattern.dailyGoal {
            if dailyGoal.everyDay {
                return "repeat.1"
            } else if dailyGoal.daysInterval > 0 {
                return "calendar.day.timeline.right"
            } else {
                return "calendar"
            }
        }
        
        // Check for weekly goal
        if let weeklyGoal = repeatPattern.weeklyGoal {
            return weeklyGoal.everyWeek ? "calendar.badge.clock" : "calendar.badge.plus"
        }
        
        // Check for monthly goal
        if let monthlyGoal = repeatPattern.monthlyGoal {
            return monthlyGoal.everyMonth ? "calendar.badge.clock" : "calendar.badge.plus"
        }
        
        return "calendar"
    }
    
    // Check if it's a follow-up pattern
    private var isFollowUp: Bool {
        guard let repeatPattern = HabitUtilities.getEffectiveRepeatPattern(for: habit, on: date) else {
            return false
        }
        return repeatPattern.followUp
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon with subtle background
            ZStack {
                Circle()
                    .fill(habitColor.opacity(0.12))
                    .frame(width: 32, height: 32)
                
                Image(systemName: patternIcon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(habitColor)
            }
            
            // Pattern text
            VStack(alignment: .leading, spacing: 2) {
                Text("Schedule")
                    .font(.customFont("Lexend", .medium, 11))
                    .foregroundColor(.secondary)
                
                Text(repeatPatternText)
                    .font(.customFont("Lexend", .semiBold, 13))
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Follow-up indicator if applicable
            if isFollowUp {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.turn.down.right")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(habitColor.opacity(0.8))
                    
                    Text("Follow-up")
                        .font(.customFont("Lexend", .medium, 10))
                        .foregroundColor(habitColor.opacity(0.8))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(habitColor.opacity(0.1))
                        .overlay(
                            Capsule()
                                .strokeBorder(habitColor.opacity(0.2), lineWidth: 0.5)
                        )
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            ZStack {
                // Glass morphism background - same as other components
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
                
                // Subtle inner glow
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.05 : 0.15),
                                Color.clear,
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                // Subtle border with habit color hint
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.15 : 0.4),
                                habitColor.opacity(0.15),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08),
                radius: 6,
                x: 0,
                y: 3
            )
        )
    }
}

// Alternative: Even more minimal version
struct UltraMinimalRepeatPatternView: View {
    let habit: Habit
    let date: Date
    
    @Environment(\.colorScheme) private var colorScheme
    
    // Extract the habit color
    private var habitColor: Color {
        if let colorData = habit.color,
           let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
            return Color(uiColor)
        }
        return .blue
    }
    
    // Get the repeat pattern text (shortened for minimal view)
    private var shortPatternText: String {
        guard let repeatPattern = HabitUtilities.getEffectiveRepeatPattern(for: habit, on: date) else {
            return "Not scheduled"
        }
        
        // Check for daily goal
        if let dailyGoal = repeatPattern.dailyGoal {
            if dailyGoal.everyDay {
                return repeatPattern.repeatsPerDay > 1 ? "Daily (\(repeatPattern.repeatsPerDay)x)" : "Daily"
            } else if dailyGoal.daysInterval > 0 {
                return "Every \(dailyGoal.daysInterval)d"
            } else if let specificDays = dailyGoal.specificDays as? [Bool] {
                let weekCount = specificDays.count / 7
                if weekCount > 1 {
                    return "\(weekCount)w rotation"
                } else {
                    let selectedCount = specificDays.filter { $0 }.count
                    return "\(selectedCount) days/week"
                }
            }
        }
        
        // Check for weekly goal
        if let weeklyGoal = repeatPattern.weeklyGoal {
            return weeklyGoal.everyWeek ? "Weekly" : "Every \(weeklyGoal.weekInterval)w"
        }
        
        // Check for monthly goal
        if let monthlyGoal = repeatPattern.monthlyGoal {
            return monthlyGoal.everyMonth ? "Monthly" : "Every \(monthlyGoal.monthInterval)m"
        }
        
        return "Custom"
    }
    
    private var patternIcon: String {
        guard let repeatPattern = HabitUtilities.getEffectiveRepeatPattern(for: habit, on: date) else {
            return "calendar"
        }
        
        if let dailyGoal = repeatPattern.dailyGoal {
            return dailyGoal.everyDay ? "repeat.1" : "calendar"
        }
        
        if let _ = repeatPattern.weeklyGoal {
            return "calendar.badge.clock"
        }
        
        if let _ = repeatPattern.monthlyGoal {
            return "calendar.badge.plus"
        }
        
        return "calendar"
    }
    
    var body: some View {
        HStack(spacing: 8) {
            // Minimal icon
            Image(systemName: patternIcon)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary.opacity(0.8))
            
            // Short pattern text
            Text(shortPatternText)
                .font(.customFont("Lexend", .medium, 11))
                .foregroundColor(.primary.opacity(0.8))
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(colorScheme == .dark ?
                    Color.white.opacity(0.08) :
                    Color.black.opacity(0.04))
                .overlay(
                    Capsule()
                        .strokeBorder(
                            .primary.opacity(0.2),
                            lineWidth: 1
                        )
                )
        )
    }
}

// Preview for both versions
// Fixed Preview for RepeatPatternView
struct MinimalRepeatPatternView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            Text("Repeat Pattern Views")
                .font(.title2.bold())
            
            VStack(spacing: 20) {
                Text("Full Minimal")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
                
                MinimalRepeatPatternView(
                    habit: sampleHabit(pattern: "Daily"),
                    date: Date()
                )
                
                MinimalRepeatPatternView(
                    habit: sampleHabit(pattern: "Weekly"),
                    date: Date()
                )
                
                MinimalRepeatPatternView(
                    habit: sampleHabit(pattern: "Custom"),
                    date: Date()
                )
                
                Text("Ultra Minimal")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
                
                HStack(spacing: 10) {
                    UltraMinimalRepeatPatternView(
                        habit: sampleHabit(pattern: "Daily"),
                        date: Date()
                    )
                    
                    UltraMinimalRepeatPatternView(
                        habit: sampleHabit(pattern: "Custom"),
                        date: Date()
                    )
                    
                    UltraMinimalRepeatPatternView(
                        habit: sampleHabit(pattern: "Monthly"),
                        date: Date()
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .previewLayout(.sizeThatFits)
    }
    
    static func sampleHabit(pattern: String) -> Habit {
        let context = PersistenceController.preview.container.viewContext
        let habit = Habit(context: context)
        habit.name = "Sample Habit - \(pattern)"
        habit.icon = "dumbbell.fill"
        habit.startDate = Date()
        
        // Set color
        if let colorData = try? NSKeyedArchiver.archivedData(withRootObject: UIColor.blue, requiringSecureCoding: false) {
            habit.color = colorData
        }
        
        // ✅ CREATE REPEAT PATTERN - this was missing!
        let repeatPattern = RepeatPattern(context: context)
        repeatPattern.repeatsPerDay = 1
        repeatPattern.effectiveFrom = Date()
        repeatPattern.followUp = false
        repeatPattern.habit = habit
        
        // Create different goals based on pattern type
        switch pattern {
        case "Daily":
            let dailyGoal = DailyGoal(context: context)
            dailyGoal.everyDay = true
            dailyGoal.repeatPattern = repeatPattern
            repeatPattern.dailyGoal = dailyGoal
            
        case "Weekly":
            let weeklyGoal = WeeklyGoal(context: context)
            weeklyGoal.everyWeek = true
            weeklyGoal.repeatPattern = repeatPattern
            repeatPattern.weeklyGoal = weeklyGoal
            
        case "Monthly":
            let monthlyGoal = MonthlyGoal(context: context)
            monthlyGoal.everyMonth = true
            monthlyGoal.repeatPattern = repeatPattern
            repeatPattern.monthlyGoal = monthlyGoal
            
        case "Custom":
            let dailyGoal = DailyGoal(context: context)
            dailyGoal.everyDay = false
            dailyGoal.daysInterval = 3 // Every 3 days
            dailyGoal.repeatPattern = repeatPattern
            repeatPattern.dailyGoal = dailyGoal
            
        default:
            // Default to daily
            let dailyGoal = DailyGoal(context: context)
            dailyGoal.everyDay = true
            dailyGoal.repeatPattern = repeatPattern
            repeatPattern.dailyGoal = dailyGoal
        }
        
        // ✅ Add the repeat pattern to the habit
        habit.addToRepeatPattern(repeatPattern)
        
        return habit
    }
}
