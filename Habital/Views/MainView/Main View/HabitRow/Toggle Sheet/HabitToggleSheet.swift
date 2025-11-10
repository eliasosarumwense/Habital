import SwiftUI
import CoreData
import UIKit

// MARK: - Custom Marquee Text Component
struct MarqueeTextToggleSheet: View {
    let text: String
    let font: Font
    let color: Color
    let shadow: Color
    
    @State private var animate = false
    @State private var textWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Measure text width (hidden)
                Text(text)
                    .font(font)
                    .foregroundColor(.clear)
                    .fixedSize(horizontal: true, vertical: false)
                    .background(
                        GeometryReader { textGeometry in
                            Color.clear
                                .onAppear {
                                    textWidth = textGeometry.size.width
                                    containerWidth = geometry.size.width
                                }
                        }
                    )
                
                // Scrolling text or static text
                if textWidth > containerWidth {
                    ScrollingTextToggle(
                        text: text,
                        font: font,
                        color: color,
                        shadow: shadow,
                        textWidth: textWidth,
                        containerWidth: containerWidth,
                        animate: $animate
                    )
                    .onAppear {
                        startAnimation()
                    }
                    .onChange(of: textWidth) { _, _ in
                        if textWidth > containerWidth {
                            startAnimation()
                        }
                    }
                } else {
                    // Static text if it fits
                    Text(text)
                        .font(font)
                        .foregroundColor(color)
                        
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .clipped()
    }
    
    private func startAnimation() {
        animate = false
        
        // Delay before starting scroll
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            let scrollDistance = textWidth - containerWidth + 20 // Extra padding
            let duration = max(2.0, Double(scrollDistance / 40)) // Slower scroll speed
            
            withAnimation(.linear(duration: duration).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

// MARK: - Scrolling Text Helper
private struct ScrollingTextToggle: View {
    let text: String
    let font: Font
    let color: Color
    let shadow: Color
    let textWidth: CGFloat
    let containerWidth: CGFloat
    @Binding var animate: Bool
    
    var body: some View {
        Text(text)
            .font(font)
            .foregroundColor(color)
            
            .fixedSize(horizontal: true, vertical: false)
            .offset(x: animate ? -(textWidth - containerWidth + 20) : 0)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}


// MARK: - Main Habit Toggle Sheet
struct HabitToggleSheet: View {
    @ObservedObject var habit: Habit
    let date: Date
    let currentStreak: Int
    @Binding var isPresented: Bool
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var toggleManager: HabitToggleManager
    
    // State for tracking
    @State private var completedRepeats: Int = 0
    @State private var completedDuration: Int = 0 // minutes
    @State private var completedQuantity: Int = 0
    @State private var isSkipped: Bool = false
    
    // Custom time selection
    @State private var showTimePicker: Bool = false
    @State private var showAllCompletionTimePicker: Bool = false
    @State private var selectedTime: Date = Date()
    @State private var selectedCompletionIndex: Int? = nil // For multi-repetition time editing
    @State private var selectedCompletionItem: CompletionItem? = nil // For SmoothPickerStack
    
    // Animation states
    @State private var ringScale: CGFloat = 5.0
    @State private var buttonPressedMinus: Bool = false
    @State private var buttonPressedPlus: Bool = false
    
    @State private var showPomodoroTimer: Bool = false
    @State private var showNotesSheet: Bool = false
    @State private var showTriggerSheet: Bool = false
    
    @State private var showCalendarView: Bool = false
    @State private var showHabitDetailSheet: Bool = false
    
    // Calendar view state variables (matching HabitDetailSheet)
    @State private var calendarTitle: String = Calendar.monthAndYear(from: Date())
    @State private var focusedWeek: Week = Week(days: Calendar.currentWeek(from: Calendar.nearestMonday(from: Date())), order: .current)
    @State private var selectedCalendarDate: Date? = Date()
    @State private var isDraggingCalendar = false
    @State private var calendarDragProgress: CGFloat = 1.0
    @State private var refreshChart = false
    
    // Streak and completion data
    @State private var currentStreakValue: Int = 0
    @State private var totalCompletionDays: Int = 0
    
    init(habit: Habit, date: Date, currentStreak: Int, isPresented: Binding<Bool>) {
        self.habit = habit
        self.date = date
        self.currentStreak = currentStreak
        self._isPresented = isPresented
    }
    
    // MARK: - Computed Properties
    
    private var habitColor: Color {
        if let colorData = habit.color,
           let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
            return Color(uiColor)
        }
        return .blue
    }
    
    private var currentRepeatPattern: RepeatPattern? {
        habit.repeatPattern?.allObjects.first as? RepeatPattern
    }
    
    private var trackingType: HabitTrackingType {
        guard let pattern = currentRepeatPattern,
              let typeString = pattern.trackingType,
              let type = HabitTrackingType(rawValue: typeString) else {
            return .repetitions
        }
        return type
    }
    
    private var repeatsPerDay: Int {
        Int(currentRepeatPattern?.repeatsPerDay ?? 1)
    }
    
    private var targetDuration: Int {
        Int(currentRepeatPattern?.duration ?? 30)
    }
    
    private var targetQuantity: Int {
        Int(currentRepeatPattern?.targetQuantity ?? 1)
    }
    
    private var quantityUnit: String {
        currentRepeatPattern?.quantityUnit ?? "items"
    }
    
    private var isCompleted: Bool {
        switch trackingType {
        case .repetitions:
            return completedRepeats >= repeatsPerDay
        case .duration:
            return completedDuration >= targetDuration
        case .quantity:
            return completedQuantity >= targetQuantity
        }
    }
    
    private var currentProgress: Double {
        switch trackingType {
        case .repetitions:
            return Double(completedRepeats) / Double(max(1, repeatsPerDay))
        case .duration:
            return Double(completedDuration) / Double(max(1, targetDuration))
        case .quantity:
            return Double(completedQuantity) / Double(max(1, targetQuantity))
        }
    }
    
    private var progressText: String {
        switch trackingType {
        case .repetitions:
            return "\(completedRepeats)/\(repeatsPerDay)"
        case .duration:
            return "\(completedDuration)m"
        case .quantity:
            return "\(completedQuantity)"
        }
    }
    
    private var shouldShowAdjustButtons: Bool {
        // Bad habits don't show adjust buttons - they can only be toggled once
        if habit.isBadHabit {
            return false
        }
        
        if isCompleted, isSkipped { return false }
        
        switch trackingType {
        case .repetitions:
            return repeatsPerDay > 1
        case .duration:
            return true
        case .quantity:
            return targetQuantity > 1
        }
    }
    
    // MARK: - Helper Methods
    
    private func getFilteredHabitsForDate(_ date: Date) -> [Habit] {
        // Just return this single habit for the calendar view
        return [habit]
    }
    
    private func calculateTotalCompletionDays() -> Int {
        // 🆕 Use the same method as HabitStreaksView - cached totalCompletions from CoreData
        return Int(habit.totalCompletions)
    }
    
    private func loadStreakAndCompletionData() {
        // 🆕 Use exact same methods as HabitStreaksView
        // Current streak: habit.calculateStreak(upTo: date)
        let calculatedStreak = habit.calculateStreak(upTo: date)
        withAnimation(.smooth(duration: 0.4, extraBounce: 0.1)) {
            currentStreakValue = calculatedStreak
        }
        
        // Total completions: Int(habit.totalCompletions) - cached value from CoreData
        let newTotalCompletions = Int(habit.totalCompletions)
        withAnimation(.smooth(duration: 0.4, extraBounce: 0.1)) {
            totalCompletionDays = newTotalCompletions
        }
    }
    
    private func loadCompletionState() {
        switch trackingType {
        case .repetitions:
            completedRepeats = toggleManager.getCompletedRepeatsCount(for: habit, on: date)
        case .duration:
            completedDuration = HabitUtilities.getDurationCompleted(for: habit, on: date)
        case .quantity:
            completedQuantity = HabitUtilities.getQuantityCompleted(for: habit, on: date)
        }
        
        // Check if skipped
        isSkipped = checkIfSkipped()
        
        // Load streak and completion data
        loadStreakAndCompletionData()
        
        // Debug output for bad habits
        if habit.isBadHabit {
            print("🔥 Bad habit loadCompletionState - isCompleted: \(isCompleted), completedRepeats: \(completedRepeats), isSkipped: \(isSkipped)")
        }
    }
    
    private func checkIfSkipped() -> Bool {
        guard let completions = habit.completion as? Set<Completion> else { return false }
        let calendar = Calendar.current
        return completions.contains { completion in
            guard let completionDate = completion.date else { return false }
            return calendar.isDate(completionDate, inSameDayAs: date) && completion.skipped
        }
    }
    
    private func getDurationIncrement(_ value: Int) -> Int {
        // Smart duration increments
        if value < 10 {
            return 1
        } else if value < 30 {
            return 5
        } else if value < 60 {
            return 10
        } else {
            return 15
        }
    }
    
    private func adjustValue(_ delta: Int) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            // In HabitToggleSheet, always get the proper completion date/time
            let completionDateTime = getCompletionDateTime()
            
            switch trackingType {
            case .repetitions:
                if delta > 0 && completedRepeats < repeatsPerDay {
                    // Add one repetition with time tracking
                    _ = toggleManager.addSingleCompletion(for: habit, on: completionDateTime, tracksTime: true)
                    completedRepeats += 1
                } else if delta < 0 && completedRepeats > 0 {
                    // Remove one repetition
                    toggleManager.removeSingleCompletion(for: habit, on: date)
                    completedRepeats -= 1
                }
            case .duration:
                let increment = getDurationIncrement(completedDuration)
                let newDuration = max(0, min(targetDuration, completedDuration + (delta * increment)))
                completedDuration = newDuration
                if newDuration > 0 {
                    let completionDateTime = getCompletionDateTime()
                    toggleManager.toggleDurationCompletion(for: habit, on: completionDateTime, minutes: newDuration, tracksTime: true)
                } else {
                    toggleManager.deleteAllCompletions(for: habit, on: date)
                }
            case .quantity:
                let newQuantity = max(0, min(targetQuantity, completedQuantity + delta))
                completedQuantity = newQuantity
                if newQuantity > 0 {
                    let completionDateTime = getCompletionDateTime()
                    toggleManager.toggleQuantityCompletion(for: habit, on: completionDateTime, quantity: newQuantity, tracksTime: true)
                } else {
                    toggleManager.deleteAllCompletions(for: habit, on: date)
                }
            }
            
            // Refresh the streak and completion data after making changes
            loadStreakAndCompletionData()
            
            // Trigger refresh for calendar view if it's open
            refreshChart.toggle()
        }
        
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    // MARK: - Updated toggleCompletion method - smart completion behavior
    private func toggleCompletion() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            let completionDateTime = getCompletionDateTime()
            // In HabitToggleSheet, ALWAYS track time to distinguish from HabitRowView completions
            let shouldTrackTime = true
            
            // Debug for bad habits
            if habit.isBadHabit {
                print("🔥 Bad habit toggle - Current isCompleted: \(isCompleted), will become: \(!isCompleted)")
            }
            
            switch trackingType {
            case .repetitions:
                if repeatsPerDay == 1 {
                    // Single repetition - use normal toggle
                    toggleManager.toggleCompletion(for: habit, on: completionDateTime, tracksTime: shouldTrackTime)
                } else {
                    // Multi-repetition - smart behavior
                    if completedRepeats == 0 {
                        // Complete all at once when starting from 0
                        toggleManager.deleteAllCompletions(for: habit, on: date)
                        for _ in 0..<repeatsPerDay {
                            _ = toggleManager.addSingleCompletion(for: habit, on: completionDateTime, tracksTime: shouldTrackTime)
                        }
                    } else if completedRepeats == repeatsPerDay {
                        // Remove all completions if already complete
                        toggleManager.deleteAllCompletions(for: habit, on: date)
                    } else {
                        // Partial completion - complete remaining repetitions
                        let remaining = repeatsPerDay - completedRepeats
                        for _ in 0..<remaining {
                            _ = toggleManager.addSingleCompletion(for: habit, on: completionDateTime, tracksTime: shouldTrackTime)
                        }
                    }
                }
            case .duration:
                if completedDuration >= targetDuration {
                    // Already complete - toggle off
                    toggleManager.deleteAllCompletions(for: habit, on: date)
                } else {
                    // Complete with target duration and time tracking
                    let completionDateTime = getCompletionDateTime()
                    toggleManager.toggleDurationCompletion(for: habit, on: completionDateTime, minutes: targetDuration, tracksTime: true)
                }
            case .quantity:
                if completedQuantity >= targetQuantity {
                    // Already complete - toggle off
                    toggleManager.deleteAllCompletions(for: habit, on: date)
                } else {
                    // Complete with target quantity and time tracking
                    let completionDateTime = getCompletionDateTime()
                    toggleManager.toggleQuantityCompletion(for: habit, on: completionDateTime, quantity: targetQuantity, tracksTime: true)
                }
            }
            HabitUtilities.clearHabitActivityCache()
            
            // ✅ Also invalidate DayKeyCache for this date
            let dayKey = DayKeyFormatter.localKey(from: date)
            DayKeyCache.shared.invalidate(habit: habit, dayKey: dayKey)
            
            // Always refresh completion state after any toggle
            loadCompletionState()
            
            // Trigger refresh for calendar view if it's open
            refreshChart.toggle()
        }
        
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }


    // MARK: - Helper method to get the correct completion date/time

    private func getCompletionDateTime() -> Date {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            // For today, use current time
            return Date()
        } else {
            // For other dates, use a default meaningful time (e.g., 9 AM) instead of start of day
            let startOfDay = calendar.startOfDay(for: date)
            return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: startOfDay) ?? startOfDay
        }
    }

    // MARK: - Helper methods to update completions to target values

    private func updateCompletionToTargetDuration(_ completionDateTime: Date, _ shouldTrackTime: Bool) {
        guard let completions = habit.completion as? Set<Completion> else { return }
        let calendar = Calendar.current
        
        // Find the completion for this date
        if let completion = completions.first(where: { completion in
            guard let completionDate = completion.date else { return false }
            return calendar.isDate(completionDate, inSameDayAs: date) && completion.completed
        }) {
            completion.duration = Int16(targetDuration)
            completion.progressPercentage = 1.0 // Fully completed
            completion.date = completionDateTime // Use the correct time
            completion.tracksTime = shouldTrackTime
            completion.loggedAt = Date()
            
            do {
                try viewContext.save()
            } catch {
                print("❌ Failed to update duration: \(error)")
                viewContext.rollback()
            }
        }
    }

    private func updateCompletionToTargetQuantity(_ completionDateTime: Date, _ shouldTrackTime: Bool) {
        guard let completions = habit.completion as? Set<Completion> else { return }
        let calendar = Calendar.current
        
        // Find the completion for this date
        if let completion = completions.first(where: { completion in
            guard let completionDate = completion.date else { return false }
            return calendar.isDate(completionDate, inSameDayAs: date) && completion.completed
        }) {
            completion.quantity = Int32(targetQuantity)
            completion.progressPercentage = 1.0 // Fully completed
            completion.date = completionDateTime // Use the correct time
            completion.tracksTime = shouldTrackTime
            completion.loggedAt = Date()
            
            do {
                try viewContext.save()
            } catch {
                print("❌ Failed to update quantity: \(error)")
                viewContext.rollback()
            }
        }
    }

    // MARK: - Updated completeWithCustomDateTime method

    private func completeWithCustomDateTime(_ customDateTime: Date) {
        switch trackingType {
        case .repetitions:
            if repeatsPerDay == 1 {
                // Single repetition - use toggle
                toggleManager.toggleCompletion(for: habit, on: customDateTime, tracksTime: true)
            } else {
                // Multi-repetition - complete remaining repetitions (don't delete existing ones)
                let remaining = repeatsPerDay - completedRepeats
                for _ in 0..<remaining {
                    _ = toggleManager.addSingleCompletion(for: habit, on: customDateTime, tracksTime: true)
                }
            }
        case .duration:
            // Complete with target duration - with time tracking
            toggleManager.toggleDurationCompletion(for: habit, on: customDateTime, minutes: targetDuration, tracksTime: true)
        case .quantity:
            // Complete with target quantity - with time tracking  
            toggleManager.toggleQuantityCompletion(for: habit, on: customDateTime, quantity: targetQuantity, tracksTime: true)
        }
        
        loadCompletionState()
    }

    // MARK: - Helper methods for custom time completion

    private func updateCompletionToTargetDurationWithCustomTime(_ customDateTime: Date) {
        guard let completions = habit.completion as? Set<Completion> else { return }
        let calendar = Calendar.current
        
        // Find the completion for this date
        if let completion = completions.first(where: { completion in
            guard let completionDate = completion.date else { return false }
            return calendar.isDate(completionDate, inSameDayAs: date) && completion.completed
        }) {
            completion.duration = Int16(targetDuration)
            completion.progressPercentage = 1.0
            completion.date = customDateTime // Preserve custom time
            completion.tracksTime = true
            completion.loggedAt = Date()
            
            do {
                try viewContext.save()
            } catch {
                print("❌ Failed to update duration with custom time: \(error)")
                viewContext.rollback()
            }
        }
    }

    private func updateCompletionToTargetQuantityWithCustomTime(_ customDateTime: Date) {
        guard let completions = habit.completion as? Set<Completion> else { return }
        let calendar = Calendar.current
        
        // Find the completion for this date
        if let completion = completions.first(where: { completion in
            guard let completionDate = completion.date else { return false }
            return calendar.isDate(completionDate, inSameDayAs: date) && completion.completed
        }) {
            completion.quantity = Int32(targetQuantity)
            completion.progressPercentage = 1.0
            completion.date = customDateTime // Preserve custom time
            completion.tracksTime = true
            completion.loggedAt = Date()
            
            do {
                try viewContext.save()
            } catch {
                print("❌ Failed to update quantity with custom time: \(error)")
                viewContext.rollback()
            }
        }
    }
    private func toggleSkip() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if isSkipped {
                toggleManager.unskipHabit(for: habit, on: date)
            } else {
                toggleManager.skipHabit(for: habit, on: date)
            }
            loadCompletionState()
            
            // Trigger refresh for calendar view if it's open
            refreshChart.toggle()
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    private func completeWithCustomTime() {
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: selectedTime)
        
        // Check if we're updating a specific completion (user clicked on a time chip)
        if let completionIndex = selectedCompletionIndex {
            // User clicked on a specific completion chip - update that exact completion
            updateSpecificCompletionTime()
            return
        }
        
        // Create the custom datetime from the selected time
        let selectedDate = calendar.startOfDay(for: date)
        let fullDateTime = calendar.date(
            bySettingHour: timeComponents.hour ?? 12,
            minute: timeComponents.minute ?? 0,
            second: timeComponents.second ?? 0,
            of: selectedDate
        ) ?? selectedDate
        
        // Check if habit has any existing completions
        let hasExistingCompletions = (trackingType == .repetitions && completedRepeats > 0) ||
                                   (trackingType == .duration && completedDuration > 0) ||
                                   (trackingType == .quantity && completedQuantity > 0)
        
        if hasExistingCompletions {
            // Update existing completions with the custom time
            updateCompletionTimes(to: fullDateTime)
            
            // If not fully completed, also complete the habit to target with the same time
            if !isCompleted {
                completeWithCustomDateTime(fullDateTime)
            }
        } else {
            // No existing completions - create new completion with custom time
            completeWithCustomDateTime(fullDateTime)
        }
        
        // Refresh the completion state
        loadCompletionState()
        
        // Trigger refresh for calendar view if it's open
        refreshChart.toggle()
        
        showTimePicker = false
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    // MARK: - New helper methods for multi-repetition time setting

    private func completeFirstRepWithCustomTime() {
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: selectedTime)
        
        let selectedDate = calendar.startOfDay(for: date)
        let fullDateTime = calendar.date(
            bySettingHour: timeComponents.hour ?? 12,
            minute: timeComponents.minute ?? 0,
            second: timeComponents.second ?? 0,
            of: selectedDate
        ) ?? selectedDate
        
        // Add only one repetition with time tracking
        _ = toggleManager.addSingleCompletion(for: habit, on: fullDateTime, tracksTime: true)
        
        // Refresh the completion state
        loadCompletionState()
        
        // Trigger refresh for calendar view if it's open
        refreshChart.toggle()
        
        showTimePicker = false
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    private func completeAllRepsWithCustomTime() {
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: selectedTime)
        
        let selectedDate = calendar.startOfDay(for: date)
        let fullDateTime = calendar.date(
            bySettingHour: timeComponents.hour ?? 12,
            minute: timeComponents.minute ?? 0,
            second: timeComponents.second ?? 0,
            of: selectedDate
        ) ?? selectedDate
        
        // Delete any existing completions and add all required repetitions with time tracking
        toggleManager.deleteAllCompletions(for: habit, on: date)
        for _ in 0..<repeatsPerDay {
            _ = toggleManager.addSingleCompletion(for: habit, on: fullDateTime, tracksTime: true)
        }
        
        // Refresh the completion state
        loadCompletionState()
        
        // Trigger refresh for calendar view if it's open
        refreshChart.toggle()
        
        showAllCompletionTimePicker = false
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    // MARK: - Helper Methods for Custom Time Completion

    struct CompletionTimeInfo {
        let time: String
        let hasTime: Bool
        let fullDate: Date
        let completion: Completion
    }
    
    // MARK: - CompletionItem for SmoothPickerStack
    struct CompletionItem: Identifiable, Hashable {
        let id: UUID
        let number: Int
        let time: String
        let hasTime: Bool
        let fullDate: Date
        let completion: Completion
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        
        static func == (lhs: CompletionItem, rhs: CompletionItem) -> Bool {
            lhs.id == rhs.id
        }
    }

    private func getMultiRepetitionCompletionTimes() -> [CompletionTimeInfo] {
        guard let completions = habit.completion as? Set<Completion> else { return [] }
        let calendar = Calendar.current
        
        // Find all completions for this date that are actually completed (not skipped)
        let completionsForDate = completions.filter { completion in
            guard let completionDate = completion.date else { return false }
            return calendar.isDate(completionDate, inSameDayAs: date) && completion.completed
        }
        
        // Sort by logged time (when they were created)
        let sortedCompletions = completionsForDate.sorted { completion1, completion2 in
            let time1 = completion1.loggedAt ?? Date.distantPast
            let time2 = completion2.loggedAt ?? Date.distantPast
            return time1 < time2
        }
        
        return sortedCompletions.compactMap { completion in
            guard let completionDate = completion.date else { return nil }
            
            let timeFormatter = DateFormatter()
            timeFormatter.timeStyle = .short
            
            if completion.tracksTime {
                return CompletionTimeInfo(
                    time: timeFormatter.string(from: completionDate),
                    hasTime: true,
                    fullDate: completionDate,
                    completion: completion
                )
            } else {
                return CompletionTimeInfo(
                    time: "No time",
                    hasTime: false,
                    fullDate: completionDate,
                    completion: completion
                )
            }
        }
    }
    
    private func getCompletionItems() -> [CompletionItem] {
        let timeInfos = getMultiRepetitionCompletionTimes()
        return timeInfos.enumerated().map { index, info in
            // Use a simple UUID() - SwiftUI will track items properly via Identifiable
            // The completion reference itself provides uniqueness
            return CompletionItem(
                id: UUID(),
                number: index + 1,
                time: info.time,
                hasTime: info.hasTime,
                fullDate: info.fullDate,
                completion: info.completion
            )
        }
    }

    private func updateSpecificCompletionTime() {
        guard let selectedItem = selectedCompletionItem else { return }
        
        let completionToUpdate = selectedItem.completion
        let currentNumber = selectedItem.number // Store the current number BEFORE updating
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: selectedTime)
        
        // Preserve the original date from the completion, just update the time
        if let originalDate = completionToUpdate.date {
            let updatedDateTime = calendar.date(
                bySettingHour: timeComponents.hour ?? 12,
                minute: timeComponents.minute ?? 0,
                second: timeComponents.second ?? 0,
                of: originalDate
            ) ?? originalDate
            
            // Update the specific completion object directly
            completionToUpdate.date = updatedDateTime
            completionToUpdate.tracksTime = true
            // Don't update loggedAt - this preserves the original creation order
            
            do {
                try viewContext.save()
                print("✅ Updated specific completion #\(currentNumber) with time: \(DateFormatter().string(from: updatedDateTime))")
            } catch {
                print("❌ Failed to save specific completion time: \(error)")
                viewContext.rollback()
            }
        }
        
        showTimePicker = false
        selectedCompletionIndex = nil
        // Don't reset selectedCompletionItem here - it will be updated in loadCompletionState
        
        // Refresh completion and streak data
        loadCompletionState()
        
        // After loading, find and select the completion with the same number as before
        let updatedItems = getCompletionItems()
        if let matchingItem = updatedItems.first(where: { $0.number == currentNumber }) {
            selectedCompletionItem = matchingItem
        }
        
        // Trigger refresh for calendar view if it's open
        refreshChart.toggle()
        
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    private func getExistingCompletionDate() -> Date? {
        guard let completions = habit.completion as? Set<Completion> else { return nil }
        let calendar = Calendar.current
        
        // Find all completions for this date that are actually completed (not skipped)
        let completionsForDate = completions.filter { completion in
            guard let completionDate = completion.date else { return false }
            return calendar.isDate(completionDate, inSameDayAs: date) && completion.completed
        }
        
        // Return the date of the most recent completion
        if let mostRecentCompletion = completionsForDate.max(by: {
            ($0.loggedAt ?? Date.distantPast) < ($1.loggedAt ?? Date.distantPast)
        }), let completionDate = mostRecentCompletion.date {
            return completionDate
        }
        
        return nil
    }

    private func updateCompletionTimes(to customDateTime: Date) {
        guard let completions = habit.completion as? Set<Completion> else { return }
        let calendar = Calendar.current
        
        // Find all completions for this date that are actually completed (not skipped)
        let completionsForDate = completions.filter { completion in
            guard let completionDate = completion.date else { return false }
            return calendar.isDate(completionDate, inSameDayAs: date) && completion.completed
        }
        
        // Update ALL completions for this date with the custom time
        for completion in completionsForDate {
            completion.date = customDateTime
            completion.tracksTime = true
            completion.loggedAt = Date() // When the adjustment was made
        }
        
        do {
            try viewContext.save()
        } catch {
            print("Failed to save custom completion times: \(error)")
            viewContext.rollback()
        }
    }
