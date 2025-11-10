//
//  CustomNavigationBar.swift
//  Habital
//
//  Created by Elias Osarumwense on 04.04.25.
//

import SwiftUI
import CoreData

extension Color {
    /// Creates a milky/pastel version of the color by mixing it with white
    func milky(intensity: Double = 0.7) -> Color {
        return self.opacity(intensity)
    }
}

// Keep the existing HabitSortOption enum unchanged
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

// MARK: - Enhanced Spiral Date View (animation for title)
struct EnhancedSpiralDateView: View {
    let date: Date
    @State private var previousDate: Date?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Group {
                if let special = specialLabelIfAny(date) {
                    // Today / Yesterday / Tomorrow (no numeric animation)
                    Text(special)
                        .font(.customFont("Lexend", .semibold, 15))
                        .foregroundColor(.primary)
                        .transition(.opacity)
                        .transaction { $0.animation = .smooth(duration: 0.3) }
                } else if isInCurrentWeek(date) {
                    // Full weekday name (no numeric animation)
                    Text(formatWeekdayFull(date))
                        .font(.customFont("Lexend", .semibold, 15))
                        .foregroundColor(.primary)
                        .transition(.opacity)
                        .transaction { $0.animation = .smooth(duration: 0.3) }
                } else {
                    // Outside current week: "MMM dd" with numeric animation on day change
                    Text(formatMonthDay(date))
                        .font(.customFont("Lexend", .semibold, 15))
                        .foregroundColor(.primary)
                        .contentTransition(.numericText(countsDown: shouldCountDown(for: .day)))
                        .transaction { $0.animation = .smooth(duration: 0.3) }
                }
            }
        }
        .onChange(of: date) { oldDate, _ in
            previousDate = oldDate
        }
        .onAppear {
            previousDate = date
        }
    }
    
    // MARK: - Display rules helpers
    private func specialLabelIfAny(_ date: Date) -> String? {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let day = cal.startOfDay(for: date)
        if cal.isDate(day, inSameDayAs: today) { return "Today" }
        if let y = cal.date(byAdding: .day, value: -1, to: today), cal.isDate(day, inSameDayAs: y) { return "Yesterday" }
        if let t = cal.date(byAdding: .day, value: 1, to: today), cal.isDate(day, inSameDayAs: t) { return "Tomorrow" }
        return nil
    }
    
    private func isInCurrentWeek(_ date: Date) -> Bool {
        let cal = Calendar.current
        let today = Date()
        guard let week = cal.dateInterval(of: .weekOfYear, for: today) else { return false }
        return week.contains(date)
    }
    
    // MARK: - Animation direction
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
    
    // MARK: - Formatting
    private func formatMonthLong(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: date)
    }
    
    private func formatYear(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: date)
    }
    
    private func formatMonthDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        return formatter.string(from: date)
    }
    
    private func formatWeekdayFull(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
}

