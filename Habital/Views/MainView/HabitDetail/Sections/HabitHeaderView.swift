//
//  HabitHeaderView.swift
//  Habital
//
//  Created by Elias Osarumwense on 20.04.25.
//

import SwiftUI

struct HabitHeaderView: View {
    let habit: Habit
    let showStreaks: Bool
    
    @State private var showEditSheet = false
    @State private var showArchiveAlert = false
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    
    // Calculate streak
    private var streak: Int {
        return habit.calculateStreak(upTo: Date())
    }
    
    // Extract the habit color
    private var habitColor: Color {
        if let colorData = habit.color,
           let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
            return Color(uiColor)
        }
        return .blue // Default color if not set
    }
    
    // Format date with specific style
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "Not set" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Header: larger icon left, name right
            HStack(alignment: .top, spacing: 14) {
                // Left column: Icon (schedule removed underneath)
                VStack(alignment: .leading, spacing: 8) {
                    HabitIconView(
                        iconName: habit.icon,
                        isActive: true,
                        habitColor: habitColor,
                        streak: streak,
                        showStreaks: false,
                        useModernBadges: true,
                        isFutureDate: false,
                        isBadHabit: habit.isBadHabit,
                        intensityLevel: habit.intensityLevel
                    )
                    .scaleEffect(2.0)
                    .frame(width: 88, height: 88)
                    
                    // Playful start date badge
                    //HabitBirthdayBadge(startDate: habit.startDate, colorScheme: colorScheme)
                }
                .frame(width: 92, alignment: .leading) // column width for alignment
                
                // Right column
                VStack(alignment: .leading, spacing: 5) {
                    // Name bigger with scrolling effect
                    ScrollingText(
                        habit.name ?? "Unnamed Habit",
                        font: .customFont("Lexend", .bold, 24),
                        speed: 30,
                        fadeWidth: 20
                    )
                    .frame(height: 29)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.trailing, 2) // pulled slightly left
                    .padding(.top, 3)
                    
                    // Description directly under the name
                    HabitDescriptionView(
                        description: habit.habitDescription,
                        colorScheme: colorScheme
                    )
                    .padding(.top, 1) // slightly tighter
                    .padding(.leading, -2) // nudge left a bit
                    .padding(.trailing, 0) // avoid extra right padding
                    /*
                    // Archived badge if needed
                    if habit.isArchived {
                        ArchivedBadge()
                    }
                     */
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Modern action buttons (temporarily removed)
                /*
                HabitHeaderActionButtons(
                    habit: habit,
                    showEditSheet: $showEditSheet,
                    showArchiveAlert: $showArchiveAlert
                )
                 */
            }
            
            // Tags directly under the schedule, with no "Tags" title and no rectangle background
            // Make tags flexible to content (no maxWidth frame on the container)
            MinimalTagsRow(habit: habit)
        }
        .padding()
        .sheetGlassBackground()
        // Comment out archive alert and edit sheet for now
        /*
        .alert(isPresented: $showArchiveAlert) {
            Alert(
                title: Text(habit.isArchived ? "Unarchive Habit" : "Archive Habit"),
                message: Text(habit.isArchived ?
                              "This habit will be restored and available in your active habits." :
                                "This habit will be archived and removed from your active habits."),
                primaryButton: .destructive(Text(habit.isArchived ? "Unarchive" : "Archive")) {
                    toggleArchiveHabit(habit: habit, context: viewContext)
                },
                secondaryButton: .cancel()
            )
        }
        .sheet(isPresented: $showEditSheet) {
            EditHabitView(habit: habit)
                .environment(\.managedObjectContext, viewContext)
        }
        */
    }
}

struct HabitHeaderMainContent: View {
    @Environment(\.colorScheme) private var colorScheme
    let habit: Habit
    let streak: Int
    let habitColor: Color
    let showStreaks: Bool
    
    @State private var showEditSheet = false
    @State private var showArchiveAlert = false
    @State private var editButtonPressed = false
    @State private var archiveButtonPressed = false
    
    @Environment(\.managedObjectContext) private var viewContext
    
    private var habitIntensity: HabitIntensity {
        return HabitIntensity(rawValue: habit.intensityLevel) ?? .light
    }
    
    // Modern action buttons (temporarily removed)
    private var actionButtons: some View {
        VStack(spacing: 10) {
            /*
            // Edit button
            Button(action: {
                // ...
            }) {
                // ...
            }
            .buttonStyle(PlainButtonStyle())
            
            // Archive/Unarchive button
            Button(action: {
                // ...
            }) {
                // ...
            }
            .buttonStyle(PlainButtonStyle())
             */
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Icon using HabitIconView
            VStack(alignment: .leading, spacing: 6) {
                HabitIconView(
                    iconName: habit.icon,
                    isActive: true, // Always active in detail sheet
                    habitColor: habitColor,
                    streak: streak,
                    showStreaks: false,
                    useModernBadges: true, // You can customize this
                    isFutureDate: false, // Since this is for current habit detail
                    isBadHabit: habit.isBadHabit,
                    intensityLevel: habit.intensityLevel
                )
                .scaleEffect(1.85)
                .frame(width: 80, height: 80)
                
                // ScheduleLineView removed as requested
            }
            .frame(width: 80, alignment: .leading)
            
            // Center column with habit name and badges
            VStack(alignment: .leading, spacing: 6) {
                ScrollingText(
                    habit.name ?? "Unnamed Habit",
                    font: .customFont("Lexend", .bold, 24),
                    speed: 30,
                    fadeWidth: 20
                )
                .frame(height: 29)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, 2) // pulled slightly left
                .padding(.top, 3)
                
                if habit.isArchived {
                    ArchivedBadge()
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.trailing, 0)
            
            // Modern action buttons (hidden)
            actionButtons
        }
        // Comment out edit/archive presentations
        /*
        .sheet(isPresented: $showEditSheet) {
            EditHabitView(habit: habit)
                .environment(\.managedObjectContext, viewContext)
        }
        .alert("Archive Habit", isPresented: $showArchiveAlert) {
            Button("Cancel", role: .cancel) { }
            Button(habit.isArchived ? "Unarchive" : "Archive", role: habit.isArchived ? .none : .destructive) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    toggleArchiveHabit()
                }
            }
        } message: {
            Text(habit.isArchived ?
                "This will unarchive the habit and make it active again." :
                "This will archive the habit and hide it from your main list.")
        }
        */
    }
    
