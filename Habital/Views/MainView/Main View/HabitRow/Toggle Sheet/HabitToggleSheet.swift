import SwiftUI
import CoreData
import UIKit

// MARK: - Main Habit Toggle Sheet
struct HabitToggleSheet: View {
    @ObservedObject var habit: Habit
    let date: Date
    let currentStreak: Int
    @Binding var isPresented: Bool
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var toggleManager: HabitToggleManager
    
    // State for tracking
    @State private var completedRepeats: Int = 0
    @State private var completedDuration: Int = 0 // minutes
    @State private var completedQuantity: Int = 0
    @State private var isSkipped: Bool = false
    
    // Custom time selection
    @State private var showTimePicker: Bool = false
    @State private var selectedTime: Date = Date()
    
    // Animation states
    @State private var ringScale: CGFloat = 4.2
    @State private var buttonPressedMinus: Bool = false
    @State private var buttonPressedPlus: Bool = false
    
    @State private var showPomodoroTimer: Bool = false
    
    @State private var showCalendarView: Bool = false
    
    init(habit: Habit, date: Date, currentStreak: Int, isPresented: Binding<Bool>) {
        self.habit = habit
        self.date = date
        self.currentStreak = currentStreak
        self._isPresented = isPresented
        
        let ctx = habit.managedObjectContext ?? PersistenceController.shared.container.viewContext
        _toggleManager = StateObject(wrappedValue: HabitToggleManager(context: ctx))
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
            // All tracking types just call toggleCompletion
            toggleManager.toggleCompletion(for: habit, on: date)
            loadCompletionState()
        }
        
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    // MARK: - Updated toggleCompletion method - calls toggleCompletion
    private func toggleCompletion() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            let completionDateTime = getCompletionDateTime()
            let shouldTrackTime = Calendar.current.isDateInToday(date)
            
            // All tracking types call toggleCompletion
            toggleManager.toggleCompletion(for: habit, on: completionDateTime, tracksTime: shouldTrackTime)
            loadCompletionState()
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
            // For other dates, use start of day
            return calendar.startOfDay(for: date)
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
        // All tracking types call toggleCompletion
        toggleManager.toggleCompletion(for: habit, on: customDateTime, tracksTime: true)
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
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    private func completeWithCustomTime() {
        let calendar = Calendar.current
        let selectedDate = calendar.startOfDay(for: date)
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: selectedTime)
        let fullDateTime = calendar.date(
            bySettingHour: timeComponents.hour ?? 12,
            minute: timeComponents.minute ?? 0,
            second: timeComponents.second ?? 0,
            of: selectedDate
        ) ?? selectedDate
        
        // Check if habit is already completed
        if isCompleted {
            // Habit is already completed - just update the completion time(s)
            updateCompletionTimes(to: fullDateTime)
        } else {
            // Habit is not completed - complete it with custom time using same logic as main toggle
            completeWithCustomDateTime(fullDateTime)
        }
        
        showTimePicker = false
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    // MARK: - Helper Methods for Custom Time Completion

