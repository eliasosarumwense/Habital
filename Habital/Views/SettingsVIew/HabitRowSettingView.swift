//
//  HabitRowSettingView.swift
//  Habital
//
//  Created by Elias Osarumwense on 14.04.25.
//

import SwiftUI
import CoreData

struct MockTrackIndicator: View {
    let isOnTrack: Bool
    let style: String
    
    var body: some View {
        HStack(spacing: style == "minimal" ? 2 : 4) {
            // Status indicator dot
            Circle()
                .fill(isOnTrack ? Color.green : Color.red)
                .frame(width: 6, height: 6)
            
            // Text based on selected style and status
            if style != "minimal" {
                Text(statusText)
                    .font(.system(size: style == "detailed" ? 11 : 9, weight: .medium))
                    .foregroundColor(isOnTrack ? Color.green : Color.red)
            }
        }
    }
    
    private var statusText: String {
        switch (isOnTrack, style) {
        case (true, "compact"):
            return "On track"
        case (false, "compact"):
            return "Off track"
        case (true, "detailed"):
            return "Completed last time"
        case (false, "detailed"):
            return "Missed last time"
        default:
            return ""
        }
    }
}

// Mock intensity indicator preview
struct MockIntensityIndicator: View {
    let style: String
    let level: Int16
    let color: Color
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        switch style {
        case "dots":
            HStack(spacing: 2) {
                ForEach(0..<Int(level), id: \.self) { index in
                    Circle()
                        .fill(color)
                        .frame(width: 4, height: 4)
                        .scaleEffect(index == Int(level) - 1 ? 1.2 : 1.0)
                }
            }
            .padding(4)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .shadow(color: Color.black.opacity(0.1), radius: 1)
            )
        case "chevron":
            VStack(spacing: 1) {
                ForEach(0..<Int(level), id: \.self) { _ in
                    Image(systemName: "chevron.up")
                        .font(.system(size: 4, weight: .bold))
                        .foregroundColor(color)
                }
            }
        case "chevron_original":
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 15, height: 15)
                    .background(
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        (colorScheme == .dark ? Color.white : Color.black).opacity(0.08),
                                        Color.clear
                                    ]),
                                    center: .center,
                                    startRadius: 7.5,
                                    endRadius: 8
                                )
                            )
                            .frame(width: 20, height: 20)
                    )
                
                Image(systemName: "chevron.up")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(color)
            }
        case "arc":
            Circle()
                .trim(from: 0, to: CGFloat(level) / 4.0)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: 2, lineCap: .round)
                )
                .frame(width: 30, height: 30)
                .rotationEffect(.degrees(-90))
        case "minimal":
            Rectangle()
                .fill(color)
                .frame(width: CGFloat(level) * 3, height: 2)
                .cornerRadius(1)
        default:
            HStack(spacing: 2) {
                ForEach(0..<Int(level), id: \.self) { index in
                    Circle()
                        .fill(color)
                        .frame(width: 4, height: 4)
                        .scaleEffect(index == Int(level) - 1 ? 1.2 : 1.0)
                }
            }
            .padding(4)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .shadow(color: Color.black.opacity(0.1), radius: 1)
            )
        }
    }
}

// Mock habit for preview
class MockHabit: NSObject, Identifiable {
    var id = UUID()
    var name: String? = "Daily Meditation"
    var habitDescription: String? = "Mindfulness practice"
    var icon: String? = "brain.head.profile"
    var isBadHabit: Bool = false
    var color: Data?
    var startDate: Date? = Calendar.current.date(byAdding: .day, value: -30, to: Date())
    var isArchived: Bool = false
    var intensityLevel: Int16 = 1
    var habitList: NSObject? = nil
    var completion: NSSet? = nil
    var repeatPattern: NSSet? = nil
    
    override init() {
        super.init()
        // Set the color (orange)
        self.color = try? NSKeyedArchiver.archivedData(withRootObject: UIColor.systemOrange, requiringSecureCoding: false)
    }
    
    // Mock methods
    func calculateOverdueDays(on date: Date) -> Int? { return 3 }
    func calculateStreak(upTo date: Date) -> Int { return 5 }
    func findMostRecentCompletion(before date: Date) -> NSObject? { return nil }
    func isCompleted(on date: Date) -> Bool { return false }
    func moveToHabitList(_ list: NSObject?, context: NSManagedObjectContext) {}
}