    // Helper function to toggle archive status
    func toggleArchiveHabit() {
        habit.isArchived.toggle()
        
        do {
            try viewContext.save()
            
            let successFeedback = UINotificationFeedbackGenerator()
            successFeedback.notificationOccurred(.success)
        } catch {
            let errorFeedback = UINotificationFeedbackGenerator()
            errorFeedback.notificationOccurred(.error)
            print("Failed to toggle archive status: \(error)")
        }
    }
}


// Subview for description
struct HabitDescriptionView: View {
    let description: String?
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Keep minimal, no header label
            Group {
                if let description = description, !description.isEmpty {
                    Text(description)
                        .font(.customFont("Lexend", .regular, 12))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("No description yet")
                        .font(.customFont("Lexend", .regular, 12))
                        .foregroundColor(.secondary.opacity(0.5))
                        .italic()
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(colorScheme == .dark ? Color.black.opacity(0.2) : Color.gray.opacity(0.05))
            )
        }
        .padding(.top, 2)
    }
}

// Minimal tags row: each tag is its own capsule (icon + value only)
struct MinimalTagsRow: View {
    let habit: Habit
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var showStartDatePopover = false
    @State private var showSchedulePopover = false
    @State private var showListPopover = false
    @State private var showCategoryPopover = false
    @State private var showIntensityPopover = false
    
    private var intensity: HabitIntensity {
        HabitIntensity(rawValue: habit.intensityLevel) ?? .light
    }
    
    private var scheduleText: String {
        UltraMinimalRepeatPatternView(habit: habit, date: Date()).shortPatternTextForUse
    }
    
    private var scheduleTextWithFrequency: String {
        let baseSchedule = UltraMinimalRepeatPatternView(habit: habit, date: Date()).shortPatternTextForUse
        let frequency = frequencyInfo.text
        return "\(baseSchedule) • \(frequency)"
    }
    
    private var frequencyInfo: (icon: String, text: String) {
        // Get the effective repeat pattern to access tracking type and values
        guard let repeatPattern = HabitUtilities.getEffectiveRepeatPattern(for: habit, on: Date()) else {
            return ("repeat", "1x")
        }
        
        // Determine tracking type - check the pattern's properties to infer the type
        if repeatPattern.duration > 0 {
            // Duration tracking
            let minutes = Int(repeatPattern.duration)
            if minutes >= 60 {
                let hours = minutes / 60
                let remainingMinutes = minutes % 60
                if remainingMinutes == 0 {
                    return ("clock", "\(hours)h")
                } else {
                    return ("clock", "\(hours)h \(remainingMinutes)m")
                }
            } else {
                return ("clock", "\(minutes)m")
            }
        } else if repeatPattern.targetQuantity > 0 {
            // Quantity tracking
            let quantity = Int(repeatPattern.targetQuantity)
            let unit = repeatPattern.quantityUnit ?? "items"
            return ("number", "\(quantity) \(unit)")
        } else {
            // Repetitions tracking (default)
            let times = Int(repeatPattern.repeatsPerDay)
            return ("repeat", times == 1 ? "1x" : "\(times)x")
        }
    }
    
    private var categoryName: String? {
        habit.category?.name?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? habit.category?.name : nil
    }
    
    private var listName: String? {
        habit.habitList?.name?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? habit.habitList?.name : nil
    }
    
    private var listColor: Color {
        if let data = habit.habitList?.color,
           let ui = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data) {
            return Color(ui)
        }
        return .secondary
    }
    
    private var listIcon: String {
        if let icon = habit.habitList?.icon, !icon.isEmpty {
            return icon
        }
        return "tray.full"
    }
    
    private var categoryIcon: String {
        if let icon = habit.category?.icon, !icon.isEmpty {
            return icon
        }
        return "square.grid.2x2"
    }
    
    var body: some View {
        // Scrollable horizontal tags list
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // 1) Start date tag first (always show) - now clickable
                Button(action: { showStartDatePopover = true }) {
                    StartDateTag(habit: habit, colorScheme: colorScheme)
                }
                .buttonStyle(PlainButtonStyle())
                .popover(isPresented: $showStartDatePopover) {
                    StartDatePopoverView(habit: habit)
                        .presentationCompactAdaptation(.popover)
                }
                
                // 2) Schedule tag (separate from frequency info) - clickable
                Button(action: { showSchedulePopover = true }) {
                    ScheduleTag(value: scheduleText, colorScheme: colorScheme)
                }
                .buttonStyle(PlainButtonStyle())
                .popover(isPresented: $showSchedulePopover) {
                    RepeatPatternPopoverView(habit: habit)
                        .presentationCompactAdaptation(.popover)
                }
                
                TagSeparator(colorScheme: colorScheme)
                    .padding(.horizontal, 2)
                
                // 3) List capsule (if available): show list icon with list color; no dot
                if let listName {
                    Button(action: { showListPopover = true }) {
                        TagCapsule(
                            icon: listIcon,
                            dotColor: .clear,
                            value: listName,
                            strokeColor: listColor.opacity(0.15),
                            colorScheme: colorScheme,
                            showDot: false,
                            iconTint: listColor
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .popover(isPresented: $showListPopover) {
                        ListPopoverView(habitList: habit.habitList!)
                            .presentationCompactAdaptation(.popover)
                    }
                }
                
                // 4) Category capsule (if available): icon only (system tint), no dot
                if let categoryName {
                    Button(action: { showCategoryPopover = true }) {
                        TagCapsule(
                            icon: categoryIcon,
                            dotColor: .clear,
                            value: categoryName,
                            strokeColor: Color.secondary.opacity(0.15),
                            colorScheme: colorScheme,
                            showDot: false,
                            iconTint: .primary.opacity(0.75)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .popover(isPresented: $showCategoryPopover) {
                        CategoryPopoverView(category: habit.category!)
                            .presentationCompactAdaptation(.popover)
                    }
                }
                
                // 5) Intensity capsule (icon changed from flame to gauge)
                Button(action: { showIntensityPopover = true }) {
                    TagCapsule(
                        icon: "gauge",
                        dotColor: intensity.color,
                        value: intensity.title,
                        strokeColor: intensity.color.opacity(0.25),
                        colorScheme: colorScheme,
                        showDot: true,
                        iconTint: .primary.opacity(0.75)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .popover(isPresented: $showIntensityPopover) {
                    IntensityPopoverView(intensity: intensity)
                        .presentationCompactAdaptation(.popover)
                }
            }
            .padding(.horizontal, 12)
        }
        .padding(.bottom, 2)
    }
}

// A distinctive schedule tag for the tags row
private struct ScheduleTag: View {
    let value: String
    let colorScheme: ColorScheme
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "calendar")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.primary.opacity(0.7))
            
            Text(value)
                .font(.customFont("Lexend", .medium, 11))
                .foregroundColor(.primary.opacity(0.85))
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.035))
                .overlay(
                    Capsule()
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.primary.opacity(0.2),
                                    Color.primary.opacity(0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .accessibilityLabel("Schedule: \(value)")
    }
}

