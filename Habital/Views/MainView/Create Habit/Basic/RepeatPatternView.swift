import SwiftUI

enum HabitGoalType: String, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
}

// Daily goal patterns
enum DailyGoalPattern: String, CaseIterable {
    case everyday = "Every Day"
    case specificDays = "Specific Days"
    case everyXDays = "Every X Days"
}

// Weekly goal patterns
enum WeeklyGoalPattern: String, CaseIterable {
    case everyWeek = "Every Week"
    case weekInterval = "Week Interval"
}

// Monthly goal patterns
enum MonthlyGoalPattern: String, CaseIterable {
    case everyMonth = "Every Month"
    case monthInterval = "Month Interval"
}

struct RepeatPatternView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    // Goal type selection
    @Binding var selectedGoalType: HabitGoalType
    
    // Daily goal properties
    @Binding var dailyGoalPattern: DailyGoalPattern
    @Binding var specificDaysDaily: [Bool]
    @Binding var selectedDaysInterval: Int
    
    // Weekly goal properties
    @Binding var weeklyGoalPattern: WeeklyGoalPattern
    @Binding var specificDaysWeekly: [Bool]
    @Binding var selectedWeekInterval: Int
    
    // Monthly goal properties
    @Binding var monthlyGoalPattern: MonthlyGoalPattern
    @Binding var specificDaysMonthly: [Bool]
    @Binding var selectedMonthInterval: Int
    
    // Follow-up toggle
    @State private var enableFollowUp = false
    
    // Animation states
    @State private var animateSelection = false
    @State private var selectedColor: Color = .blue
    
    // Days of the week
    private let daysOfWeek = ["M", "T", "W", "T", "F", "S", "S"]
    private let fullDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Simple background
                Color(colorScheme == .dark ? Color(hex: "0A0A0A") : Color(hex: "F5F5F7"))
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 12) {
                            // Goal Type Selector
                            goalTypeSelector
                            
                            // Pattern options based on selected goal type
                            VStack(spacing: 8) {
                                switch selectedGoalType {
                                case .daily:
                                    dailyGoalOptions
                                case .weekly:
                                    weeklyGoalOptions
                                case .monthly:
                                    monthlyGoalOptions
                                }
                            }
                            
                            // Follow-up toggle
                            followUpToggle
                            
                            Spacer().frame(height: 80)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    }
                    
                    // Bottom action bar
                    VStack(spacing: 0) {
                        Divider()
                        HStack(spacing: 12) {
                            Button("Cancel") {
                                dismiss()
                            }
                            .font(.custom("Lexend-Regular", size: 14))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                            
                            Button("Done") {
                                dismiss()
                            }
                            .font(.custom("Lexend-Medium", size: 14))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(selectedColor)
                            .cornerRadius(10)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(colorScheme == .dark ? Color(hex: "1A1A1A") : .white))
                    }
                }
            }
            .navigationTitle("Repeat Pattern")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    animateSelection = true
                }
            }
        }
    }
    
    // MARK: - Goal Type Selector
    private var goalTypeSelector: some View {
        HStack(spacing: 6) {
            ForEach(HabitGoalType.allCases, id: \.self) { goalType in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedGoalType = goalType
                    }
                }) {
                    Text(goalType.rawValue)
                        .font(.custom("Lexend-Medium", size: 13))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .foregroundColor(selectedGoalType == goalType ? .white : .primary)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedGoalType == goalType ? selectedColor : Color.gray.opacity(0.1))
                        )
                }
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(colorScheme == .dark ? Color(hex: "1A1A1A") : .white))
        )
    }
    
    // MARK: - Daily Goal Options
    private var dailyGoalOptions: some View {
        VStack(spacing: 8) {
            // Daily patterns
            ForEach([
                (DailyGoalPattern.everyday, "repeat", "Every day"),
                (DailyGoalPattern.specificDays, "calendar", "Select days"),
                (DailyGoalPattern.everyXDays, "arrow.trianglehead.clockwise", "Custom interval")
            ], id: \.0) { pattern, icon, subtitle in
                compactPatternOption(
                    title: pattern.rawValue,
                    subtitle: subtitle,
                    icon: icon,
                    isSelected: dailyGoalPattern == pattern,
                    action: { dailyGoalPattern = pattern }
                )
            }
            
            // Specific days selector
            if dailyGoalPattern == .specificDays {
                compactDaysSelector(specificDays: $specificDaysDaily)
            }
            
            // Interval selector
            if dailyGoalPattern == .everyXDays {
                compactIntervalSelector(
                    intervalValue: $selectedDaysInterval,
                    minValue: 1,
                    maxValue: 30,
                    quickValues: [2, 7, 14],
                    unit: "day"
                )
            }
        }
    }
    
    // MARK: - Weekly Goal Options
    private var weeklyGoalOptions: some View {
        VStack(spacing: 8) {
            ForEach([
                (WeeklyGoalPattern.everyWeek, "calendar", "Every week"),
                (WeeklyGoalPattern.weekInterval, "calendar.badge.plus", "Custom weeks")
            ], id: \.0) { pattern, icon, subtitle in
                compactPatternOption(
                    title: pattern.rawValue,
                    subtitle: subtitle,
                    icon: icon,
                    isSelected: weeklyGoalPattern == pattern,
                    action: { weeklyGoalPattern = pattern }
                )
            }
            
            if weeklyGoalPattern == .weekInterval {
                compactIntervalSelector(
                    intervalValue: $selectedWeekInterval,
                    minValue: 2,
                    maxValue: 8,
                    quickValues: [2, 3, 4],
                    unit: "week"
                )
            }
            
            compactDaysSelector(specificDays: $specificDaysWeekly)
        }
    }
    
    // MARK: - Monthly Goal Options
    private var monthlyGoalOptions: some View {
        VStack(spacing: 8) {
            ForEach([
                (MonthlyGoalPattern.everyMonth, "calendar", "Every month"),
                (MonthlyGoalPattern.monthInterval, "calendar.badge.plus", "Custom months")
            ], id: \.0) { pattern, icon, subtitle in
                compactPatternOption(
                    title: pattern.rawValue,
                    subtitle: subtitle,
                    icon: icon,
                    isSelected: monthlyGoalPattern == pattern,
                    action: { monthlyGoalPattern = pattern }
                )
            }
            
            if monthlyGoalPattern == .monthInterval {
                compactIntervalSelector(
                    intervalValue: $selectedMonthInterval,
                    minValue: 2,
                    maxValue: 12,
                    quickValues: [2, 3, 6],
                    unit: "month"
                )
            }
            
            compactMonthDaysSelector
        }
    }
    
    // MARK: - Follow-up Toggle
    private var followUpToggle: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Enable Follow-up")
                    .font(.custom("Lexend-Medium", size: 14))
                    .foregroundColor(.primary)
                
                Text("Get reminders after completing")
                    .font(.custom("Lexend-Regular", size: 11))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $enableFollowUp)
                .toggleStyle(SwitchToggleStyle(tint: selectedColor))
                .scaleEffect(0.85)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(colorScheme == .dark ? Color(hex: "1A1A1A") : .white))
        )
        .padding(.top, 8)
    }
    
    // MARK: - Compact Pattern Option
    private func compactPatternOption(title: String, subtitle: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                action()
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? selectedColor : .secondary)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.custom("Lexend-Medium", size: 13))
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.custom("Lexend-Regular", size: 10))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(selectedColor)
                        .font(.system(size: 18))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(colorScheme == .dark ? Color(hex: "1A1A1A") : .white))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(isSelected ? selectedColor.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Compact Days Selector
    private func compactDaysSelector(specificDays: Binding<[Bool]>) -> some View {
        VStack(spacing: 8) {
            let weekCount = specificDays.wrappedValue.count / 7
            
            ForEach(0..<weekCount, id: \.self) { weekIndex in
                compactWeekSection(weekIndex: weekIndex, specificDays: specificDays)
            }
            
            // Add week button for daily pattern
            if weekCount < 4 && selectedGoalType == .daily && dailyGoalPattern == .specificDays {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        specificDays.wrappedValue.append(contentsOf: Array(repeating: false, count: 7))
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 14))
                        Text("Add Week")
                            .font(.custom("Lexend-Regular", size: 12))
                    }
                    .foregroundColor(selectedColor)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(selectedColor.opacity(0.1))
                    )
                }
            }
            
            // Quick selects
            HStack(spacing: 6) {
                ForEach(["None", "Weekdays", "Weekends", "All"], id: \.self) { option in
                    compactQuickSelect(option, specificDays: specificDays)
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(colorScheme == .dark ? Color(hex: "1A1A1A") : .white))
        )
    }
    
    // MARK: - Compact Week Section
    private func compactWeekSection(weekIndex: Int, specificDays: Binding<[Bool]>) -> some View {
        VStack(spacing: 4) {
            if weekIndex > 0 {
                HStack {
                    Text("Week \(weekIndex + 1)")
                        .font(.custom("Lexend-Regular", size: 10))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if selectedGoalType == .daily && dailyGoalPattern == .specificDays {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                let startIndex = weekIndex * 7
                                let endIndex = startIndex + 7
                                specificDays.wrappedValue.removeSubrange(startIndex..<endIndex)
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.red.opacity(0.6))
                        }
                    }
                }
            }
            
            HStack(spacing: 4) {
                ForEach(0..<7, id: \.self) { dayIndex in
                    let globalIndex = (weekIndex * 7) + dayIndex
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            specificDays.wrappedValue[globalIndex].toggle()
                        }
                    }) {
                        VStack(spacing: 2) {
                            Text(daysOfWeek[dayIndex])
                                .font(.custom("Lexend-Medium", size: 10))
                                .foregroundColor(specificDays.wrappedValue[globalIndex] ? .white : .primary)
                                .frame(width: 32, height: 32)
                                .background(
                                    Circle()
                                        .fill(specificDays.wrappedValue[globalIndex] ? selectedColor : Color.gray.opacity(0.1))
                                )
                            
                            Text(fullDays[dayIndex])
                                .font(.custom("Lexend-Regular", size: 8))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Compact Month Days Selector
    private var compactMonthDaysSelector: some View {
        VStack(spacing: 8) {
            Text("Select Days")
                .font(.custom("Lexend-Medium", size: 11))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(0..<31, id: \.self) { index in
                    let day = index + 1
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            specificDaysMonthly[index].toggle()
                        }
                    }) {
                        Text("\(day)")
                            .font(.custom("Lexend-Regular", size: 11))
                            .foregroundColor(specificDaysMonthly[index] ? .white : .primary)
                            .frame(width: 28, height: 28)
                            .background(
                                Circle()
                                    .fill(specificDaysMonthly[index] ? selectedColor : Color.gray.opacity(0.1))
                                    .overlay(
                                        Circle()
                                            .strokeBorder(
                                                day >= 29 ? Color.orange.opacity(0.5) : Color.clear,
                                                lineWidth: 1
                                            )
                                    )
                            )
                    }
                }
            }
            
            HStack(spacing: 6) {
                ForEach(["None", "Start", "Mid", "End"], id: \.self) { option in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            switch option {
                            case "None":
                                specificDaysMonthly = Array(repeating: false, count: 31)
                            case "Start":
                                var days = Array(repeating: false, count: 31)
                                days[0] = true
                                specificDaysMonthly = days
                            case "Mid":
                                var days = Array(repeating: false, count: 31)
                                days[14] = true
                                specificDaysMonthly = days
                            case "End":
                                var days = Array(repeating: false, count: 31)
                                days[30] = true
                                specificDaysMonthly = days
                            default:
                                break
                            }
                        }
                    }) {
                        Text(option)
                            .font(.custom("Lexend-Regular", size: 10))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(6)
                    }
                }
            }
            
            Text("Days 29-31 default to last day if month is shorter")
                .font(.custom("Lexend-Regular", size: 9))
                .foregroundColor(.secondary)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(colorScheme == .dark ? Color(hex: "1A1A1A") : .white))
        )
    }
    
    // MARK: - Compact Interval Selector
    private func compactIntervalSelector(intervalValue: Binding<Int>, minValue: Int, maxValue: Int, quickValues: [Int], unit: String) -> some View {
        VStack(spacing: 8) {
            HStack {
                Button(action: {
                    if intervalValue.wrappedValue > minValue {
                        intervalValue.wrappedValue -= 1
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(intervalValue.wrappedValue > minValue ? selectedColor : Color.gray.opacity(0.3))
                }
                .disabled(intervalValue.wrappedValue <= minValue)
                
                Spacer()
                
                VStack(spacing: 0) {
                    Text("\(intervalValue.wrappedValue)")
                        .font(.custom("Lexend-Bold", size: 24))
                        .foregroundColor(.primary)
                    
                    Text(intervalValue.wrappedValue == 1 ? unit : "\(unit)s")
                        .font(.custom("Lexend-Regular", size: 10))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    if intervalValue.wrappedValue < maxValue {
                        intervalValue.wrappedValue += 1
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(intervalValue.wrappedValue < maxValue ? selectedColor : Color.gray.opacity(0.3))
                }
                .disabled(intervalValue.wrappedValue >= maxValue)
            }
            .padding(.horizontal, 12)
            
            HStack(spacing: 6) {
                ForEach(quickValues, id: \.self) { value in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            intervalValue.wrappedValue = value
                        }
                    }) {
                        Text("\(value)")
                            .font(.custom("Lexend-Medium", size: 11))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(intervalValue.wrappedValue == value ? selectedColor.opacity(0.2) : Color.gray.opacity(0.1))
                            )
                            .foregroundColor(intervalValue.wrappedValue == value ? selectedColor : .primary)
                    }
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(colorScheme == .dark ? Color(hex: "1A1A1A") : .white))
        )
    }
    
    // MARK: - Compact Quick Select
    private func compactQuickSelect(_ option: String, specificDays: Binding<[Bool]>) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                let weekCount = specificDays.wrappedValue.count / 7
                
                switch option {
                case "None":
                    specificDays.wrappedValue = Array(repeating: false, count: weekCount * 7)
                case "Weekdays":
                    var updated = Array(repeating: false, count: weekCount * 7)
                    for week in 0..<weekCount {
                        for day in 0..<5 {
                            updated[(week * 7) + day] = true
                        }
                    }
                    specificDays.wrappedValue = updated
                case "Weekends":
                    var updated = Array(repeating: false, count: weekCount * 7)
                    for week in 0..<weekCount {
                        updated[(week * 7) + 5] = true
                        updated[(week * 7) + 6] = true
                    }
                    specificDays.wrappedValue = updated
                case "All":
                    specificDays.wrappedValue = Array(repeating: true, count: weekCount * 7)
                default:
                    break
                }
            }
        }) {
            Text(option)
                .font(.custom("Lexend-Regular", size: 10))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(6)
        }
    }
}



 #Preview {
     RepeatPatternView(
         selectedGoalType: .constant(.daily),
         dailyGoalPattern: .constant(.specificDays),
         specificDaysDaily: .constant(Array(repeating: false, count: 7)),
         selectedDaysInterval: .constant(1),
         weeklyGoalPattern: .constant(.everyWeek),
         specificDaysWeekly: .constant(Array(repeating: false, count: 7)),
         selectedWeekInterval: .constant(2),
         monthlyGoalPattern: .constant(.everyMonth),
         specificDaysMonthly: .constant(Array(repeating: false, count: 31)),
         selectedMonthInterval: .constant(2)
     )
 }
 