// MARK: - Stock Navigation Bar Wrapper View
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
    
    init(showingCreateHabitView: Binding<Bool>,
         selectedDate: Binding<Date>,
         sortOption: Binding<HabitSortOption>,
         title: String,
         showArchivedHabits: Binding<Bool>,
         selectedListIndex: Binding<Int>) {
        self._showingCreateHabitView = showingCreateHabitView
        self._selectedDate = selectedDate
        self._sortOption = sortOption
        self.title = title
        self._showArchivedHabits = showArchivedHabits
        self._selectedListIndex = selectedListIndex
    }
    
    var body: some View {
        EmptyView()
            .toolbar {
                toolbarContent
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    customTitleView
                }
            }
            .sheet(isPresented: $showHabitSortView) {
                HabitSortView(selectedList: getCurrentList())
                    .presentationCornerRadius(24)
                    .environment(\.managedObjectContext, viewContext)
            }
            .sheet(isPresented: $showCreateList) {
                if #available(iOS 16.0, *) {
                    NavigationStack {
                        CreateHabitListView()
                            .environment(\.managedObjectContext, viewContext)
                    }
                    .presentationCornerRadius(24)
                } else {
                    NavigationView {
                        CreateHabitListView()
                            .environment(\.managedObjectContext, viewContext)
                    }
                    .presentationCornerRadius(24)
                }
            }
            .sheet(isPresented: $showManageLists) {
                if #available(iOS 16.0, *) {
                    NavigationStack {
                        ManageHabitListsView()
                            .environment(\.managedObjectContext, viewContext)
                    }
                    .presentationCornerRadius(24)
                } else {
                    NavigationView {
                        ManageHabitListsView()
                            .environment(\.managedObjectContext, viewContext)
                    }
                    .presentationCornerRadius(24)
                }
            }
            .sheet(item: $listToEdit) { list in
                if #available(iOS 16.0, *) {
                    NavigationStack {
                        EditHabitListView(list: list)
                            .environment(\.managedObjectContext, viewContext)
                    }
                    .presentationCornerRadius(24)
                } else {
                    NavigationView {
                        EditHabitListView(list: list)
                            .environment(\.managedObjectContext, viewContext)
                    }
                    .presentationCornerRadius(24)
                }
            }
    }
    
    private var titleTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity).combined(with: .scale(scale: 0.98)),
            removal: .move(edge: .top).combined(with: .opacity)
        )
    }
    
    private var customTitleView: some View {
        let anim = Animation.easeInOut(duration: 0.25)
        let subtitleText = getCurrentListName()
        let subtitleID = "\(selectedListIndex)-\(showArchivedHabits ? 1 : 0)-\(subtitleText)"
        
        return VStack(spacing: 2) {
            if showArchivedHabits {
                ZStack {
                    Text("Archive")
                        .id("archive-\(showArchivedHabits ? 1 : 0)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .transition(titleTransition)
                }
                .animation(anim, value: showArchivedHabits)
                
                ZStack {
                    Text("\(countArchivedHabits(context: viewContext)) habits")
                        .id("archive-count-\(countArchivedHabits(context: viewContext))")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                        .transition(titleTransition)
                }
                .animation(anim, value: showArchivedHabits)
            } else {
                ZStack {
                    EnhancedSpiralDateView(date: selectedDate)
                        .id("enhanced-date-\(Calendar.current.startOfDay(for: selectedDate).timeIntervalSince1970)")
                        .transition(titleTransition)
                }
                .animation(anim, value: selectedDate)
                .frame(width: 110)
                
                ZStack {
                    HStack(spacing: 4) {
                        // Only show dot if we're not in "All Habits" (selectedListIndex > 0)
                        if selectedListIndex > 0 {
                            Circle()
                                .fill(titleDotColor)
                                .frame(width: 6, height: 6)
                        }
                        
                        Text(subtitleText)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    .id(subtitleID)
                    .transition(titleTransition)
                }
                .animation(anim, value: subtitleID)
            }
        }
        .animation(anim, value: showArchivedHabits)
    }
    
    private func dayKey(_ date: Date) -> String {
        let start = Calendar.current.startOfDay(for: date)
        return String(start.timeIntervalSince1970)
    }
    
    private func getDateDisplayText() -> String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let selectedDay = calendar.startOfDay(for: selectedDate)
        
        if selectedDay == today {
            return "Today"
        } else if let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
                  selectedDay == yesterday {
            return "Yesterday"
        } else if let tomorrow = calendar.date(byAdding: .day, value: 1, to: today),
                  selectedDay == tomorrow {
            return "Tomorrow"
        }
        
        if let weekInterval = calendar.dateInterval(of: .weekOfYear, for: today),
           weekInterval.contains(selectedDate) {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: selectedDate)
        }
        
        return "\(formatMonth(selectedDate)) \(formatDay(selectedDate))"
    }
    
    private func getCurrentListName() -> String {
        if selectedListIndex == 0 {
            return "All Habits"
        } else if selectedListIndex > 0 && selectedListIndex <= habitLists.count {
            let list = Array(habitLists)[selectedListIndex - 1]
            return list.name ?? "Unnamed List"
        }
        return "All Habits"
    }

    private func formatMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date)
    }

    private func formatDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    private func formatWeekday(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
    
    private var navigationTitle: String {
        if showArchivedHabits {
            return "Archive (\(countArchivedHabits(context: viewContext)))"
        } else {
            return formatNavigationTitle(selectedDate)
        }
    }
    
    private func formatNavigationTitle(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            if showArchivedHabits {
                Button(action: {
                    selectList(index: 0, showArchived: false)
                }) {
                    Image(systemName: "arrow.left")
                }
            } else {
                Menu {
                    listMenuContent
                } label: {
                    Image(systemName: currentListIcon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(currentListColor)
                }
            }
        }
        
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            if !showArchivedHabits {
                Menu {
                    sortMenuContent
                } label: {
                    Image(systemName: sortOption.icon)
                }
                
                Button(action: {
                    showingCreateHabitView = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
    }
    
    @ViewBuilder
    private var sortMenuContent: some View {
        ForEach(HabitSortOption.allCases) { option in
            Button(action: {
                withAnimation {
                    sortOption = option
                }
                HabitSortOption.save(option)
            }) {
                HStack {
                    Label(option.rawValue, systemImage: option.icon)
                    if option == sortOption {
                        Spacer()
                        Image(systemName: "checkmark")
                    }
                }
            }
        }
        
        Divider()
        
        Button(action: {
            showHabitSortView = true
        }) {
            Label("Customize Sort", systemImage: "arrow.up.arrow.down.circle")
        }
    }
    
    @ViewBuilder
    private var listMenuContent: some View {
        Button(action: {
            selectList(index: 0, showArchived: false)
        }) {
            HStack {
                Label("All Habits", systemImage: "tray.full")
                if selectedListIndex == 0 && !showArchivedHabits {
                    Image(systemName: "checkmark")
                }
            }
        }
        
        ForEach(Array(habitLists.enumerated()), id: \.element.id) { listIndex, list in
            Button(action: {
                selectList(index: listIndex + 1, showArchived: false)
            }) {
                HStack {
                    Label("\(list.name ?? "Unnamed List")", systemImage: list.icon ?? "list.bullet")
                    if selectedListIndex == listIndex + 1 && !showArchivedHabits {
                        Image(systemName: "checkmark")
                    }
                }
            }
        }
        
        Divider()
        
        Button(action: {
            selectList(index: 0, showArchived: true)
        }) {
            HStack {
                Label("Archived (\(countArchivedHabits(context: viewContext)))", systemImage: "archivebox")
                if showArchivedHabits {
                    Image(systemName: "checkmark")
                }
            }
        }
        
        Divider()
        
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
        
        if selectedListIndex > 0 && selectedListIndex <= habitLists.count && !showArchivedHabits {
            let currentList = Array(habitLists)[selectedListIndex - 1]
            Button(action: {
                listToEdit = currentList
            }) {
                Label("Edit '\(currentList.name ?? "List")'", systemImage: "pencil")
            }
        }
    }
    
    private func selectList(index: Int, showArchived: Bool) {
        withAnimation {
            selectedListIndex = index
            showArchivedHabits = showArchived
        }
        
        UserDefaults.saveSelectedListIndex(index)
        UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.7)
    }
    
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
            return .orange.opacity(0.7)
        } else if selectedListIndex == 0 {
            // No list selected - use custom tint based on color scheme
            return colorScheme == .dark ? Color(hexString: "C9D4FF") : Color(hexString: "4050B5")
        } else if selectedListIndex > 0 && selectedListIndex <= habitLists.count {
            let list = Array(habitLists)[selectedListIndex - 1]
            if let colorData = list.color,
               let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
                return Color(uiColor).opacity(0.7)
            }
            return colorScheme == .dark ? Color(hexString: "C9D4FF") : Color(hexString: "4050B5")
        }
        return colorScheme == .dark ? Color(hexString: "C9D4FF") : Color(hexString: "4050B5")
    }
    
    // Separate color for the dot indicator in the title (with milky effect)
    private var titleDotColor: Color {
        if showArchivedHabits {
            return .orange.milky()
        } else if selectedListIndex > 0 && selectedListIndex <= habitLists.count {
            let list = Array(habitLists)[selectedListIndex - 1]
            if let colorData = list.color,
               let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
                return Color(uiColor).milky()
            }
        }
        return colorScheme == .dark ? Color(hexString: "C9D4FF") : Color(hexString: "4050B5")
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