// Start date tag for the tags row
private struct StartDateTag: View {
    let habit: Habit
    let colorScheme: ColorScheme
    
    private var formattedStartDate: String {
        guard let startDate = habit.startDate else {
            return "Not set"
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter.string(from: startDate)
    }
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "flag.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
            
            Text(formattedStartDate)
                .font(.customFont("Lexend", .medium, 11))
                .foregroundColor(.primary)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.035))
                .overlay(
                    Capsule()
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.primary.opacity(0.2),
                                    Color.primary.opacity(0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .accessibilityLabel("Started: \(formattedStartDate)")
    }
}


// Playful start date badge that shows when the habit was "born"
private struct HabitBirthdayBadge: View {
    let startDate: Date?
    let colorScheme: ColorScheme
    
    private var ageInfo: (icon: String, text: String, color: Color) {
        guard let startDate = startDate else {
            return ("calendar.badge.plus", "New", .blue)
        }
        
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day, .weekOfYear, .month, .year], from: startDate, to: now)
        
        if let years = components.year, years > 0 {
            return ("birthday.cake", "\(years)y old", .orange)
        } else if let months = components.month, months > 0 {
            return ("calendar.badge.clock", "\(months)mo old", .green)
        } else if let weeks = components.weekOfYear, weeks > 0 {
            return ("calendar", "\(weeks)w old", .blue)
        } else if let days = components.day, days > 0 {
            return ("sunrise", "\(days)d old", .yellow)
        } else {
            return ("sparkles", "Today!", .pink)
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: ageInfo.icon)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(ageInfo.color)
            
            Text(ageInfo.text)
                .font(.customFont("Lexend", .semibold, 9))
                .foregroundColor(.primary.opacity(0.8))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.05))
                .overlay(
                    Capsule()
                        .strokeBorder(ageInfo.color.opacity(0.3), lineWidth: 1)
                )
        )
        .accessibilityLabel("Habit started: \(ageInfo.text)")
    }
}

// A subtle vertical separator to make the schedule tag stand out
private struct TagSeparator: View {
    let colorScheme: ColorScheme
    
    var body: some View {
        Rectangle()
            .fill((colorScheme == .dark ? Color.white : Color.black).opacity(0.08))
            .frame(width: 1, height: 18)
            .overlay(
                Rectangle()
                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
            )
            .cornerRadius(0.5)
    }
}

// Reusable tag capsule styled like HabitListBadge (no label prefix)
// Updated: supports optional dot and custom icon tint; slightly smaller overall size
private struct TagCapsule: View {
    let icon: String
    let dotColor: Color
    let value: String
    let strokeColor: Color
    let colorScheme: ColorScheme
    var showDot: Bool = true
    var iconTint: Color = .primary.opacity(0.75)
    
    var body: some View {
        HStack(spacing: 6) {
            // Icon first (can be tinted with list color)
            Image(systemName: icon)
                .font(.system(size: 10.5, weight: .medium))
                .foregroundColor(iconTint)
            
            // Optional small colored dot
            if showDot {
                Circle()
                    .fill(dotColor)
                    .frame(width: 5, height: 5)
            }
            
            // Value
            Text(value)
                .font(.customFont("Lexend", .medium, 11))
                .foregroundColor(.primary.opacity(0.82))
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(colorScheme == .dark ? Color.white.opacity(0.07) : Color.black.opacity(0.035))
                .overlay(
                    Capsule()
                        .strokeBorder(strokeColor, lineWidth: 1)
                )
        )
        // No maxWidth frame; sizes intrinsically to content
    }
}

// Helper to access shortPatternText without UI (reuse logic from UltraMinimalRepeatPatternView)
private extension UltraMinimalRepeatPatternView {
    /*
    var shortPatternTextForUse: String {
        guard let repeatPattern = HabitUtilities.getEffectiveRepeatPattern(for: habit, on: date) else {
            return "Not scheduled"
        }
        
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
        
        if let weeklyGoal = repeatPattern.weeklyGoal {
            return weeklyGoal.everyWeek ? "Weekly" : "Every \(weeklyGoal.weekInterval)w"
        }
        
        if let monthlyGoal = repeatPattern.monthlyGoal {
            return monthlyGoal.everyMonth ? "Monthly" : "Every \(monthlyGoal.monthInterval)m"
        }
        
        return "Custom"
    }
     */
}

// Simple non-scrollable layout for tags
struct FlexibleTagRow<Content: View>: View {
    @ViewBuilder let content: Content
    
    var body: some View {
        // Replaced ScrollView with plain HStack per request
        HStack(spacing: 8) {
            content
        }
    }
}

