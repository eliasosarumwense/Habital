//
//  CustomNavigationBar.swift
//  Habital
//
//  Created by Elias Osarumwense on 04.04.25.
//
/*
import SwiftUI
import CoreData

// ... (Keep all existing enum HabitSortOption code unchanged) ...

enum HabitSortOption: String, CaseIterable, Identifiable {
    case ascending = "Ascending (A-Z)"
    case descending = "Descending (Z-A)"
    case custom = "Custom Order"
    case streak = "Highest Streak"
    case completion = "Incomplete First"
    case recentCompletion = "Recent Activity"
    
    var id: String { self.rawValue }
    
    var sortDescriptor: NSSortDescriptor {
        switch self {
        case .ascending:
            return NSSortDescriptor(keyPath: \Habit.name, ascending: true)
        case .descending:
            return NSSortDescriptor(keyPath: \Habit.name, ascending: false)
        case .custom:
            return NSSortDescriptor(keyPath: \Habit.order, ascending: true)
        case .streak, .completion, .recentCompletion:
            return NSSortDescriptor(keyPath: \Habit.order, ascending: true)
        }
    }
    
    var icon: String {
        switch self {
        case .ascending: return "arrow.up"
        case .descending: return "arrow.down"
        case .custom: return "arrow.up.arrow.down"
        case .streak: return "flame"
        case .completion: return "checkmark.circle"
        case .recentCompletion: return "clock.arrow.circlepath"
        }
    }
    
    static func save(_ option: HabitSortOption) {
        UserDefaults.standard.set(option.rawValue, forKey: "habitSortOption")
    }
    
    static func load() -> HabitSortOption {
        if let savedValue = UserDefaults.standard.string(forKey: "habitSortOption"),
           let savedOption = HabitSortOption(rawValue: savedValue) {
            return savedOption
        }
        return .custom
    }
}

// ... (Keep all spiral date animation code unchanged) ...

// MARK: - Updated Navigation Bar with Archived Habits Option
struct NavBarMainHabitView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    
    @Binding var showingCreateHabitView: Bool
    @Binding var selectedDate: Date
    @Binding var sortOption: HabitSortOption
    @Binding var showArchivedHabits: Bool
    @Binding var selectedListIndex: Int
    
    let title: String
    
    @State private var showHabitSortView = false
    @State private var isPressed = false
    @State private var showCreateList = false
    @State private var showManageLists = false
    @State private var listToEdit: HabitList?
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \HabitList.order, ascending: true)],
        animation: .default
    )
    private var habitLists: FetchedResults<HabitList>
    
    init(showingCreateHabitView: Binding<Bool>, selectedDate: Binding<Date>, sortOption: Binding<HabitSortOption>, title: String, showArchivedHabits: Binding<Bool>, selectedListIndex: Binding<Int>) {
        self._showingCreateHabitView = showingCreateHabitView
        self._selectedDate = selectedDate
        self._sortOption = sortOption
        self.title = title
        self._showArchivedHabits = showArchivedHabits
        self._selectedListIndex = selectedListIndex
    }
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.clear)
                .edgesIgnoringSafeArea(.top)
            
            HStack(spacing: 0) {
                // Left side - Spiral animated date display
                VStack(alignment: .leading, spacing: 0) {
                    if !showArchivedHabits {
                        EnhancedSpiralDateView(date: selectedDate)
                    } else {
                        // Archive view - show archived habits info
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Archive")
                                .font(.customFont("Lexend", .bold, 22))
                                .foregroundColor(.primary)
                            
                            Text("\(countArchivedHabits(context: viewContext)) habits")
                                .font(.customFont("Lexend", .medium, 16))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 5)
                Spacer()
                
                // Right side - Action buttons (only show when not in archive mode)
                if !showArchivedHabits {
                    HStack(spacing: 12) {
                        // Sort button
                        Menu {
                            ForEach(HabitSortOption.allCases) { option in
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        sortOption = option
                                    }
                                    HabitSortOption.save(option)
                                }) {
                                    HStack {
                                        Label(option.rawValue, systemImage: option.icon)
                                        
                                        if option == sortOption {
                                            Spacer()
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                                .disabled(option == sortOption)
                            }
                            
                            Divider()
                            
                            Button(action: {
                                showHabitSortView = true
                            }) {
                                Label("Customize Sort", systemImage: "arrow.up.arrow.down.circle")
                            }
                        } label: {
                            CircularGlassSortButton(
                                currentSortIcon: sortOption.icon,
                                currentSortColor: .secondary
                            )
                        }
                        
                        // Enhanced List Selection Button with Archived Option
                        Menu {
                            // All Habits option
                            Button(action: {
                                selectList(index: 0, showArchived: false)
                            }) {
                                HStack {
                                    Label("All Habits", systemImage: "tray.full")
                                    Spacer()
                                    if selectedListIndex == 0 && !showArchivedHabits {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            
                            // Individual habit lists
                            ForEach(Array(habitLists.enumerated()), id: \.element.id) { listIndex, list in
                                Button(action: {
                                    selectList(index: listIndex + 1, showArchived: false)
                                }) {
                                    HStack {
                                        Label("\(list.name ?? "Unnamed List")", systemImage: list.icon ?? "list.bullet")
                                        Spacer()
                                        if selectedListIndex == listIndex + 1 && !showArchivedHabits {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                            }
                            
                            Divider()
                            
                            // ✅ NEW: Archived Habits option
                            Button(action: {
                                selectList(index: 0, showArchived: true)
                            }) {
                                HStack {
                                    Label("Archived (\(countArchivedHabits(context: viewContext)))", systemImage: "archivebox")
                                    Spacer()
                                    if showArchivedHabits {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            
                            Divider()
                            
                            // List management options
                            Button(action: {
                                showCreateList = true
                            }) {
                                Label("Create New List", systemImage: "plus.circle")
                            }
                            
                            Button(action: {
                                showManageLists = true
                            }) {
                                Label("Manage Lists", systemImage: "gear")
                            }
                            
                            // Edit current list (only show if a specific list is selected)
                            if selectedListIndex > 0 && selectedListIndex <= habitLists.count && !showArchivedHabits {
                                let currentList = Array(habitLists)[selectedListIndex - 1]
                                Button(action: {
                                    listToEdit = currentList
                                }) {
                                    Label("Edit '\(currentList.name ?? "List")'", systemImage: "pencil")
                                }
                            }
                        } label: {
                            CircularGlassListButton(
                                currentListIcon: currentListIcon,
                                currentListColor: currentListColor
                            )
                        }
                        
                        // Add button
                        Button(action: {
                            showingCreateHabitView = true
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                                .frame(width: 36, height: 36)
                                .glassCircleBackground(backgroundColor: .primary.opacity(0.7))
                                .scaleEffect(isPressed ? 0.95 : 1.0)
                        }
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { _ in
                                    withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                                        isPressed = true
                                    }
                                }
                                .onEnded { _ in
                                    withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                                        isPressed = false
                                    }
                                    showingCreateHabitView = true
                                }
                        )
                    }
                } else {
                    // Archive mode - show back button
                    Button(action: {
                        selectList(index: 0, showArchived: false)
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .frame(width: 36, height: 36)
                            .glassCircleBackground(backgroundColor: .secondary.opacity(0.1))
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .frame(height: 50)
        // Keep all existing sheet modifiers...
        .sheet(isPresented: $showHabitSortView) {
            HabitSortView(selectedList: getCurrentList())
                .presentationCornerRadius(50)
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(isPresented: $showCreateList) {
            NavigationView {
                CreateHabitListView()
                    .environment(\.managedObjectContext, viewContext)
            }
            .presentationCornerRadius(24)
        }
        .sheet(isPresented: $showManageLists) {
            NavigationView {
                ManageHabitListsView()
                    .environment(\.managedObjectContext, viewContext)
            }
            .presentationCornerRadius(24)
        }
        .sheet(item: $listToEdit) { list in
            NavigationView {
                EditHabitListView(list: list)
                    .environment(\.managedObjectContext, viewContext)
            }
            .presentationCornerRadius(24)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Unified method to handle list selection
    private func selectList(index: Int, showArchived: Bool) {
        withAnimation(.interpolatingSpring(stiffness: 300, damping: 30)) {
            selectedListIndex = index
            showArchivedHabits = showArchived
        }
        
        UserDefaults.saveSelectedListIndex(index)
        UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.7)
    }
    
    // MARK: - Computed Properties for List Selection
    
    private var currentListIcon: String {
        if showArchivedHabits {
            return "archivebox"
        } else if selectedListIndex == 0 {
            return "tray.full"
        } else if selectedListIndex > 0 && selectedListIndex <= habitLists.count {
            let list = Array(habitLists)[selectedListIndex - 1]
            return list.icon ?? "list.bullet"
        }
        return "list.bullet"
    }
    
    private var currentListColor: Color {
        if showArchivedHabits {
            return .orange
        } else if selectedListIndex == 0 {
            return .secondary
        } else if selectedListIndex > 0 && selectedListIndex <= habitLists.count {
            let list = Array(habitLists)[selectedListIndex - 1]
            if let colorData = list.color,
               let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
                return Color(uiColor)
            }
            return .secondary
        }
        return .secondary
    }
    
    private func getCurrentList() -> HabitList? {
        if let habitLists = try? viewContext.fetch(NSFetchRequest<HabitList>(entityName: "HabitList")) {
            let sortedLists = habitLists.sorted { $0.order < $1.order }
            if selectedListIndex > 0 && selectedListIndex <= sortedLists.count {
                return sortedLists[selectedListIndex - 1]
            }
        }
        return nil
    }
}

// Keep all existing circular button components unchanged...
struct CircularGlassSortButton: View {
    let currentSortIcon: String
    let currentSortColor: Color
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            Image(systemName: currentSortIcon)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(currentSortColor)
        }
        .frame(width: 36, height: 36)
        .glassCircleBackground(backgroundColor: currentSortColor.opacity(0.1))
        .contentShape(Circle())
    }
}

struct CircularGlassListButton: View {
    let currentListIcon: String
    let currentListColor: Color
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            Image(systemName: currentListIcon)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(currentListColor)
        }
        .frame(width: 36, height: 36)
        .glassCircleBackground(backgroundColor: currentListColor.opacity(0.1))
        .contentShape(Circle())
    }
}

// Keep all spiral animation views unchanged...
struct SpiralDateView: View {
    let date: Date
    @State private var monthRotationAngle: Double = 0
    @State private var dayRotationAngle: Double = 0
    @State private var yearRotationAngle: Double = 0
    @State private var monthScale: Double = 1.0
    @State private var dayScale: Double = 1.0
    @State private var yearScale: Double = 1.0
    @State private var monthOpacity: Double = 1.0
    @State private var dayOpacity: Double = 1.0
    @State private var yearOpacity: Double = 1.0
    @State private var previousDate: Date?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Text(formatMonth(date))
                    .font(.customFont("Lexend", .bold, 22))
                    .foregroundColor(.primary)
                    .rotation3DEffect(
                        .degrees(monthRotationAngle),
                        axis: (x: 1.0, y: 0.0, z: 0.0),
                        anchor: .center,
                        perspective: 1.0
                    )
                    .scaleEffect(monthScale)
                    .opacity(monthOpacity)
                
                Text(formatYear(date))
                    .font(.customFont("Lexend", .bold, 22))
                    .foregroundColor(.primary)
                    .rotation3DEffect(
                        .degrees(yearRotationAngle),
                        axis: (x: 1.0, y: 0.0, z: 0.0),
                        anchor: .center,
                        perspective: 1.0
                    )
                    .scaleEffect(yearScale)
                    .opacity(yearOpacity)
            }
            .padding(.horizontal, 20)
            Text(formatDayAndWeekday(date))
                .font(.customFont("Lexend", .medium, 15))
                .foregroundColor(.secondary)
                .rotation3DEffect(
                    .degrees(dayRotationAngle),
                    axis: (x: 1.0, y: 0.0, z: 0.0),
                    anchor: .center,
                    perspective: 1.0
                )
                .scaleEffect(dayScale)
                .opacity(dayOpacity)
        }
        .onChange(of: date) { oldDate, newDate in
            performSelectiveHorizontalFlip(from: oldDate, to: newDate)
        }
        .onAppear {
            previousDate = date
        }
    }
    
    private func performSelectiveHorizontalFlip(from oldDate: Date, to newDate: Date) {
        let calendar = Calendar.current
        
        let yearChanged = !calendar.isDate(oldDate, equalTo: newDate, toGranularity: .year)
        let monthChanged = !calendar.isDate(oldDate, equalTo: newDate, toGranularity: .month)
        let dayChanged = !calendar.isDate(oldDate, equalTo: newDate, toGranularity: .day)
        
        if yearChanged {
            animateYearFlip()
        }
        
        if monthChanged && !yearChanged {
            animateMonthFlip()
        }
        
        if dayChanged {
            animateDayFlip()
        }
    }
    
    private func animateMonthFlip() {
        withAnimation(.easeInOut(duration: 0.2)) {
            monthRotationAngle = 90
            monthScale = 0.9
            monthOpacity = 0.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            monthRotationAngle = -90
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                monthRotationAngle = 0
                monthScale = 1.0
                monthOpacity = 1.0
            }
        }
    }
    
    private func animateDayFlip() {
        withAnimation(.easeInOut(duration: 0.2)) {
            dayRotationAngle = 90
            dayScale = 0.9
            dayOpacity = 0.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            dayRotationAngle = -90
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                dayRotationAngle = 0
                dayScale = 1.0
                dayOpacity = 1.0
            }
        }
    }
    
    private func animateYearFlip() {
        withAnimation(.easeInOut(duration: 0.2)) {
            yearRotationAngle = 90
            yearScale = 0.9
            yearOpacity = 0.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            yearRotationAngle = -90
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                yearRotationAngle = 0
                yearScale = 1.0
                yearOpacity = 1.0
            }
        }
    }
    
    private func formatMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: date)
    }
    
    private func formatYear(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: date)
    }
    
    private func formatDayAndWeekday(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d"
        return formatter.string(from: date)
    }
}

struct EnhancedSpiralDateView: View {
    let date: Date
    @State private var previousDate: Date?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Text(formatMonth(date))
                    .font(.customFont("Lexend", .bold, 22))
                    .foregroundStyle(GradientStyles.topToBottom(color: .primary, endOpacity: 0.7))
                    .contentTransition(.numericText(countsDown: shouldCountDown(for: .month)))
                    .transaction { transaction in
                        transaction.animation = .smooth(duration: 0.3)
                    }
                
                Text(formatYear(date))
                    .font(.customFont("Lexend", .bold, 22))
                    .foregroundStyle(GradientStyles.topToBottom(color: .primary, endOpacity: 0.7))
                    .contentTransition(.numericText(countsDown: shouldCountDown(for: .year)))
                    .transaction { transaction in
                        transaction.animation = .smooth(duration: 0.3)
                    }
            }
            
            Text(formatDayAndWeekday(date))
                .font(.customFont("Lexend", .medium, 13))
                .foregroundColor(.secondary)
                .contentTransition(.numericText(countsDown: shouldCountDown(for: .day)))
                .transaction { transaction in
                    transaction.animation = .smooth(duration: 0.3)
                }
        }
        .onChange(of: date) { oldDate, newDate in
            previousDate = oldDate
        }
        .onAppear {
            previousDate = date
        }
    }
    
    private func shouldCountDown(for component: DateComponent) -> Bool {
        guard let previousDate = previousDate else { return false }
        
        let calendar = Calendar.current
        
        switch component {
        case .year:
            let currentYear = calendar.component(.year, from: date)
            let previousYear = calendar.component(.year, from: previousDate)
            return currentYear < previousYear
            
        case .month:
            let currentMonth = calendar.component(.month, from: date)
            let previousMonth = calendar.component(.month, from: previousDate)
            return currentMonth < previousMonth
            
        case .day:
            let currentDay = calendar.component(.day, from: date)
            let previousDay = calendar.component(.day, from: previousDate)
            return currentDay < previousDay
        }
    }
    
    private enum DateComponent {
        case year, month, day
    }
    
    private func formatMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: date)
    }
    
    private func formatYear(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: date)
    }
    
    private func formatDayAndWeekday(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d"
        return formatter.string(from: date)
    }
}

// Updated helper function
func startNavigationBar(title: String, showingCreateHabitView: Binding<Bool>, selectedDate: Binding<Date>, sortOption: Binding<HabitSortOption>, showArchivedHabits: Binding<Bool>, selectedListIndex: Binding<Int>) -> some View {
    NavBarMainHabitView(
        showingCreateHabitView: showingCreateHabitView,
        selectedDate: selectedDate,
        sortOption: sortOption,
        title: title,
        showArchivedHabits: showArchivedHabits,
        selectedListIndex: selectedListIndex
    )
}
*/