struct StockNavigationBarModifier: ViewModifier {
    @Binding var showingCreateHabitView: Bool
    @Binding var selectedDate: Date
    @Binding var sortOption: HabitSortOption
    @Binding var showArchivedHabits: Bool
    @Binding var selectedListIndex: Int
    let title: String
    
    init(showingCreateHabitView: Binding<Bool>,
         selectedDate: Binding<Date>,
         sortOption: Binding<HabitSortOption>,
         showArchivedHabits: Binding<Bool>,
         selectedListIndex: Binding<Int>,
         title: String) {
        self._showingCreateHabitView = showingCreateHabitView
        self._selectedDate = selectedDate
        self._sortOption = sortOption
        self._showArchivedHabits = showArchivedHabits
        self._selectedListIndex = selectedListIndex
        self.title = title
    }
    
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                content
                    .overlay(
                        NavBarMainHabitView(
                            showingCreateHabitView: $showingCreateHabitView,
                            selectedDate: $selectedDate,
                            sortOption: $sortOption,
                            title: title,
                            showArchivedHabits: $showArchivedHabits,
                            selectedListIndex: $selectedListIndex
                        )
                        .opacity(0)
                    )
            }
        } else {
            NavigationView {
                content
                    .overlay(
                        NavBarMainHabitView(
                            showingCreateHabitView: $showingCreateHabitView,
                            selectedDate: $selectedDate,
                            sortOption: $sortOption,
                            title: title,
                            showArchivedHabits: $showArchivedHabits,
                            selectedListIndex: $selectedListIndex
                        )
                        .opacity(0)
                    )
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }
}

func startNavigationBar(title: String,
                        showingCreateHabitView: Binding<Bool>,
                        selectedDate: Binding<Date>,
                        sortOption: Binding<HabitSortOption>,
                        showArchivedHabits: Binding<Bool>,
                        selectedListIndex: Binding<Int>) -> some View {
    EmptyView()
        .modifier(StockNavigationBarModifier(
            showingCreateHabitView: showingCreateHabitView,
            selectedDate: selectedDate,
            sortOption: sortOption,
            showArchivedHabits: showArchivedHabits,
            selectedListIndex: selectedListIndex,
            title: title
        ))
}