// Category chip
struct CategoryChip: View {
    let category: HabitCategory
    @Environment(\.colorScheme) private var colorScheme
    
    private var color: Color {
        if let data = category.color,
           let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data) {
            return Color(uiColor)
        }
        return .secondary
    }
    
    var body: some View {
        HStack(spacing: 6) {
            if let icon = category.icon, !icon.isEmpty {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(color)
            }
            Text(category.name ?? "Category")
                .font(.customFont("Lexend", .medium, 11))
                .foregroundColor(.primary.opacity(0.8))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04))
                .overlay(
                    Capsule()
                        .strokeBorder(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// Placeholder when no category is set
struct CategoryChipPlaceholder: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
            Text("No Category")
                .font(.customFont("Lexend", .medium, 11))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.03))
                .overlay(
                    Capsule()
                        .strokeBorder(Color.secondary.opacity(0.15), lineWidth: 1)
                )
        )
    }
}

// Difficulty/Intensity chip
struct DifficultyChip: View {
    let intensity: HabitIntensity
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "gauge")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(intensity.color)
            Text(intensity.title)
                .font(.customFont("Lexend", .medium, 11))
                .foregroundColor(.primary.opacity(0.85))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04))
                .overlay(
                    Capsule()
                        .strokeBorder(intensity.color.opacity(0.25), lineWidth: 1)
                )
        )
    }
}

// Subview for habit list badge
struct HabitListBadge: View {
    let habitList: HabitList
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var listColor: Color {
        habitList.color != nil ? (Color(data: habitList.color!) ?? .secondary) : .secondary
    }
    
    var body: some View {
        HStack(spacing: 8) {
            // Minimal colored indicator
            Circle()
                .fill(listColor)
                .frame(width: 8, height: 8)
            
            // List name with modern typography
            Text(habitList.name ?? "Unnamed List")
                .font(.customFont("Lexend", .medium, 12))
                .foregroundColor(.primary.opacity(0.7))
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(colorScheme == .dark ?
                    Color.white.opacity(0.08) :
                    Color.black.opacity(0.04))
                .overlay(
                    Capsule()
                        .strokeBorder(
                            listColor.opacity(0.15),
                            lineWidth: 1
                        )
                )
        )
    }
}

// Alternative even more minimal version
struct MinimalHabitListBadge: View {
    let habitList: HabitList
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var listColor: Color {
        habitList.color != nil ? (Color(data: habitList.color!) ?? .secondary) : .secondary
    }
    
    var body: some View {
        HStack(spacing: 6) {
            // Small colored dot
            Circle()
                .fill(listColor)
                .frame(width: 6, height: 6)
            
            // List name
            Text(habitList.name ?? "Unnamed List")
                .font(.customFont("Lexend", .regular, 11))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
    }
}

// Glass morphism version for premium feel
struct GlassHabitListBadge: View {
    let habitList: HabitList
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var listColor: Color {
        habitList.color != nil ? (Color(data: habitList.color!) ?? .secondary) : .secondary
    }
    
    var body: some View {
        HStack(spacing: 8) {
            // Glass circle with colored border
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .strokeBorder(listColor, lineWidth: 1.5)
                )
            
            // List name
            Text(habitList.name ?? "Unnamed List")
                .font(.customFont("Lexend", .medium, 11))
                .foregroundColor(.primary.opacity(0.8))
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .strokeBorder(
                        LinearGradient(
                                colors: [
                                    Color.white.opacity(colorScheme == .dark ? 0.1 : 0.3),
                                    listColor.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
}

// Subview for habit type badge
struct HabitTypeBadge: View {
    let isBadHabit: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: isBadHabit ? "xmark.circle.fill" : "checkmark.circle.fill")
                .foregroundColor(isBadHabit ? .red : .green)
                .font(.system(size: 10))
            
            Text(isBadHabit ? "Bad Habit" : "Good Habit")
                .font(.system(size: 10, weight: .semibold))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(isBadHabit ? Color.red.opacity(0.15) : Color.green.opacity(0.15))
                .overlay(
                    Capsule()
                        .strokeBorder(isBadHabit ? Color.red.opacity(0.2) : Color.green.opacity(0.2), lineWidth: 1)
                )
        )
        .foregroundColor(isBadHabit ? .red : .green)
    }
}

// Subview for archived badge
struct ArchivedBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "archivebox.fill")
                .foregroundColor(.gray)
                .font(.system(size: 10))
            
            Text("Archived")
                .font(.system(size: 10, weight: .semibold))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.gray.opacity(0.15))
                .overlay(
                    Capsule()
                        .strokeBorder(Color.gray.opacity(0.2), lineWidth: 1)
                )
        )
        .foregroundColor(.gray)
    }
}

// Extension to handle Color initialization from Data
extension Color {
    init?(data: Data) {
        guard let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data) else {
            return nil
        }
        self.init(uiColor)
    }
}

// A compact, non-capsule schedule line that fits under the habit icon
// (Kept here for potential reuse elsewhere, but not used in header anymore)
private struct ScheduleLineView: View {
    let habit: Habit
    let date: Date
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var shortText: String {
        UltraMinimalRepeatPatternView(habit: habit, date: date).shortPatternTextForUse
    }
    
    private var iconName: String {
        // Mirror MinimalRepeatPattern’s icon logic in a compact way
        guard let repeatPattern = HabitUtilities.getEffectiveRepeatPattern(for: habit, on: date) else {
            return "calendar"
        }
        if let daily = repeatPattern.dailyGoal {
            return daily.everyDay ? "repeat.1" : "calendar"
        }
        if repeatPattern.weeklyGoal != nil { return "calendar.badge.clock" }
        if repeatPattern.monthlyGoal != nil { return "calendar.badge.plus" }
        return "calendar"
    }
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: iconName)
                .font(.system(size: 10.5, weight: .semibold))
                .foregroundColor(.secondary.opacity(0.85))
            
            Text(shortText)
                .font(.customFont("Lexend", .medium, 10.5))
                .foregroundColor(.primary.opacity(0.9))
                .lineLimit(1)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.035))
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.12), lineWidth: 0.75)
                )
        )
        // No maxWidth here to keep intrinsic width when used elsewhere
    }
}

