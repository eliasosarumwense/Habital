//
//  HabitRowView.swift
//  Habital
//
//  Created by Elias Osarumwense on 10.04.25.
//

import SwiftUI
import CoreData

struct HabitRowView: View {
    //let habit: Habit
    let isActive: Bool
    let isCompleted: Bool
    let nextOccurrence: String
    let toggleCompletion: () -> Void
    let editHabit: () -> Void
    let deleteHabit: () -> Void
    let date: Date
    
    @Environment(\.colorScheme) private var colorScheme
    //@Environment(\.managedObjectContext) private var viewContext
    //@StateObject private var toggleManager = HabitToggleManager(context: PersistenceController.shared.container.viewContext)
    // App storage for settings
    @AppStorage("showStreaks") private var showStreaks = true
    @AppStorage("highlightOverdueHabits") private var highlightOverdueHabits = true
    @AppStorage("useModernBadges") private var useModernBadges = true
    @AppStorage("showHabitDescription") private var showHabitDescription = false
    @AppStorage("showRepeatPattern") private var showRepeatPattern = true
    @AppStorage("showOverdueText") private var showOverdueText = true
    @AppStorage("customRowBackground") private var customRowBackground = false
    @AppStorage("rowBackgroundOpacity") private var rowBackgroundOpacity = 0.1
    
    @AppStorage("showTrackIndicator") private var showTrackIndicator = false
    @AppStorage("trackIndicatorStyle") private var trackIndicatorStyle = "minimal"
    
    // State for tracking completions when repeatsPerDay > 1
    @State private var completedRepeats: Int = 0
    
    private var isCompletedLocal: Bool {
        completedRepeats >= repeatsPerDay // works for 1Ã— and multi-repeat
    }
    
    @State private var showDetailSheet = false
    @State private var showToggleSheet = false
    
    @State private var availableHabitLists: [HabitList] = []
    
    @State var dragOffset = CGSize.zero
    @State var position = CGSize.zero
    @State var position2 = CGSize.zero

    @State private var isBeingDeleted = false
    
    @State private var selectedDetent: PresentationDetent = .height(400)
    
    @State private var showingAnalyticsSheet = false
    
    
    // Add these state variables to your HabitRowView
    @State private var showTimePickerPopover = false
    @State private var showTimeMenuPopover = false
    @State private var selectedPickerTime = Date()
    
    let calendar = Calendar.current
    
    @ObservedObject var habit: Habit
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var toggleManager: HabitToggleManager
    
    @State private var iconPressed = false

