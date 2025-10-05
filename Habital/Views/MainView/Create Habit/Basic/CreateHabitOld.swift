//
//  CreateHabitOld.swift
//  Habital
//
//  Created by Elias Osarumwense on 23.08.25.
//

//
//  CreateHabitView.swift
//  Habital
//
//  Created by Elias Osarumwense on 29.03.25.
//
/*
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
    
    // Form state - initialized with AI data or defaults
    @State private var name: String
    @State private var habitDescription: String
    @State private var startDate = Date()
    @State private var icon: String
    @State private var showIconPicker = false
    @State private var selectedColor: Color
    @State private var showColorPicker = false
    
    // Goal Type
    @State private var selectedGoalType: HabitGoalType = .daily
    
    // Daily goal properties
    @State private var dailyGoalPattern: DailyGoalPattern = .everyday
    @State private var specificDaysDaily: [Bool] = Array(repeating: false, count: 7)
    @State private var selectedDaysInterval: Int = 1
    
    // Weekly goal properties
    @State private var weeklyGoalPattern: WeeklyGoalPattern = .everyWeek
    @State private var specificDaysWeekly: [Bool] = Array(repeating: false, count: 7)
    @State private var selectedWeekInterval: Int = 2
    
    // Monthly goal properties
    @State private var monthlyGoalPattern: MonthlyGoalPattern = .everyMonth
    @State private var specificDaysMonthly: [Bool] = Array(repeating: false, count: 31)
    @State private var selectedMonthInterval: Int = 2
    
    // Common properties
    @State private var followUpEnabled: Bool = false
    
    // NEW: Habit tracking type - either by repetitions or duration
    @State private var habitTrackingType: HabitTrackingType = .repetitions
    @State private var repeatsPerDay: Int
    @State private var durationMinutes: Int = 15 // Default 15 minutes
    
    // Notification properties
    @State private var notificationsEnabled: Bool = false
    @State private var notificationTime = Date()
    @State private var notificationNotes: String = ""
    @State private var showNotificationSheet = false
    
    // Other state variables
    @State private var isBadHabit: Bool
    @State private var selectedHabitList: HabitList?
    @State private var showHabitListPicker = false
    @State private var showRepeatPatternSheet = false
    @State private var animateIcon = false
    @State private var animateCards = false
    @State private var showFollowUpInfo = false
    @State private var selectedIntensity: HabitIntensity
    
    private let colors: [Color] = [.blue, .green, .orange, .red, .purple, .pink, .yellow, .primary]
    
    let onHabitCreated: (() -> Void)?
    
    // MARK: - Initializers
    
    // Default initializer for normal habit creation
    init(preselectedList: HabitList? = nil, onHabitCreated: (() -> Void)? = nil) {
        self.habitData = nil
        self.dynamicIcon = nil
        self.habitColor = nil
        self.preselectedList = preselectedList
        self.onHabitCreated = onHabitCreated
        
        // Initialize with default values
        self._name = State(initialValue: "")
        self._habitDescription = State(initialValue: "")
        self._icon = State(initialValue: "star")
        self._selectedColor = State(initialValue: .primary)
        self._isBadHabit = State(initialValue: false)
        self._repeatsPerDay = State(initialValue: 1)
        self._selectedIntensity = State(initialValue: .light)
        self._selectedHabitList = State(initialValue: preselectedList)
    }

    // AI data initializer for pre-filled habit creation
    init(habitData: HabitResponse, dynamicIcon: String, habitColor: Color, preselectedList: HabitList? = nil, onHabitCreated: (() -> Void)? = nil) {
        self.habitData = habitData
        self.dynamicIcon = dynamicIcon
        self.habitColor = habitColor
        self.preselectedList = preselectedList
        self.onHabitCreated = onHabitCreated
        
        // Initialize state with AI data
        self._name = State(initialValue: habitData.name)
        self._habitDescription = State(initialValue: habitData.habitDescription ?? "")
        self._icon = State(initialValue: dynamicIcon)
        self._selectedColor = State(initialValue: habitColor)
        self._isBadHabit = State(initialValue: habitData.isBadHabit ?? false)
        
        // Use repeatsPerDay from AI (separate from intensity)
        self._repeatsPerDay = State(initialValue: habitData.repeatsPerDay ?? 1)
        self._selectedHabitList = State(initialValue: preselectedList)
        
        // Map intensity level to HabitIntensity enum (separate from repeats)
        let intensity: HabitIntensity
        switch habitData.intensityLevel ?? 2 {
        case 1: intensity = .light
        case 2: intensity = .moderate
        case 3: intensity = .high
        case 4: intensity = .extreme
        default: intensity = .moderate
        }
        self._selectedIntensity = State(initialValue: intensity)
        
        // Parse start date
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let startDateFromResponse = formatter.date(from: habitData.startDate) {
            self._startDate = State(initialValue: startDateFromResponse)
        }
        
        // Set up daily pattern based on repeat pattern
        if let repeatPattern = habitData.repeatPattern, repeatPattern.everyDay == true {
            self._dailyGoalPattern = State(initialValue: .everyday)
        }
    }
    
    
    
    // Computed property to check if this is AI-generated
    private var isAIGenerated: Bool {
        return habitData != nil
    }
    
    var body: some View {
        ZStack (alignment: .top) {
            
            UltraThinMaterialNavBar(
                title: "Create Habit",
                leftIcon: "xmark",
                rightIcon: "info.circle",
                leftAction: {
                    dismiss()
                },
                
                titleColor: .primary,
                leftIconColor: .red
            )
            .zIndex(1)
            
            contentView
                
            
            
        }
            .sheet(isPresented: $showRepeatPatternSheet) {
                repeatPatternSheet
            }
            .sheet(isPresented: $showIconPicker) {
                iconPickerSheet
            }
            .sheet(isPresented: $showHabitListPicker) {
                habitListPickerSheet
            }
        }
    
    
    // MARK: - Main Content View
    
    private var contentView: some View {
        ZStack {
            backgroundGradient
            
            ScrollView(.vertical, showsIndicators: false) {
                Color.clear.frame(height: 50)
                VStack(spacing: 28) {
                    headerSection
                    mainFormCard
                    createButton
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            toolbarContent
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8)) {
                animateCards = true
            }
        }
    }
    
    // MARK: - Background
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: backgroundGradientColors),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    private var backgroundGradientColors: [Color] {
        [
            colorScheme == .dark ? Color(.systemBackground) : Color(.systemGray6).opacity(0.3),
            colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white
        ]
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 10) {
            if isAIGenerated {
                //aiBadge
            }
            
            iconContainer
            titleAndSubtitle
            modernColorPicker
        }
        .padding(.top, 20)
        .padding(.horizontal, 20)
    }
    
    private var aiBadge: some View {
        HStack {
            badgeContent
            Spacer()
        }
        .padding(.horizontal, 20)
    }
    
    private var badgeContent: some View {
        ZStack {
            // Main badge content
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
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.purple.opacity(0.12),
                                Color.blue.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.purple.opacity(0.3),
                                        Color.blue.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Color.purple.opacity(0.15), radius: 6, x: 0, y: 3)
            )
        }
    }
    
    private var badgeBackground: some View {
        Capsule()
            .fill(.purple.opacity(0.1))
            .overlay(
                Capsule()
                    .strokeBorder(.purple.opacity(0.3), lineWidth: 0.5)
            )
    }
    
    private var iconContainer: some View {
        ZStack {
            //iconContainerBackground
            
            // Replace the old icon content with HabitIconView
            HabitIconView(
                iconName: icon,
                isActive: true, // Always active in creation view
                habitColor: selectedColor,
                streak: 0, // No streak in creation view
                showStreaks: false,
                useModernBadges: false,
                isFutureDate: false,
                isBadHabit: isBadHabit,
                intensityLevel: selectedIntensity.rawValue
            )
            .scaleEffect(animateCards ? 2.6 : 2.8) // Scale up for the creation view display
            .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: animateCards)
            .frame(height: 120)
        }
        .onTapGesture {
            handleIconTap()
        }
    }
    
    private var iconContainerBackground: some View {
        RoundedRectangle(cornerRadius: 30)
            .fill(.ultraThinMaterial)
            .frame(width: 160, height: 160)
            .overlay(iconContainerBorder)
            //.scaleEffect(animateCards ? 1.05 : 1.0)
            
    }
    
    private var iconContainerBorder: some View {
        RoundedRectangle(cornerRadius: 24)
            .strokeBorder(
                LinearGradient(
                    gradient: Gradient(colors: [selectedColor.opacity(0.2), selectedColor.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }
    
    private var titleAndSubtitle: some View {
        VStack(spacing: 4) {
            Text("\(name)")
                .font(.custom("Lexend-Bold", size: 26))
                .foregroundColor(.primary)
            
            Text(isAIGenerated ? "Adjust the AI suggestion to fit your needs" : "Build positive habits that stick")
                .font(.custom("Lexend-Regular", size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Main Form Card
    
    private var mainFormCard: some View {
        VStack(spacing: 20) {
            basicInfoSection
            Divider().padding(.vertical, 4)
            customizationSection
            Divider().padding(.vertical, 4)
            scheduleSection
            Divider().padding(.vertical, 4)
            organizationSection
            Divider().padding(.vertical, 4)
            notificationsSection
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .background(formCardBackground)
        .padding(.horizontal, 16)
    }
    
    private var formCardBackground: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(.ultraThinMaterial)
            .overlay(formCardBorder)
            //.shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
    
    private var formCardBorder: some View {
        RoundedRectangle(cornerRadius: 24)
            .strokeBorder(.quaternary, lineWidth: 0.5)
    }
    
    // MARK: - Form Sections
    
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            modernTextField(
                title: "Habit Name",
                text: $name,
                icon: "pencil.circle.fill",
                placeholder: "e.g., Drink water"
            )
            
            modernTextField(
                title: "Description",
                text: $habitDescription,
                icon: "text.alignleft",
                placeholder: "Optional description"
            )
        }
    }
    
    private var customizationSection: some View {
        VStack(spacing: 16) {
            badHabitToggle
            if !isBadHabit {
                intensitySelection
            }
        }
    }
    
    private var badHabitToggle: some View {
        HStack {
            badHabitIcon
            badHabitInfo
            Spacer()
            badHabitSwitch
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(sectionCardBackground)
    }
    
    private var badHabitIcon: some View {
        ZStack {
            Circle()
                .fill((isBadHabit ? Color.red : Color.green).opacity(0.15))
                .frame(width: 36, height: 36)
            
            Image(systemName: isBadHabit ? "xmark.circle" : "checkmark.circle")
                .foregroundColor(isBadHabit ? .red : .green)
                .font(.system(size: 16, weight: .medium))
        }
    }
    
    private var badHabitInfo: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(isBadHabit ? "Bad Habit" : "Good Habit")
                .font(.custom("Lexend-SemiBold", size: 14))
                .foregroundColor(.primary)
            
            Text(isBadHabit ? "Track habits you want to reduce" : "Track positive habits")
                .font(.custom("Lexend-Regular", size: 11))
                .foregroundColor(.secondary)
        }
    }
    
    private var badHabitSwitch: some View {
        Toggle("", isOn: $isBadHabit)
            .toggleStyle(SwitchToggleStyle(tint: isBadHabit ? .red : .green))
    }
    
    private var intensitySelection: some View {
        Menu {
            intensityMenuOptions
        } label: {
            intensityMenuLabel
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var intensityMenuOptions: some View {
        ForEach(HabitIntensity.allCases) { intensity in
            Button(action: {
                selectedIntensity = intensity
                //repeatsPerDay = Int(intensity.rawValue)
                triggerHaptic(.impactLight)
            }) {
                intensityMenuOption(intensity)
            }
        }
    }
    
    private func intensityMenuOption(_ intensity: HabitIntensity) -> some View {
        HStack {
            Circle()
                .fill(intensity.color)
                .frame(width: 10, height: 10)
            Text(intensity.title)
                .font(.custom("Lexend-Medium", size: 14))
            if selectedIntensity == intensity {
                Spacer()
                Image(systemName: "checkmark")
            }
        }
    }
    
    private var intensityMenuLabel: some View {
        HStack {
            intensityIcon
            intensityInfo
            Spacer()
            intensityIndicator
            Image(systemName: "chevron.down")
                .font(.system(size: 11))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(sectionCardBackground)
    }
    
    private var intensityIcon: some View {
        ZStack {
            Circle()
                .fill(selectedIntensity.color.opacity(0.15))
                .frame(width: 36, height: 36)
            
            Image(systemName: "flame.fill")
                .foregroundColor(selectedIntensity.color)
                .font(.system(size: 16, weight: .medium))
        }
    }
    
    private var intensityInfo: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Intensity")
                .font(.custom("Lexend-SemiBold", size: 14))
                .foregroundColor(.primary)
            
            Text("\(selectedIntensity.title) - \(selectedIntensity.description)")
                .font(.custom("Lexend-Regular", size: 11))
                .foregroundColor(.secondary)
        }
    }
    
    private var intensityIndicator: some View {
        Circle()
            .fill(selectedIntensity.color)
            .frame(width: 14, height: 14)
    }
    
    private var scheduleSection: some View {
        VStack(spacing: 16) {
            sectionHeader(title: "Schedule", icon: "calendar.circle.fill")
            startDateRow
            repeatPatternButton
            trackingTypeAndGoalSection
            followUpRow
        }
    }
    
    private var startDateRow: some View {
        HStack {
            Label {
                Text("Start Date")
                    .font(.custom("Lexend-Medium", size: 14))
            } icon: {
                Image(systemName: "calendar")
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            DatePicker("", selection: $startDate, displayedComponents: .date)
                .labelsHidden()
            
            firstOccurrencePreview
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(sectionCardBackground)
    }
    
    private var firstOccurrencePreview: some View {
        VStack(alignment: .trailing, spacing: 3) {
            Text("First")
                .font(.custom("Lexend-Regular", size: 10))
                .foregroundColor(.secondary)
            
            Text(firstOccurrenceFromToday)
                .font(.custom("Lexend-SemiBold", size: 11))
                .foregroundColor(selectedColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(selectedColor.opacity(0.12))
                )
        }
    }
    
    private var repeatPatternButton: some View {
        Button(action: { showRepeatPatternSheet.toggle() }) {
            HStack {
                repeatPatternIcon
                repeatPatternInfo
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(sectionCardBackground)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var repeatPatternIcon: some View {
        ZStack {
            Circle()
                .fill(selectedColor.opacity(0.15))
                .frame(width: 36, height: 36)
            
            Image(systemName: "repeat")
                .foregroundColor(selectedColor)
                .font(.system(size: 16, weight: .medium))
        }
    }
    
    private var repeatPatternInfo: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Repeat Pattern")
                .font(.custom("Lexend-SemiBold", size: 14))
                .foregroundColor(.primary)
            
            Text(repeatPatternText)
                .font(.custom("Lexend-Regular", size: 11))
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
    }
    
    // NEW: Combined tracking type and goal section
    private var trackingTypeAndGoalSection: some View {
        VStack(spacing: 16) {
            // Tracking Type Selector
            trackingTypeSelector
            
            // Goal based on tracking type
            if habitTrackingType == .repetitions {
                repeatsPerDayRow
            } else {
                durationRow
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(sectionCardBackground)
    }
    
    // NEW: Tracking type selector
    private var trackingTypeSelector: some View {
        VStack(spacing: 8) {
            HStack {
                Label {
                    Text("Tracking Method")
                        .font(.custom("Lexend-Medium", size: 14))
                } icon: {
                    Image(systemName: "target")
                        .foregroundColor(selectedColor)
                }
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                trackingTypeButton(.repetitions)
                trackingTypeButton(.duration)
                Spacer()
            }
        }
    }
    
    // NEW: Individual tracking type button
    private func trackingTypeButton(_ type: HabitTrackingType) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                habitTrackingType = type
            }
            triggerHaptic(.impactLight)
        }) {
            HStack(spacing: 6) {
                Image(systemName: type.icon)
                    .font(.system(size: 12, weight: .medium))
                
                Text(type.title)
                    .font(.custom("Lexend-Medium", size: 12))
            }
            .foregroundColor(habitTrackingType == type ? .white : selectedColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(habitTrackingType == type ? selectedColor : selectedColor.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var repeatsPerDayRow: some View {
        HStack {
            Label {
                Text("Repeats Per Day")
                    .font(.custom("Lexend-Medium", size: 14))
            } icon: {
                Image(systemName: "repeat.circle")
                    .foregroundColor(selectedColor)
            }
            
            Spacer()
            
            repeatsStepper
        }
    }
    
    private var repeatsStepper: some View {
        HStack(spacing: 10) {
            Button(action: decrementRepeats) {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(repeatsPerDay > 1 ? selectedColor : .gray.opacity(0.5))
            }
            .disabled(repeatsPerDay <= 1)
            
            Text("\(repeatsPerDay)")
                .font(.custom("Lexend-Bold", size: 15))
                .frame(minWidth: 28)
                .foregroundColor(.primary)
            
            Button(action: incrementRepeats) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(repeatsPerDay < 20 ? selectedColor : .gray.opacity(0.5))
            }
            .disabled(repeatsPerDay >= 20)
        }
    }
    
    // NEW: Duration row
    private var durationRow: some View {
        HStack {
            Label {
                Text("Duration")
                    .font(.custom("Lexend-Medium", size: 14))
            } icon: {
                Image(systemName: "clock")
                    .foregroundColor(selectedColor)
            }
            
            Spacer()
            
            durationStepper
        }
    }
    
    // NEW: Duration stepper
    private var durationStepper: some View {
        HStack(spacing: 10) {
            Button(action: decrementDuration) {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(durationMinutes > 5 ? selectedColor : .gray.opacity(0.5))
            }
            .disabled(durationMinutes <= 5)
            
            Text(durationText)
                .font(.custom("Lexend-Bold", size: 15))
                .frame(minWidth: 60)
                .foregroundColor(.primary)
            
            Button(action: incrementDuration) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(durationMinutes < 480 ? selectedColor : .gray.opacity(0.5)) // Max 8 hours
            }
            .disabled(durationMinutes >= 480)
        }
    }
    
    // NEW: Computed property for duration text
    private var durationText: String {
        if durationMinutes < 60 {
            return "\(durationMinutes)m"
        } else {
            let hours = durationMinutes / 60
            let minutes = durationMinutes % 60
            if minutes == 0 {
                return "\(hours)h"
            } else {
                return "\(hours)h \(minutes)m"
            }
        }
    }
    
    private var followUpRow: some View {
        VStack(spacing: 8) {
            HStack {
                Label {
                    Text("Follow-up if missed")
                        .font(.custom("Lexend-Medium", size: 14))
                        .foregroundColor(followUpDisabled ? .secondary : .primary)
                } icon: {
                    Image(systemName: "arrow.turn.down.right")
                        .foregroundColor(followUpDisabled ? .gray : selectedColor)
                }
                
                Spacer()
                
                // Info button
                Button(action: {
                    showFollowUpInfo = true
                }) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
                
                Toggle("", isOn: $followUpEnabled)
                    .toggleStyle(SwitchToggleStyle(tint: selectedColor))
                    .disabled(followUpDisabled)
                    .scaleEffect(0.9)
            }
            
            // Quick description
            HStack {
                Text(followUpDescription)
                    .font(.custom("Lexend-Regular", size: 11))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(sectionCardBackground)
        .alert("Follow-up Feature", isPresented: $showFollowUpInfo) {
            Button("Got it") { }
        } message: {
            Text("When enabled, if you miss a scheduled habit on its due date, the habit will continue to appear in your daily view on subsequent days until you complete it. After completion, the next occurrence is calculated from the completion date, helping maintain consistent habit streaks even when you miss scheduled days.")
        }
    }

    // Add this computed property for the description text
    private var followUpDescription: String {
        if isBadHabit {
            return "Not applicable for bad habits"
        } else if selectedGoalType == .daily && dailyGoalPattern == .everyday {
            return "Not needed for daily habits"
        } else {
            return "Habit remains active until completed"
        }
    }
    
    private var organizationSection: some View {
        VStack(spacing: 16) {
            sectionHeader(title: "Organization", icon: "folder.fill")
            habitListButton
        }
    }
    
    private var habitListButton: some View {
        Button(action: { showHabitListPicker = true }) {
            HStack {
                habitListIcon
                habitListInfo
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(sectionCardBackground)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var habitListIcon: some View {
        ZStack {
            Circle()
                .fill(selectedColor.opacity(0.15))
                .frame(width: 36, height: 36)
            
            Image(systemName: "list.bullet")
                .foregroundColor(selectedColor)
                .font(.system(size: 16, weight: .medium))
        }
    }
    
    private var habitListInfo: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Habit List")
                .font(.custom("Lexend-SemiBold", size: 14))
                .foregroundColor(.primary)
            
            Text(selectedHabitList?.name ?? "No list selected")
                .font(.custom("Lexend-Regular", size: 11))
                .foregroundColor(.secondary)
        }
    }
    
    private var notificationsSection: some View {
        VStack(spacing: 16) {
            sectionHeader(title: "Notifications", icon: "bell.fill")
            notificationContent
        }
    }
    
    private var notificationContent: some View {
        VStack(spacing: 12) {
            notificationToggle
            
            if notificationsEnabled {
                Divider()
                notificationTimeRow
                Divider()
                notificationMessageSection
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(sectionCardBackground)
    }
    
    private var notificationToggle: some View {
        HStack {
            Label {
                Text("Enable Notifications")
                    .font(.custom("Lexend-Medium", size: 14))
            } icon: {
                Image(systemName: "bell.fill")
                    .foregroundColor(selectedColor)
            }
            
            Spacer()
            
            Toggle("", isOn: $notificationsEnabled)
                .toggleStyle(SwitchToggleStyle(tint: selectedColor))
        }
    }
    
    private var notificationTimeRow: some View {
        HStack {
            Label {
                Text("Time")
                    .font(.custom("Lexend-Medium", size: 13))
            } icon: {
                Image(systemName: "clock")
                    .foregroundColor(selectedColor)
            }
            
            Spacer()
            
            DatePicker("", selection: $notificationTime, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .scaleEffect(0.95)
        }
    }
    
    private var notificationMessageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label {
                    Text("Custom Message")
                        .font(.custom("Lexend-Medium", size: 13))
                } icon: {
                    Image(systemName: "text.bubble")
                        .foregroundColor(selectedColor)
                }
            }
            
            TextField("Optional notification message", text: $notificationNotes)
                .font(.custom("Lexend-Regular", size: 13))
                .textFieldStyle(ModernTextFieldStyle())
                .focused($isTextFieldFocused)
        }
    }
    
    // MARK: - Create Button
    
    private var createButton: some View {
        Button(action: createHabitAction) {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
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
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 32)
    }
    
    private var createButtonBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(createButtonGradient)
    }
    
    private var createButtonGradient: LinearGradient {
        LinearGradient(
            colors: name.isEmpty ?
                [.gray.opacity(0.6), .gray.opacity(0.4)] :
                [selectedColor, selectedColor.opacity(0.8)],
            startPoint: .leading,
            endPoint: .trailing
        )
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
    
    // MARK: - Toolbar
    
    private var toolbarContent: some ToolbarContent {
        Group {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
                .font(.custom("Lexend-Medium", size: 16))
                .foregroundColor(.primary)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    createHabitAction()
                }
                .font(.custom("Lexend-SemiBold", size: 16))
                .foregroundColor(selectedColor)
                .disabled(name.isEmpty)
            }
        }
    }
    
    // MARK: - Reusable Components
    
    private var modernColorPicker: some View {
        HStack(spacing: 10) {
            ForEach(colors, id: \.self) { color in
                colorPickerButton(color)
            }
        }
        .padding(.horizontal)
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
                .overlay(colorPickerOverlay(color))
                .shadow(
                    color: color.opacity(0.4),
                    radius: selectedColor == color ? 6 : 3,
                    x: 0,
                    y: selectedColor == color ? 3 : 1
                )
                .scaleEffect(selectedColor == color ? 1.1 : 1.0)
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    private func colorPickerOverlay(_ color: Color) -> some View {
        Circle()
            .stroke(.white, lineWidth: 2.5)
            .opacity(selectedColor == color ? 1 : 0)
    }
    
    private func sectionHeader(title: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(selectedColor)
            
            Text(title)
                .font(.custom("Lexend-SemiBold", size: 16))
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
    
    private func modernTextField(title: String, text: Binding<String>, icon: String, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            textFieldHeader(title: title, icon: icon, text: text)
            
            TextField(placeholder, text: text)
                .font(.custom("Lexend-Regular", size: 15))
                .textFieldStyle(ModernTextFieldStyle())
                .focused($isTextFieldFocused)
        }
    }
    
    private func textFieldHeader(title: String, icon: String, text: Binding<String>) -> some View {
        HStack {
            Label {
                Text(title)
                    .font(.custom("Lexend-Medium", size: 14))
                    .foregroundColor(.primary)
            } icon: {
                Image(systemName: icon)
                    .foregroundColor(selectedColor)
            }
            
            Spacer()
            
            if title == "Habit Name" && !text.wrappedValue.isEmpty {
                Text("\(text.wrappedValue.count)/50")
                    .font(.custom("Lexend-Regular", size: 12))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var sectionCardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(.ultraThinMaterial)
            .overlay(sectionCardBorder)
    }
    
    private var sectionCardBorder: some View {
        RoundedRectangle(cornerRadius: 16)
            .strokeBorder(.quaternary, lineWidth: 0.5)
    }
    
    // MARK: - Actions
    
    private func handleIconTap() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            animateIcon = true
            showIconPicker.toggle()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            animateIcon = false
        }
        
        triggerHaptic(.impactMedium)
    }
    
    private func decrementRepeats() {
        if repeatsPerDay > 1 {
            repeatsPerDay -= 1
            triggerHaptic(.impactLight)
        }
    }
    
    private func incrementRepeats() {
        if repeatsPerDay < 20 {
            repeatsPerDay += 1
            triggerHaptic(.impactLight)
        }
    }
    
    // NEW: Duration manipulation functions
    private func decrementDuration() {
        if durationMinutes > 5 {
            // Decrease by 5 minutes if under 1 hour, by 15 minutes if over
            let decrement = durationMinutes <= 60 ? 5 : 15
            durationMinutes = max(5, durationMinutes - decrement)
            triggerHaptic(.impactLight)
        }
    }
    
    private func incrementDuration() {
        if durationMinutes < 480 { // Max 8 hours
            // Increase by 5 minutes if under 1 hour, by 15 minutes if over
            let increment = durationMinutes < 60 ? 5 : 15
            durationMinutes = min(480, durationMinutes + increment)
            triggerHaptic(.impactLight)
        }
    }
    
    private func createHabitAction() {
        createHabit()
        
        // Call the completion closure if provided
        onHabitCreated?()
        
        // Only dismiss if no completion closure (backward compatibility)
        if onHabitCreated == nil {
            dismiss()
        }
    }
    
    // MARK: - Computed Properties
    
    private var followUpDisabled: Bool {
        (selectedGoalType == .daily && dailyGoalPattern == .everyday) || isBadHabit
    }
    
    // MARK: - Helper Functions
    
    private func isEmoji(_ text: String) -> Bool {
        if text.isEmpty { return false }
        
        if text.count == 1, let firstChar = text.first {
            return firstChar.isEmoji
        }
        
        for scalar in text.unicodeScalars {
            if scalar.properties.isEmoji {
                return true
            }
        }
        
        return false
    }
    
    private func createHabit() {
        let newHabit = Habit(context: viewContext)
        newHabit.id = UUID()
        newHabit.name = name
        newHabit.habitDescription = habitDescription
        newHabit.startDate = startDate
        newHabit.icon = icon
        newHabit.isBadHabit = isBadHabit
        newHabit.intensityLevel = selectedIntensity.rawValue
        
        // Set the habit list if one is selected
        if let selectedList = selectedHabitList {
            newHabit.habitList = selectedList
        }
        
        // Determine the order for the new habit
        determineHabitOrder(for: newHabit)
        
        // Store color
        storeHabitColor(for: newHabit)
        
        // Create repeat pattern and establish relationship
        let repeatPattern = createRepeatPattern(for: newHabit)
        
        // Create notification if enabled (using NSSet relationship)
        createNotificationIfEnabled(for: newHabit)
        
        // Create appropriate goal type linked to the repeat pattern
        createGoalType(for: repeatPattern)
        
        // IMPORTANT: Add the RepeatPattern to the Habit's NSSet
        newHabit.addToRepeatPattern(repeatPattern)
        
        // Save the context
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
            print("Error determining habit order: \(error)")
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
        
        // NEW: Set either repeatsPerDay or duration based on tracking type
        if habitTrackingType == .repetitions {
            repeatPattern.repeatsPerDay = Int16(repeatsPerDay)
            repeatPattern.duration = 0 // Clear duration when using repetitions
        } else {
            repeatPattern.duration = Int16(durationMinutes)
            repeatPattern.repeatsPerDay = 0 // Clear repeats when using duration
        }
        
        // Establish the bidirectional relationship
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
            createDailyGoal(with: repeatPattern)
        case .weekly:
            createWeeklyGoal(with: repeatPattern)
        case .monthly:
            createMonthlyGoal(with: repeatPattern)
        }
    }
    
    private func createDailyGoal(with repeatPattern: RepeatPattern) {
        let dailyGoal = DailyGoal(context: viewContext)
        
        switch dailyGoalPattern {
        case .everyday:
            dailyGoal.everyDay = true
            dailyGoal.daysInterval = 0 // Not used when everyDay is true
        case .specificDays:
            dailyGoal.everyDay = false
            dailyGoal.specificDays = specificDaysDaily as NSObject
            dailyGoal.daysInterval = 0 // Not used for specific days
        case .everyXDays:
            dailyGoal.everyDay = false
            dailyGoal.daysInterval = Int16(selectedDaysInterval)
            dailyGoal.specificDays = nil // Not used for interval days
        }
        
        // Establish the bidirectional relationship
        dailyGoal.repeatPattern = repeatPattern
        repeatPattern.dailyGoal = dailyGoal
    }
    
    private func createWeeklyGoal(with repeatPattern: RepeatPattern) {
        let weeklyGoal = WeeklyGoal(context: viewContext)
        
        switch weeklyGoalPattern {
        case .everyWeek:
            weeklyGoal.everyWeek = true
            weeklyGoal.weekInterval = 0 // Not used when everyWeek is true
        case .weekInterval:
            weeklyGoal.everyWeek = false
            weeklyGoal.weekInterval = Int16(selectedWeekInterval)
        }
        
        // Always set specific days for weekly goals
        weeklyGoal.specificDays = specificDaysWeekly as NSObject
        
        // Establish the bidirectional relationship
        weeklyGoal.repeatPattern = repeatPattern
        repeatPattern.weeklyGoal = weeklyGoal
    }

    private func createMonthlyGoal(with repeatPattern: RepeatPattern) {
        let monthlyGoal = MonthlyGoal(context: viewContext)
        
        switch monthlyGoalPattern {
        case .everyMonth:
            monthlyGoal.everyMonth = true
            monthlyGoal.monthInterval = 0 // Not used when everyMonth is true
        case .monthInterval:
            monthlyGoal.everyMonth = false
            monthlyGoal.monthInterval = Int16(selectedMonthInterval)
        }
        
        // Always set specific days for monthly goals
        monthlyGoal.specificDays = specificDaysMonthly as NSObject
        
        // Establish the bidirectional relationship
        monthlyGoal.repeatPattern = repeatPattern
        repeatPattern.monthlyGoal = monthlyGoal
    }
    
    private func saveContext() {
        do {
            
            try viewContext.save()
            NotificationCenter.default.post(name: NSNotification.Name("HabitCreated"), object: nil)
        } catch {
            print("Error saving habit: \(error)")
        }
    }
    
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
}

// MARK: - Supporting Types

// NEW: Enum for habit tracking type
enum HabitTrackingType: String, CaseIterable {
    case repetitions = "repetitions"
    case duration = "duration"
    
    var title: String {
        switch self {
        case .repetitions:
            return "Times"
        case .duration:
            return "Duration"
        }
    }
    
    var icon: String {
        switch self {
        case .repetitions:
            return "repeat"
        case .duration:
            return "clock"
        }
    }
    
    var description: String {
        switch self {
        case .repetitions:
            return "Track by number of completions"
        case .duration:
            return "Track by time spent"
        }
    }
}

// MARK: - Supporting Functions

private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
    let impactFeedback = UIImpactFeedbackGenerator(style: style)
    impactFeedback.impactOccurred()
}

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
*/