// MARK: - Popover Views

struct StartDatePopoverView: View {
    let habit: Habit
    @Environment(\.colorScheme) private var colorScheme
    
    private var startDateInfo: (date: String, daysAgo: String, description: String) {
        guard let startDate = habit.startDate else {
            return ("Not set", "New habit", "No start date has been set for this habit")
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        let formattedDate = formatter.string(from: startDate)
        
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day], from: startDate, to: now)
        let days = components.day ?? 0
        
        let daysText = days == 0 ? "Started today" : 
                      days == 1 ? "1 day ago" : 
                      "\(days) days ago"
        
        let description = days == 0 ? "This habit was started today" :
                         days < 7 ? "Started less than a week ago" :
                         days < 30 ? "Started \(days / 7) week\(days / 7 == 1 ? "" : "s") ago" :
                         days < 365 ? "Started about \(days / 30) month\(days / 30 == 1 ? "" : "s") ago" :
                         "Started over a year ago"
        
        return (formattedDate, daysText, description)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 10) {
                Image(systemName: "flag.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.green)
                    .frame(width: 24, height: 24)
                
                Text("Start Date")
                    .font(.customFont("Lexend", .bold, 16))
                    .foregroundColor(.primary)
            }
            
            Divider()
                .opacity(0.6)
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                Text(startDateInfo.date)
                    .font(.customFont("Lexend", .bold, 18))
                    .foregroundColor(.green)
                
                Text(startDateInfo.daysAgo)
                    .font(.customFont("Lexend", .semibold, 14))
                    .foregroundColor(.primary)
                
                Text(startDateInfo.description)
                    .font(.customFont("Lexend", .regular, 12))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Motivation section
            if let startDate = habit.startDate, startDate <= Date() {
                Divider()
                    .opacity(0.3)
                
                HStack(spacing: 6) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.pink)
                    
                    Text("Keep building your streak!")
                        .font(.customFont("Lexend", .regular, 11))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .frame(width: 260)
        .modernGlassPopoverBackground()
    }
}

struct RepeatPatternPopoverView: View {
    let habit: Habit
    @Environment(\.colorScheme) private var colorScheme
    
    private var repeatPatternInfo: (title: String, description: String, icon: String, details: String) {
        guard let repeatPattern = HabitUtilities.getEffectiveRepeatPattern(for: habit, on: Date()) else {
            return ("Not Scheduled", "This habit has no active schedule", "calendar.badge.exclamationmark", "Set up a schedule to track this habit regularly")
        }
        
        if let dailyGoal = repeatPattern.dailyGoal {
            if dailyGoal.everyDay {
                let reps = repeatPattern.repeatsPerDay
                let repsText = reps > 1 ? "\(reps) times per day" : "Once per day"
                return ("Daily Habit", 
                       "Every day",
                       "repeat.1",
                       "Target: \(repsText)")
            } else if dailyGoal.daysInterval > 0 {
                return ("Interval Schedule", 
                       "Every \(dailyGoal.daysInterval) days",
                       "calendar.day.timeline.right",
                       "Regular interval-based habit")
            } else if let specificDays = dailyGoal.specificDays as? [Bool] {
                let weekCount = specificDays.count / 7
                if weekCount > 1 {
                    return ("Multi-Week Pattern", 
                           "\(weekCount) week rotation",
                           "arrow.triangle.2.circlepath",
                           "Complex weekly pattern with specific days")
                } else {
                    let selectedCount = specificDays.filter { $0 }.count
                    let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
                    let activeDays = specificDays.enumerated().compactMap { index, isActive in
                        isActive ? dayNames[index] : nil
                    }.joined(separator: ", ")
                    return ("Weekly Schedule", 
                           "\(selectedCount) days per week",
                           "calendar.badge.clock",
                           "Active days: \(activeDays)")
                }
            }
        }
        
        if let weeklyGoal = repeatPattern.weeklyGoal {
            return weeklyGoal.everyWeek ? 
                ("Weekly Habit", "Once per week", "calendar", "Weekly commitment") :
                ("Multi-Week Schedule", "Every \(weeklyGoal.weekInterval) weeks", "calendar", "Longer interval pattern")
        }
        
        if let monthlyGoal = repeatPattern.monthlyGoal {
            return monthlyGoal.everyMonth ?
                ("Monthly Habit", "Once per month", "calendar", "Monthly commitment") :
                ("Multi-Month Schedule", "Every \(monthlyGoal.monthInterval) months", "calendar", "Extended monthly pattern")
        }
        
        return ("Custom Schedule", "Custom repeat pattern", "calendar.badge.plus", "Personalized scheduling")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 10) {
                Image(systemName: repeatPatternInfo.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 24, height: 24)
                
                Text("Repeat Pattern")
                    .font(.customFont("Lexend", .bold, 16))
                    .foregroundColor(.primary)
            }
            
            Divider()
                .opacity(0.6)
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                Text(repeatPatternInfo.title)
                    .font(.customFont("Lexend", .semibold, 14))
                    .foregroundColor(.primary)
                
                Text(repeatPatternInfo.description)
                    .font(.customFont("Lexend", .bold, 16))
                    .foregroundColor(.blue)
                
                Text(repeatPatternInfo.details)
                    .font(.customFont("Lexend", .regular, 12))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Additional scheduling info
            Divider()
                .opacity(0.3)
            
            HStack(spacing: 6) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                
                Text("Helps maintain consistency")
                    .font(.customFont("Lexend", .regular, 11))
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .frame(width: 280)
        .modernGlassPopoverBackground()
    }
}

struct SchedulePopoverView: View {
    let habit: Habit
    @Environment(\.colorScheme) private var colorScheme
    
