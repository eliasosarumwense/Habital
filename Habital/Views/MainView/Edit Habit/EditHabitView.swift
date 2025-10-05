//
//  EditHabitView.swift
//  Habital
//
//  Created by Elias Osarumwense on 02.04.25.
//

import SwiftUI
import CoreData

struct PatternValues {
    var goalType: HabitGoalType = .daily
    var dailyGoalPattern: DailyGoalPattern = .everyday
    var weeklyGoalPattern: WeeklyGoalPattern = .everyWeek
    var monthlyGoalPattern: MonthlyGoalPattern = .everyMonth
    var specificDaysDaily: [Bool] = Array(repeating: false, count: 7)
    var specificDaysWeekly: [Bool] = Array(repeating: false, count: 7)
    var specificDaysMonthly: [Bool] = Array(repeating: false, count: 31)
    var daysInterval: Int = 1
    var weekInterval: Int = 1
    var monthInterval: Int = 1
    var followUp: Bool = false
    var repeatsPerDay: Int = 1  // Add this property
    
    func isEqual(to other: PatternValues) -> Bool {
        // Check if goal type is the same
        guard goalType == other.goalType else { return false }
        
        // Check follow-up
        guard followUp == other.followUp else { return false }
        
        // Check repeatsPerDay
        guard repeatsPerDay == other.repeatsPerDay else { return false }
        
        // Check specific goal type properties
        switch goalType {
        case .daily:
            guard dailyGoalPattern == other.dailyGoalPattern else { return false }
            
            switch dailyGoalPattern {
            case .everyday:
                return true
            case .everyXDays:
                return daysInterval == other.daysInterval
            case .specificDays:
                return specificDaysDaily == other.specificDaysDaily
            }
            
        case .weekly:
            guard weeklyGoalPattern == other.weeklyGoalPattern else { return false }
            guard specificDaysWeekly == other.specificDaysWeekly else { return false }
            
            if weeklyGoalPattern == .weekInterval {
                return weekInterval == other.weekInterval
            }
            return true
            
        case .monthly:
            guard monthlyGoalPattern == other.monthlyGoalPattern else { return false }
            guard specificDaysMonthly == other.specificDaysMonthly else { return false }
            
            if monthlyGoalPattern == .monthInterval {
                return monthInterval == other.monthInterval
            }
            return true
        }
    }
}
struct EditHabitView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @ObservedObject var habit: Habit
    
    @State private var name: String
    @State private var habitDescription: String
    @State private var startDate: Date
    @State private var icon: String
    @State private var showIconPicker = false
    
    // State for the selected habit list
    @State private var selectedHabitList: HabitList?
    @State private var showHabitListPicker = false
    
    // State for bad habit toggle
    @State private var isBadHabit: Bool
    
    // Goal type states
    @State private var selectedGoalType: HabitGoalType = .daily
    
    // Daily goal states
    @State private var dailyGoalPattern: DailyGoalPattern = .everyday
    @State private var specificDaysDaily: [Bool] = Array(repeating: false, count: 7)
    @State private var selectedDaysInterval: Int = 1
    
    // Weekly goal states
    @State private var weeklyGoalPattern: WeeklyGoalPattern = .everyWeek
    @State private var specificDaysWeekly: [Bool] = Array(repeating: false, count: 7)
    @State private var selectedWeekInterval: Int = 2
    
    // Monthly goal states
    @State private var monthlyGoalPattern: MonthlyGoalPattern = .everyMonth
    @State private var specificDaysMonthly: [Bool] = Array(repeating: false, count: 31)
    @State private var selectedMonthInterval: Int = 2
    
    // Common states
    @State private var followUpEnabled: Bool = false
    @State private var showRepeatPatternSheet = false
    
    // UI State
    @State private var selectedColor: Color = .primary
    @State private var animateIcon = false
    
    // New states for the effective date and overwrite option
    @State private var effectiveFrom: Date = {
        let calendar = Calendar.current
        // Get tomorrow's date by adding 1 day to today
        return calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    }()
    @State private var overwriteAllPatterns: Bool = false
    
    // Track if pattern was changed
    @State private var patternChanged: Bool = false
    
    // New for intensity
    @State private var selectedIntensity: HabitIntensity = .moderate
    
    // Repeats per day
    @State private var repeatsPerDay: Int = 1
    
    @State private var showPatternHistory = false
    @State private var selectedPattern: RepeatPattern? = nil
    @State private var patternHistoryData: [(RepeatPattern, Date)] = []
    
    @State private var shouldCreateNewPattern = false
    @State private var canCreateNewPattern = true
    
    @State private var showDeleteAlert = false
    @State private var patternToDelete: RepeatPattern? = nil
    
    // Original pattern values for comparison
    private var originalPattern: PatternValues
    
    private let colors: [Color] = [ .yellow, .orange, .red, .pink, .purple, .blue, .green, .primary ]
    
    init(habit: Habit) {
        self.habit = habit
        _name = State(initialValue: habit.name ?? "")
        _habitDescription = State(initialValue: habit.habitDescription ?? "")
        _startDate = State(initialValue: habit.startDate ?? Date())
        _icon = State(initialValue: habit.icon ?? "star")
        _isBadHabit = State(initialValue: habit.isBadHabit)
        _selectedHabitList = State(initialValue: habit.habitList)
        
        // Initialize intensity from habit
        _selectedIntensity = State(initialValue: HabitIntensity(rawValue: habit.intensityLevel) ?? .moderate)
        
        // Extract color
        if let colorData = habit.color,
           let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
            _selectedColor = State(initialValue: Color(uiColor))
        }
        
        // Create default pattern values to compare against later
        var patternValues = PatternValues()
        
        // Get the most recent repeat pattern
        if let repeatPattern = getMostRecentRepeatPattern(for: habit) {
            // Set follow-up state
            _followUpEnabled = State(initialValue: repeatPattern.followUp)
            if let repeatPattern = getMostRecentRepeatPattern(for: habit) {
                // If there's a most recent pattern, set effective date to day after that pattern
                if let patternDate = repeatPattern.effectiveFrom,
                   let dayAfter = Calendar.current.date(byAdding: .day, value: 1, to: patternDate) {
                    _effectiveFrom = State(initialValue: dayAfter)
                } else {
                    // Fallback to tomorrow if pattern date is nil
                    _effectiveFrom = State(initialValue: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date())
                }
            }
            
            // Set repeats per day
            _repeatsPerDay = State(initialValue: Int(repeatPattern.repeatsPerDay))
            patternValues.repeatsPerDay = Int(repeatPattern.repeatsPerDay)
            
            // Set goal type and pattern based on which goal entity exists
            if let dailyGoal = repeatPattern.dailyGoal {
                _selectedGoalType = State(initialValue: .daily)
                patternValues.goalType = .daily
                
                // Set specific daily goal pattern
                if dailyGoal.everyDay {
                    _dailyGoalPattern = State(initialValue: .everyday)
                    patternValues.dailyGoalPattern = .everyday
                } else if dailyGoal.daysInterval > 0 {
                    _dailyGoalPattern = State(initialValue: .everyXDays)
                    _selectedDaysInterval = State(initialValue: Int(dailyGoal.daysInterval))
                    patternValues.dailyGoalPattern = .everyXDays
                    patternValues.daysInterval = Int(dailyGoal.daysInterval)
                } else if let specificDays = dailyGoal.specificDays as? [Bool], specificDays.count == 7 {
                    _dailyGoalPattern = State(initialValue: .specificDays)
                    _specificDaysDaily = State(initialValue: specificDays)
                    patternValues.dailyGoalPattern = .specificDays
                    patternValues.specificDaysDaily = specificDays
                }
            } else if let weeklyGoal = repeatPattern.weeklyGoal {
                _selectedGoalType = State(initialValue: .weekly)
                patternValues.goalType = .weekly
                
                // Set specific weekly goal pattern
                if weeklyGoal.everyWeek {
                    _weeklyGoalPattern = State(initialValue: .everyWeek)
                    patternValues.weeklyGoalPattern = .everyWeek
                } else if weeklyGoal.weekInterval > 0 {
                    _weeklyGoalPattern = State(initialValue: .weekInterval)
                    _selectedWeekInterval = State(initialValue: Int(weeklyGoal.weekInterval))
                    patternValues.weeklyGoalPattern = .weekInterval
                    patternValues.weekInterval = Int(weeklyGoal.weekInterval)
                }
                
                // Set weekly specific days
                if let specificDays = weeklyGoal.specificDays as? [Bool], specificDays.count == 7 {
                    _specificDaysWeekly = State(initialValue: specificDays)
                    patternValues.specificDaysWeekly = specificDays
                }
            } else if let monthlyGoal = repeatPattern.monthlyGoal {
                _selectedGoalType = State(initialValue: .monthly)
                patternValues.goalType = .monthly
                
                // Set specific monthly goal pattern
                if monthlyGoal.everyMonth {
                    _monthlyGoalPattern = State(initialValue: .everyMonth)
                    patternValues.monthlyGoalPattern = .everyMonth
                } else if monthlyGoal.monthInterval > 0 {
                    _monthlyGoalPattern = State(initialValue: .monthInterval)
                    _selectedMonthInterval = State(initialValue: Int(monthlyGoal.monthInterval))
                    patternValues.monthlyGoalPattern = .monthInterval
                    patternValues.monthInterval = Int(monthlyGoal.monthInterval)
                }
                
                // Set monthly specific days
                if let specificDays = monthlyGoal.specificDays as? [Bool], specificDays.count == 31 {
                    _specificDaysMonthly = State(initialValue: specificDays)
                    patternValues.specificDaysMonthly = specificDays
                }
            }
            
            patternValues.followUp = repeatPattern.followUp
        }
        
        self.originalPattern = patternValues
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                (colorScheme == .dark ? Color(hex: "121212") : Color(UIColor.systemGroupedBackground))
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 15) {
                        // Icon section with animation
                        VStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                selectedColor.opacity(0.7),
                                                selectedColor.opacity(0.4)
                                            ]),
                                            startPoint: .bottomTrailing,
                                            endPoint: .topLeading
                                        )
                                    )
                                    .shadow(color: selectedColor.opacity(0.7), radius: 16, x: 0, y: 2)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        selectedColor.opacity(0.1),
                                                        selectedColor.opacity(0.4),
                                                        selectedColor.opacity(0.1)
                                                    ]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 2
                                            )
                                    )
                                    .frame(width: 150, height: 150)
                                
                                // Display emoji or SF Symbol
                                if isEmoji(icon) {
                                    Text(icon)
                                        .frame(width: 90, height: 90)
                                        .font(.system(size: 80))
                                        .scaleEffect(animateIcon ? 1.1 : 1.0)
                                } else {
                                    Image(systemName: icon)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 90, height: 90)
                                        .foregroundColor(.white)
                                        .scaleEffect(animateIcon ? 1.1 : 1.0)
                                }
                                
                                // Add red cross for bad habits
                                if isBadHabit {
                                    ZStack {
                                        Circle()
                                            .fill(Color(.systemBackground))
                                            .frame(width: 34, height: 34)
                                        
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                            .font(.system(size: 30))
                                    }
                                    .offset(x: 48, y: 48) // Position at bottom right
                                    .zIndex(10) // Ensure it's on top
                                }
                            }
                            .shadow(color: selectedColor.opacity(0.2), radius: 6, x: 0, y: 2)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    animateIcon = true
                                    // Reset animation after short delay
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        animateIcon = false
                                    }
                                }
                                triggerHaptic(.impactMedium)
                                showIconPicker.toggle()
                            }
                            
                            Text("Tap to change icon")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 10)
                        
                        // Color picker section
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Select Color")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 5)
                            
                            HStack(spacing: 15) {
                                ForEach(colors, id: \.self) { color in
                                    Circle()
                                        .fill(color)
                                        .frame(width: 25, height: 25)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: 2)
                                                .opacity(selectedColor == color ? 1 : 0)
                                        )
                                        .shadow(color: color.opacity(0.4), radius: 2, x: 0, y: 1)
                                        .onTapGesture {
                                            withAnimation(.spring()) {
                                                selectedColor = color
                                            }
                                            triggerHaptic(.impactRigid)
                                        }
                                }
                                
                                // Custom color picker button
                                ColorPicker("", selection: $selectedColor)
                                    .labelsHidden()
                                    .frame(width: 25, height: 25)
                            }
                            .padding(.horizontal, 5)
                            .padding(.vertical, 5)
                        }
                        
                        // Habit info card
                        VStack {
                            customTextField(title: "Name", text: $name, icon: "pencil")
                                .padding(.bottom, 8)
                                .padding(.horizontal)
                            
                            customTextField(title: "Description", text: $habitDescription, icon: "text.badge.plus")
                                .padding(.bottom, 8)
                                .padding(.horizontal)
                            
                            // Habit Schedule section
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Habit Schedule")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.primary)
                                    .padding(.horizontal)
                                
                                VStack(spacing: 12) {
                                    // Date and first occurrence section
                                    VStack(spacing: 10) {
                                        // Start date picker with cleaner layout
                                        HStack(spacing: 12) {
                                            // Icon with background
                                            HStack {
                                                ZStack {
                                                    Circle()
                                                        .fill(selectedColor.opacity(0.15))
                                                        .frame(width: 32, height: 32)
                                                    
                                                    Image(systemName: "calendar")
                                                        .foregroundColor(selectedColor)
                                                        .font(.system(size: 14, weight: .medium))
                                                }
                                                
                                                HStack(spacing: 0) {
                                                    Text("Start Date:")
                                                        .font(.system(size: 12, weight: .medium))
                                                        .foregroundColor(.primary)
                                                    
                                                    DatePicker("", selection: $startDate, displayedComponents: .date)
                                                        .datePickerStyle(CompactDatePickerStyle())
                                                        .labelsHidden()
                                                        .fixedSize()
                                                        .scaleEffect(0.9)
                                                        //.offset(x: -5)
                                                        .disabled(true)
                                                }
                                            }
                                            //.frame(width: 150)
                                            .padding(.horizontal)
                                            
                                            
                                                Spacer()
                                            
                                        }
                                        .frame(height: 25)
                                        .padding(.vertical, 2)
                                    }
                                    
                                    Divider()
                                        .padding(.vertical, 1)
                                    
                                    // Repeat pattern button
                                    Button(action: {
                                        showRepeatPatternSheet.toggle()
                                    }) {
                                        HStack {
                                            ZStack {
                                                Circle()
                                                    .fill(selectedColor.opacity(0.15))
                                                    .frame(width: 36, height: 36)
                                                
                                                Image(systemName: "repeat")
                                                    .foregroundColor(selectedColor)
                                                    .font(.system(size: 16, weight: .medium))
                                            }
                                            
                                            VStack(alignment: .leading, spacing: 3) {
                                                HStack {
                                                    Text(repeatPatternText)
                                                        .font(.system(size: 14, weight: .semibold))
                                                        .foregroundColor(.primary)
                                                    
                                                    
                                                }
                                                
                                                Text("Tap to set your habit schedule")
                                                    .font(.caption2)
                                                    .foregroundColor(.gray)
                                            }
                                            
                                            Spacer()
                                            
                                            Image(systemName: "chevron.right")
                                                .foregroundColor(.gray)
                                                .font(.system(size: 14, weight: .medium))
                                        }
                                        .padding(14)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color(.systemBackground))
                                                .shadow(color: Color(.systemGray4).opacity(0.2), radius: 3, x: 0, y: 2)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(.primary.opacity(0.2), lineWidth: 2)
                                                        .shadow(color: colorScheme == .dark ? .white : .black, radius: 2)
                                                )
                                        )
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .padding(.vertical, 3)
                                    
                                    Divider()
                                        .padding(.vertical, 1)
                                    
                                    // Follow-up option
                                    HStack {
                                        ZStack {
                                            Circle()
                                                .fill(selectedColor.opacity((selectedGoalType == .daily && dailyGoalPattern == .everyday) || isBadHabit ? 0.05 : 0.15))
                                                .frame(width: 32, height: 32)
                                            
                                            Image(systemName: "arrow.turn.down.right")
                                                .foregroundColor((selectedGoalType == .daily && dailyGoalPattern == .everyday) || isBadHabit ? selectedColor.opacity(0.4) : selectedColor)
                                                .font(.system(size: 14, weight: .medium))
                                        }
                                        
                                        Toggle(isOn: $followUpEnabled) {
                                            HStack {
                                                VStack(alignment: .leading, spacing: 3) {
                                                    Text("Follow-up if missed")
                                                        .font(.system(size: 13, weight: .medium))
                                                        .foregroundColor((selectedGoalType == .daily && dailyGoalPattern == .everyday) || isBadHabit ? .gray : .primary)
                                                    
                                                    Text(isBadHabit
                                                         ? "Not applicable for bad habits"
                                                         : (selectedGoalType == .daily && dailyGoalPattern == .everyday
                                                           ? "Not needed for daily habits"
                                                           : "Habit remains active until completed"))
                                                    .font(.caption2)
                                                    .foregroundColor(.gray)
                                                    .fixedSize(horizontal: false, vertical: true)
                                                }
                                            }
                                        }
                                        .toggleStyle(SwitchToggleStyle(tint: selectedColor))
                                        .disabled(isBadHabit)
                                        .opacity((selectedGoalType == .daily && dailyGoalPattern == .everyday) || isBadHabit ? 0.8 : 1)
                                        .onChange(of: followUpEnabled) { _ in
                                            checkForPatternChanges()
                                        }
                                    }
                                    
                                    Divider()
                                        .padding(.vertical, 1)
                                    
                                    // Repeats per day section
                                    HStack {
                                        ZStack {
                                            Circle()
                                                .fill(selectedColor.opacity(0.15))
                                                .frame(width: 28, height: 28)
                                            
                                            Image(systemName: "repeat.circle")
                                                .foregroundColor(selectedColor)
                                                .font(.system(size: 12, weight: .medium))
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Repeats Per Day")
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundColor(.primary)
                                        }
                                        
                                        Spacer()
                                        
                                        // Stepper with value display
                                        HStack(spacing: 8) {
                                            Button(action: {
                                                if repeatsPerDay > 1 {
                                                    repeatsPerDay -= 1
                                                    checkForPatternChanges()
                                                    triggerHaptic(.impactRigid)
                                                }
                                            }) {
                                                Image(systemName: "minus.circle.fill")
                                                    .foregroundColor(repeatsPerDay > 1 ? selectedColor : .gray.opacity(0.8))
                                                    .font(.system(size: 22))
                                            }
                                            .disabled(repeatsPerDay <= 1)
                                            
                                            Text("\(repeatsPerDay)x")
                                                .font(.system(size: 15, weight: .bold))
                                                .frame(minWidth: 25)
                                                .foregroundColor(.primary)
                                            
                                            Button(action: {
                                                if repeatsPerDay < 20 {
                                                    repeatsPerDay += 1
                                                    checkForPatternChanges()
                                                    triggerHaptic(.impactRigid)
                                                }
                                            }) {
                                                Image(systemName: "plus.circle.fill")
                                                    .foregroundColor(repeatsPerDay < 20 ? selectedColor : .gray.opacity(0.8))
                                                    .font(.system(size: 22))
                                            }
                                            
                                            .disabled(repeatsPerDay >= 20)
                                        }
                                        .onChange(of: repeatsPerDay) { _ in
                                            checkForPatternChanges()
                                        }
                                    }
                                    .padding(3)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color(.systemBackground))
                                    )
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemBackground))
                                        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 0)
                                )
                                .cornerRadius(10)
                                .padding(.horizontal)
                            }
                            
                            VStack(alignment: .leading, spacing: 5) {
                                if patternChanged {
                                    VStack(spacing: 8) {
                                        HStack {
                                            Toggle(isOn: $shouldCreateNewPattern) {
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text("Create new pattern")
                                                        .font(.system(size: 13, weight: .medium))
                                                        .foregroundColor(.primary)
                                                    
                                                    
                                                                Text("Will create a new repeat schedule.")
                                                                    .font(.caption2)
                                                                    .foregroundColor(.secondary)
                                                           
                                                    //.animation(.linear(duration: 0.3), value: shouldCreateNewPattern)
                                                    .frame(height: 15) // Fixed height to prevent layout jumps
                                                }
                                            }
                                            .toggleStyle(SwitchToggleStyle(tint: selectedColor))
                                        }
                                        
                                        // Effective date picker - appears with animation when shouldCreateNewPattern is true
                                        if shouldCreateNewPattern {
                                            HStack {
                                                ZStack {
                                                    Circle()
                                                        .fill(selectedColor.opacity(0.15))
                                                        .frame(width: 28, height: 28)
                                                    
                                                    Image(systemName: "calendar.badge.plus")
                                                        .foregroundColor(selectedColor)
                                                        .font(.system(size: 12, weight: .medium))
                                                }
                                                
                                                HStack(spacing: 5) {
                                                    Text("Effective From:")
                                                        .font(.system(size: 13, weight: .medium))
                                                        .foregroundColor(.primary)
                                                    
                                                    // Calculate the minimum allowed date (day after most recent pattern)
                                                    let minDate: Date = {
                                                        if let mostRecentPattern = getMostRecentRepeatPattern(for: habit),
                                                           let mostRecentDate = mostRecentPattern.effectiveFrom {
                                                            if let dayAfter = Calendar.current.date(byAdding: .day, value: 1, to: mostRecentDate) {
                                                                return dayAfter
                                                            }
                                                        }
                                                        return Date()
                                                    }()
                                                    
                                                    DatePicker("",
                                                              selection: $effectiveFrom,
                                                              in: minDate...,
                                                              displayedComponents: .date)
                                                        .datePickerStyle(CompactDatePickerStyle())
                                                        .labelsHidden()
                                                        .scaleEffect(0.9)
                                                }
                                                
                                                Spacer()
                                            }
                                            .padding(.top, 4)
                                            .transition(.opacity.combined(with: .move(edge: .top)))
                                        }
                                    }
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(.systemBackground).opacity(0.8))
                                            .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 0)
                                    )
                                    .cornerRadius(10)
                                    .padding(.horizontal)
                                    .animation(.linear(duration: 0.3), value: shouldCreateNewPattern)
                                }
                                
                                HStack(alignment: .center, spacing: 10) {
                                        HStack {
                                            Image(systemName: "clock.arrow.circlepath")
                                                .foregroundColor(selectedColor)
                                                .font(.system(size: 14))
                                            
                                            Text("Schedule History")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.primary)
                                        }
                                        
                                        Spacer()
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal)
                                    
                                
                                
                                
                                if !patternHistoryData.isEmpty {
                                    VStack(spacing: 10) {
                                        ForEach(patternHistoryData.indices, id: \.self) { index in
                                            let (pattern, date) = patternHistoryData[index]
                                            
                                            HStack {
                                                Button(action: {
                                                    //selectedPattern = pattern
                                                    //loadPattern(pattern: pattern)
                                                }) {
                                                    HStack {
                                                        ZStack {
                                                            Circle()
                                                                .fill(selectedColor.opacity(0.15))
                                                                .frame(width: 32, height: 32)
                                                            
                                                            Image(systemName: index == 0 ? "clock" : "clock.arrow.circlepath")
                                                                .foregroundColor(selectedColor)
                                                                .font(.system(size: 14, weight: .medium))
                                                        }
                                                        
                                                        VStack(alignment: .leading, spacing: 3) {
                                                            HStack(spacing: 4) {
                                                                if index == 0 {
                                                                    Text("Current")
                                                                        .font(.caption)
                                                                        .padding(.horizontal, 6)
                                                                        .padding(.vertical, 2)
                                                                        .background(selectedColor.opacity(0.15))
                                                                        .cornerRadius(4)
                                                                }
                                                                
                                                                Text("From \(formattedDate(for: date))")
                                                                    .font(.system(size: 14, weight: .medium))
                                                                    .foregroundColor(.primary)
                                                            }
                                                            
                                                            Text(getPatternDescription(for: pattern))
                                                                .font(.caption)
                                                                .foregroundColor(.secondary)
                                                                .lineLimit(1)
                                                        }
                                                        
                                                        Spacer()
                                                        
                                                        if patternChanged && !shouldCreateNewPattern && index == 0{
                                                            Text("• Changing")
                                                                .font(.caption2)
                                                                .foregroundColor(.orange)
                                                                .padding(.horizontal, 6)
                                                                .padding(.vertical, 2)
                                                                .background(Color.orange.opacity(0.15))
                                                                .cornerRadius(4)
                                                        }
                                                        
                                                        if patternHistoryData.count > 1 {
                                                            Button(action: {
                                                                patternToDelete = pattern
                                                                showDeleteAlert = true
                                                            }) {
                                                                Image(systemName: "trash")
                                                                    .foregroundColor(.red)
                                                                    .font(.system(size: 14))
                                                                    .padding(8)
                                                            }
                                                            .buttonStyle(BorderlessButtonStyle())
                                                        }
                                                        /*
                                                        Image(systemName: "chevron.right")
                                                            .foregroundColor(.gray)
                                                            .font(.system(size: 14, weight: .medium))
                                                         */
                                                    }
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                                .padding(12)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .fill((!shouldCreateNewPattern && patternChanged && index == 0) ?
                                                             selectedColor.opacity(0.1) : Color(.systemBackground))
                                                        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 0)
                                                )
                                                .cornerRadius(10)
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            
                        }
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Habit Intensity")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.gray)
                                .padding(.horizontal)
                            
                            Menu {
                                ForEach(HabitIntensity.allCases) { intensity in
                                    Button(action: {
                                        selectedIntensity = intensity
                                    }) {
                                        HStack {
                                            Circle()
                                                .fill(intensity.color)
                                                .frame(width: 10, height: 10)
                                            Text(intensity.title)
                                            if selectedIntensity == intensity {
                                                Spacer()
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack {
                                    ZStack {
                                        Circle()
                                            .fill(selectedIntensity.color.opacity(0.15))
                                            .frame(width: 28, height: 28)
                                        
                                        Image(systemName: "chevron.up")
                                            .foregroundColor(selectedIntensity.color)
                                            .font(.system(size: 12, weight: .medium))
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Intensity: \(selectedIntensity.title)")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.primary)
                                        
                                        Text(selectedIntensity.description)
                                            .font(.caption2)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Spacer()
                                    
                                    Circle()
                                        .fill(selectedIntensity.color)
                                        .frame(width: 16, height: 16)
                                    
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemBackground))
                                        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 0)
                                )
                                .cornerRadius(10)
                            }
                            .padding(.horizontal)
                        }
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Habit List")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.gray)
                                .padding(.horizontal)
                            
                            Button(action: {
                                showHabitListPicker = true
                            }) {
                                HStack {
                                    Image(systemName: "list.bullet")
                                        .foregroundColor(selectedColor)
                                        .frame(width: 25)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(selectedHabitList?.name ?? "No list selected")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.primary)
                                        
                                        Text("Tap to select a habit list")
                                            .font(.caption2)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemBackground))
                                        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 0)
                                )
                                .cornerRadius(10)
                            }
                            .padding(.horizontal)
                        }
                        
                        // Save button
                        Button(action: {
                            saveHabit()
                            HabitUtilities.clearHabitActivityCache()
                            dismiss()
                        }) {
                            Text("Save Changes")
                                .font(.subheadline)
                                .foregroundColor(Color(UIColor { $0.userInterfaceStyle == .dark ? .black : .white }))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    name.isEmpty ?
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.7)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ) :
                                    LinearGradient(
                                        gradient: Gradient(colors: [selectedColor.opacity(0.8), selectedColor]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                                .shadow(color: name.isEmpty ? Color.gray.opacity(0.3) : selectedColor.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .disabled(name.isEmpty)
                        .padding(.horizontal)
                        .padding(.top, 5)
                        .padding(.bottom, 20)
                    }
                }
            }
            .onAppear() {
                loadPatternHistory()
            }
            .navigationTitle("Edit Habit")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: effectiveFrom) { newValue in
                // Enforce that the new effective date is at least one day newer
                // than the most recent pattern's effective date
                if let mostRecentPattern = getMostRecentRepeatPattern(for: habit),
                   let mostRecentDate = mostRecentPattern.effectiveFrom {
                    let calendar = Calendar.current
                    
                    // Get the day after the most recent pattern's date
                    if let minAllowedDate = calendar.date(byAdding: .day, value: 1, to: mostRecentDate) {
                        // If selected date is earlier than allowed minimum, reset to minimum
                        if newValue < minAllowedDate {
                            effectiveFrom = minAllowedDate
                        }
                    }
                }
            }
            .onChange(of: repeatsPerDay) { _ in
                checkForPatternChanges()
            }
            .onDisappear() {
                HabitUtilities.clearHabitActivityCache()
            }

            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.primary)
                }
            }
            .sheet(isPresented: $showRepeatPatternSheet) {
                // Check for pattern changes after sheet is dismissed
                checkForPatternChanges()
            } content: {
                RepeatPatternView(
                    selectedGoalType: $selectedGoalType,
                    dailyGoalPattern: $dailyGoalPattern,
                    specificDaysDaily: $specificDaysDaily,
                    selectedDaysInterval: $selectedDaysInterval,
                    weeklyGoalPattern: $weeklyGoalPattern,
                    specificDaysWeekly: $specificDaysWeekly,
                    selectedWeekInterval: $selectedWeekInterval,
                    monthlyGoalPattern: $monthlyGoalPattern,
                    specificDaysMonthly: $specificDaysMonthly,
                    selectedMonthInterval: $selectedMonthInterval
                )
            }
            .sheet(isPresented: $showIconPicker) {
                IconPickerView(
                    selectedIcon: $icon,
                    selectedColor: selectedColor
                )
            }
            .sheet(isPresented: $showHabitListPicker) {
                HabitListPickerView(selectedHabitList: $selectedHabitList)
                    .environment(\.managedObjectContext, viewContext)
            }
            .alert(isPresented: $showDeleteAlert) {
                Alert(
                    title: Text("Delete Pattern?"),
                    message: Text("Are you sure you want to delete this repeat pattern? This action cannot be undone."),
                    primaryButton: .destructive(Text("Delete")) {
                        if let pattern = patternToDelete {
                            deletePattern(pattern)
                            loadPatternHistory() // Refresh the list
                            
                            // If we were editing this pattern, select the most recent one instead
                            if selectedPattern == pattern {
                                selectedPattern = getMostRecentRepeatPattern(for: habit)
                                if let mostRecent = selectedPattern {
                                    loadPattern(pattern: mostRecent)
                                }
                            }
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
    /*
    // Check if repeat pattern has changed
    private func checkForPatternChanges() {
        // Current pattern values
        let currentPattern = PatternValues(
            goalType: selectedGoalType,
            dailyGoalPattern: dailyGoalPattern,
            weeklyGoalPattern: weeklyGoalPattern,
            monthlyGoalPattern: monthlyGoalPattern,
            specificDaysDaily: specificDaysDaily,
            specificDaysWeekly: specificDaysWeekly,
            specificDaysMonthly: specificDaysMonthly,
            daysInterval: selectedDaysInterval,
            weekInterval: selectedWeekInterval,
            monthInterval: selectedMonthInterval,
            followUp: followUpEnabled
        )
        
        // Compare current values with original values
        patternChanged = !originalPattern.isEqual(to: currentPattern)
    }
    */
    private func checkForPatternChanges() {
        // If a pattern is selected, we need to compare against that pattern instead
        if let selectedPattern = selectedPattern {
            // Create a PatternValues instance from the selected pattern
            var comparisonPattern = PatternValues(
                goalType: .daily, // Default values, will be overridden
                followUp: selectedPattern.followUp,
                repeatsPerDay: Int(selectedPattern.repeatsPerDay) // Add this line
            )
            
            // Set values based on the pattern type
            if let dailyGoal = selectedPattern.dailyGoal {
                comparisonPattern.goalType = .daily
                
                if dailyGoal.everyDay {
                    comparisonPattern.dailyGoalPattern = .everyday
                } else if dailyGoal.daysInterval > 0 {
                    comparisonPattern.dailyGoalPattern = .everyXDays
                    comparisonPattern.daysInterval = Int(dailyGoal.daysInterval)
                } else if let specificDays = dailyGoal.specificDays as? [Bool] {
                    comparisonPattern.dailyGoalPattern = .specificDays
                    comparisonPattern.specificDaysDaily = specificDays
                }
            } else if let weeklyGoal = selectedPattern.weeklyGoal {
                comparisonPattern.goalType = .weekly
                
                if weeklyGoal.everyWeek {
                    comparisonPattern.weeklyGoalPattern = .everyWeek
                } else {
                    comparisonPattern.weeklyGoalPattern = .weekInterval
                    comparisonPattern.weekInterval = Int(weeklyGoal.weekInterval)
                }
                
                if let specificDays = weeklyGoal.specificDays as? [Bool] {
                    comparisonPattern.specificDaysWeekly = specificDays
                }
            } else if let monthlyGoal = selectedPattern.monthlyGoal {
                comparisonPattern.goalType = .monthly
                
                if monthlyGoal.everyMonth {
                    comparisonPattern.monthlyGoalPattern = .everyMonth
                } else {
                    comparisonPattern.monthlyGoalPattern = .monthInterval
                    comparisonPattern.monthInterval = Int(monthlyGoal.monthInterval)
                }
                
                if let specificDays = monthlyGoal.specificDays as? [Bool] {
                    comparisonPattern.specificDaysMonthly = specificDays
                }
            }
            
            // Current pattern values from UI
            let currentPattern = PatternValues(
                goalType: selectedGoalType,
                dailyGoalPattern: dailyGoalPattern,
                weeklyGoalPattern: weeklyGoalPattern,
                monthlyGoalPattern: monthlyGoalPattern,
                specificDaysDaily: specificDaysDaily,
                specificDaysWeekly: specificDaysWeekly,
                specificDaysMonthly: specificDaysMonthly,
                daysInterval: selectedDaysInterval,
                weekInterval: selectedWeekInterval,
                monthInterval: selectedMonthInterval,
                followUp: followUpEnabled,
                repeatsPerDay: repeatsPerDay // Add this line
            )
            
            // Compare current values with the selected pattern values
            patternChanged = !comparisonPattern.isEqual(to: currentPattern)
        } else {
            // Current pattern values
            let currentPattern = PatternValues(
                goalType: selectedGoalType,
                dailyGoalPattern: dailyGoalPattern,
                weeklyGoalPattern: weeklyGoalPattern,
                monthlyGoalPattern: monthlyGoalPattern,
                specificDaysDaily: specificDaysDaily,
                specificDaysWeekly: specificDaysWeekly,
                specificDaysMonthly: specificDaysMonthly,
                daysInterval: selectedDaysInterval,
                weekInterval: selectedWeekInterval,
                monthInterval: selectedMonthInterval,
                followUp: followUpEnabled,
                repeatsPerDay: repeatsPerDay // Add this line
            )
            
            // Compare current values with original values
            patternChanged = !originalPattern.isEqual(to: currentPattern)
        }
    }
    private func saveHabit() {
        // Update basic habit information
        habit.name = name
        habit.habitDescription = habitDescription
        habit.startDate = startDate
        habit.icon = icon
        habit.isBadHabit = isBadHabit
        habit.habitList = selectedHabitList
        habit.intensityLevel = selectedIntensity.rawValue
        
        // Store color as data
        if let colorData = try? NSKeyedArchiver.archivedData(withRootObject: UIColor(selectedColor), requiringSecureCoding: false) {
            habit.color = colorData
        }
        
        // Only update repeat pattern if changed
        if patternChanged {
            let normalizedEffectiveDate = Calendar.current.startOfDay(for: effectiveFrom)
            
            if shouldCreateNewPattern {
                // Create a new RepeatPattern without deleting old ones
                let repeatPattern = RepeatPattern(context: viewContext)
                repeatPattern.effectiveFrom = normalizedEffectiveDate
                repeatPattern.creationDate = Date() // Set the creation date to now
                repeatPattern.followUp = followUpEnabled
                repeatPattern.repeatsPerDay = Int16(repeatsPerDay)
                repeatPattern.habit = habit
                
                // Create appropriate goal type based on selection
                createGoalEntity(for: repeatPattern)
            } else {
                // Update the selected pattern instead of creating a new one
                if let pattern = selectedPattern ?? getMostRecentRepeatPattern(for: habit) {
                    // Don't change the effective date when overwriting
                    // pattern.effectiveFrom = normalizedEffectiveDate
                    pattern.followUp = followUpEnabled
                    pattern.repeatsPerDay = Int16(repeatsPerDay)
                    
                    // Remove old goal entities
                    if let dailyGoal = pattern.dailyGoal {
                        viewContext.delete(dailyGoal)
                    }
                    if let weeklyGoal = pattern.weeklyGoal {
                        viewContext.delete(weeklyGoal)
                    }
                    if let monthlyGoal = pattern.monthlyGoal {
                        viewContext.delete(monthlyGoal)
                    }
                    
                    // Create new goal entity based on selection
                    createGoalEntity(for: pattern)
                }
            }
        }
        
        do {
            try viewContext.save()
        } catch {
            print("Error saving habit: \(error)")
        }
    }
    private func createGoalEntity(for pattern: RepeatPattern) {
        switch selectedGoalType {
        case .daily:
            let dailyGoal = DailyGoal(context: viewContext)
            
            switch dailyGoalPattern {
            case .everyday:
                dailyGoal.everyDay = true
            case .specificDays:
                dailyGoal.specificDays = specificDaysDaily as NSObject
            case .everyXDays:
                dailyGoal.daysInterval = Int16(selectedDaysInterval)
            }
            
            dailyGoal.repeatPattern = pattern
        
        case .weekly:
            let weeklyGoal = WeeklyGoal(context: viewContext)
            
            switch weeklyGoalPattern {
            case .everyWeek:
                weeklyGoal.everyWeek = true
            case .weekInterval:
                weeklyGoal.weekInterval = Int16(selectedWeekInterval)
            }
            
            weeklyGoal.specificDays = specificDaysWeekly as NSObject
            weeklyGoal.repeatPattern = pattern
            
        case .monthly:
            let monthlyGoal = MonthlyGoal(context: viewContext)
            
            switch monthlyGoalPattern {
            case .everyMonth:
                monthlyGoal.everyMonth = true
            case .monthInterval:
                monthlyGoal.monthInterval = Int16(selectedMonthInterval)
            }
            
            monthlyGoal.specificDays = specificDaysMonthly as NSObject
            monthlyGoal.repeatPattern = pattern
        }
    }
    
    private func loadPatternHistory() {
        guard let repeatPatterns = habit.repeatPattern as? Set<RepeatPattern> else {
            patternHistoryData = []
            return
        }
        
        patternHistoryData = repeatPatterns.compactMap { pattern -> (RepeatPattern, Date)? in
            guard let effectiveFrom = pattern.effectiveFrom else { return nil }
            return (pattern, effectiveFrom)
        }
        .sorted { $0.1 > $1.1 } // Most recent first
    }

    // Load a specific pattern into the UI
    private func loadPattern(pattern: RepeatPattern) {
        // Set the effective date first
        if let effectiveFrom = pattern.effectiveFrom {
            self.effectiveFrom = effectiveFrom
        }
        
        // Set repeats per day
        self.repeatsPerDay = Int(pattern.repeatsPerDay)
        
        // Set follow-up state
        self.followUpEnabled = pattern.followUp
        
        // Reset pattern specifics based on type
        if let dailyGoal = pattern.dailyGoal {
            self.selectedGoalType = .daily
            
            if dailyGoal.everyDay {
                self.dailyGoalPattern = .everyday
            } else if dailyGoal.daysInterval > 0 {
                self.dailyGoalPattern = .everyXDays
                self.selectedDaysInterval = Int(dailyGoal.daysInterval)
            } else if let specificDays = dailyGoal.specificDays as? [Bool] {
                self.dailyGoalPattern = .specificDays
                
                // Handle cases where specificDays might have different lengths
                if specificDays.count <= self.specificDaysDaily.count {
                    // Clear existing array
                    self.specificDaysDaily = Array(repeating: false, count: self.specificDaysDaily.count)
                    
                    // Copy values from the pattern
                    for (index, value) in specificDays.enumerated() {
                        if index < self.specificDaysDaily.count {
                            self.specificDaysDaily[index] = value
                        }
                    }
                } else {
                    // If pattern has more days, replace our array
                    self.specificDaysDaily = specificDays
                }
            }
        } else if let weeklyGoal = pattern.weeklyGoal {
            self.selectedGoalType = .weekly
            
            if weeklyGoal.everyWeek {
                self.weeklyGoalPattern = .everyWeek
            } else {
                self.weeklyGoalPattern = .weekInterval
                self.selectedWeekInterval = Int(weeklyGoal.weekInterval)
            }
            
            if let specificDays = weeklyGoal.specificDays as? [Bool], specificDays.count == 7 {
                self.specificDaysWeekly = specificDays
            }
        } else if let monthlyGoal = pattern.monthlyGoal {
            self.selectedGoalType = .monthly
            
            if monthlyGoal.everyMonth {
                self.monthlyGoalPattern = .everyMonth
            } else {
                self.monthlyGoalPattern = .monthInterval
                self.selectedMonthInterval = Int(monthlyGoal.monthInterval)
            }
            
            if let specificDays = monthlyGoal.specificDays as? [Bool], specificDays.count == 31 {
                self.specificDaysMonthly = specificDays
            }
        }
        
        // After loading, check for changes
        checkForPatternChanges()
    }

    // Helper to get a descriptive text for a pattern
    private func getPatternDescription(for pattern: RepeatPattern) -> String {
        var description = ""
        
        if let dailyGoal = pattern.dailyGoal {
            if dailyGoal.everyDay {
                description = "Daily"
            } else if dailyGoal.daysInterval > 0 {
                description = "Every \(dailyGoal.daysInterval) days"
            } else if let specificDays = dailyGoal.specificDays as? [Bool] {
                let selectedDays = specificDays.enumerated()
                    .filter { $0.1 }
                    .map { dayAbbreviation(for: $0.0 % 7) }
                
                if selectedDays.isEmpty {
                    description = "No days selected"
                } else if selectedDays.count <= 3 {
                    description = selectedDays.joined(separator: ", ")
                } else {
                    description = "\(selectedDays.count) specific days"
                }
            }
        } else if let weeklyGoal = pattern.weeklyGoal {
            if weeklyGoal.everyWeek {
                description = "Weekly"
            } else {
                description = "Every \(weeklyGoal.weekInterval) weeks"
            }
            
            if let specificDays = weeklyGoal.specificDays as? [Bool] {
                let selectedDays = specificDays.enumerated()
                    .filter { $0.1 }
                    .map { dayAbbreviation(for: $0.0) }
                
                if !selectedDays.isEmpty && selectedDays.count <= 3 {
                    description += ": " + selectedDays.joined(separator: ", ")
                } else if !selectedDays.isEmpty {
                    description += ": \(selectedDays.count) days"
                }
            }
        } else if let monthlyGoal = pattern.monthlyGoal {
            if monthlyGoal.everyMonth {
                description = "Monthly"
            } else {
                description = "Every \(monthlyGoal.monthInterval) months"
            }
            
            if let specificDays = monthlyGoal.specificDays as? [Bool] {
                let selectedDays = specificDays.enumerated()
                    .filter { $0.1 }
                    .map { String($0.0 + 1) }
                
                if !selectedDays.isEmpty && selectedDays.count <= 3 {
                    description += ": " + selectedDays.joined(separator: ", ")
                } else if !selectedDays.isEmpty {
                    description += ": \(selectedDays.count) days"
                }
            }
        }
        
        if pattern.followUp {
            description += " with follow-up"
        }
        
        if pattern.repeatsPerDay > 1 {
            description += " (\(pattern.repeatsPerDay)x per day)"
        }
        
        return description
    }

    // 8. Day abbreviation helper
    private func dayAbbreviation(for index: Int) -> String {
        let abbreviations = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
        return abbreviations[index % 7]
    }
    
    private var repeatPatternText: String {
        switch selectedGoalType {
        case .daily:
            switch dailyGoalPattern {
            case .everyday:
                return "Every day"
            case .specificDays:
                // Check if the array has multiple weeks
                let weekCount = specificDaysDaily.count / 7
                
                if weekCount > 1 {
                    // Multi-week pattern
                    var weekDescriptions: [String] = []
                    
                    for week in 0..<weekCount {
                        let startIndex = week * 7
                        let endIndex = startIndex + 7
                        
                        let daysForWeek = Array(specificDaysDaily[startIndex..<endIndex])
                        let selectedDayNames = daysForWeek
                            .enumerated()
                            .compactMap { index, isSelected in
                                isSelected ? dayName(for: index) : nil
                            }
                        
                        if !selectedDayNames.isEmpty {
                            weekDescriptions.append("Week \(week + 1): \(selectedDayNames.joined(separator: ", "))")
                        }
                    }
                    
                    if weekDescriptions.isEmpty {
                        return "No days selected"
                    } else if weekDescriptions.count == 1 {
                        // Only one week has selections
                        return weekDescriptions[0]
                    } else {
                        // Return a simplified pattern message
                        return "Every \(weekCount) weeks rotation (\(weekDescriptions.count) active weeks)"
                    }
                } else {
                    // Standard single week
                    let selectedDayNames = specificDaysDaily
                        .enumerated()
                        .compactMap { index, isSelected in
                            isSelected ? dayName(for: index) : nil
                        }
                    return selectedDayNames.isEmpty ? "No days selected" : selectedDayNames.joined(separator: ", ")
                }
            case .everyXDays:
                if selectedDaysInterval == 1 {
                    return "Every day"
                } else {
                    return "Every \(selectedDaysInterval) days"
                }
            }
            
        case .weekly:
            let selectedDayNames = specificDaysWeekly
                .enumerated()
                .compactMap { index, isSelected in
                    isSelected ? dayName(for: index) : nil
                }
            let daysText = selectedDayNames.isEmpty ? "No days selected" : selectedDayNames.joined(separator: ", ")
            
            switch weeklyGoalPattern {
            case .everyWeek:
                return "Weekly: \(daysText)"
            case .weekInterval:
                return "Every \(selectedWeekInterval) weeks: \(daysText)"
            }
            
        case .monthly:
            let selectedDates = specificDaysMonthly
                .enumerated()
                .compactMap { index, isSelected in
                    isSelected ? "\(index + 1)" : nil
                }
            let datesText = selectedDates.isEmpty ? "No dates selected" : selectedDates.joined(separator: ", ")
            
            switch monthlyGoalPattern {
            case .everyMonth:
                return "Monthly: \(datesText)"
            case .monthInterval:
                return "Every \(selectedMonthInterval) months: \(datesText)"
            }
        }
    }
    
    private func dayName(for index: Int) -> String {
        let days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        return days[index % 7]
    }
    
    private func isEmoji(_ text: String) -> Bool {
        if text.isEmpty { return false }
        
        // Check if it's a single character emoji
        if text.count == 1, let firstChar = text.first {
            return firstChar.isEmoji
        }
        
        // Some emojis are multiple characters
        for scalar in text.unicodeScalars {
            if scalar.properties.isEmoji {
                return true
            }
        }
        
        return false
    }
    
    private func customTextField(title: String, text: Binding<String>, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(selectedColor)
                .frame(width: 25)
                .font(.system(size: 12))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.gray)
                
                TextField("", text: text)
                    .font(.system(size: 14, weight: .medium))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 0)
        )
        .cornerRadius(10)
    }
    /*
    private func deletePattern(_ pattern: RepeatPattern) {
        
        // Don't allow deleting the most recent pattern
        guard let patterns = habit.repeatPattern as? Set<RepeatPattern>,
              patterns.count > 1,
              let mostRecent = getMostRecentRepeatPattern(for: habit),
              pattern != mostRecent else {
            return
        }
         
        /*
        guard let patterns = habit.repeatPattern as? Set<RepeatPattern>,
              patterns.count > 1 else {
            return
        }
        */
        // Check if this is the oldest pattern by getting all patterns sorted by date
        let sortedPatterns = patterns.compactMap { p -> (RepeatPattern, Date)? in
            guard let date = p.effectiveFrom else { return nil }
            return (p, date)
        }.sorted { $0.1 < $1.1 } // Sort by date ascending (oldest first)
        
        let isOldestPattern = !sortedPatterns.isEmpty && sortedPatterns[0].0 == pattern
        
        // First delete any associated goal entities
        if let dailyGoal = pattern.dailyGoal {
            viewContext.delete(dailyGoal)
        }
        if let weeklyGoal = pattern.weeklyGoal {
            viewContext.delete(weeklyGoal)
        }
        if let monthlyGoal = pattern.monthlyGoal {
            viewContext.delete(monthlyGoal)
        }
        
        // Remove the pattern from the habit
        habit.removeFromRepeatPattern(pattern)
        
        // Delete the pattern itself
        viewContext.delete(pattern)
        
        // If we deleted the oldest pattern, set the new oldest pattern's effectiveFrom to startDate
        if isOldestPattern && sortedPatterns.count > 1 {
            // Get the next oldest pattern (which is now the oldest)
            let newOldestPattern = sortedPatterns[1].0
            newOldestPattern.effectiveFrom = habit.startDate
        }
        
        // Save changes
        do {
            try viewContext.save()
            print("Successfully deleted pattern")
        } catch {
            print("Failed to delete pattern: \(error)")
        }
    }
     */
    private func deletePattern(_ pattern: RepeatPattern) {
        // Allow deleting any pattern as long as there's more than one
        guard let patterns = habit.repeatPattern as? Set<RepeatPattern>,
              patterns.count > 1 else {
            return
        }
        
        // Safety checks and preparation
        do {
            // Begin a nested context for safe operations
            let backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            backgroundContext.parent = viewContext
            
            // Get the pattern in this context
            let patternObjectID = pattern.objectID
            guard let patternInContext = try? backgroundContext.existingObject(with: patternObjectID) as? RepeatPattern,
                  let habitInContext = patternInContext.habit else {
                return
            }
            
            // Important: Check if this is the oldest pattern
            let sortedPatterns = patterns.compactMap { p -> (RepeatPattern, Date)? in
                guard let date = p.effectiveFrom else { return nil }
                return (p, date)
            }.sorted { $0.1 < $1.1 } // Sort by date ascending (oldest first)
            
            let isOldestPattern = !sortedPatterns.isEmpty && sortedPatterns[0].0 == pattern
            
            // First delete any associated goal entities
            if let dailyGoal = patternInContext.dailyGoal {
                backgroundContext.delete(dailyGoal)
            }
            if let weeklyGoal = patternInContext.weeklyGoal {
                backgroundContext.delete(weeklyGoal)
            }
            if let monthlyGoal = patternInContext.monthlyGoal {
                backgroundContext.delete(monthlyGoal)
            }
            
            // Remove relationship to habit before deleting
            habitInContext.removeFromRepeatPattern(patternInContext)
            
            // Delete the pattern itself
            backgroundContext.delete(patternInContext)
            
            // If we deleted the oldest pattern, set the new oldest pattern's effectiveFrom to startDate
            if isOldestPattern && sortedPatterns.count > 1 {
                // Get the next oldest pattern (which is now the oldest)
                let newOldestPatternID = sortedPatterns[1].0.objectID
                guard let newOldestPattern = try? backgroundContext.existingObject(with: newOldestPatternID) as? RepeatPattern else {
                    // Roll back and return if we can't get the object
                    backgroundContext.rollback()
                    return
                }
                newOldestPattern.effectiveFrom = habit.startDate
            }
            
            // Save the background context
            try backgroundContext.save()
            
            // Save the main context
            try viewContext.save()
            
            // Update the UI
            loadPatternHistory()
            
        } catch {
            print("Failed to delete pattern: \(error)")
            // Handle the error, perhaps show an alert to the user
        }
    }
}

// Helper function to get the most recent repeat pattern for a habit
func getMostRecentRepeatPattern(for habit: Habit) -> RepeatPattern? {
    guard let repeatPatterns = habit.repeatPattern as? Set<RepeatPattern> else {
        return nil
    }
    
    return repeatPatterns.sorted { pattern1, pattern2 in
        guard let date1 = pattern1.effectiveFrom, let date2 = pattern2.effectiveFrom else {
            return false
        }
        return date1 > date2
    }.first
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let habit = Habit(context: context)
    habit.name = "Morning Run"
    habit.habitDescription = "Go for a 5km run every morning"
    habit.startDate = Date()
    habit.icon = "figure.run"
    habit.isBadHabit = false
    
    // Create a repeat pattern for preview
    let repeatPattern = RepeatPattern(context: context)
    repeatPattern.effectiveFrom = Date()
    repeatPattern.followUp = false
    
    // Create a daily goal
    let dailyGoal = DailyGoal(context: context)
    dailyGoal.everyDay = true
    dailyGoal.repeatPattern = repeatPattern
    
    // Connect repeat pattern to habit
    repeatPattern.habit = habit
    
    return EditHabitView(habit: habit)
        .environment(\.managedObjectContext, context)
}