    init(
        habit: Habit,
        isActive: Bool,
        isCompleted: Bool,
        nextOccurrence: String,
        toggleCompletion: @escaping () -> Void,
        editHabit: @escaping () -> Void,
        deleteHabit: @escaping () -> Void,
        date: Date
    ) {
        _habit = ObservedObject(initialValue: habit)
        self.habit = habit
        self.isActive = isActive
        self.isCompleted = isCompleted
        self.nextOccurrence = nextOccurrence
        self.toggleCompletion = toggleCompletion
        self.editHabit = editHabit
        self.deleteHabit = deleteHabit
        self.date = date

        let ctx = habit.managedObjectContext ?? PersistenceController.shared.container.viewContext
        _toggleManager = StateObject(wrappedValue: HabitToggleManager(context: ctx))
    }
    // Extract the habit color or use a default
    private var habitColor: Color {
        if let colorData = habit.color,
           let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
            return Color(uiColor)
        }
        return .blue // Default color if not set
    }
    
    // Calculate overdue days for this habit
    private var overdueDays: Int? {
        return habit.calculateOverdueDays(on: date)
    }
    
    
    // Check if habit is a followup habit
    private var isFollowupHabit: Bool {
        // Get the effective repeat pattern
        if let repeatPattern = HabitUtilities.getEffectiveRepeatPattern(for: habit, on: date) {
            return repeatPattern.followUp
        }
        return false
    }
    
    // Check if the date is in the past
    private var isInPast: Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let selectedDay = calendar.startOfDay(for: date)
        return selectedDay < today
    }
    
    // Check if the date is in the future
    private var isFutureDate: Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let selectedDay = calendar.startOfDay(for: date)
        return selectedDay > today
    }
    
    // Get the streak relative to the selected date
    private var streak: Int {
        if showStreaks {
            return habit.calculateStreak(upTo: date)
        }
        else {
            return 0
        }
    }
    
    private func handleEditAction() {
        withAnimation(.spring(response: 0.4)) {
            position2 = .zero
        }
        editHabit()
    }

    private func handleArchiveAction() {
        withAnimation(.spring(response: 0.4)) {
            position2 = .zero
        }
        toggleArchiveHabit(habit: habit, context: viewContext)
    }

    private func handleDeleteAction() {
        withAnimation(.spring(response: 0.4)) {
            position2 = .zero
        }
        deleteHabit()
    }
    
    // Get the repeats per day from the effective repeat pattern
    private var repeatsPerDay: Int {
        // Try to get the repeatPattern directly from the habit
        if let patterns = habit.repeatPattern as? Set<RepeatPattern>, !patterns.isEmpty {
            let patternsArray = Array(patterns)
        }
        
        // Now try the utility method
        guard let repeatPattern = HabitUtilities.getEffectiveRepeatPattern(for: habit, on: date) else {
            return 1
        }
        
        let value = max(1, Int(repeatPattern.repeatsPerDay))
        return value
    }
    
    // Get the repeat pattern text
    private var repeatPatternText: String {
        guard let repeatPattern = HabitUtilities.getEffectiveRepeatPattern(for: habit, on: date) else { return "Not scheduled" }
        
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
                    // Multi-week pattern
                    var weekDescriptions: [String] = []
                    let dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
                    
                    // Generate description for each week
                    for week in 0..<weekCount {
                        let startIndex = week * 7
                        let endIndex = startIndex + 7
                        
                        if endIndex <= specificDays.count {
                            let daysForWeek = Array(specificDays[startIndex..<endIndex])
                            let selectedDays = zip(dayNames, daysForWeek)
                                .filter { $0.1 }
                                .map { $0.0 }
                            
                            if !selectedDays.isEmpty {
                                weekDescriptions.append("Week \(week + 1): \(selectedDays.joined(separator: ", "))")
                            }
                        }
                    }
                    
                    if weekDescriptions.isEmpty {
                        return "No days selected"
                    } else if weekDescriptions.count == 1 {
                        return weekDescriptions[0] + repeatsText
                    } else {
                        return "\(weekCount) weeks rotation" + repeatsText
                    }
                } else if specificDays.count == 7 {
                    // Single week pattern
                    let dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
                    let selectedDays = zip(dayNames, specificDays)
                        .filter { $0.1 }
                        .map { $0.0 }
                    
                    if selectedDays.isEmpty {
                        return "No days selected" + repeatsText
                    } else {
                        return selectedDays.joined(separator: ", ") + repeatsText
                    }
                } else {
                    return "Custom daily pattern" + repeatsText
                }
            }
        }
        
        // Check for weekly goal
        if let weeklyGoal = repeatPattern.weeklyGoal {
            let baseText = weeklyGoal.everyWeek ? "Weekly" : "Every \(weeklyGoal.weekInterval) weeks"
            
            if let specificDays = weeklyGoal.specificDays as? [Bool], specificDays.count == 7 {
                let dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
                let selectedDays = zip(dayNames, specificDays)
                    .filter { $0.1 }
                    .map { $0.0 }
                
                if selectedDays.isEmpty {
                    return "\(baseText): No days selected" + repeatsText
                } else {
                    return "\(baseText): \(selectedDays.joined(separator: ", "))" + repeatsText
                }
            }
            
            return baseText + repeatsText
        }
        
        // Check for monthly goal
        if let monthlyGoal = repeatPattern.monthlyGoal {
            let baseText = monthlyGoal.everyMonth ? "Monthly" : "Every \(monthlyGoal.monthInterval) months"
            
            if let specificDays = monthlyGoal.specificDays as? [Bool], specificDays.count == 31 {
                let selectedDays = (0..<specificDays.count)
                    .filter { specificDays[$0] }
                    .map { String($0 + 1) }
                
                if selectedDays.isEmpty {
                    return "\(baseText): No days selected" + repeatsText
                } else if selectedDays.count <= 3 {
                    return "\(baseText): \(selectedDays.joined(separator: ", "))" + repeatsText
                } else {
                    return "\(baseText): \(selectedDays.count) days" + repeatsText
                }
            }
            
            return baseText + repeatsText
        }
        
        return "Not scheduled"
    }
    
    private var habitIntensity: HabitIntensity {
        return HabitIntensity(rawValue: habit.intensityLevel) ?? .light
    }
    
    
    
    // Check if we should show overdue text
    private var shouldShowOverdue: Bool {
        return highlightOverdueHabits &&
               isActive &&
               isFollowupHabit &&
               !isFutureDate &&
               overdueDays != nil &&
               overdueDays! > 0
    }
    
    // Load completed repeats for this habit on this date
    private func loadCompletedRepeats() {
        // Use the toggle manager to get completed repeats count
        completedRepeats = toggleManager.getCompletedRepeatsCount(for: habit, on: date)
    }
    
    private func handleCompletionTap(withCustomDate customDate: Date? = nil) {
        // Normalize only the regular date to 00:00h
        let normalizedDate = date.normalizedToStartOfDay()
        
        // Use custom date as-is if provided, otherwise use the normalized regular date
        let completionDate = customDate ?? normalizedDate
        
        // Only track time when a custom date is provided (custom time completion)
        let shouldTrackTime = customDate != nil
        
        // Normal toggle behavior with the completion date and conditional time tracking
        toggleManager.toggleCompletion(for: habit, on: completionDate, tracksTime: shouldTrackTime)
        
        if repeatsPerDay > 1 {
            withAnimation(.smooth(duration: 0.4)) {
                // Use normalized date for consistency
                self.completedRepeats = toggleManager.getCompletedRepeatsCount(for: habit, on: normalizedDate)
            }
        }
    }
    
    // Add this method to complete with analytics:
    private func completeWithAnalytics(_ analyticsData: AnalyticsData) {
        // First do the normal completion
        toggleManager.toggleCompletion(for: habit, on: date)
        
        // Then find the completion and add analytics data
        if let completion = findMostRecentCompletion() {
            completion.updateWithAnalytics(analyticsData)
            
            do {
                try viewContext.save()
            } catch {
                print("Failed to save analytics data: \(error)")
            }
        }
        
        // Update UI
        if repeatsPerDay > 1 {
            withAnimation(.smooth(duration: 0.4)) {
                self.completedRepeats = toggleManager.getCompletedRepeatsCount(for: habit, on: date)
            }
        }
        
        showingAnalyticsSheet = false
    }

    // Helper to find the most recent completion
    private func findMostRecentCompletion() -> Completion? {
        guard let completions = habit.completion as? Set<Completion> else { return nil }
        
        let calendar = Calendar.current
        let normalizedDate = calendar.startOfDay(for: date)
        let nextDay = calendar.date(byAdding: .day, value: 1, to: normalizedDate)!
        
        return completions
            .filter { completion in
                guard let compDate = completion.date else { return false }
                return compDate >= normalizedDate && compDate < nextDay && completion.completed
            }
            .max { ($0.loggedAt ?? Date.distantPast) < ($1.loggedAt ?? Date.distantPast) }
    }
    

    func deleteAllCompletions(for habit: Habit, on date: Date, in context: NSManagedObjectContext) {
        let calendar = Calendar.current
        let normalizedDate = calendar.startOfDay(for: date)
        let nextDay = calendar.date(byAdding: .day, value: 1, to: normalizedDate)!
        
        // Fetch all completions for this habit on the specified date
        let request: NSFetchRequest<Completion> = Completion.fetchRequest()
        request.predicate = NSPredicate(
            format: "habit == %@ AND date >= %@ AND date < %@",
            habit,
            normalizedDate as NSDate,
            nextDay as NSDate
        )
        
        do {
            let completions = try context.fetch(request)
            
            // Delete all found completions
            for completion in completions {
                context.delete(completion)
            }
            
            // Update habit's last completion date if needed
            if !completions.isEmpty {
                // Find the most recent completion before this date
                habit.lastCompletionDate = habit.findMostRecentCompletion(before: date)?.date
            }
            
            try context.save()
        } catch {
            print("âŒ Failed to delete completions: \(error)")
        }
    }
    
    private func forceCompleteHabit() {
        let calendar = Calendar.current
        let selectedDate = calendar.startOfDay(for: date)
        
        // Create a new completion for today
        let newCompletion = Completion(context: viewContext)
        newCompletion.date = selectedDate
        newCompletion.completed = true
        newCompletion.habit = habit
        newCompletion.loggedAt = Date()
        
        // Save changes
        do {
            try viewContext.save()
            // Update UI state (this will be reflected in parent views)
            withAnimation(.smooth(duration: 0.4)) {
                completedRepeats = 1
            }
            toggleCompletion()
        } catch {
            print("Error forcing habit completion: \(error)")
            viewContext.rollback()
        }
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
        
        // Use handleCompletionTap with custom datetime (will automatically set tracksTime: true)
        handleCompletionTap(withCustomDate: fullCompletionDateTime)
        
        // Close swipe after completion
        withAnimation(.spring(response: 0.4)) {
            position2 = .zero
        }
    }

    private func completeAtLastTime() {
        completeWithCustomTime(0) // 0 minutes offset = exact last time
    }

    private func completeWithTimeOffset() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let selectedDay = calendar.startOfDay(for: date)
        
        if calendar.isDate(selectedDay, inSameDayAs: today) {
            // For today: complete 15 minutes ago
            completeWithCustomTime(-15)
        } else {
            // For other dates: complete at last completion time
            completeAtLastTime()
        }
    }
    private var firstButtonLabel: String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let selectedDay = calendar.startOfDay(for: date)
        
        if calendar.isDate(selectedDay, inSameDayAs: today) {
            return "15m"
        } else {
            if let lastTime = getLastCompletionTime() {
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                return formatter.string(from: lastTime)
            } else {
                return "12PM"
            }
        }
    }

    private var secondButtonLabel: String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let selectedDay = calendar.startOfDay(for: date)
        
        if calendar.isDate(selectedDay, inSameDayAs: today) {
            return "30m"
        } else {
            // For past dates, show "Same Time" instead of "Now"
            return "Same"
        }
    }
    
    private func skipHabit() {
        // Trigger appropriate haptic feedback for skipping
        //triggerHaptic(.impactMedium)
        
        // Skip the habit using the toggle manager
        toggleManager.skipHabit(for: habit, on: date)
        
        // Close the swipe gesture
        withAnimation(.spring(response: 0.4)) {
            position2 = .zero
        }
        
        // Update completion counts if needed
        if repeatsPerDay > 1 {
            withAnimation(.smooth(duration: 0.4)) {
                self.completedRepeats = toggleManager.getCompletedRepeatsCount(for: habit, on: date)
            }
        }
    }
    
    private var isSkipped: Bool {
        guard let completions = habit.completion as? Set<Completion> else { return false }
        let calendar = Calendar.current
        return completions.contains { completion in
            guard let completionDate = completion.date else { return false }
            return calendar.isDate(completionDate, inSameDayAs: date) && completion.skipped
        }
    }
    
    private func addQuickDuration(_ minutes: Int) {
        let currentMinutes = HabitUtilities.getDurationCompleted(for: habit, on: date)
        let newTotal = currentMinutes + minutes
        toggleManager.toggleDurationCompletion(for: habit, on: date, minutes: newTotal)
        
        // Update local state if needed
        updateCompletedRepeats()
        
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }

    private func addQuickQuantity(_ amount: Int) {
        let currentQuantity = HabitUtilities.getQuantityCompleted(for: habit, on: date)
        let newTotal = currentQuantity + amount
        toggleManager.toggleQuantityCompletion(for: habit, on: date, quantity: newTotal)
        
        // Update local state if needed
        updateCompletedRepeats()
        
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }

    private func updateCompletedRepeats() {
        let trackingType = getTrackingType(for: habit)
        switch trackingType {
        case .repetitions:
            completedRepeats = HabitUtilities.getCompletedRepeatsCount(for: habit, on: date)
        case .duration:
            let target = getTargetDuration()
            let completed = HabitUtilities.getDurationCompleted(for: habit, on: date)
            completedRepeats = completed >= target ? 1 : 0
        case .quantity:
            let target = getTargetQuantity()
            let completed = HabitUtilities.getQuantityCompleted(for: habit, on: date)
            completedRepeats = completed >= target ? 1 : 0
        }
    }

    private func getTrackingType(for habit: Habit) -> HabitTrackingType {
        guard let pattern = habit.repeatPattern?.allObjects.first as? RepeatPattern,
              let typeString = pattern.trackingType,
              let type = HabitTrackingType(rawValue: typeString) else {
            return .repetitions
        }
        return type
    }

    private func getTargetDuration() -> Int {
        guard let pattern = habit.repeatPattern?.allObjects.first as? RepeatPattern else { return 30 }
        return Int(pattern.duration)
    }

    private func getTargetQuantity() -> Int {
        guard let pattern = habit.repeatPattern?.allObjects.first as? RepeatPattern else { return 1 }
        return Int(pattern.targetQuantity)
    }
    
    private var trackingType: HabitTrackingType {
        guard let pattern = habit.repeatPattern?.allObjects.first as? RepeatPattern,
              let typeString = pattern.trackingType else {
            return .repetitions
        }
        
        switch typeString {
        case "duration":
            return .duration
        case "quantity":
            return .quantity
        default:
            return .repetitions
        }
    }

    private var targetDuration: Int {
        guard let pattern = habit.repeatPattern?.allObjects.first as? RepeatPattern else { return 30 }
        return Int(pattern.duration)
    }

    private var completedDuration: Int {
        return HabitUtilities.getDurationCompleted(for: habit, on: date)
    }

    private var targetQuantity: Int {
        guard let pattern = habit.repeatPattern?.allObjects.first as? RepeatPattern else { return 1 }
        return Int(pattern.targetQuantity)
    }

    private var completedQuantity: Int {
        return HabitUtilities.getQuantityCompleted(for: habit, on: date)
    }

    private var quantityUnit: String {
        guard let pattern = habit.repeatPattern?.allObjects.first as? RepeatPattern else { return "items" }
        return pattern.quantityUnit ?? "items"
    }

    // Update your context menu to include tracking-specific options:
    // Add this to your existing context menu actions:
    private var trackingSpecificMenuItems: some View {
        Group {
            let trackingType = getTrackingType(for: habit)
            
            switch trackingType {
            case .duration:
                Button("Add 15 min") {
                    addQuickDuration(15)
                }
                Button("Add 30 min") {
                    addQuickDuration(30)
                }
                
            case .quantity:
                let unit = habit.repeatPattern?.allObjects.first as? RepeatPattern
                let unitName = (unit?.quantityUnit ?? "items").lowercased()
                
                Button("Add 1 \(unitName)") {
                    addQuickQuantity(1)
                }
                Button("Add 5 \(unitName)") {
                    addQuickQuantity(5)
                }
                
            case .repetitions:
                EmptyView()
            }
        }
    }
    
    var body: some View {
        ZStack {
            HStack {
                        Spacer()
                        
                HStack(spacing: 6) {
                        // First button: Time menu with preset options
                        SwipeActionButton(
                            iconName: "clock.arrow.circlepath",
                            
                            iconColor: .primary,
                            action: {
                                showTimeMenuPopover = true
                            },
                            position: position2,
                            label: "Recently"
                        )
                        .popover(isPresented: $showTimeMenuPopover, arrowEdge: .trailing) {
                            TimeMenuPopoverContent(
                                onSelectTime: { minutesOffset in
                                    completeWithCustomTime(minutesOffset)
                                    showTimeMenuPopover = false
                                },
                                onCancel: {
                                    showTimeMenuPopover = false
                                }
                            )
                            .presentationCompactAdaptation(.popover)
                        }
                        
                        // Second button: Custom time picker
                        SwipeActionButton(
                            iconName: "clock.badge.questionmark",
                            
                            iconColor: .primary,
                            action: {
                                selectedPickerTime = getCompletionTimeForSelectedDate()
                                showTimePickerPopover = true
                            },
                            position: position2,
                            label: "Custom"
                        )
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
                                    withAnimation(.spring(response: 0.4)) {
                                        position2 = .zero
                                    }
                                },
                                onCancel: {
                                    showTimePickerPopover = false
                                }
                            )
                            .presentationCompactAdaptation(.popover)
                        }
                    SwipeActionButton(
                            iconName: "arrow.right",
                            
                            iconColor: .primary,
                            action: {
                                skipHabit()
                            },
                            position: position2,
                            label: "Skip"
                        )
                    }
                    .padding(.trailing, 10)
                    }
        HStack {
            
            // Use the animated HabitIconView component
            HabitIconView(
                iconName: habit.icon,
                isActive: isActive,
                habitColor: habitColor,
                streak: streak,
                showStreaks: showStreaks,
                useModernBadges: useModernBadges,
                isFutureDate: isFutureDate,
                isBadHabit: habit.isBadHabit,
                intensityLevel: habit.intensityLevel
            )
            .scaleEffect(iconPressed ? 0.8 : 1.05)
            //.shadow(color: habitColor.opacity(iconPressed ? 0.4 : 0.2), radius: iconPressed ? 8 : 4)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: iconPressed)
            .padding(.trailing, 6)
            .onTapGesture {
                // Press animation
                withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                    iconPressed = true
                }
                
                // Haptic feedback
                triggerHaptic(.impactSoft)
                
                // Open detail sheet
                showDetailSheet = true
                
                // Reset animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        iconPressed = false
                    }
                }
            }
            
            // Habit name and pattern stacked vertically
            VStack(alignment: .leading, spacing: 2) {
                HStack (spacing: 4) {
                    Text(habit.name ?? "Unnamed Habit")
                        .font(.custom("Lexend-Medium", size: 15))
                        .foregroundColor(isActive ? .primary : .gray)
                        .contentTransition(.interpolate)
                    
                    if showTrackIndicator && isActive && !isFutureDate {
                        let style: TrackIndicatorStyle = {
                            switch trackIndicatorStyle {
                            case "compact": return .compact
                            case "detailed": return .detailed
                            default: return .minimal
                            }
                        }()
                        
                        EnhancedHabitTrackIndicator(
                            habit: habit,
                            date: date,
                            style: style
                        )
                    }
                }
                
                // Show description if available and setting is enabled
                if showHabitDescription, let description = habit.habitDescription, !description.isEmpty {
                    Text(description)
                        .font(.custom("Lexend-Regular", size: 10))
                        .lineLimit(1)
                        .foregroundColor(isActive ? .secondary : .gray)
                        .contentTransition(.interpolate)
                }
                HStack(spacing: 4) {
                    // Add the repeat pattern text if setting is enabled
                    if showRepeatPattern {
                        
                        Text(repeatPatternText)
                            .customFont("Lexend", .semiBold, 11)
                            .foregroundColor(.secondary)
                            .contentTransition(.interpolate)
                        
                        if isFollowupHabit {
                            Image(systemName: "arrow.turn.down.right")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                    if shouldShowOverdue && showOverdueText, let days = overdueDays {
                        HStack(spacing: 3) {
                            // Dot separator
                            Text("-")
                                .font(.system(size: 10))
                                .foregroundColor(.primary)
                            
                            Text("\(days)d overdue")
                                .customFont("Lexend", .semiBold, 10)
                                .foregroundColor(.red)
                                .fontWeight(.medium)
                        }
                    }
                }
                
                
                
                
                // Show archived status if the habit is archived
                if habit.isArchived {
                    Text("Archived")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.2))
                        )
                }
            }
            
            Spacer()
            
            if isActive {
                HStack(spacing: 8) {
                    VStack (alignment: .trailing, spacing: 5){
                        /*
                         if isInPast && (repeatsPerDay <= 1 ? !isCompleted : completedRepeats < repeatsPerDay) {
                            Text(habit.isBadHabit ? "Avoided" : "Missed")
                                .customFont("Lexend", .medium, 11)
                                .foregroundColor(habit.isBadHabit ? .green : .secondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.primary.opacity(0.05))
                                        .overlay(
                                            Capsule()
                                                .strokeBorder(
                                                    Color.primary.opacity(0.1),
                                                    lineWidth: 0.5
                                                )
                                        )
                                )
                        }
                         */
                    }
                         
                    ZStack(alignment: .topTrailing) {
                        // Completion button for different tracking types
                        if !habit.isArchived {
                            if !habit.isBadHabit {
                                // Use the enhanced RingFillCheckmarkButton for all tracking types
                                RingFillCheckmarkButton(
                                    habitColor: habitColor,
                                    isCompleted: Binding(
                                        get: {
                                            switch trackingType {
                                            case .repetitions:
                                                return isCompletedLocal
                                            case .duration:
                                                return completedDuration >= targetDuration
                                            case .quantity:
                                                return completedQuantity >= targetQuantity
                                            }
                                        },
                                        set: { _ in
                                            switch trackingType {
                                            case .repetitions:
                                                handleCompletionTap()
                                            case .duration:
                                                // Toggle between 0 and target duration
                                                let newDuration = completedDuration >= targetDuration ? 0 : targetDuration
                                                toggleManager.toggleDurationCompletion(for: habit, on: date, minutes: newDuration)
                                                updateCompletedRepeats()
                                            case .quantity:
                                                // Toggle between 0 and target quantity
                                                let newQuantity = completedQuantity >= targetQuantity ? 0 : targetQuantity
                                                toggleManager.toggleQuantityCompletion(for: habit, on: date, quantity: newQuantity)
                                                updateCompletedRepeats()
                                            }
                                        }
                                    ),
                                    onTap: { /* handled by binding */ },
                                    isInPast: isInPast,
                                    repeatsPerDay: repeatsPerDay,
                                    completedRepeats: completedRepeats,
                                    onLongPress: {
                                        // Long press actions based on tracking type
                                        switch trackingType {
                                        case .repetitions:
                                            // Could show multi-repeat options
                                            break
                                        case .duration:
                                            // Quick add 15 minutes
                                            addQuickDuration(15)
                                        case .quantity:
                                            // Quick add 1 item
                                            addQuickQuantity(1)
                                        }
                                    },
                                    isSkipped: isSkipped,
                                    trackingType: trackingType,
                                    targetDuration: targetDuration,
                                    completedDuration: completedDuration,
                                    targetQuantity: targetQuantity,
                                    completedQuantity: completedQuantity,
                                    quantityUnit: quantityUnit
                                )
                                .disabled(isFutureDate ? true : ((position2.width < 0) ? true : false))
                                .scaleEffect(1.17)
                            } else {
                                // Keep existing bad habit button
                                BadHabitButton(
                                    successColor: .green,
                                    failureColor: .red,
                                    isBroken: Binding(
                                        get: { isCompleted },
                                        set: { _ in toggleCompletion() }
                                    ),
                                    streakCount: streak
                                ) {
                                    // Handled by binding
                                }
                                .disabled(isFutureDate ? true : ((position2.width < 0) ? true : false))
                            }
                        }
                    }
                    
                }
            } else {
                // Next occurrence text with arrow
                HStack(spacing: 4) {
                    Image(systemName: "arrow.right")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    
                    Text(nextOccurrence)
                        .customFont("Lexend", .semiBold, 11  )
                        .foregroundColor(.primary.opacity(0.8))
                        .contentTransition(.numericText(countsDown: false))
                        .animation(.smooth(duration: 0.6), value: nextOccurrence)
                }
            }
        }
        
        .frame(height: 50)
        .padding(.vertical, 8)
        .padding(.horizontal)
        /*
         .background(
         ZStack {
         // Simulated soft shadow (dark mode aware)
         RoundedRectangle(cornerRadius: 30)
         .fill(
         colorScheme == .dark
         ? Color.black.opacity(0.4) // Darker in dark mode for contrast
         : Color.black.opacity(0.15) // Softer in light mode
         )
         .blur(radius: 8)   // More blur = softer shadow
         .offset(y: 4)       // Direction of shadow
         .padding(-2)        // Prevent blur cutoff
         
         // Main background fill
         RoundedRectangle(cornerRadius: 30)
         .fill(
         isActive
         ? (colorScheme == .dark
         ? Color(red: 0.11, green: 0.11, blue: 0.12)
         : Color(red: 0.94, green: 0.94, blue: 0.96))
         : (colorScheme == .dark
         ? Color(red: 0.08, green: 0.08, blue: 0.09)
         : Color(red: 0.90, green: 0.90, blue: 0.92))
         )
         
         // Gradient border
         RoundedRectangle(cornerRadius: 30)
         .strokeBorder(
         LinearGradient(
         colors: [
         habitColor.opacity(isActive ? (colorScheme == .dark ? 0.2 : 0.35) : 0.05),
         Color.primary.opacity(colorScheme == .dark ? 0.05 : 0.1)
         ],
         startPoint: .leading,
         endPoint: .trailing
         ),
         lineWidth: 1
         )
         
         // Optional accent background
         if customRowBackground && isActive {
         RoundedRectangle(cornerRadius: 30)
         .fill(habitColor.opacity(colorScheme == .dark ? 0.08 : 0.04))
         }
         
         /*
          // Optional overlay for past items
          if isInPast {
          RoundedRectangle(cornerRadius: 20)
          .fill(Color.primary.opacity(0.05))
          }
          */
         }
         )
         */
        //.lightGlassBackground(cornerRadius: 30)
        .glassBackground(cornerRadius: 30)
        .offset(x: position2.width)
        .gesture(
            DragGesture(minimumDistance: 30)
                .onChanged { value in
                    // Only allow leftward swipe (negative translation)
                    if value.translation.width < 0 {
                        position2.width = max(value.translation.width, -170) // Increased from -120 to -180
                    }
                }
                .onEnded { value in
                    let swipeThreshold: CGFloat = -50
                    
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        if value.translation.width < swipeThreshold {
                            position2.width = -170 // Increased from -120 to -180
                        } else {
                            position2.width = 0
                        }
                    }
                }
        )
        //.animation(.easeInOut(duration: 0.3), value: isCompleted)
        //.animation(.smooth(duration: 0.3), value: isActive)
        //.animation(.smooth(duration: 0.3), value: isCompleted)
        //.animation(.smooth(duration: 0.3), value: completedRepeats)
        //.animation(.smooth(duration: 0.4), value: habit.name)
        /*
         .transition(.asymmetric(
         insertion: .move(edge: .leading).combined(with: .opacity),
         removal: .move(edge: .trailing).combined(with: .opacity)
         ))
         */
        //.opacity(isInPast ? 0.9 : 1)
            
        .onTapGesture {
            if position2.width < 0 {
                // If swiped, first close the swipe
                withAnimation(.spring(response: 0.4)) {
                    position2 = .zero
                }
            } else {
                showToggleSheet = true
            }
        }
        .sheet(isPresented: $showDetailSheet) {
            HabitDetailSheet(habit: habit, date: date, isPresented: $showDetailSheet, selectedDetent: $selectedDetent)
            /*
                .presentationCornerRadius(45)
                .presentationDetents([.height(440), .large], selection: $selectedDetent) // 300 points high
                .presentationBackground(.ultraThinMaterial)
            
             */
                .presentationDetents([.medium, .large], selection: $selectedDetent)
                        .presentationCornerRadius(45)
                        .presentationDetents([.medium], selection: .constant(.medium))
                        // Don't set presentationBackground - let iOS 26 handle it automatically
                        .interactiveDismissDisabled(false)
                        
        }
            
        .sheet(isPresented: $showToggleSheet) {
            HabitToggleSheet(
                habit: habit,
                date: date,
                currentStreak: streak,  // ← Pass the calculated streak from HabitRowView
                isPresented: $showToggleSheet
            )
            .presentationCornerRadius(45)
            .presentationDetents([.medium], selection: .constant(.medium))
            .presentationBackground(.ultraThinMaterial)
            .interactiveDismissDisabled(false)
        }
             
        .sheet(isPresented: $showingAnalyticsSheet) {
            CompletionAnalyticsSheet(
                habit: habit,
                date: date,
                onComplete: { analyticsData in
                    completeWithAnalytics(analyticsData)
                },
                onDismiss: {
                    showingAnalyticsSheet = false
                }
            )
            .presentationDetents([.fraction(0.5), .medium])
        }
        .contextMenu {
            Button(action: editHabit) {
                Label("Edit Habit", systemImage: "pencil")
            }
            
            Button(action: {
                toggleArchiveHabit(habit: habit, context: viewContext)
            }) {
                Label(habit.isArchived ? "Unarchive" : "Archive",
                      systemImage: habit.isArchived ? "tray.and.arrow.up" : "archivebox")
            }
            
            if !isActive {
                Button(action: {
                    // Force complete this habit for today
                    toggleManager.forceCompleteHabit(habit, on: date)
                    withAnimation(.smooth(duration: 0.4)) {
                        completedRepeats = 1
                    }
                    toggleCompletion()
                }) {
                    Label("Complete Today", systemImage: "checkmark.circle")
                }
            }
            
            // Add a divider before the Move To section
            Divider()
            
            // Show current list information if any
            if let currentList = habit.habitList {
                Text("Currently in: \(currentList.name ?? "Unknown List")")
            }
            
            // Move To section with available habit lists
            Menu {
                // Option to remove from all lists
                if habit.habitList != nil {
                    Button(action: {
                        habit.moveToHabitList(nil, context: viewContext)
                        availableHabitLists = fetchAvailableHabitLists(for: habit, excluding: habit.habitList, in: viewContext)
                    }) {
                        Label("Remove from List", systemImage: "tray.full.fill")
                    }
                }
                
                // Available habit lists
                ForEach(availableHabitLists, id: \.self) { list in
                    Button(action: {
                        habit.moveToHabitList(list, context: viewContext)
                        availableHabitLists = fetchAvailableHabitLists(for: habit, excluding: habit.habitList, in: viewContext)
                    }) {
                        Label(list.name ?? "Unnamed List", systemImage: list.icon ?? "list.bullet")
                    }
                }
                
                // Show a message if no other lists are available
                if availableHabitLists.isEmpty {
                    Text("No other lists available")
                }
            } label: {
                Label("Move to List", systemImage: "folder")
            }
            
            Divider()
            
            Button(role: .destructive, action: {
                // Immediate visual feedback
                withAnimation(.easeOut(duration: 0.2)) {
                    isBeingDeleted = true
                }
                
                // Small delay to allow animation to be visible
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    deleteHabit()
                }
            }) {
                Label("Delete Habit", systemImage: "trash")
            }
        }
        .onAppear {
            // Load completions for the specific date when the view appears
            loadCompletedRepeats()
            
            availableHabitLists = fetchAvailableHabitLists(for: habit, excluding: habit.habitList, in: viewContext)
        }
        .onChange(of: date) { oldDate, newDate in
            loadCompletedRepeats()
        }
        // Listen to Core Data changes directly for immediate updates
        .onChange(of: habit.completion?.count ?? 0) { _, _ in
            loadCompletedRepeats()
        }
        // Also listen to the habit's lastCompletionDate for safety
        .onChange(of: habit.lastCompletionDate) { _, _ in
            loadCompletedRepeats()
        }
        .onChange(of: date) { _, _ in loadCompletedRepeats() }
        .onReceive(NotificationCenter.default.publisher(
            for: .NSManagedObjectContextObjectsDidChange,
            object: viewContext
        )) { note in
            if let updated = note.userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject>,
               updated.contains(where: { $0.objectID == habit.objectID }) {
                loadCompletedRepeats()
            }
        }
    }
    }
}
struct option: View {
    var iconName:String
    var iconColoor:Color
    var action:() -> Void
    var position2 : CGSize
    var body: some View {
        Button {
            action()
        } label: {
            ZStack{
                Circle().frame(width: 34, height: 34)
                    .foregroundColor(iconColoor.opacity(0.2))
                Image(systemName: iconName).resizable().scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(iconColoor)
                
            }
        }
        
        .opacity(min(max(-position2.width / 130, 0), 1))
        .scaleEffect(min(max(-position2.width / 130, 0), 1))
        .animation(.spring, value: position2)

    }
}