    private var detailedScheduleInfo: (title: String, description: String, icon: String) {
        guard let repeatPattern = HabitUtilities.getEffectiveRepeatPattern(for: habit, on: Date()) else {
            return ("Not Scheduled", "This habit has no active schedule", "calendar.badge.exclamationmark")
        }
        
        if let dailyGoal = repeatPattern.dailyGoal {
            if dailyGoal.everyDay {
                let reps = repeatPattern.repeatsPerDay
                return ("Daily Habit", 
                       reps > 1 ? "Repeats \(reps) times every day" : "Once every day",
                       "repeat.1")
            } else if dailyGoal.daysInterval > 0 {
                return ("Interval Schedule", 
                       "Repeats every \(dailyGoal.daysInterval) days",
                       "calendar")
            } else if let specificDays = dailyGoal.specificDays as? [Bool] {
                let weekCount = specificDays.count / 7
                if weekCount > 1 {
                    return ("Weekly Rotation", 
                           "\(weekCount) week pattern with custom days",
                           "arrow.triangle.2.circlepath")
                } else {
                    let selectedCount = specificDays.filter { $0 }.count
                    let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
                    let activeDays = specificDays.enumerated().compactMap { index, isActive in
                        isActive ? dayNames[index] : nil
                    }.joined(separator: ", ")
                    return ("Weekly Schedule", 
                           "\(selectedCount) days per week: \(activeDays)",
                           "calendar.badge.clock")
                }
            }
        }
        
        if let weeklyGoal = repeatPattern.weeklyGoal {
            return weeklyGoal.everyWeek ? 
                ("Weekly Habit", "Once every week", "calendar") :
                ("Multi-Week Schedule", "Every \(weeklyGoal.weekInterval) weeks", "calendar")
        }
        
        if let monthlyGoal = repeatPattern.monthlyGoal {
            return monthlyGoal.everyMonth ?
                ("Monthly Habit", "Once every month", "calendar") :
                ("Multi-Month Schedule", "Every \(monthlyGoal.monthInterval) months", "calendar")
        }
        
        return ("Custom Schedule", "Custom repeat pattern", "calendar.badge.plus")
    }
    
    private var frequencyInfo: (icon: String, text: String, description: String) {
        guard let repeatPattern = HabitUtilities.getEffectiveRepeatPattern(for: habit, on: Date()) else {
            return ("repeat", "1x", "Simple completion")
        }
        
        if repeatPattern.duration > 0 {
            let minutes = Int(repeatPattern.duration)
            if minutes >= 60 {
                let hours = minutes / 60
                let remainingMinutes = minutes % 60
                let timeText = remainingMinutes == 0 ? "\(hours)h" : "\(hours)h \(remainingMinutes)m"
                return ("clock.fill", timeText, "Duration-based tracking")
            } else {
                return ("clock.fill", "\(minutes)m", "Duration-based tracking")
            }
        } else if repeatPattern.targetQuantity > 0 {
            let quantity = Int(repeatPattern.targetQuantity)
            let unit = repeatPattern.quantityUnit ?? "items"
            return ("number.square.fill", "\(quantity) \(unit)", "Quantity-based tracking")
        } else {
            let times = Int(repeatPattern.repeatsPerDay)
            return ("repeat", times == 1 ? "Once" : "\(times) times", "Simple completion tracking")
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 10) {
                Image(systemName: detailedScheduleInfo.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 24, height: 24)
                
                Text("Schedule")
                    .font(.customFont("Lexend", .bold, 16))
                    .foregroundColor(.primary)
            }
            
            Divider()
                .opacity(0.6)
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                Text(detailedScheduleInfo.title)
                    .font(.customFont("Lexend", .semibold, 14))
                    .foregroundColor(.primary)
                
                Text(detailedScheduleInfo.description)
                    .font(.customFont("Lexend", .regular, 12))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Frequency/Target info
            Divider()
                .opacity(0.3)
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: frequencyInfo.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.blue)
                        .frame(width: 16, height: 16)
                    