// Stream line of Habit to make it work with MockHabit
extension MockHabit: ObservableObject {
    @objc var lastCompletionDate: Date? {
        return Calendar.current.date(byAdding: .day, value: -2, to: Date())
    }
}


// CheckmarkColorPreview component to show checkmark color examples
struct CheckmarkColorPreview: View {
    let color: Color
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            // Fixed checkmark (not toggleable)
            ZStack {
                // Progress ring
                Circle()
                    .trim(from: 0, to: 1.0)
                    .stroke(
                        color,
                        style: StrokeStyle(
                            lineWidth: 3,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                    .frame(width: 32, height: 32)
                    .rotationEffect(.degrees(-90))
                
                // Checkmark
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(color)
            }
            
            // Label under checkmark
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(width: 60)
    }
}

struct HabitRowSettingView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    // Sample habit for preview
    @State private var isCompleted = false
    @State private var mockHabit = MockHabit()
    
    // App storage for settings
    @AppStorage("showStreaks") private var showStreaks = true
    @AppStorage("highlightOverdueHabits") private var highlightOverdueHabits = true
    @AppStorage("useModernBadges") private var useModernBadges = false
    @AppStorage("showHabitDescription") private var showHabitDescription = false
    @AppStorage("showRepeatPattern") private var showRepeatPattern = true
    @AppStorage("showOverdueText") private var showOverdueText = true
    @AppStorage("customRowBackground") private var customRowBackground = false
    @AppStorage("rowBackgroundOpacity") private var rowBackgroundOpacity = 0.1
    @AppStorage("checkmarkColorType") private var checkmarkColorType = "habit" // "habit", "green", "primary"
    @AppStorage("iconColorType") private var iconColorType = "habit" // "habit", "primary"
    @AppStorage("iconBackgroundColorType") private var iconBackgroundColorType = "habit" // "habit", "primary"
    @AppStorage("iconBackgroundOpacity") private var iconBackgroundOpacity = 0.2
    @AppStorage("showTrackIndicator") private var showTrackIndicator = true
    @AppStorage("trackIndicatorStyle") private var trackIndicatorStyle = "minimal"
    @AppStorage("showIntensityIndicator") private var showIntensityIndicator = true
    @AppStorage("intensityIndicatorStyle") private var intensityIndicatorStyle = "dots"
    