/*
    private func completeWithCustomDateTime(_ customDateTime: Date) {
        // Use the same logic as the main toggle button but with custom date/time
        switch trackingType {
        case .repetitions:
            if repeatsPerDay > 1 {
                // For multi-repetition habits, complete all remaining repetitions
                // First delete any existing completions
                toggleManager.deleteAllCompletions(for: habit, on: date)
                
                // Add all required completions with custom time
                for _ in 0..<repeatsPerDay {
                    _ = toggleManager.addSingleCompletion(for: habit, on: customDateTime, tracksTime: true)
                }
                completedRepeats = repeatsPerDay
            } else {
                // Single repetition - use toggle with custom time
                toggleManager.toggleCompletion(for: habit, on: customDateTime, tracksTime: true)
                loadCompletionState()
            }
            
        case .duration:
            // Complete with target duration and custom time
            toggleManager.toggleDurationCompletion(for: habit, on: customDateTime, minutes: targetDuration, tracksTime: true)
            completedDuration = targetDuration
            
        case .quantity:
            // Complete with target quantity and custom time
            toggleManager.toggleQuantityCompletion(for: habit, on: customDateTime, quantity: targetQuantity)
            completedQuantity = targetQuantity
        }
    }
    */
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.string(from: date)
        }
    }
    

    
    private func getCompletionTime() -> String? {
        guard let completions = habit.completion as? Set<Completion>,
              let completion = completions.first(where: { completion in
                  guard let completionDate = completion.date else { return false }
                  return Calendar.current.isDate(completionDate, inSameDayAs: date) && completion.completed
              }),
              let completionDate = completion.date else {
            return nil
        }
        
        // If completion doesn't track time, return nil (this means it was completed from HabitRowView)
        if !completion.tracksTime {
            return nil
        }
        
        // For completions that track time, always show the time
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: completionDate)
    }
    
    private var backgroundGradient: some View {
        let base = habitColor
        let customBottom = colorScheme == .dark ? Color(hex: "14141A") : Color(hex: "E8E8FF")

        let top   = colorScheme == .dark ? 0.10 : 0.15
        let mid   = colorScheme == .dark ? 0.06 : 0.11
        let low   = colorScheme == .dark ? 0.04 : 0.08

        return LinearGradient(
            gradient: Gradient(colors: [
                base.opacity(top),      // habit color at TOP (most visible)
                base.opacity(mid),
                base.opacity(low),
                customBottom            // custom color at BOTTOM
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    // MARK: - Body
    
    var body: some View {
        ZStack {
            backgroundGradient
            VStack(spacing: 0) {
                // Header - fixed height
                headerSection
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    .padding(.bottom, 26)
                
                // Main Toggle Area - fixed height
                mainToggleSection
                    .padding(.horizontal, 18)
                    //.padding(.bottom, 6)
                
                // Time button directly under ring - fixed height
                timeButtonSection
                    .padding(.horizontal, 16)
                    //.padding(.bottom, 6)
                
                 // Fills remaining space
                
                // Skip button and other actions at bottom - fixed height
                bottomActionsSection
                    .padding(.horizontal, 16)
                    //.padding(.bottom, 6)
                
                
            }
            .frame(maxWidth: .infinity)
            .allowsHitTesting(true)
            .onAppear {
                loadCompletionState()
            }
            .onChange(of: selectedCalendarDate) { oldDate, newDate in
                // When user interacts with calendar, refresh our completion state
                loadCompletionState()
            }
            .onChange(of: refreshChart) { _, _ in
                // When calendar triggers refresh, update our completion state
                loadCompletionState()
            }
            .onChange(of: showNotesSheet) { _, _ in
                // Refresh state when notes sheet is dismissed to update checkmark
                if !showNotesSheet {
                    loadCompletionState()
                }
            }
            .onChange(of: showTriggerSheet) { _, _ in
                // Refresh state when trigger sheet is dismissed to update checkmark
                if !showTriggerSheet {
                    loadCompletionState()
                }
            }
            .onChange(of: completedRepeats) { oldValue, newValue in
                // When completions change (user toggles or deletes), update picker
                if trackingType == .repetitions && repeatsPerDay > 1 {
                    // Get the updated completion items
                    let items = getCompletionItems()
                    
                    if newValue > oldValue {
                        // Added a completion - jump to latest
                        if let lastItem = items.last {
                            selectedCompletionItem = lastItem
                            selectedTime = lastItem.fullDate
                        }
                    } else if newValue < oldValue {
                        // Deleted a completion - update to last available or clear if none
                        if let lastItem = items.last {
                            selectedCompletionItem = lastItem
                            selectedTime = lastItem.fullDate
                        } else {
                            selectedCompletionItem = nil
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private var headerSection: some View {
        HStack(spacing: 12) {
            // Main habit info box (3/4 width) - increased padding
            HStack(alignment: .center, spacing: 0) {
                // Small habit icon using HabitIconView
                HStack (spacing: 4){
                    HabitIconView(
                        iconName: habit.icon ?? habit.name?.first?.uppercased(),
                        isActive: true,
                        habitColor: habitColor,
                        streak: 0, // No streak display in header
                        showStreaks: false,
                        useModernBadges: false,
                        isFutureDate: false,
                        isBadHabit: habit.isBadHabit,
                        intensityLevel: habit.intensityLevel,
                        durationMinutes: nil
                    )
                    .scaleEffect(0.8)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        // Habit name with scrolling animation
                        ScrollingText(
                            habit.name ?? "Habit",
                            font: .customFont("Lexend", .bold, 17),
                            speed: 30,
                            fadeWidth: 15
                        )
                        .frame(height: 22)
                        
                        
                        // Only schedule tag (removed frequency)
                        HabitScheduleTag(habit: habit, colorScheme: colorScheme)
                            .offset(y: -2)
                    }
                }
                .offset(x: -5)
                
                Spacer()
                
                // Detail arrow indicator
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 15) // Increased from 16
            .padding(.vertical, 12) // Increased from 8
            .frame(maxWidth: .infinity)
            .frame(height: 48) // Increased from 40
            .sheetGlassBackground(cornerRadius: 30)
            .onTapGesture {
                showHabitDetailSheet = true
            }
            
            // Stats box (1/4 width) - horizontal layout with divider
            HStack(alignment: .center, spacing: 8) {
                // Current streak (left side)
                VStack(spacing: 1) {
                    Text("\(currentStreakValue)")
                        .font(.custom("Lexend-SemiBold", size: 16))
                        .foregroundColor(.primary)
                        .contentTransition(.numericText())
                    
                    Text("Streak")
                        .font(.custom("Lexend-Medium", size: 10))
                        .foregroundColor(.secondary)
                }
                
                // Divider
                Rectangle()
                    .fill(.secondary.opacity(0.3))
                    .frame(width: 1, height: 20)
                
                // Total completions (right side)
                VStack(spacing: 1) {
                    Text("\(totalCompletionDays)")
                        .font(.custom("Lexend-SemiBold", size: 16))
                        .foregroundColor(.primary)
                        .contentTransition(.numericText())
                    
                    Text("Total")
                        .font(.custom("Lexend-Medium", size: 10))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12) // Increased from 8
            .frame(width: 100, height: 48) // Increased width and height to match habit box
            .sheetGlassBackground(cornerRadius: 30)
        }
        .animation(.smooth(duration: 0.4, extraBounce: 0.1), value: currentStreakValue)
        .animation(.smooth(duration: 0.4, extraBounce: 0.1), value: totalCompletionDays)
    }
    
    @ViewBuilder
    private var mainToggleSection: some View {
        HStack(spacing: 8) {
            // Enhanced Minus Button - matching bottom button style
            if shouldShowAdjustButtons {
                Button(action: { adjustValue(-1) }) {
                    Image(systemName: "minus")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(width: 38, height: 38)
                }
                .glassButton()
                .disabled(
                    (trackingType == .repetitions && completedRepeats == 0) ||
                    (trackingType == .duration && completedDuration == 0) ||
                    (trackingType == .quantity && completedQuantity == 0)
                )
                .opacity(
                    ((trackingType == .repetitions && completedRepeats == 0) ||
                     (trackingType == .duration && completedDuration == 0) ||
                     (trackingType == .quantity && completedQuantity == 0)) ? 0.3 : 1
                )
            } else {
                // Invisible placeholder to maintain layout
                Spacer()
                    .frame(width: 38, height: 38)
            }
            
            VStack(spacing: 0) {
                ZStack {
                    // Use BadHabitButton for bad habits, RingFillCheckmarkButton for regular habits
                    Button(action: toggleCompletion) {
                        if habit.isBadHabit {
                            BadHabitButton(
                                successColor: .green,
                                failureColor: .red,
                                isBroken: .init(
                                    get: { isCompleted },
                                    set: { _ in
                                        // The BadHabitButton will handle the toggle,
                                        // but we need to ensure the main toggleCompletion is called
                                        // This is handled by the main button action
                                    }
                                ),
                                streakCount: currentStreak
                            ) {
                                // This is called by BadHabitButton when tapped
                                // We need to call toggleCompletion to actually update the data
                                toggleCompletion()
                            }
                            .scaleEffect(ringScale)
                        } else {
                            RingFillCheckmarkButton(
                                habitColor: habitColor,
                                isCompleted: .constant(isCompleted),
                                onTap: toggleCompletion,
                                repeatsPerDay: repeatsPerDay,
                                completedRepeats: completedRepeats,
                                isSkipped: isSkipped,
                                trackingType: trackingType == .repetitions ? .repetitions :
                                    trackingType == .duration ? .duration : .quantity,
                                targetDuration: targetDuration,
                                completedDuration: completedDuration,
                                targetQuantity: targetQuantity,
                                completedQuantity: completedQuantity,
                                quantityUnit: quantityUnit,
                                hideText: true // Hide the internal text
                            )
                            .scaleEffect(ringScale)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Clean overlay text rendered at proper scale (only for non-bad habits)
                    if !isSkipped && !habit.isBadHabit {
                        VStack(spacing: 0) {
                            // Main progress text
                            VStack {
                                Text(getMainProgressText())
                                    .font(.custom("Lexend-Bold", size: 28))
                                    .foregroundColor(.primary)
                                    .contentTransition(.numericText())
                                    .opacity(shouldShowMainText() ? 1 : 0)
                                    .animation(.smooth(duration: 0.3), value: getMainProgressInt())
                                
                                // Subtitle text for incomplete states
                                if shouldShowSubtitle() {
                                    Text(getSubtitleText())
                                        .font(.custom("Lexend-SemiBold", size: 12))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .offset(y: 15)
                            // Badge for completed states (bottom right equivalent)
                            Text(getBadgeText())
                                .font(.custom("Lexend-Bold", size: 18))
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                .contentTransition(.numericText())
                                .padding(.horizontal, 13)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(.ultraThinMaterial)
                                )
                                .offset(x: 65, y: 60)
                                .scaleEffect(shouldShowBadge() ? 1.0 : 0.1)
                                .opacity(shouldShowBadge() ? 1.0 : 0.0)
                                .animation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.3), value: shouldShowBadge())
                                .animation(.smooth(duration: 0.3), value: getBadgeInt())
                        }
                        .allowsHitTesting(false) // Let touches pass through to button
                    }
                }
            }
            .frame(width: 200, height: 180) // Reduced ring area size
            .padding(.bottom, 6)
            
            // Enhanced Plus Button - matching bottom button style
            if shouldShowAdjustButtons {
                Button(action: { adjustValue(1) }) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(width: 38, height: 38)
                }
                .glassButton()
                .disabled(
                    (trackingType == .repetitions && completedRepeats >= repeatsPerDay) ||
                    (trackingType == .duration && completedDuration >= targetDuration) ||
                    (trackingType == .quantity && completedQuantity >= targetQuantity)
                )
                .opacity(
                    ((trackingType == .repetitions && completedRepeats >= repeatsPerDay) ||
                     (trackingType == .duration && completedDuration >= targetDuration) ||
                     (trackingType == .quantity && completedQuantity >= targetQuantity)) ? 0.3 : 1
                )
            } else {
                // Invisible placeholder to maintain layout
                Spacer()
                    .frame(width: 38, height: 38)
            }
        }
        .frame(height: 200) // Reduced main toggle section height
    }
    
    private func getMainProgressText() -> String {
        switch trackingType {
        case .repetitions:
            if repeatsPerDay > 1 && completedRepeats < repeatsPerDay {
                return "\(completedRepeats)"
            }
            return ""
        case .duration:
            if completedDuration < targetDuration {
                return formatDuration(completedDuration)
            }
            return ""
        case .quantity:
            if completedQuantity < targetQuantity {
                return "\(completedQuantity)"
            }
            return ""
        }
    }
    
    private func getMainProgressInt() -> Int {
        switch trackingType {
        case .repetitions:
            return completedRepeats
        case .duration:
            return completedDuration
        case .quantity:
            return completedQuantity
        }
    }

    private func shouldShowMainText() -> Bool {
        return !getMainProgressText().isEmpty && !isCompleted
    }

    private func shouldShowSubtitle() -> Bool {
        switch trackingType {
        case .repetitions:
            return repeatsPerDay > 1 && !isCompleted
        case .duration:
            return !isCompleted
        case .quantity:
            return !isCompleted
        }
    }

    private func getSubtitleText() -> String {
        switch trackingType {
        case .repetitions:
            return "of \(repeatsPerDay)"
        case .duration:
            return "of \(formatDuration(targetDuration))"
        case .quantity:
            return "of \(targetQuantity) \(quantityUnit)"
        }
    }

    private func shouldShowBadge() -> Bool {
        return isCompleted
    }

    private func getBadgeText() -> String {
        switch trackingType {
        case .repetitions:
            return "\(completedRepeats)"
        case .duration:
            return formatDuration(completedDuration)
        case .quantity:
            return "\(completedQuantity) \(quantityUnit)"
        }
    }
    
    private func getBadgeInt() -> Int {
        switch trackingType {
        case .repetitions:
            return completedRepeats
        case .duration:
            return completedDuration
        case .quantity:
            return completedQuantity
        }
    }

    private func formatDuration(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            return mins > 0 ? "\(hours)h\(mins)m" : "\(hours)h"
        }
    }


    
    @ViewBuilder
    private var timeButtonSection: some View {
        ZStack {
            // Centered group — always in the middle
            Group {
                if habit.isBadHabit {
                    if isSkipped {
                        Text("Skipped")
                            .font(.custom("Lexend-Medium", size: 16))
                            .foregroundColor(.secondary)
                    } else {
                        Text(isCompleted ? "Habit Broken" : "Streak Active")
                            .font(.custom("Lexend-Medium", size: 16))
                            .foregroundColor(isCompleted ? .red : .green)
                    }
                } else if trackingType == .repetitions && repeatsPerDay > 1 {
                    multiRepetitionTimeContent
                } else {
                    singleCompletionTimeContent
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
/*
            // Row content (Date on left, Spacer to maintain structure)
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Date")
                        .font(.custom("Lexend-Medium", size: 12))
                        .foregroundColor(.secondary)

                    Text(formatDate(date))
                        .font(.custom("Lexend-Medium", size: 15))
                        .foregroundColor(.primary)
                }
                .frame(width: 90, alignment: .leading)

                Spacer()
            }
            .padding(.horizontal, 16)
 */
        }
        .frame(height: 52)
    }
    
    @ViewBuilder
    private var singleCompletionTimeContent: some View {
        // Time picker button 
        Button(action: {
            // Set default time to completion time or current time
            selectedTime = getDefaultTimeForPicker()
            showTimePicker.toggle()
        }) {
            HStack(spacing: 6) {
                // Show different text based on habit state
                if isSkipped {
                    Text("Skipped")
                        .font(.custom("Lexend-Medium", size: 16))
                        .foregroundColor(.secondary)
                } else if let completionTime = getCompletionTime() {
                    Text(completionTime)
                        .font(.custom("Lexend-Medium", size: 17))
                        .foregroundColor(.primary)
                } else if isCompleted {
                    Text("No time logged")
                        .font(.custom("Lexend-Medium", size: 15))
                        .foregroundColor(.secondary)
                } else {
                    Text("Choose Time")
                        .font(.custom("Lexend-Medium", size: 17))
                        .foregroundColor(.secondary)
                }
                
                // Arrow icon - only show when not skipped
                if !isSkipped {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(width: 140, height: 40)
        .glassButton(tintColor: getCompletionTime() != nil && !isSkipped ? habitColor.opacity(0.3) : nil)
        .disabled(isSkipped)
        .scaleEffect(showTimePicker ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: showTimePicker)
        .popover(isPresented: $showTimePicker, arrowEdge: .bottom) {
            VStack(spacing: 0) {
                // Header with title
                HStack {
                    Text(isCompleted ? "Adjust Time" : "Set Time")
                        .font(.custom("Lexend-Medium", size: 14))
                        .foregroundColor(.primary)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .padding(.bottom, 6)
                
                // Direct DatePicker
                DatePicker(
                    "",
                    selection: $selectedTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(WheelDatePickerStyle())
                .labelsHidden()
                .accentColor(habitColor)
                .frame(height: 150)
                .padding(.horizontal, 6)
                
                // Action Buttons
                HStack(spacing: 8) {
                    Button("Cancel") {
                        showTimePicker = false
                    }
                    .font(.custom("Lexend-Medium", size: 12))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                    
                    Button(isCompleted ? "Update" : "Set") {
                        completeWithCustomTime()
                    }
                    .font(.custom("Lexend-Medium", size: 12))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(habitColor, in: RoundedRectangle(cornerRadius: 8))
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 12)
            }
            .frame(width: 260)
            .frame(maxHeight: 240)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
            .presentationCompactAdaptation(.popover)
        }
    }
    
    @ViewBuilder
    private var multiRepetitionTimeContent: some View {
        if isSkipped {
            // Show skipped state
            Text("Skipped")
                .font(.custom("Lexend-Medium", size: 16))
                .foregroundColor(.secondary)
        } else {
            // Show completion times with native Picker
            let completionItems = getCompletionItems()
            
            if completionItems.isEmpty {
                // No completions yet - show "Choose Time" button centered
                Button(action: {
                    selectedTime = Date()
                    selectedCompletionIndex = nil
                    selectedCompletionItem = nil
                    showTimePicker = true
                }) {
                    Text("Choose Time")
                        .font(.custom("Lexend-Medium", size: 17))
                        .foregroundColor(.secondary)
                }
                .frame(width: 140, height: 40)
                .glassButton()
                .scaleEffect(showTimePicker ? 0.98 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: showTimePicker)
                .popover(isPresented: $showTimePicker, arrowEdge: .bottom) {
                    VStack(spacing: 0) {
                        // Header with title
                        HStack {
                            Text("Set Time")
                                .font(.custom("Lexend-Medium", size: 14))
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.top, 12)
                        .padding(.bottom, 6)
                        
                        // Direct DatePicker
                        DatePicker(
                            "",
                            selection: $selectedTime,
                            displayedComponents: .hourAndMinute
                        )
                        .datePickerStyle(WheelDatePickerStyle())
                        .labelsHidden()
                        .accentColor(habitColor)
                        .frame(height: 150)
                        .padding(.horizontal, 6)
                        
                        // Action Buttons
                        HStack(spacing: 8) {
                            Button("Cancel") {
                                showTimePicker = false
                                selectedCompletionIndex = nil
                                selectedCompletionItem = nil
                            }
                            .font(.custom("Lexend-Medium", size: 12))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                            
                            Button("Set") {
                                completeFirstRepWithCustomTime()
                            }
                            .font(.custom("Lexend-Medium", size: 12))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(habitColor, in: RoundedRectangle(cornerRadius: 8))
                        }
                        .padding(.horizontal, 12)
                        .padding(.top, 8)
                        .padding(.bottom, 12)
                    }
                    .frame(width: 260)
                    .frame(maxHeight: 240)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                    .presentationCompactAdaptation(.popover)
                }
            } else if completionItems.count == 1 {
                // Only one completion - just show time button (no picker needed)
                let selectedItem = completionItems[0]
                Button(action: {
                    selectedCompletionItem = selectedItem
                    selectedTime = selectedItem.fullDate
                    showTimePicker = true
                }) {
                    HStack(spacing: 6) {
                        if selectedItem.hasTime {
                            Text(selectedItem.time)
                                .font(.custom("Lexend-Medium", size: 17))
                                .foregroundColor(.primary)
                        } else {
                            Text("Set Time")
                                .font(.custom("Lexend-Medium", size: 17))
                                .foregroundColor(.secondary)
                        }
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 140, height: 40)
                .glassButton(tintColor: selectedItem.hasTime ? habitColor.opacity(0.3) : nil)
                .scaleEffect(showTimePicker ? 0.98 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: showTimePicker)
                .popover(isPresented: $showTimePicker, arrowEdge: .bottom) {
                    VStack(spacing: 0) {
                        // Header with title
                        HStack {
                            Text("Adjust Time")
                                .font(.custom("Lexend-Medium", size: 14))
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.top, 12)
                        .padding(.bottom, 6)
                        
                        // Direct DatePicker
                        DatePicker(
                            "",
                            selection: $selectedTime,
                            displayedComponents: .hourAndMinute
                        )
                        .datePickerStyle(WheelDatePickerStyle())
                        .labelsHidden()
                        .accentColor(habitColor)
                        .frame(height: 150)
                        .padding(.horizontal, 6)
                        
                        // Action Buttons
                        HStack(spacing: 8) {
                            Button("Cancel") {
                                showTimePicker = false
                            }
                            .font(.custom("Lexend-Medium", size: 12))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                            
                            Button("Update") {
                                updateSpecificCompletionTime()
                            }
                            .font(.custom("Lexend-Medium", size: 12))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(habitColor, in: RoundedRectangle(cornerRadius: 8))
                        }
                        .padding(.horizontal, 12)
                        .padding(.top, 8)
                        .padding(.bottom, 12)
                    }
                    .frame(width: 260)
                    .frame(maxHeight: 240)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                    .presentationCompactAdaptation(.popover)
                }
            } else {
                // Multiple completions - show picker on left and time button centered
                HStack(spacing: 0) {
                    // Left side - Native Picker showing completion number (only when multiple completions)
                    Menu {
                        ForEach(completionItems) { item in
                            Button(action: {
                                // Haptic feedback when changing completion number
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                
                                // Animate the time change with delay
                                withAnimation(.smooth(duration: 0.4).delay(0.2)) {
                                    selectedCompletionItem = item
                                    selectedTime = item.fullDate
                                }
                            }) {
                                Text("#\(item.number)")
                                    .font(.custom("Lexend-SemiBold", size: 15))
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text("#\(selectedCompletionItem?.number ?? completionItems.last?.number ?? 1)")
                                .font(.custom("Lexend-SemiBold", size: 15))
                                .foregroundColor(.primary)
                                .contentTransition(.numericText())
                            Image(systemName: "chevron.up")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 60, height: 40)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(.ultraThinMaterial)
                        )
                    }
                    .onChange(of: completionItems.count) { oldCount, newCount in
                        // When completion count changes, jump to latest
                        if newCount > oldCount, let lastItem = completionItems.last {
                            selectedCompletionItem = lastItem
                            selectedTime = lastItem.fullDate
                        } else if newCount < oldCount {
                            // When count decreases (deletion), select last available
                            if let lastItem = completionItems.last {
                                selectedCompletionItem = lastItem
                                selectedTime = lastItem.fullDate
                            } else {
                                selectedCompletionItem = nil
                            }
                        }
                    }
                    .onAppear {
                        // Only set initial selection if none exists
                        if selectedCompletionItem == nil {
                            selectedCompletionItem = completionItems.last
                        }
                    }
                    
                    // Fixed spacing before arrow
                    Color.clear
                        .frame(width: 20)
                    
                    // Arrow indicator - centered
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary.opacity(0.8))
                    
                    // Fixed spacing after arrow
                    Color.clear
                        .frame(width: 1)
                    
                    // Center - Time button showing the selected completion's time
                    if let selectedItem = selectedCompletionItem {
                        Button(action: {
                            selectedTime = selectedItem.fullDate
                            showTimePicker = true
                        }) {
                            HStack(spacing: 6) {
                                if selectedItem.hasTime {
                                    Text(selectedItem.time)
                                        .font(.custom("Lexend-Medium", size: 17))
                                        .foregroundColor(.primary)
                                        .contentTransition(.numericText())
                                } else {
                                    Text("Set Time")
                                        .font(.custom("Lexend-Medium", size: 15))
                                        .foregroundColor(.secondary)
                                }
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            .contentShape(Rectangle())
                        }
                        .frame(width: 120, height: 40)
                        .glassButton(tintColor: selectedItem.hasTime ? habitColor.opacity(0.3) : nil)
                        .scaleEffect(showTimePicker ? 0.98 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: showTimePicker)
                        .animation(.smooth(duration: 0.4).delay(0.2), value: selectedItem.time)
                        .popover(isPresented: $showTimePicker, arrowEdge: .bottom) {
                            VStack(spacing: 0) {
                                // Header with title showing which completion is being edited
                                HStack {
                                    if let selectedItem = selectedCompletionItem {
                                        Text("Adjust Time (#\(selectedItem.number))")
                                            .font(.custom("Lexend-Medium", size: 14))
                                            .foregroundColor(.primary)
                                    } else {
                                        Text("Adjust Time")
                                            .font(.custom("Lexend-Medium", size: 14))
                                            .foregroundColor(.primary)
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal, 12)
                                .padding(.top, 12)
                                .padding(.bottom, 6)
                                
                                // Direct DatePicker
                                DatePicker(
                                    "",
                                    selection: $selectedTime,
                                    displayedComponents: .hourAndMinute
                                )
                                .datePickerStyle(WheelDatePickerStyle())
                                .labelsHidden()
                                .accentColor(habitColor)
                                .frame(height: 150)
                                .padding(.horizontal, 6)
                                
                                // Action Buttons
                                HStack(spacing: 8) {
                                    Button("Cancel") {
                                        showTimePicker = false
                                    }
                                    .font(.custom("Lexend-Medium", size: 12))
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                                    
                                    Button("Update") {
                                        updateSpecificCompletionTime()
                                    }
                                    .font(.custom("Lexend-Medium", size: 12))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(habitColor, in: RoundedRectangle(cornerRadius: 8))
                                }
                                .padding(.horizontal, 12)
                                .padding(.top, 8)
                                .padding(.bottom, 12)
                            }
                            .frame(width: 260)
                            .frame(maxHeight: 240)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                            .presentationCompactAdaptation(.popover)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    @ViewBuilder
    private var bottomActionsSection: some View {
        // Use HStack to evenly distribute buttons instead of ZStack
        VStack {
            // Elegant minimal divider - matching HabitDetailSheet style
            VStack(spacing: 0) {
                let baseColor = habitColor
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                baseColor.opacity(colorScheme == .dark ? 0.2 : 0.15),
                                baseColor.opacity(colorScheme == .dark ? 0.3 : 0.4),
                                baseColor.opacity(colorScheme == .dark ? 0.2 : 0.15),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1.5)
                    .opacity(0.8)
            }
            .padding(.vertical, 7)
            
            Spacer()
            HStack {
                // Skip button - only show for non-bad habits
                if !habit.isBadHabit {
                    Button(action: toggleSkip) {
                        Image(systemName: isSkipped ? "arrow.uturn.backward.circle.fill" : "forward.fill")
                            .font(.system(size: 18, weight: .medium))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundColor(isSkipped ? .secondary : .primary)
                            .frame(width: 38, height: 38)
                    }
                    .glassButton()
                    
                    Spacer()
                }
                
                // Trigger button - show for all bad habits, but disable when not broken
                if habit.isBadHabit {
                    Button(action: { 
                        if isCompleted {
                            showTriggerSheet.toggle() 
                        }
                    }) {
                        ZStack {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(isCompleted ? .primary : .secondary)
                            
                            // Checkmark indicator if trigger exists
                            if habit.hasTrigger(for: date) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.primary)
                                    .background(Circle().fill(.regularMaterial))
                                    .offset(x: 11, y: -11)
                            }
                        }
                        .frame(width: 38, height: 38)
                    }
                    .glassButton()
                    .disabled(!isCompleted)
                    .opacity(isCompleted ? 1.0 : 0.5)
                    
                    Spacer()
                }
                
                // Calendar button
                Button(action: {
                    showCalendarView.toggle()
                }) {
                    Image(systemName: "calendar")
                        .font(.system(size: 18, weight: .medium))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundColor(.primary)
                        .frame(width: 38, height: 38)
                }
                .glassButton()
                
                Spacer()
                
                // Notes button
                Button(action: { 
                    // For bad habits, only allow notes when completed
                    if !habit.isBadHabit || isCompleted {
                        showNotesSheet.toggle() 
                    }
                }) {
                    ZStack {
                        Image(systemName: "text.rectangle")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor((habit.isBadHabit && !isCompleted) ? .secondary : .primary)
                        
                        // Checkmark indicator if note exists
                        if habit.hasNote(for: date) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.primary)
                                .background(Circle().fill(.regularMaterial))
                                .offset(x: 11, y: -11)
                        }
                    }
                    .frame(width: 38, height: 38)
                }
                .glassButton()
                .disabled(habit.isBadHabit && !isCompleted)
                .opacity((habit.isBadHabit && !isCompleted) ? 0.5 : 1.0)
                
                // Conditionally show Pomodoro timer button - only for duration tracking and non-bad habits
                if trackingType == .duration && !isSkipped && !habit.isBadHabit {
                    Spacer()
                    
                    // Pomodoro timer button
                    Button(action: { showPomodoroTimer.toggle() }) {
                        Image(systemName: "timer")
                            .font(.system(size: 18, weight: .medium))
                            
                            .foregroundColor(.primary)
                            .frame(width: 38, height: 38)
                    }
                    .glassButton()
                }
            }
            .padding(.horizontal)
        }
        .frame(height: 70) // Increased height for better spacing
        .sheet(isPresented: $showCalendarView) {
            CalendarAndCompletionView(
                habit: habit,
                selectedCalendarDate: $selectedCalendarDate,
                calendarTitle: $calendarTitle,
                focusedWeek: $focusedWeek,
                isDraggingCalendar: $isDraggingCalendar,
                calendarDragProgress: $calendarDragProgress,
                getFilteredHabitsForDate: getFilteredHabitsForDate,
                refreshTrigger: $refreshChart
            )
            
            .environment(\.managedObjectContext, viewContext)
            .presentationDetents([.fraction(0.70)])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(45)
            
        }
        .sheet(isPresented: $showPomodoroTimer) {
            PomodoroTimerSheet(
                habit: habit,
                date: date,
                habitColor: habitColor,
                targetDuration: targetDuration,
                onComplete: { minutes in
                    // Save the completed minutes using toggleManager with time tracking
                    let completionDateTime = getCompletionDateTime()
                    toggleManager.toggleDurationCompletion(for: habit, on: completionDateTime, minutes: minutes)
                    updateCompletionToTrackTime(completionDateTime)
                    loadCompletionState()
                    showPomodoroTimer = false
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            )
            .presentationDetents([.height(400)])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(45)
        }
        .sheet(isPresented: $showHabitDetailSheet) {
            HabitDetailSheet(
                habit: habit,
                date: date,
                isPresented: $showHabitDetailSheet,
                selectedDetent: .constant(.large)
            )
            .presentationDetents([.fraction(0.88)])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showNotesSheet) {
            HabitNotesSheet(
                habit: habit,
                date: date,
                habitColor: habitColor,
                isPresented: $showNotesSheet
            )
            .presentationDetents([.fraction(0.43)])
            .presentationDragIndicator(.visible)
            //.presentationCornerRadius(32)
            //.presentationBackgroundInteraction(.disabled) // Allow interaction with background
        }
        .sheet(isPresented: $showTriggerSheet) {
            HabitTriggerSheet(
                habit: habit,
                date: date,
                habitColor: habitColor,
                isPresented: $showTriggerSheet
            )
            .presentationDetents([.fraction(0.55)])
            .presentationDragIndicator(.visible)
        }
    }

    private func updateCompletionToTrackTime(_ completionDateTime: Date) {
        guard let completions = habit.completion as? Set<Completion> else { return }
        let calendar = Calendar.current
        
        // Find the most recent completion for this date
        let completionsForDate = completions.filter { completion in
            guard let completionDate = completion.date else { return false }
            return calendar.isDate(completionDate, inSameDayAs: date) && completion.completed
        }
        
        if let mostRecentCompletion = completionsForDate.max(by: {
            ($0.loggedAt ?? Date.distantPast) < ($1.loggedAt ?? Date.distantPast)
        }) {
            mostRecentCompletion.date = completionDateTime
            mostRecentCompletion.tracksTime = true
            mostRecentCompletion.loggedAt = Date()
            
            do {
                try viewContext.save()
            } catch {
                print("❌ Failed to update completion to track time: \(error)")
                viewContext.rollback()
            }
        }
    }

    private func getDefaultTimeForPicker() -> Date {
        // If habit is completed, use the completion time
        if let completionTime = getCompletionDateTimePicker() {
            return completionTime
        }
        // Otherwise use current time
        return Date()
    }

    private func getCompletionDateTimePicker() -> Date? {
        guard let completions = habit.completion as? Set<Completion>,
              let completion = completions.first(where: { completion in
                  guard let completionDate = completion.date else { return false }
                  return Calendar.current.isDate(completionDate, inSameDayAs: date) && completion.completed && completion.tracksTime
              }),
              let completionDate = completion.date else {
            return nil
        }
        return completionDate
    }
}


// MARK: - Minimal Time Picker Popover (Direct Integration)
struct MinimalTimePickerPopover: View {
    @Binding var selectedTime: Date
    let isAdjustingExisting: Bool
    let habitColor: Color
    let onComplete: (Date) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with title
            HStack {
                Text(isAdjustingExisting ? "Adjust Time" : "Set Time")
                    .font(.custom("Lexend-Medium", size: 14))
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .padding(.bottom, 6)
            
            // Direct DatePicker - Smaller height
            DatePicker(
                "",
                selection: $selectedTime,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(WheelDatePickerStyle())
            .labelsHidden()
            .accentColor(habitColor)
            .frame(height: 150) // Slightly bigger height
            .padding(.horizontal, 6)
            
            // Action Buttons
            HStack(spacing: 8) {
                Button("Cancel") {
                    onCancel()
                }
                .font(.custom("Lexend-Medium", size: 12))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                
                Button(isAdjustingExisting ? "Update" : "Set") {
                    onComplete(selectedTime)
                }
                .font(.custom("Lexend-Medium", size: 12))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(habitColor, in: RoundedRectangle(cornerRadius: 8))
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
        .frame(width: 260) // Slightly bigger width
        .frame(maxHeight: 240) // Slightly bigger overall
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

struct HabitToggleSheet_AllTypes_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Repetitions
            HabitToggleSheet(
                habit: mockHabit(
                    name: "Push-ups",
                    color: .systemBlue,
                    type: .repetitions(count: 3)
                ),
                date: Date(),
                currentStreak: 9,
                isPresented: .constant(true)
            )
            .presentationDetents([.height(520)])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(32)
            
            .previewDisplayName("Repetitions – 5 per day")

            // Duration
            HabitToggleSheet(
                habit: mockHabit(
                    name: "Meditation",
                    color: .systemGreen,
                    type: .duration(minutes: 30)
                ),
                date: Date(),
                currentStreak: 12,
                isPresented: .constant(true)
            )
            .presentationDetents([.height(520)])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(32)
            .presentationBackground(.ultraThinMaterial)
            .previewDisplayName("Duration – 30 minutes")

            // Quantity
            HabitToggleSheet(
                habit: mockHabit(
                    name: "Drink Water",
                    color: .systemCyan,
                    type: .quantity(amount: 8, unit: "glasses")
                ),
                date: Date(),
                currentStreak: 5,
                isPresented: .constant(true)
            )
            .presentationDetents([.height(520)])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(32)
            .presentationBackground(.ultraThinMaterial)
            .previewDisplayName("Quantity – 8 glasses")
        }
    }
}

// MARK: - Mock Builders
private enum TrackingKind {
    case repetitions(count: Int)
    case duration(minutes: Int)
    case quantity(amount: Int, unit: String)

    var typeString: String {
        switch self {
        case .repetitions: return "repetitions"
        case .duration:    return "duration"
        case .quantity:    return "quantity"
        }
    }
}

private func mockHabit(
    name: String,
    color: UIColor,
    type: TrackingKind
) -> Habit {
    let context = PersistenceController.preview.container.viewContext

    let habit = Habit(context: context)
    habit.id = UUID()
    habit.name = name

    // Color
    if let colorData = try? NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: false) {
        habit.color = colorData
    }

    // Repeat Pattern
    let pattern = RepeatPattern(context: context)
    pattern.trackingType = type.typeString
    pattern.effectiveFrom = Date()
    pattern.habit = habit

    switch type {
    case .repetitions(let count):
        pattern.repeatsPerDay = Int16(count)

    case .duration(let minutes):
        pattern.duration = Int16(minutes)
        pattern.repeatsPerDay = 1

    case .quantity(let amount, let unit):
        pattern.targetQuantity = Int32(amount)
        pattern.quantityUnit = unit
        pattern.repeatsPerDay = 1
    }

    habit.addToRepeatPattern(pattern)
    return habit
}

// MARK: - Completion Time Chip Component
struct CompletionTimeChip: View {
    let time: String
    let hasTime: Bool
    let habitColor: Color
    let repetitionNumber: Int
    let isSelected: Bool
    let onTap: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                // Small number indicator
                Text("\(repetitionNumber)")
                    .font(.custom("Lexend-Medium", size: 11))
                    .foregroundColor(hasTime ? .primary : .secondary)
                    .frame(width: 18, height: 18)
                    .background(
                        Circle()
                            .fill(hasTime ? habitColor.opacity(0.12) : Color.secondary.opacity(0.08))
                    )
                
                // Time text
                Text(time)
                    .font(.custom("Lexend-Medium", size: 12))
                    .foregroundColor(hasTime ? .primary : .secondary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(
                                isSelected ? habitColor : Color.secondary.opacity(0.2),
                                lineWidth: isSelected ? 1.5 : 0.8
                            )
                    )
            )
            .scaleEffect(isSelected ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}



// MARK: - Streak and Completion Display Component
struct StreakCompletionDisplay: View {
    let currentStreak: Int
    let totalCompletions: Int
    let habitColor: Color
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 1) {
            // Current streak - orange color
            HStack(alignment: .center, spacing: 2) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.orange)
                
                Text("\(currentStreak)")
                    .font(.custom("Lexend-SemiBold", size: 13))
                    .foregroundColor(.orange)
                    .contentTransition(.numericText())
            }
            
            // Total completions - green color
            HStack(alignment: .center, spacing: 2) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.green)
                
                Text("\(totalCompletions)")
                    .font(.custom("Lexend-SemiBold", size: 13))
                    .foregroundColor(.green)
                    .contentTransition(.numericText())
            }
        }
        .animation(.smooth(duration: 0.4, extraBounce: 0.1), value: currentStreak)
        .animation(.smooth(duration: 0.4, extraBounce: 0.1), value: totalCompletions)
    }
}

// MARK: - Habit Frequency Tag (copied exactly from HabitHeaderView)
private struct HabitFrequencyTag: View {
    let habit: Habit
    let colorScheme: ColorScheme
    
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
                let remainingMins = minutes % 60
                return ("clock", remainingMins > 0 ? "\(hours)h \(remainingMins)m" : "\(hours)h")
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
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: frequencyInfo.icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text(frequencyInfo.text)
                .font(.customFont("Lexend", .medium, 11))
                .foregroundColor(.primary.opacity(0.65))
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                
        )
    }
}

// MARK: - Habit Schedule Tag (based on HabitHeaderView ScheduleTag)
private struct HabitScheduleTag: View {
    let habit: Habit
    let colorScheme: ColorScheme
    
    private var scheduleText: String {
        guard let repeatPattern = HabitUtilities.getEffectiveRepeatPattern(for: habit, on: Date()) else {
            return "Daily"
        }
        
        // Check daily goals first
        if let dailyGoal = repeatPattern.dailyGoal {
            if dailyGoal.everyDay {
                return "Daily"
            } else if dailyGoal.daysInterval > 0 {
                return "Every \(dailyGoal.daysInterval)d"
            } else if let specificDays = dailyGoal.specificDays as? [Bool] {
                let weekCount = specificDays.count / 7
                if weekCount > 1 {
                    return "\(weekCount)w rotation"
                } else {
                    let selectedCount = specificDays.filter { $0 }.count
                    return selectedCount == 1 ? "1 day/week" : "\(selectedCount) days/week"
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
    
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "calendar")
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.primary.opacity(0.5))
            
            Text(scheduleText)
                .font(.customFont("Lexend", .medium, 11))
                .foregroundColor(.primary.opacity(0.65))
                .lineLimit(1)
        }
        
    }
}

// MARK: - Modern Glass Effect Extension
extension View {
    /// Applies modern glass effect using iOS 26+ API with fallback to ultraThinMaterial
    func modernGlassEffect(tintColor: Color) -> some View {
        Group {
            if #available(iOS 26.0, *) {
                // Use new iOS 26+ glass API - apply behind the content
                self
                    .background(
                        Circle()
                            .fill(.clear)
                            .glassEffect(.regular.tint(tintColor.opacity(0.6)).interactive(), in: .circle)
                    )
            } else {
                // Fallback to ultraThinMaterial for older versions
                self.background(
                    Circle()
                        .fill(.ultraThinMaterial.opacity(0.8))
                        .overlay(
                            Circle()
                                .fill(tintColor.opacity(0.12))
                        )
                        .overlay(
                            Circle()
                                .strokeBorder(tintColor.opacity(0.25), lineWidth: 0.5)
                        )
                )
            }
        }
    }
    
    /// Glass button with optional tint color
    @ViewBuilder
    func glassButton(tintColor: Color? = nil) -> some View {
        if #available(iOS 26.0, *) {
            self
                .buttonStyle(.glassProminent)
                .tint(tintColor?.opacity(0.7) ?? .clear)
        } else {
            // Fallback style for iOS < 26
            if let tintColor = tintColor {
                self
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(tintColor.opacity(0.7))
                            )
                    )
            } else {
                self
                    .buttonStyle(.borderedProminent)
                    .tint(.clear)
            }
        }
    }
}