                    Text("Target: \(frequencyInfo.text)")
                        .font(.customFont("Lexend", .semibold, 12))
                        .foregroundColor(.primary)
                }
                
                Text(frequencyInfo.description)
                    .font(.customFont("Lexend", .regular, 11))
                    .foregroundColor(.secondary)
                    .padding(.leading, 24)
            }
            
            // Start date info if available
            if let startDate = habit.startDate {
                Divider()
                    .opacity(0.3)
                
                HStack(spacing: 6) {
                    Image(systemName: "flag.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.green)
                    
                    Text("Started: \(startDate, style: .date)")
                        .font(.customFont("Lexend", .regular, 11))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .frame(width: 280)
        .modernGlassPopoverBackground()
    }
}

struct FrequencyPopoverView: View {
    let habit: Habit
    @Environment(\.colorScheme) private var colorScheme
    
    private var frequencyInfo: (title: String, description: String, icon: String, value: String) {
        guard let repeatPattern = HabitUtilities.getEffectiveRepeatPattern(for: habit, on: Date()) else {
            return ("No Target", "No frequency set", "questionmark", "Not set")
        }
        
        if repeatPattern.duration > 0 {
            let minutes = Int(repeatPattern.duration)
            let value = minutes >= 60 ? 
                "\(minutes / 60)h \(minutes % 60 == 0 ? "" : "\(minutes % 60)m")" :
                "\(minutes)m"
            return ("Duration Target", 
                   "Time-based habit tracking",
                   "clock.fill", 
                   value.trimmingCharacters(in: .whitespaces))
        } else if repeatPattern.targetQuantity > 0 {
            let quantity = Int(repeatPattern.targetQuantity)
            let unit = repeatPattern.quantityUnit ?? "items"
            return ("Quantity Target",
                   "Amount-based habit tracking",
                   "number.square.fill",
                   "\(quantity) \(unit)")
        } else {
            let times = Int(repeatPattern.repeatsPerDay)
            return ("Repetition Target",
                   "Simple completion tracking",
                   "repeat",
                   times == 1 ? "Once" : "\(times) times")
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 10) {
                Image(systemName: frequencyInfo.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.blue)
                    .frame(width: 24, height: 24)
                
                Text("Target")
                    .font(.customFont("Lexend", .bold, 16))
                    .foregroundColor(.primary)
            }
            
            Divider()
                .opacity(0.6)
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                Text(frequencyInfo.title)
                    .font(.customFont("Lexend", .semibold, 14))
                    .foregroundColor(.primary)
                
                Text(frequencyInfo.value)
                    .font(.customFont("Lexend", .bold, 20))
                    .foregroundColor(.blue)
                
                Text(frequencyInfo.description)
                    .font(.customFont("Lexend", .regular, 12))
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .frame(width: 240)
        .modernGlassPopoverBackground()
    }
}

struct ListPopoverView: View {
    let habitList: HabitList
    @Environment(\.colorScheme) private var colorScheme
    
    private var listColor: Color {
        if let data = habitList.color,
           let ui = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data) {
            return Color(ui)
        }
        return .secondary
    }
    
    private var listIcon: String {
        habitList.icon?.isEmpty == false ? habitList.icon! : "tray.full"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with list color
            HStack(spacing: 10) {
                Image(systemName: listIcon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(listColor)
                    .frame(width: 24, height: 24)
                
                Text("List")
                    .font(.customFont("Lexend", .bold, 16))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Circle()
                    .fill(listColor)
                    .frame(width: 12, height: 12)
            }
            
            Divider()
                .opacity(0.6)
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                Text(habitList.name ?? "Unnamed List")
                    .font(.customFont("Lexend", .semibold, 14))
                    .foregroundColor(.primary)
                /*
                if let description = habitList.habitDescription, !description.isEmpty {
                    Text(description)
                        .font(.customFont("Lexend", .regular, 12))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("No description")
                        .font(.customFont("Lexend", .regular, 12))
                        .foregroundColor(.secondary.opacity(0.6))
                        .italic()
                }
                 */
            }
            
            // Additional info
            Divider()
                .opacity(0.3)
            
            HStack(spacing: 6) {
                Image(systemName: "number")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                
                Text("List organization")
                    .font(.customFont("Lexend", .regular, 11))
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .frame(width: 260)
        .modernGlassPopoverBackground()
    }
}

struct CategoryPopoverView: View {
    let category: HabitCategory
    @Environment(\.colorScheme) private var colorScheme
    
    private var categoryColor: Color {
        if let data = category.color,
           let ui = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data) {
            return Color(ui)
        }
        return .secondary
    }
    
    private var categoryIcon: String {
        category.icon?.isEmpty == false ? category.icon! : "square.grid.2x2"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with category color
            HStack(spacing: 10) {
                Image(systemName: categoryIcon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(categoryColor)
                    .frame(width: 24, height: 24)
                
                Text("Category")
                    .font(.customFont("Lexend", .bold, 16))
                    .foregroundColor(.primary)
                
                Spacer()
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(categoryColor)
                    .frame(width: 16, height: 12)
            }
            
            Divider()
                .opacity(0.6)
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                Text(category.name ?? "Unnamed Category")
                    .font(.customFont("Lexend", .semibold, 14))
                    .foregroundColor(.primary)
                /*
                if let description = category.habitDescription, !description.isEmpty {
                    Text(description)
                        .font(.customFont("Lexend", .regular, 12))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("No description")
                        .font(.customFont("Lexend", .regular, 12))
                        .foregroundColor(.secondary.opacity(0.6))
                        .italic()
                }
                 */
            }
            
            // Additional info
            Divider()
                .opacity(0.3)
            
            HStack(spacing: 6) {
                Image(systemName: "tag.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                
                Text("Habit categorization")
                    .font(.customFont("Lexend", .regular, 11))
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .frame(width: 260)
        .modernGlassPopoverBackground()
    }
}

struct IntensityPopoverView: View {
    let intensity: HabitIntensity
    @Environment(\.colorScheme) private var colorScheme
    
    private var intensityDetails: (description: String, tips: String) {
        switch intensity {
        case .light:
            return (
                "Low intensity: easy to maintain with minimal effort. Ideal for beginners or when consistency matters more than intensity. The focus is on creating a positive feedback loop and steady progress.",
                "Start small and focus on consistency rather than results. Avoid overcommitting early. Celebrate small wins to reinforce the habit and build confidence."
            )

        case .moderate:
            return (
                "Moderate intensity: requires regular attention and steady commitment. Balances challenge with sustainability, allowing meaningful progress without overwhelming demands.",
                "Establish a structured routine that fits your lifestyle. Use reminders or scheduling to maintain consistency. Periodically assess your progress and adjust difficulty if things feel too easy or too hard."
            )

        case .high:
            return (
                "High intensity: demands strong discipline and mental focus. Suitable for users with prior experience in habit formation or those pursuing ambitious goals. Expect noticeable fatigue or friction as part of the process.",
                "Prioritize recovery and balance to avoid burnout. Break large goals into manageable segments. Use accountability methods — such as progress tracking or partner check-ins — to stay motivated through difficult phases."
            )

        case .extreme:
            return (
                "Extreme intensity: maximal effort and total dedication required. This level pushes physical, mental, or emotional limits and is not sustainable long-term. It’s intended for short bursts of peak performance or major life transformations.",
                "Plan strategically: ensure proper rest, nutrition, and mental recovery. Avoid sustaining this level indefinitely — use it for limited, high-impact goals. Monitor stress and well-being closely, and be ready to taper down intensity when signs of burnout appear."
            )
        }
    }

    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with intensity color
            HStack(spacing: 10) {
                Image(systemName: "gauge")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(intensity.color)
                    .frame(width: 24, height: 24)
                
                Text("Intensity")
                    .font(.customFont("Lexend", .bold, 16))
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Visual intensity indicator
                HStack(spacing: 3) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(index < intensity.rawValue ? intensity.color : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
            }
            
            Divider()
                .opacity(0.6)
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                Text(intensity.title)
                    .font(.customFont("Lexend", .semibold, 14))
                    .foregroundColor(.primary)
                
                Text(intensityDetails.description)
                    .font(.customFont("Lexend", .regular, 12))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Tips section
            Divider()
                .opacity(0.3)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.yellow)
                    
                    Text("Tip")
                        .font(.customFont("Lexend", .semibold, 11))
                        .foregroundColor(.primary)
                }
                
                Text(intensityDetails.tips)
                    .font(.customFont("Lexend", .regular, 11))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(width: 280)
        .modernGlassPopoverBackground()
    }
}