    // Helper computed property to get habit color
    private var habitColor: Color {
        if let colorData = mockHabit.color,
           let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
            return Color(uiColor)
        }
        return .blue
    }
    
    // Get intensity color based on level
    private var intensityColor: Color {
        switch mockHabit.intensityLevel {
        case 1: return .green
        case 2: return .orange
        case 3: return .red
        case 4: return .purple
        default: return .green
        }
    }
    
    // Mock row view that mimics HabitRowView
    struct MockHabitRowView: View {
        let habit: MockHabit
        let isActive: Bool
        @Binding var isCompleted: Bool
        let nextOccurrence: String
        
        @AppStorage("showStreaks") private var showStreaks = true
        @AppStorage("highlightOverdueHabits") private var highlightOverdueHabits = true
        @AppStorage("useModernBadges") private var useModernBadges = false
        @AppStorage("showHabitDescription") private var showHabitDescription = true
        @AppStorage("showRepeatPattern") private var showRepeatPattern = true
        @AppStorage("showOverdueText") private var showOverdueText = true
        @AppStorage("customRowBackground") private var customRowBackground = false
        @AppStorage("rowBackgroundOpacity") private var rowBackgroundOpacity = 0.1
        @AppStorage("showTrackIndicator") private var showTrackIndicator = false
        @AppStorage("trackIndicatorStyle") private var trackIndicatorStyle = "minimal"
        @AppStorage("showIntensityIndicator") private var showIntensityIndicator = true
        
        @Environment(\.colorScheme) private var colorScheme
        
        private var habitColor: Color {
            if let colorData = habit.color,
               let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
                return Color(uiColor)
            }
            return .blue // Default color if not set
        }
        
        // Calculated overdue days
        private var overdueDays: Int? {
            return habit.calculateOverdueDays(on: Date())
        }
        
        // Check if overdue should be shown
        private var shouldShowOverdue: Bool {
            return highlightOverdueHabits && isActive && overdueDays != nil && overdueDays! > 0
        }
        
        // Get intensity color based on level
        private var intensityColor: Color {
            switch habit.intensityLevel {
            case 1: return .green
            case 2: return .orange
            case 3: return .red
            default: return .green
            }
        }
        
        var body: some View {
            HStack {
                // Use the HabitIconView with proper intensity display
                ZStack {
                    HabitIconView(
                        iconName: habit.icon,
                        isActive: isActive,
                        habitColor: habitColor,
                        streak: habit.calculateStreak(upTo: Date()),
                        showStreaks: showStreaks,
                        useModernBadges: useModernBadges,
                        isFutureDate: false,
                        isBadHabit: habit.isBadHabit,
                        intensityLevel: showIntensityIndicator ? habit.intensityLevel : 0 // Only show intensity if enabled
                    )
                    
                }
                .padding(.trailing, 8)
                
                // Habit name and pattern stacked vertically
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(habit.name ?? "Unnamed Habit")
                            .customFont("Lexend", .medium, 15)
                            .foregroundColor(isActive ? .primary : .gray)
                        
                        if showTrackIndicator && isActive {
                            MockTrackIndicator(isOnTrack: true, style: trackIndicatorStyle)
                        }
                    }
                    
                    // Show description if available and setting is enabled
                    if showHabitDescription, let description = habit.habitDescription, !description.isEmpty {
                        Text(description)
                            .font(.caption)
                            .lineLimit(1)
                            .foregroundColor(isActive ? .secondary : .gray)
                    }
                    
                    // Add the repeat pattern text if setting is enabled
                    if showRepeatPattern {
                        HStack(spacing: 4) {
                            Text("Every 2 days")
                                .font(.system(size: 10))
                                .foregroundColor(isActive ? .secondary : .gray)
                            
                            Image(systemName: "arrow.turn.down.right")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Add overdue text (only if highlight overdue is enabled)
                    if shouldShowOverdue && showOverdueText, let days = overdueDays {
                        Text("Overdue by \(days) day\(days > 1 ? "s" : "")")
                            .font(.system(size: 10))
                            .foregroundColor(.red)
                            .bold()
                    }
                }
                
                Spacer()
                
                if isActive {
                    HStack(spacing: 4) {
                        // "Skipped" text for past habits that aren't completed
                        if !isCompleted && !habit.isBadHabit {
                            Text("Skipped")
                                .font(.caption2)
                                .foregroundColor(.red)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.red.opacity(0.1))
                                )
                        }
                        
                        ZStack(alignment: .topTrailing) {
                            // Completion checkmark
                            RingFillCheckmarkButton(
                                habitColor: habitColor,
                                isCompleted: $isCompleted,
                                onTap: {},
                                repeatsPerDay: 1,
                                completedRepeats: isCompleted ? 1 : 0
                            )
                            
                            // Overdue indicator
                            if shouldShowOverdue && showOverdueText && !isCompleted {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.red)
                                    .font(.system(size: 14))
                                    .background(Circle().fill(Color.white).frame(width: 12, height: 12))
                                    .offset(x: 5, y: -5)
                            }
                        }
                    }
                } else {
                    // Next occurrence text
                    HStack(spacing: 2) {
                        Image(systemName: "arrow.right")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        
                        Text(nextOccurrence)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .frame(height: 50)
            .padding(.vertical, 8)
            .padding(.horizontal)
            .background(
                ZStack {
                    // Background fill
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            isActive
                            ? (colorScheme == .dark ? Color(UIColor.systemGray6) : Color.white)
                            : (colorScheme == .dark ? Color(UIColor.systemGray5).opacity(0.5) : Color.gray.opacity(0.1))
                        )
                    
                    // Custom colored overlay if enabled
                    if customRowBackground && isActive {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(habitColor.opacity(rowBackgroundOpacity))
                    }
                }
                .shadow(color: colorScheme == .dark ? .white.opacity(0.33) : .black.opacity(0.33), radius: 2)
            )
        }
    }

    var body: some View {
        List {
            // Sample habit row at top
            Section {
                MockHabitRowView(
                    habit: mockHabit,
                    isActive: true,
                    isCompleted: $isCompleted,
                    nextOccurrence: "3 days overdue"
                )
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                .padding(.horizontal, 10)
            } header: {
                Text("Sample Habit Preview")
            }
            
            // Text Display Settings - reorganized
            Section(header: Text("Text Display")) {
                Toggle("Show Habit Description", isOn: $showHabitDescription)
                Toggle("Show Repeat Pattern", isOn: $showRepeatPattern)
                
                
                // Streak badge now appears after overdue text setting
                Toggle("Show Streaks", isOn: $showStreaks)
                
                if showStreaks {
                    Toggle("Use Modern Translucent Badges", isOn: $useModernBadges)
                        
                }
                
                Toggle("Highlight Overdue Habits", isOn: $highlightOverdueHabits)
            }
            
            // Intensity Indicator Settings
            Section(header: Text("Intensity Indicator")) {
                Toggle("Show Intensity Indicator", isOn: $showIntensityIndicator)
                
                if showIntensityIndicator {
                    Picker("Indicator Style", selection: $intensityIndicatorStyle) {
                        Text("Dots").tag("dots")
                        Text("Chevron (Stacked)").tag("chevron")
                        Text("Chevron (Original)").tag("chevron_original")
                        Text("Arc").tag("arc")
                        Text("Minimal").tag("minimal")
                    }
                    
                    // Intensity level selector for preview
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Preview Intensity Level:")
                            Spacer()
                            Picker("", selection: $mockHabit.intensityLevel) {
                                Text("Light").tag(Int16(1))
                                Text("Moderate").tag(Int16(2))
                                Text("High").tag(Int16(3))
                                Text("Extreme").tag(Int16(4))
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .frame(width: 200)
                        }
                        
                        HStack {
                            Text("Preview:")
                            Spacer()
                            MockIntensityIndicator(
                                style: intensityIndicatorStyle,
                                level: mockHabit.intensityLevel,
                                color: intensityColor
                            )
                        }
                    }
                }
            }
            
            // Checkmark Appearance
            Section(header: Text("Checkmark Appearance")) {
                Picker("Checkmark Color", selection: $checkmarkColorType) {
                    Text("Match Habit Color").tag("habit")
                    Text("Always Green").tag("green")
                    Text("System Primary").tag("primary")
                }
                /*
                // Checkmark color examples
                HStack(spacing: 16) {
                    Spacer()
                    CheckmarkColorPreview(color: habitColor, label: "Habit")
                    CheckmarkColorPreview(color: .green, label: "Green")
                    CheckmarkColorPreview(color: .accentColor, label: "Accent")
                    Spacer()
                }
                .padding(.top, 8)
                 */
            }
            
            // Track Indicator Settings
            Section(header: Text("Track Indicator")) {
                Toggle("Show Track Indicator", isOn: $showTrackIndicator)
                
                if showTrackIndicator {
                    Picker("Indicator Style", selection: $trackIndicatorStyle) {
                        Text("Minimal").tag("minimal")
                        Text("Compact").tag("compact")
                        Text("Detailed").tag("detailed")
                    }
                    
                    HStack {
                        Text("On Track Preview:")
                        Spacer()
                        MockTrackIndicator(isOnTrack: true, style: trackIndicatorStyle)
                    }
                    
                    HStack {
                        Text("Off Track Preview:")
                        Spacer()
                        MockTrackIndicator(isOnTrack: false, style: trackIndicatorStyle)
                    }
                }
            }
            
            // Icon Appearance
            Section(header: Text("Icon Appearance")) {
                Picker("Icon Color", selection: $iconColorType) {
                    Text("Match Habit Color").tag("habit")
                    Text("System Primary").tag("primary")
                }
                
                Picker("Icon Background", selection: $iconBackgroundColorType) {
                    Text("Match Habit Color").tag("habit")
                    Text("System Primary").tag("primary")
                }
                
            }
            
            // Row Background
            Section(header: Text("Row Background")) {
                Toggle("Custom Row Background", isOn: $customRowBackground)
                
                if customRowBackground {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Background Opacity")
                            Spacer()
                            Text("\(Int(rowBackgroundOpacity * 100))%")
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(value: $rowBackgroundOpacity, in: 0.05...0.3, step: 0.05)
                    }
                }
            }
            
            
        }
        .navigationTitle("Row Appearance")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: resetToDefault) {
                    Text("Reset")
                }
            }
        }
    }
    
    // Reset settings to default
    private func resetToDefault() {
        showHabitDescription = false
        showRepeatPattern = true
        showOverdueText = true
        checkmarkColorType = "habit"
        
        // Reset icon appearance to original values
        iconColorType = "primary"
        iconBackgroundColorType = "habit"
  
        
        customRowBackground = false
        rowBackgroundOpacity = 0.1
        showTrackIndicator = true
        trackIndicatorStyle = "minimal"
        showStreaks = true
        highlightOverdueHabits = true
        useModernBadges = true
        showIntensityIndicator = true
        intensityIndicatorStyle = "dots"
    }
}

struct HabitRowSettingView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            HabitRowSettingView()
        }
    }
}
