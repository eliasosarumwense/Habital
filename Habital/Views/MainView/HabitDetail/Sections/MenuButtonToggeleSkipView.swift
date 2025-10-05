//
//  MenuButtonToggeleSkipView.swift
//  Habital
//
//  Created by Elias Osarumwense on 20.08.25.
//
import SwiftUI

struct CircleMenuButton: View {
    let habit: Habit
    let date: Date
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var toggleManager = HabitToggleManager(context: PersistenceController.shared.container.viewContext)
    
    // State for the menu and time picker
    @State private var showTimeMenuPopover = false
    @State private var showTimePickerPopover = false
    @State private var selectedPickerTime = Date()
    
    // Extract the habit color
    private var habitColor: Color {
        if let colorData = habit.color,
           let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
            return Color(uiColor)
        }
        return .blue // Default color if not set
    }
    
    var body: some View {
        HStack {
            Spacer()
            
            Button(action: {
                showTimeMenuPopover = true
            }) {
                ZStack {
                    Circle()
                        .fill(habitColor.opacity(0.1))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Circle()
                                .strokeBorder(habitColor.opacity(0.3), lineWidth: 1)
                        )
                    
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(habitColor)
                }
            }
            .popover(isPresented: $showTimeMenuPopover, arrowEdge: .trailing) {
                CircleMenuPopoverContent(
                    habit: habit,
                    date: date,
                    onSkip: {
                        skipHabit()
                        showTimeMenuPopover = false
                    },
                    onSelectTime: { minutesOffset in
                        completeWithCustomTime(minutesOffset)
                        showTimeMenuPopover = false
                    },
                    onShowTimePicker: {
                        showTimeMenuPopover = false
                        selectedPickerTime = getCompletionTimeForSelectedDate()
                        showTimePickerPopover = true
                    },
                    onCancel: {
                        showTimeMenuPopover = false
                    }
                )
                .presentationCompactAdaptation(.popover)
            }
            .popover(isPresented: $showTimePickerPopover, arrowEdge: .trailing) {
                TimePickerPopoverContent(
                    selectedTime: $selectedPickerTime,
                    lastCompletionTime: getLastCompletionTime(),
                    onComplete: { pickedTime in
                        let calendar = Calendar.current
                        let selectedDate = calendar.startOfDay(for: date)
                        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: pickedTime)
                        let fullCompletionDateTime = calendar.date(bySettingHour: timeComponents.hour ?? 12,
                                                                 minute: timeComponents.minute ?? 0,
                                                                 second: timeComponents.second ?? 0,
                                                                 of: selectedDate) ?? selectedDate
                        
                        handleCompletionTap(withCustomDate: fullCompletionDateTime)
                        showTimePickerPopover = false
                    },
                    onCancel: {
                        showTimePickerPopover = false
                    }
                )
                .presentationCompactAdaptation(.popover)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func skipHabit() {
        toggleManager.skipHabit(for: habit, on: date)
    }
    
    private func completeWithCustomTime(_ minutesOffset: Int = 0) {
        let calendar = Calendar.current
        let selectedDate = calendar.startOfDay(for: date)
        let baseTime = getCompletionTimeForSelectedDate()
        let completionTime = baseTime.addingTimeInterval(TimeInterval(minutesOffset * 60))
        
        // Create the full datetime by combining the selected date with the completion time
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: completionTime)
        let fullCompletionDateTime = calendar.date(bySettingHour: timeComponents.hour ?? 12,
                                                 minute: timeComponents.minute ?? 0,
                                                 second: timeComponents.second ?? 0,
                                                 of: selectedDate) ?? selectedDate
        
        handleCompletionTap(withCustomDate: fullCompletionDateTime)
    }
    
    private func handleCompletionTap(withCustomDate customDate: Date? = nil) {
        // Use custom date if provided, otherwise use the regular date
        let completionDate = customDate ?? date
        
        // Only track time when a custom date is provided (custom time completion)
        let shouldTrackTime = customDate != nil
        
        // Normal toggle behavior with the custom date and conditional time tracking
        toggleManager.toggleCompletion(for: habit, on: completionDate, tracksTime: shouldTrackTime)
    }
    
    private func getLastCompletionTime() -> Date? {
        guard let completions = habit.completion as? Set<Completion>,
              !completions.isEmpty else {
            return nil
        }
        
        // Find the most recent completion with a loggedAt time
        let recentCompletion = completions
            .filter { $0.completed && $0.loggedAt != nil }
            .max { ($0.loggedAt ?? Date.distantPast) < ($1.loggedAt ?? Date.distantPast) }
        
        return recentCompletion?.loggedAt
    }
    
    private func getCompletionTimeForSelectedDate() -> Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let selectedDay = calendar.startOfDay(for: date)
        
        if calendar.isDate(selectedDay, inSameDayAs: today) {
            // For today: use current time minus minutes
            return Date()
        } else {
            // For other dates: use the last completion time or default to 12:00 PM
            if let lastCompletionTime = getLastCompletionTime() {
                // Extract time components from last completion
                let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: lastCompletionTime)
                // Apply this time to the selected date
                return calendar.date(bySettingHour: timeComponents.hour ?? 12,
                                   minute: timeComponents.minute ?? 0,
                                   second: timeComponents.second ?? 0,
                                   of: selectedDay) ?? selectedDay
            } else {
                // Default to 12:00 PM on the selected date
                return calendar.date(bySettingHour: 12, minute: 0, second: 0, of: selectedDay) ?? selectedDay
            }
        }
    }
}

// MARK: - Menu Popover Content
struct CircleMenuPopoverContent: View {
    let habit: Habit
    let date: Date
    let onSkip: () -> Void
    let onSelectTime: (Int) -> Void // minutes ago
    let onShowTimePicker: () -> Void
    let onCancel: () -> Void
    
    private var habitColor: Color {
        if let colorData = habit.color,
           let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
            return Color(uiColor)
        }
        return .blue
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Skip Button
            Button(action: onSkip) {
                HStack {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.red)
                    
                    Text("Skip Habit")
                        .customFont("Lexend", .medium, 14)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.red.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(PlainButtonStyle())
            
            // Time Options Section
            VStack(spacing: 8) {
                HStack {
                    Text("Complete with time:")
                        .customFont("Lexend", .medium, 12)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 4)
                
                // Preset time options
                ForEach([15, 30, 45, 60, 120], id: \.self) { minutes in
                    Button(action: {
                        onSelectTime(-minutes) // negative for "ago"
                    }) {
                        HStack {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(habitColor)
                            
                            Text("\(minutes == 60 ? "1h" : minutes == 120 ? "2h" : "\(minutes)m") ago")
                                .customFont("Lexend", .medium, 14)
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(habitColor.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Custom Time Picker Button
                Button(action: onShowTimePicker) {
                    HStack {
                        Image(systemName: "clock.badge.questionmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(habitColor)
                        
                        Text("Choose custom time...")
                            .customFont("Lexend", .medium, 14)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(habitColor.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(16)
        .frame(width: 220)
    }
}