// MARK: - Preview for the HabitHeaderView
struct HabitHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Create a sample habit for preview
            HabitHeaderView(habit: createSampleHabit(), showStreaks: true)
                .padding()
                .previewDisplayName("Light Mode")
            
            HabitHeaderView(habit: createSampleHabit(), showStreaks: true)
                .padding()
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
            
            // Bad habit example
            HabitHeaderView(habit: createBadHabit(), showStreaks: true)
                .padding()
                .previewDisplayName("Bad Habit")
        }
    }
    
    // Helper to create a sample habit for preview
    static func createSampleHabit() -> Habit {
        let context = PersistenceController.preview.container.viewContext
        
        let habit = Habit(context: context)
        habit.id = UUID()
        habit.name = "Morning medsfsddsd"
        habit.habitDescription = "Start each day with 10 minutes of mindfulness meditation to improve focus and reduce stress."
        habit.startDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())
        habit.icon = "brain.head.profile"
        habit.isBadHabit = false
        habit.intensityLevel = 1
        if let colorData = try? NSKeyedArchiver.archivedData(withRootObject: UIColor.blue, requiringSecureCoding: false) {
            habit.color = colorData
        }
        
        // Create a list for the habit
        let list = HabitList(context: context)
        list.id = UUID()
        list.name = "Wellness"
        list.icon = "heart.fill"
        if let colorData = try? NSKeyedArchiver.archivedData(withRootObject: UIColor.green, requiringSecureCoding: false) {
            list.color = colorData
        }
        habit.habitList = list
        
        // Create a category for preview
        let category = HabitCategory(context: context)
        category.id = UUID()
        category.name = "Health"
        category.icon = "heart.fill"
        if let colorData = try? NSKeyedArchiver.archivedData(withRootObject: UIColor.systemRed, requiringSecureCoding: false) {
            category.color = colorData
        }
        habit.category = category
        
        return habit
    }
    
    // Helper to create a sample bad habit for preview
    static func createBadHabit() -> Habit {
        let context = PersistenceController.preview.container.viewContext
        
        let habit = Habit(context: context)
        habit.id = UUID()
        habit.name = "Late Night Snacking"
        habit.habitDescription = "Avoiding food after 8pm to improve sleep quality and digestion."
        habit.startDate = Calendar.current.date(byAdding: .day, value: -15, to: Date())
        habit.icon = "moon.zzz.fill"
        habit.isBadHabit = true
        if let colorData = try? NSKeyedArchiver.archivedData(withRootObject: UIColor.red, requiringSecureCoding: false) {
            habit.color = colorData
        }
        habit.intensityLevel = 3
        return habit
    }
}

struct HabitStartDateView: View {
    let startDate: Date?
    let formatDate: (Date?) -> String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "calendar")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                
            Text(formatDate(startDate))
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.primary.opacity(0.8))
        }
        //.padding(8)
    }
}

// MARK: - Glass Effect Extensions for Popovers
extension View {
    /// Applies a modern glass background effect optimized for popovers
    /// Uses iOS 26+ Liquid Glass effects with fallback to ultraThinMaterial
    /// - Parameters:
    ///   - cornerRadius: The corner radius for the glass effect (default: 12)
    ///   - tintColor: Optional color tint for the glass effect
    ///   - interactiveGlass: Enable interactive glass effect on supported iOS versions (default: false)
    /// - Returns: A view with the modern glass popover background applied
    func modernGlassPopoverBackground(
        cornerRadius: CGFloat = 12,
        tintColor: Color? = nil,
        interactiveGlass: Bool = false
    ) -> some View {
        modifier(ModernGlassPopoverModifier(
            cornerRadius: cornerRadius,
            tintColor: tintColor,
            interactiveGlass: interactiveGlass
        ))
    }
}

// MARK: - Modern Glass Popover Modifier
struct ModernGlassPopoverModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    
    let cornerRadius: CGFloat
    let tintColor: Color?
    let interactiveGlass: Bool
    
    init(cornerRadius: CGFloat = 12, tintColor: Color? = nil, interactiveGlass: Bool = false) {
        self.cornerRadius = cornerRadius
        self.tintColor = tintColor
        self.interactiveGlass = interactiveGlass
    }
    
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            // iOS 26+ uses glassEffect modifier with basic configuration
            if let tintColor = tintColor {
                content
                    .glassEffect(
                        in: .rect(cornerRadius: cornerRadius, style: .continuous)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(tintColor.opacity(0.1))
                    )
            } else {
                content
                    .glassEffect(
                        in: .rect(cornerRadius: cornerRadius, style: .continuous)
                    )
            }
        } else {
            // Fallback for iOS < 26 - Enhanced ultraThinMaterial with glassmorphism styling
            content
                .background(
                    ZStack {
                        // Base glass material
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(.ultraThinMaterial)
                        
                        // Optional color tint overlay
                        if let tintColor = tintColor {
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .fill(
                                    tintColor.opacity(colorScheme == .dark ? 0.1 : 0.15)
                                )
                        }
                        
                        // Glass highlight effect
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(colorScheme == .dark ? 0.15 : 0.4),
                                        Color.clear,
                                        Color.black.opacity(colorScheme == .dark ? 0.15 : 0.02)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .blendMode(.overlay)
                        
                        // Subtle border for definition
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(colorScheme == .dark ? 0.3 : 0.5),
                                        Color.white.opacity(colorScheme == .dark ? 0.08 : 0.15),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.5
                            )
                    }
                    .shadow(
                        color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1),
                        radius: 8,
                        x: 0,
                        y: 3
                    )
                )
        }
    }
}