func fetchAvailableHabitLists(for habit: Habit, excluding currentList: HabitList?, in context: NSManagedObjectContext) -> [HabitList] {
    let request: NSFetchRequest<HabitList> = HabitList.fetchRequest()
    
    // If habit is already in a list, exclude that list
    if let currentList = currentList {
        request.predicate = NSPredicate(format: "self != %@", currentList)
    }
    
    // Sort by order property
    request.sortDescriptors = [NSSortDescriptor(keyPath: \HabitList.order, ascending: true)]
    
    do {
        return try context.fetch(request)
    } catch {
        print("Error fetching habit lists: \(error)")
        return []
    }
}

struct SwipeActionButton: View {
    let iconName: String
    let iconColor: Color
    let action: () -> Void
    let position: CGSize
    let label: String?
    
    @Environment(\.colorScheme) private var colorScheme
    
    init(iconName: String, iconColor: Color, action: @escaping () -> Void, position: CGSize, label: String? = nil) {
        self.iconName = iconName
        self.iconColor = iconColor
        self.action = action
        self.position = position
        self.label = label
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 1) {
                Image(systemName: iconName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(iconColor)
                
                if let label = label, !label.isEmpty {
                    Text(label)
                        .customFont("Lexend", .medium, 7)
                        .foregroundColor(iconColor.opacity(0.8))
                        .lineLimit(1)
                }
            }
            .frame(width: 45, height: 45)
            .background(
                Circle()
                    .fill(
                        colorScheme == .dark
                            ? Color.white.opacity(0.1)
                            : Color.black.opacity(0.05)
                    )
                    .overlay(
                        Circle()
                            .strokeBorder(
                                colorScheme == .dark
                                    ? Color.white.opacity(0.15)
                                    : Color.black.opacity(0.1),
                                lineWidth: 0.5
                            )
                    )
            )
        }
        .opacity(min(max(-position.width / 150, 0), 1))
        .scaleEffect(min(max(-position.width / 150, 0), 1))
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: position)
    }
}

