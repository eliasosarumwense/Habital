//
//  CreateHabitView.swift
//  Habital
//
//  Created by Elias Osarumwense on 29.03.25.
//

import SwiftUI
import CoreData

//
//  CreateHabitView.swift
//  Habital
//
//  Minimal single-screen design with expandable sections
//
//
//  CreateHabitView.swift
//  Habital
//
//  Minimal single-screen design with expandable sections
//

import SwiftUI
import CoreData

struct CreateHabitView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isTextFieldFocused: Bool
    
    // Optional AI data - nil when creating from scratch
    let habitData: HabitResponse?
    let dynamicIcon: String?
    let habitColor: Color?
    let preselectedList: HabitList?
    
    // Core form state
    @State private var name: String
    @State private var startDate = Date()
    @State private var icon: String
    @State private var selectedColor: Color
    @State private var repeatsPerDay: Int
    
    // Schedule state
    @State private var selectedGoalType: HabitGoalType = .daily
    @State private var dailyGoalPattern: DailyGoalPattern = .everyday
    @State private var specificDaysDaily: [Bool] = Array(repeating: false, count: 7)
    @State private var selectedDaysInterval: Int = 1
    @State private var weeklyGoalPattern: WeeklyGoalPattern = .everyWeek
    @State private var specificDaysWeekly: [Bool] = Array(repeating: false, count: 7)
    @State private var selectedWeekInterval: Int = 2
    @State private var monthlyGoalPattern: MonthlyGoalPattern = .everyMonth
    @State private var specificDaysMonthly: [Bool] = Array(repeating: false, count: 31)
    @State private var selectedMonthInterval: Int = 2
    @State private var followUpEnabled: Bool = false
    
    // Expandable sections
    @State private var showAdvancedOptions = false
    @State private var habitDescription: String
    @State private var isBadHabit: Bool
    @State private var selectedIntensity: HabitIntensity
    @State private var selectedHabitList: HabitList?
    @State private var notificationsEnabled: Bool = false
    @State private var notificationTime = Date()
    @State private var notificationNotes: String = ""
    @State private var selectedCategory: HabitCategory? = nil
    
    // UI state
    @State private var showIconPicker = false
    @State private var showHabitListPicker = false
    @State private var showRepeatPatternSheet = false
    @State private var animateIcon = false
    
    private let colors: [Color] = [
        .red,
        .orange,
        .yellow,
        .green,
        .mint,
        .teal,
        .cyan,
        .blue,
        .indigo,
        .purple,
        .pink,
        .brown,
        .gray,
        .black,
        .white
    ]

    let onHabitCreated: (() -> Void)?
    
    // Tracking type selection
    @State private var habitTrackingType: HabitTrackingType = .repetitions

    // Duration tracking
    @State private var durationMinutes: Int = 30

    // Quantity tracking
    @State private var targetQuantity: Int = 10
    @State private var quantityUnit: String = "pages"
    @State private var customUnit: String = ""
    
    @State private var habitWallpaper: UIImage? = nil
    @State private var wallpaperPrompt: String = ""
    @State private var showWallpaperSheet = false
    
    // MARK: - Initializers
    
    // Default initializer
    init(preselectedList: HabitList? = nil, onHabitCreated: (() -> Void)? = nil) {
        self.habitData = nil
        self.dynamicIcon = nil
        self.habitColor = nil
        self.preselectedList = preselectedList
        self.onHabitCreated = onHabitCreated
        
        self._name = State(initialValue: "")
        self._habitDescription = State(initialValue: "")
        self._icon = State(initialValue: "star")
        self._selectedColor = State(initialValue: .primary)
        self._isBadHabit = State(initialValue: false)
        self._repeatsPerDay = State(initialValue: 1)
        self._selectedIntensity = State(initialValue: .light)
        self._selectedHabitList = State(initialValue: preselectedList)
    }

    // AI data initializer
    init(habitData: HabitResponse, dynamicIcon: String, habitColor: Color, preselectedList: HabitList? = nil, onHabitCreated: (() -> Void)? = nil) {
        self.habitData = habitData
        self.dynamicIcon = dynamicIcon
        self.habitColor = habitColor
        self.preselectedList = preselectedList
        self.onHabitCreated = onHabitCreated
        
        self._name = State(initialValue: habitData.name)
        self._habitDescription = State(initialValue: habitData.habitDescription ?? "")
        self._icon = State(initialValue: dynamicIcon)
        self._selectedColor = State(initialValue: habitColor)
        self._isBadHabit = State(initialValue: habitData.isBadHabit ?? false)
        self._repeatsPerDay = State(initialValue: habitData.repeatsPerDay ?? 1)
        self._selectedHabitList = State(initialValue: preselectedList)
        
        let intensity: HabitIntensity
        switch habitData.intensityLevel ?? 2 {
        case 1: intensity = .light
        case 2: intensity = .moderate
        case 3: intensity = .high
        case 4: intensity = .extreme
        default: intensity = .moderate
        }
        self._selectedIntensity = State(initialValue: intensity)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let startDateFromResponse = formatter.date(from: habitData.startDate) {
            self._startDate = State(initialValue: startDateFromResponse)
        }
        
        if let repeatPattern = habitData.repeatPattern, repeatPattern.everyDay == true {
            self._dailyGoalPattern = State(initialValue: .everyday)
        }
    }
    
    private var isAIGenerated: Bool {
        return habitData != nil
    }
    
    private var backgroundView: some View {
        ZStack {
            // Base gradient (existing)
            let base = selectedColor ?? .secondary
            let top   = colorScheme == .dark ? 0.10 : 0.15
            let mid   = colorScheme == .dark ? 0.06 : 0.11
            let low   = colorScheme == .dark ? 0.04 : 0.08
            let floor = colorScheme == .dark ? Color(hex: "0A0A0A") : .clear
            
            LinearGradient(
                gradient: Gradient(colors: [
                    floor,
                    base.opacity(low),
                    base.opacity(mid),
                    base.opacity(top)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Wallpaper overlay with fade
            if let wallpaper = habitWallpaper {
                GeometryReader { geometry in
                    Image(uiImage: wallpaper)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .mask(
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: .black, location: 0.0),
                                    .init(color: .black.opacity(0.8), location: 0.3),
                                    .init(color: .black.opacity(0.4), location: 0.5),
                                    .init(color: .clear, location: 0.8)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .opacity(colorScheme == .dark ? 0.4 : 0.5)
                        .ignoresSafeArea()
                }
            }
        }
    }
    
    var body: some View {

            ZStack {
                backgroundView
                /*
                // Background matching MainCreateHabitView style
                LinearGradient(
                    gradient: Gradient(colors: [
                        colorScheme == .dark ? Color(.systemBackground) : Color(.systemGray6).opacity(0.3),
                        colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                */
                VStack(spacing: 0) {
                    // Navigation
                    CreateHabitNavigationHeader(
                        selectedColor: selectedColor,
                        isNameEmpty: name.isEmpty,
                        dismiss: { dismiss() },
                        createAction: { createHabitAction() }
                    )
                    VStack(spacing: 0) {
                        // Main content
                        VStack(spacing: 15) {
                            // AI badge if applicable
                            if isAIGenerated {
                                aiBadge
                            }
                            
                            
                            // Core habit info (icon, name, description)
                            CreateHabitCoreSection(
                                name: $name,
                                //habitDescription: $habitDescription,
                                icon: $icon,
                                selectedColor: $selectedColor,
                                isTextFieldFocused: $isTextFieldFocused,
                                colors: colors,
                                isBadHabit: $isBadHabit,
                                selectedIntensity: $selectedIntensity,
                                showIconPicker: { showIconPicker = true },
                                showWallpaperPicker: { showWallpaperSheet = true },
                                hasWallpaper: habitWallpaper != nil,
                                hasExistingHabits: false  // Add the missing parameter
                            )
                            
                            // Schedule with next occurrence
                            CreateHabitScheduleSection(
                                        startDate: $startDate,
                                        repeatsPerDay: $repeatsPerDay,
                                        habitTrackingType: $habitTrackingType,  // NEW
                                        durationMinutes: $durationMinutes,      // NEW
                                        targetQuantity: $targetQuantity,        // NEW
                                        quantityUnit: $quantityUnit,           // NEW
                                        selectedColor: selectedColor,
                                        isBadHabit: isBadHabit,
                                        repeatPatternText: repeatPatternText,
                                        firstOccurrenceText: firstOccurrenceFromToday,
                                        showRepeatPattern: { showRepeatPatternSheet = true }
                                    )
                            
                            // Advanced options
                            CreateHabitMoreOptionsSection(
                                showAdvancedOptions: $showAdvancedOptions,
                                isBadHabit: $isBadHabit,
                                selectedIntensity: $selectedIntensity,
                                selectedHabitList: $selectedHabitList,
                                selectedCategory: $selectedCategory,  // ADD THIS LINE
                                notificationsEnabled: $notificationsEnabled,
                                notificationTime: $notificationTime,
                                notificationNotes: $notificationNotes,
                                isTextFieldFocused: $isTextFieldFocused,
                                selectedColor: selectedColor,
                                showHabitListPicker: { showHabitListPicker = true }
                            )
                        }
                        .padding(.horizontal)
                        
                        // Spacer to push content to top
                        Spacer()
                        
                    }
                    .padding(.bottom, 10)
                }
                /*
                VStack {
                    Spacer()
                    createButton
                        .padding(.bottom, 25)
                }
                 */
            }
            .ignoresSafeArea()

        .sheet(isPresented: $showRepeatPatternSheet) {
            repeatPatternSheet
        }
        .sheet(isPresented: $showIconPicker) {
            iconPickerSheet
        }
        .sheet(isPresented: $showHabitListPicker) {
            habitListPickerSheet
        }
        .sheet(isPresented: $showWallpaperSheet) {
            HabitWallpaperSheet(
                selectedImage: $habitWallpaper,
                userPrompt: $wallpaperPrompt
            )
        }
    }
    
    
    
    private var aiBadge: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.purple)
                
                Text("AI Generated")
                    .font(.custom("Lexend-Medium", size: 11))
                    .foregroundColor(.purple)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.purple.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                    )
            )
            
            Spacer()
        }
    }
    
    
    
    // MARK: - Quick Schedule Section
    private var quickScheduleSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Schedule")
                    .font(.custom("Lexend-SemiBold", size: 16))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                // Start date and repeat pattern
                HStack(spacing: 16) {
                    // Start date
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Start")
                            .font(.custom("Lexend-Medium", size: 12))
                            .foregroundColor(.secondary)
                        
                        DatePicker("", selection: $startDate, displayedComponents: .date)
                            .labelsHidden()
                            .scaleEffect(0.9)
                            .clipped()
                    }
                    
                    Spacer()
                    
                    // Repeat pattern button
                    Button(action: { showRepeatPatternSheet = true }) {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Pattern")
                                .font(.custom("Lexend-Medium", size: 12))
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 4) {
                                Text(repeatPatternText)
                                    .font(.custom("Lexend-Medium", size: 14))
                                    .foregroundColor(selectedColor)
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(selectedColor.opacity(0.6))
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Next occurrence display
                HStack {
                    Text("First occurrence")
                        .font(.custom("Lexend-Medium", size: 14))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(firstOccurrenceFromToday)
                        .font(.custom("Lexend-SemiBold", size: 12))
                        .foregroundColor(selectedColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(selectedColor.opacity(0.12))
                        )
                }
                
                // Repeats per day (only for good habits)
                if !isBadHabit {
                    HStack {
                        Text("Times per day")
                            .font(.custom("Lexend-Medium", size: 14))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        HStack(spacing: 12) {
                            Button(action: {
                                if repeatsPerDay > 1 {
                                    repeatsPerDay -= 1
                                    triggerHaptic(.impactLight)
                                }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(repeatsPerDay > 1 ? selectedColor : .gray.opacity(0.5))
                            }
                            .disabled(repeatsPerDay <= 1)
                            
                            Text("\(repeatsPerDay)")
                                .font(.custom("Lexend-Bold", size: 16))
                                .frame(minWidth: 24)
                                .foregroundColor(.primary)
                            
                            Button(action: {
                                if repeatsPerDay < 20 {
                                    repeatsPerDay += 1
                                    triggerHaptic(.impactLight)
                                }
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(repeatsPerDay < 20 ? selectedColor : .gray.opacity(0.5))
                            }
                            .disabled(repeatsPerDay >= 20)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(glassBackground)
    }
    
    
    
    // MARK: - Create Button
    private var createButton: some View {
        Button(action: createHabitAction) {
            HStack(spacing: 12) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .semibold))
                
                Text("Create Habit")
                    .font(.custom("Lexend-SemiBold", size: 16))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(createButtonBackground)
            .disabled(name.isEmpty)
            .opacity(name.isEmpty ? 0.6 : 1.0)
            .padding(.horizontal)
        }
    }
    
    // MARK: - Computed Properties
    
    private var repeatPatternText: String {
        switch selectedGoalType {
        case .daily:
            return getDailyPatternText()
        case .weekly:
            return getWeeklyPatternText()
        case .monthly:
            return getMonthlyPatternText()
        }
    }
    
    private func getDailyPatternText() -> String {
        switch dailyGoalPattern {
        case .everyday:
            return "Every day"
        case .specificDays:
            let selectedDayNames = getSelectedDayNames(from: specificDaysDaily)
            return selectedDayNames.isEmpty ? "No days selected" : selectedDayNames.joined(separator: ", ")
        case .everyXDays:
            return selectedDaysInterval == 1 ? "Every day" : "Every \(selectedDaysInterval) days"
        }
    }
    
    private func getWeeklyPatternText() -> String {
        let selectedDayNames = getSelectedDayNames(from: specificDaysWeekly)
        let daysText = selectedDayNames.isEmpty ? "No days selected" : selectedDayNames.joined(separator: ", ")
        
        switch weeklyGoalPattern {
        case .everyWeek:
            return "Weekly: \(daysText)"
        case .weekInterval:
            return "Every \(selectedWeekInterval) weeks: \(daysText)"
        }
    }
    
    private func getMonthlyPatternText() -> String {
        let selectedDates = getSelectedDates(from: specificDaysMonthly)
        let datesText = selectedDates.isEmpty ? "No dates selected" : selectedDates.joined(separator: ", ")
        
        switch monthlyGoalPattern {
        case .everyMonth:
            return "Monthly: \(datesText)"
        case .monthInterval:
            return "Every \(selectedMonthInterval) months: \(datesText)"
        }
    }
    
    private func getSelectedDayNames(from days: [Bool]) -> [String] {
        return days.enumerated().compactMap { index, isSelected in
            isSelected ? dayName(for: index) : nil
        }
    }
    
    private func getSelectedDates(from days: [Bool]) -> [String] {
        return days.enumerated().compactMap { index, isSelected in
            isSelected ? "\(index + 1)" : nil
        }
    }
    
    private var firstOccurrenceFromToday: String {
        let privateContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        privateContext.parent = PersistenceController.shared.container.viewContext
        
        let tempHabit = createTempHabit(in: privateContext)
        let tempRepeatPattern = createTempRepeatPattern(for: tempHabit, in: privateContext)
        
        createTempGoalType(for: tempRepeatPattern, in: privateContext)
        
        let repeatPatterns = NSSet(object: tempRepeatPattern)
        tempHabit.repeatPattern = repeatPatterns
        
        return calculateFirstOccurrence(for: tempHabit)
    }
    
    private func createTempHabit(in context: NSManagedObjectContext) -> Habit {
        let tempHabit = Habit(context: context)
        tempHabit.startDate = startDate
        tempHabit.id = UUID()
        return tempHabit
    }
    
    private func createTempRepeatPattern(for habit: Habit, in context: NSManagedObjectContext) -> RepeatPattern {
        let tempRepeatPattern = RepeatPattern(context: context)
        tempRepeatPattern.effectiveFrom = startDate
        tempRepeatPattern.followUp = followUpEnabled
        return tempRepeatPattern
    }
    
    private func createTempGoalType(for repeatPattern: RepeatPattern, in context: NSManagedObjectContext) {
        switch selectedGoalType {
        case .daily:
            createTempDailyGoal(for: repeatPattern, in: context)
        case .weekly:
            createTempWeeklyGoal(for: repeatPattern, in: context)
        case .monthly:
            createTempMonthlyGoal(for: repeatPattern, in: context)
        }
    }
    
    private func createTempDailyGoal(for repeatPattern: RepeatPattern, in context: NSManagedObjectContext) {
        let dailyGoal = DailyGoal(context: context)
        
        switch dailyGoalPattern {
        case .everyday:
            dailyGoal.everyDay = true
        case .specificDays:
            dailyGoal.specificDays = specificDaysDaily as NSObject
        case .everyXDays:
            dailyGoal.daysInterval = Int16(selectedDaysInterval)
        }
        
        dailyGoal.repeatPattern = repeatPattern
        repeatPattern.dailyGoal = dailyGoal
    }
    
    private func createTempWeeklyGoal(for repeatPattern: RepeatPattern, in context: NSManagedObjectContext) {
        let weeklyGoal = WeeklyGoal(context: context)
        
        switch weeklyGoalPattern {
        case .everyWeek:
            weeklyGoal.everyWeek = true
        case .weekInterval:
            weeklyGoal.weekInterval = Int16(selectedWeekInterval)
        }
        
        weeklyGoal.specificDays = specificDaysWeekly as NSObject
        weeklyGoal.repeatPattern = repeatPattern
        repeatPattern.weeklyGoal = weeklyGoal
    }
    
    private func createTempMonthlyGoal(for repeatPattern: RepeatPattern, in context: NSManagedObjectContext) {
        let monthlyGoal = MonthlyGoal(context: context)
        
        switch monthlyGoalPattern {
        case .everyMonth:
            monthlyGoal.everyMonth = true
        case .monthInterval:
            monthlyGoal.monthInterval = Int16(selectedMonthInterval)
        }
        
        monthlyGoal.specificDays = specificDaysMonthly as NSObject
        monthlyGoal.repeatPattern = repeatPattern
        repeatPattern.monthlyGoal = monthlyGoal
    }
    
    private func calculateFirstOccurrence(for habit: Habit) -> String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let normalizedStartDate = calendar.startOfDay(for: startDate)
        let referenceDate = max(today, normalizedStartDate)
        
        if selectedGoalType == .daily && dailyGoalPattern == .specificDays && !specificDaysDaily.isEmpty {
            return findNextSpecificDay(from: referenceDate, for: habit)
        }
        
        let nextText = HabitUtilities.getNextOccurrenceText(for: habit, selectedDate: referenceDate)
        
        if nextText == "Today" && referenceDate != today {
            return formatRelativeDate(referenceDate)
        }
        
        return nextText
    }
    
    private func findNextSpecificDay(from referenceDate: Date, for habit: Habit) -> String {
        let calendar = Calendar.current
        var currentDate = referenceDate
        
        for dayOffset in 0..<30 {
            if HabitUtilities.isHabitActive(habit: habit, on: currentDate) {
                return formatRelativeDate(currentDate)
            }
            
            if let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDate) {
                currentDate = nextDay
            } else {
                break
            }
        }
        return "Not scheduled"
    }

    private func formatRelativeDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let daysDifference = calendar.dateComponents([.day], from: today, to: date).day ?? 0
        
        if daysDifference == 0 {
            return "Today"
        } else if daysDifference == 1 {
            return "Tomorrow"
        } else if daysDifference < 7 {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd. MMMM"
            return formatter.string(from: date)
        }
    }
    
    private func dayName(for index: Int) -> String {
        let days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        return days[index % 7]
    }
    
    // MARK: - Helper Views
    
    private var glassBackground: some View {
        ZStack {
            // Main glass background - matching MainCreateHabitView style
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
            
            // Subtle gradient overlay for depth
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(colorScheme == .dark ? 0.1 : 0.3),
                            Color.clear,
                            Color.black.opacity(colorScheme == .dark ? 0.15 : 0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .blendMode(.overlay)
            
            // Border with glass effect
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(colorScheme == .dark ? 0.3 : 0.5),
                            Color.white.opacity(colorScheme == .dark ? 0.1 : 0.2),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
    }
    
    private var createButtonBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(
                LinearGradient(
                    colors: name.isEmpty ?
                        [.gray.opacity(0.6), .gray.opacity(0.4)] :
                        [selectedColor, selectedColor.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
    }
    
    private func colorPickerButton(_ color: Color) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedColor = color
            }
            triggerHaptic(.impactLight)
        }) {
            Circle()
                .fill(color)
                .frame(width: 28, height: 28)
                .overlay(
                    Circle()
                        .stroke(.white, lineWidth: selectedColor == color ? 2.5 : 0)
                )
                .shadow(
                    color: color.opacity(0.4),
                    radius: selectedColor == color ? 6 : 3,
                    x: 0,
                    y: selectedColor == color ? 3 : 1
                )
                .scaleEffect(selectedColor == color ? 1.1 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Sheets
    private var repeatPatternSheet: some View {
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
    
    private var iconPickerSheet: some View {
        IconPickerView(
            selectedIcon: $icon,
            selectedColor: selectedColor
        )
    }
    
    private var habitListPickerSheet: some View {
        HabitListPickerView(selectedHabitList: $selectedHabitList)
            .environment(\.managedObjectContext, viewContext)
    }
    
    // MARK: - Actions
    private func createHabitAction() {
        createHabit()
        onHabitCreated?()
        if onHabitCreated == nil {
            dismiss()
        }
    }
    
    // MARK: - Core Data Functions
    private func createHabit() {
        let newHabit = Habit(context: viewContext)
        newHabit.id = UUID()
        newHabit.name = name
        newHabit.habitDescription = habitDescription
        newHabit.startDate = startDate
        newHabit.icon = icon
        newHabit.isBadHabit = isBadHabit
        newHabit.isArchived = false  // Explicitly set to false so it shows up in the overview
        newHabit.intensityLevel = selectedIntensity.rawValue
        newHabit.category = selectedCategory
        if let selectedList = selectedHabitList {
            newHabit.habitList = selectedList
        }
        
        determineHabitOrder(for: newHabit)
        storeHabitColor(for: newHabit)
        
        let repeatPattern = createRepeatPattern(for: newHabit)
        createNotificationIfEnabled(for: newHabit)
        createGoalType(for: repeatPattern)
        
        newHabit.addToRepeatPattern(repeatPattern)
        saveContext()
    }
    
    private func determineHabitOrder(for habit: Habit) {
        let fetchRequest: NSFetchRequest<Habit> = Habit.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Habit.order, ascending: false)]
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try viewContext.fetch(fetchRequest)
            let highestOrder = results.first?.order ?? -1
            habit.order = highestOrder + 1
        } catch {
            habit.order = 0
        }
    }
    
    private func storeHabitColor(for habit: Habit) {
        if let colorData = try? NSKeyedArchiver.archivedData(withRootObject: UIColor(selectedColor), requiringSecureCoding: false) {
            habit.color = colorData
        }
    }
    
    private func createRepeatPattern(for habit: Habit) -> RepeatPattern {
        let repeatPattern = RepeatPattern(context: viewContext)
        repeatPattern.creationDate = Date()
        repeatPattern.effectiveFrom = startDate
        repeatPattern.followUp = followUpEnabled
        
        // FIX: Actually set the tracking type (this was commented out!)
        repeatPattern.trackingType = habitTrackingType.rawValue
        
        // Configure based on tracking type
        switch habitTrackingType {
        case .repetitions:
            repeatPattern.repeatsPerDay = Int16(repeatsPerDay)
            repeatPattern.duration = 0
            repeatPattern.targetQuantity = 0
            
        case .duration:
            repeatPattern.repeatsPerDay = 1 // Duration habits complete once
            repeatPattern.duration = Int16(durationMinutes)
            repeatPattern.targetQuantity = 0
            
        case .quantity:
            repeatPattern.repeatsPerDay = 1 // Quantity habits complete once
            repeatPattern.duration = 0
            repeatPattern.targetQuantity = Int32(targetQuantity)
            repeatPattern.quantityUnit = quantityUnit == "custom" ? customUnit : quantityUnit
        }
        
        repeatPattern.habit = habit
        return repeatPattern
    }
    
    private func createNotificationIfEnabled(for habit: Habit) {
        if notificationsEnabled {
            let notification = Notification(context: viewContext)
            notification.id = UUID()
            notification.timestamp = notificationTime
            notification.notes = notificationNotes
            notification.habit = habit
            habit.addToNotification(notification)
        }
    }
    
    private func createGoalType(for repeatPattern: RepeatPattern) {
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
            dailyGoal.repeatPattern = repeatPattern
            repeatPattern.dailyGoal = dailyGoal
            
        case .weekly:
            let weeklyGoal = WeeklyGoal(context: viewContext)
            weeklyGoal.everyWeek = weeklyGoalPattern == .everyWeek
            if weeklyGoalPattern == .weekInterval {
                weeklyGoal.weekInterval = Int16(selectedWeekInterval)
            }
            weeklyGoal.specificDays = specificDaysWeekly as NSObject
            weeklyGoal.repeatPattern = repeatPattern
            repeatPattern.weeklyGoal = weeklyGoal
            
        case .monthly:
            let monthlyGoal = MonthlyGoal(context: viewContext)
            monthlyGoal.everyMonth = monthlyGoalPattern == .everyMonth
            if monthlyGoalPattern == .monthInterval {
                monthlyGoal.monthInterval = Int16(selectedMonthInterval)
            }
            monthlyGoal.specificDays = specificDaysMonthly as NSObject
            monthlyGoal.repeatPattern = repeatPattern
            repeatPattern.monthlyGoal = monthlyGoal
        }
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
            NotificationCenter.default.post(name: NSNotification.Name("HabitCreated"), object: nil)
        } catch {
            print("Error saving habit: \(error)")
        }
    }
}

// MARK: - Supporting Functions
private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
    let impactFeedback = UIImpactFeedbackGenerator(style: style)
    impactFeedback.impactOccurred()
}

// MARK: - Supporting Types





// MARK: - Supporting Views

struct ModernTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(.quaternary, lineWidth: 0.5)
                    )
            )
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct HabitResponse: Codable, Identifiable {
    let id = UUID()
    let name: String
    let habitDescription: String?
    let isBadHabit: Bool?
    let startDate: String
    let intensityLevel: Int?
    let repeatsPerDay: Int?  // NEW: Separate from intensity
    
    struct RepeatPattern: Codable {
        let type: String?
        let everyDay: Bool?
        let daily: Bool?
        let daysInterval: Int?
        let specificDays: [String]?
    }
    let repeatPattern: RepeatPattern?
}

// Wrapper for array of habits
struct HabitResponseWrapper: Codable {
    let habits: [HabitResponse]
}