    private func updateCompletionTimes(to customDateTime: Date) {
        guard let completions = habit.completion as? Set<Completion> else { return }
        let calendar = Calendar.current
        
        // Find all completions for this date
        let completionsForDate = completions.filter { completion in
            guard let completionDate = completion.date else { return false }
            return calendar.isDate(completionDate, inSameDayAs: date)
        }
        
        // Update the most recent completion's time
        if let mostRecentCompletion = completionsForDate.max(by: {
            ($0.loggedAt ?? Date.distantPast) < ($1.loggedAt ?? Date.distantPast)
        }) {
            mostRecentCompletion.date = customDateTime
            mostRecentCompletion.loggedAt = Date() // When the adjustment was made
            mostRecentCompletion.tracksTime = true
            
            do {
                try viewContext.save()
            } catch {
                print("Failed to save custom completion time: \(error)")
                viewContext.rollback()
            }
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
            toggleManager.toggleDurationCompletion(for: habit, on: customDateTime, minutes: targetDuration)
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
                  return Calendar.current.isDate(completionDate, inSameDayAs: date)
              }),
              let completionDate = completion.date else {
            return nil
        }
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: completionDate)
    }
    
    private var backgroundGradient: some View {
        let base = habitColor ?? .secondary

        let top   = colorScheme == .dark ? 0.10 : 0.15
        let mid   = colorScheme == .dark ? 0.06 : 0.11
        let low   = colorScheme == .dark ? 0.04 : 0.08
        let floor = colorScheme == .dark ? Color(hex: "0A0A0A") : .clear

        return LinearGradient(
            gradient: Gradient(colors: [
                floor,                 // now at the TOP side
                base.opacity(low),
                base.opacity(mid),
                base.opacity(top)      // strongest color at the BOTTOM
            ]),
            startPoint: .top,          // top → bottom list maps to top side
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    // MARK: - Body
    
    var body: some View {
        ZStack {
            backgroundGradient
            VStack(spacing: 0) {
                // Header - refined spacing
                headerSection
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 10)
                
                // Main Toggle Area - much larger ring with proper spacing
                mainToggleSection
                    .padding(.horizontal, 32)
                    .padding(.bottom, 10)
                
                // Quick Actions - refined
                quickActionsSection
                    .padding(.horizontal, 24)
                    .padding(.bottom, 10)
                
                // Custom Time Button - now shown for all tracking types
                customTimeSection
                    .padding(.horizontal, 24)
                    .padding(.bottom, 10)
            }
            .frame(maxWidth: .infinity)
            .allowsHitTesting(true)
            .onAppear {
                loadCompletionState()
            }
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private var headerSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                // Habit name on its own line
                Text(habit.name ?? "Habit")
                    .font(.custom("Lexend-Medium", size: 22))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                // Date and Streak in HStack
                HStack(spacing: 14) {
                    // Date with icon
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        Text(formatDate(date))
                            .font(.custom("Lexend-Medium", size: 14))
                            .foregroundColor(.secondary)
                    }
                    
                }
            }
            
            Spacer()
            
        }
    }
    
    @ViewBuilder
    private var mainToggleSection: some View {
        HStack(spacing: 10) {
            // Enhanced Minus Button
            if shouldShowAdjustButtons {
                Button(action: { adjustValue(-1) }) {
                    Image(systemName: "minus")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 30, height: 30)
                        .background(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [habitColor.opacity(0.8), habitColor.opacity(0.6)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: habitColor.opacity(0.3), radius: 8, x: 0, y: 4)
                        )
                        .scaleEffect(buttonPressedMinus ? 0.88 : 1.0)
                }
                .buttonStyle(PlainButtonStyle())
                .onLongPressGesture(
                    minimumDuration: 0,
                    maximumDistance: .infinity,
                    pressing: { pressing in
                        withAnimation(.easeInOut(duration: 0.12)) {
                            buttonPressedMinus = pressing
                        }
                    },
                    perform: {}
                )
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
            }
            VStack(spacing: 0) {
                ZStack {
                    // The scaled ring with text hidden
                    Button(action: toggleCompletion) {
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
                    .buttonStyle(PlainButtonStyle())
                    
                    // Clean overlay text rendered at proper scale
                    if !isSkipped {
                        VStack(spacing: 0) {
                            // Main progress text
                    
                            VStack {
                                Text(getMainProgressText())
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                    .opacity(shouldShowMainText() ? 1 : 0)
                                
                                // Subtitle text for incomplete states
                                if shouldShowSubtitle() {
                                    Text(getSubtitleText())
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .offset(y: 15)
                            // Badge for completed states (bottom right equivalent)
                            Text(getBadgeText())
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(.ultraThinMaterial)
                                )
                                .offset(x: 55, y: 50)
                                .scaleEffect(shouldShowBadge() ? 1.0 : 0.1) // Start much smaller
                                .opacity(shouldShowBadge() ? 1.0 : 0.0)
                                .animation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.3), value: shouldShowBadge())
                                // More bouncy spring with faster response
                        }
                        .allowsHitTesting(false) // Let touches pass through to button
                    }
                    
                }
                
            }
                .frame(width: 230, height: 180)
                .padding(.bottom, 15)
            // Enhanced Plus Button
            if shouldShowAdjustButtons {
                Button(action: { adjustValue(1) }) {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 30, height: 30)
                        .background(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [habitColor.opacity(0.8), habitColor.opacity(0.6)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: habitColor.opacity(0.3), radius: 8, x: 0, y: 4)
                        )
                        .scaleEffect(buttonPressedPlus ? 0.88 : 1.0)
                }
                .buttonStyle(PlainButtonStyle())
                .onLongPressGesture(
                    minimumDuration: 0,
                    maximumDistance: .infinity,
                    pressing: { pressing in
                        withAnimation(.easeInOut(duration: 0.12)) {
                            buttonPressedPlus = pressing
                        }
                    },
                    perform: {}
                )
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
            }
        }
        
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
            return "\(completedQuantity)"
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
    private var quickActionsSection: some View {
        VStack(spacing: 14) {
            // Skip/Unskip Button in HStack with quick increment buttons for duration/quantity
            HStack(spacing: 10) {
                Button(action: toggleSkip) {
                    HStack(spacing: 10) {
                        Image(systemName: isSkipped ? "arrow.uturn.backward.circle.fill" : "forward.circle")
                            .font(.system(size: 16, weight: .medium))
                            .symbolRenderingMode(.hierarchical)
                        Text(isSkipped ? "Unskip" : "Skip")
                            .font(.custom("Lexend-Medium", size: 16))
                    }
                    .foregroundColor(isSkipped ? .white : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(
                                isSkipped ?
                                LinearGradient(
                                    colors: [habitColor.opacity(0.8), habitColor.opacity(0.6)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ) :
                                LinearGradient(
                                    colors: [Color.primary.opacity(0.05), Color.primary.opacity(0.02)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(
                                        isSkipped ? Color.clear : Color.primary.opacity(0.08),
                                        lineWidth: 1
                                    )
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Quick increment buttons for duration and quantity
                if !isSkipped && !isCompleted {
                    if trackingType == .duration {
                        ForEach([5, 10], id: \.self) { minutes in
                            quickIncrementButton(value: minutes, unit: "m")
                        }
                    } else if trackingType == .quantity {
                        ForEach([1, 5], id: \.self) { amount in
                            quickIncrementButton(value: amount, unit: "")
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func quickIncrementButton(value: Int, unit: String) -> some View {
        Button(action: {
            if trackingType == .duration {
                let newValue = min(targetDuration, completedDuration + value)
                completedDuration = newValue
                toggleManager.toggleDurationCompletion(for: habit, on: date, minutes: newValue)
            } else if trackingType == .quantity {
                let newValue = min(targetQuantity, completedQuantity + value)
                completedQuantity = newValue
                toggleManager.toggleQuantityCompletion(for: habit, on: date, quantity: newValue)
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }) {
            Text("+\(value)\(unit)")
                .font(.custom("Lexend-Medium", size: 14))
                .foregroundColor(habitColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [habitColor.opacity(0.1), habitColor.opacity(0.05)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(habitColor.opacity(0.2), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
        private var customTimeSection: some View {
            VStack(spacing: 12) {
                // Main custom time row
                HStack(spacing: 12) {
                    // Calendar/Time picker button (left button)
                    Button(action: {
                        // Set default time to completion time or current time
                        selectedTime = getDefaultTimeForPicker()
                        showTimePicker.toggle()
                    }) {
                        VStack(spacing: 6) {
                            Image(systemName: isCompleted ? "clock.badge.checkmark" : "clock.circle.fill")
                                .font(.system(size: 20, weight: .medium))
                                .symbolRenderingMode(.hierarchical)
                                .foregroundColor(habitColor)
                            
                            Text("Time")
                                .font(.custom("Lexend-Medium", size: 12))
                                .foregroundColor(.primary)
                        }
                        .frame(width: 70, height: 70)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.primary.opacity(0.04), Color.primary.opacity(0.01)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .strokeBorder(
                                            LinearGradient(
                                                colors: [habitColor.opacity(0.15), habitColor.opacity(0.05)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1
                                        )
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Calendar view button (middle button)
                    Button(action: {
                        showCalendarView.toggle()
                    }) {
                        HStack(spacing: 14) {
                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 18, weight: .medium))
                                .symbolRenderingMode(.hierarchical)
                                .foregroundColor(habitColor)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("View Calendar")
                                    .font(.custom("Lexend-Medium", size: 16))
                                    .foregroundColor(.primary)
                                Text("See completion history")
                                    .font(.custom("Lexend-Regular", size: 12))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right.circle")
                                .font(.system(size: 16, weight: .medium))
                                .symbolRenderingMode(.hierarchical)
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.primary.opacity(0.04), Color.primary.opacity(0.01)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .strokeBorder(
                                            LinearGradient(
                                                colors: [habitColor.opacity(0.15), habitColor.opacity(0.05)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1
                                        )
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Right button - Pomodoro for duration, placeholder for others
                    if trackingType == .duration && !isSkipped {
                        Button(action: { showPomodoroTimer.toggle() }) {
                            VStack(spacing: 6) {
                                Image(systemName: "timer")
                                    .font(.system(size: 20, weight: .medium))
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundColor(habitColor)
                                
                                Text("Focus")
                                    .font(.custom("Lexend-Medium", size: 12))
                                    .foregroundColor(.primary)
                            }
                            .frame(width: 70, height: 70)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [habitColor.opacity(0.08), habitColor.opacity(0.02)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .strokeBorder(
                                                LinearGradient(
                                                    colors: [habitColor.opacity(0.2), habitColor.opacity(0.08)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1
                                            )
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else if !isSkipped {
                        // Dummy button for non-duration habits
                        VStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 20, weight: .medium))
                                .symbolRenderingMode(.hierarchical)
                                .foregroundColor(Color.primary.opacity(0.3))
                            
                            Text("More")
                                .font(.custom("Lexend-Medium", size: 12))
                                .foregroundColor(Color.primary.opacity(0.3))
                        }
                        .frame(width: 70, height: 70)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.primary.opacity(0.02))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .strokeBorder(Color.primary.opacity(0.05), lineWidth: 1)
                                )
                        )
                        .allowsHitTesting(false) // Disabled dummy button
                    }
                }
            }
            .popover(isPresented: $showTimePicker) {
                TimePickerPopover(
                    selectedTime: $selectedTime,
                    onComplete: { _ in
                        completeWithCustomTime()
                    }
                )
                .presentationCompactAdaptation(.popover)
            }
            
            .sheet(isPresented: $showPomodoroTimer) {
                PomodoroTimerSheet(
                    habit: habit,
                    date: date,
                    habitColor: habitColor,
                    targetDuration: targetDuration,
                    onComplete: { minutes in
                        // Save the completed minutes using toggleManager
                        toggleManager.toggleDurationCompletion(for: habit, on: date, minutes: minutes)
                        loadCompletionState()
                        showPomodoroTimer = false
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    }
                )
                .presentationDetents([.height(400)])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(32)
                .presentationBackground(.ultraThinMaterial)
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
                  return Calendar.current.isDate(completionDate, inSameDayAs: date)
              }),
              let completionDate = completion.date else {
            return nil
        }
        return completionDate
    }
}


// MARK: - Enhanced Time Picker Popover
struct TimePickerPopover: View {
    @Binding var selectedTime: Date
    let onComplete: (Date) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Text("Select Completion Time")
                    .font(.custom("Lexend-Medium", size: 20))
                    .foregroundColor(.primary)
                
                Text("Choose when you completed this habit")
                    .font(.custom("Lexend-Regular", size: 14))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 16)
            
            // Time Picker
            DatePicker(
                "",
                selection: $selectedTime,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(WheelDatePickerStyle())
            .labelsHidden()
            .frame(maxHeight: 180)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.primary.opacity(0.02))
            )
            
            // Action Buttons
            HStack(spacing: 14) {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.secondary.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(Color.secondary.opacity(0.15), lineWidth: 1)
                        )
                )
                
                Button("Set Time") {
                    onComplete(selectedTime)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.9), Color.blue.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color.blue.opacity(0.3), radius: 6, x: 0, y: 3)
                )
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.bottom, 20)
        }
        .padding(.horizontal, 28)
        .frame(width: 340)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
                )
        )
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
            .presentationBackground(.ultraThinMaterial)
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