struct TimeMenuPopoverContent: View {
    let onSelectTime: (Int) -> Void // minutes ago
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach([15, 30, 45, 60, 120], id: \.self) { minutes in
                Button(action: {
                    onSelectTime(-minutes) // negative for "ago"
                }) {
                    HStack {
                        Text("\(minutes == 60 ? "1h" : minutes == 120 ? "2h" : "\(minutes)m") ago")
                            .customFont("Lexend", .medium, 14)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.primary.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(12)
        .frame(width: 140)
    }
}

struct TimePickerPopoverContent: View {
    @Binding var selectedTime: Date
    let lastCompletionTime: Date?
    let onComplete: (Date) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            VStack(spacing: 4) {
                Text("Select Time")
                    .font(.customFont("Lexend", .semiBold, 16))
                    .foregroundColor(.primary)
                
                if let lastTime = lastCompletionTime {
                    Text("Last: \(lastTime, formatter: timeFormatter)")
                        .font(.customFont("Lexend", .regular, 12))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 8)
            
            // Time Picker
            DatePicker(
                "",
                selection: $selectedTime,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .frame(height: 120)
            
            // Action buttons
            HStack(spacing: 12) {
                Button("Cancel") {
                    onCancel()
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                
                Button("Complete") {
                    onComplete(selectedTime)
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Color.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .padding(.bottom, 8)
        }
        .padding(.horizontal, 16)
        .frame(width: 250)
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
}
