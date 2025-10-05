//
//  MainHabitsView.swift
//  Habital
//
//  Created by Elias Osarumwense on 29.03.25.
//
import SwiftUI
import CoreData


//
//  MainHabitsView.swift
//  Habital
//
//  Created by Elias Osarumwense on 29.03.25.
//
struct MainHabitsView: View {
    
    @EnvironmentObject var dataManager: StatsDataManager
    @StateObject var progressOverlayManager = ProgressOverlayManager()
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.managedObjectContext) var viewContext
    @StateObject private var toggleManager = HabitToggleManager(context: PersistenceController.shared.container.viewContext)
    // Use the preloaded habit manager
    @EnvironmentObject var habitManager: HabitPreloadManager
    
    @State var sortOption: HabitSortOption = HabitSortOption.load()
    
    
    // Keep the original @FetchRequest as fallback, but we'll primarily use preloaded data
    @FetchRequest private var habits: FetchedResults<Habit>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \HabitList.order, ascending: true)]
        // Remove animation parameter entirely
    )
    private var habitLists: FetchedResults<HabitList>
    
    @State private var showingCreateHabitView = false
    @State private var showingEditHabitView: Habit? = nil
    @State private var showingSettingsView = false
    @State private var showHabitSortView = false
    @State var selectedDate = Date()
    @State private var weekOffset = 0
    @State private var isAnimatingDateChange = false
    private let daysOffset = 15
    
    @State var selectedListIndex = UserDefaults.loadSelectedListIndex()
    
    // Navigation state for Stats view
    @State private var showStatsView = false
    
    // Create StatsView once and reuse it
    @State private var statsViewInstance: StatsView? = nil
    
    // Simple scroll position tracking
    @State private var scrollOffset: CGFloat = 0
    @State private var listChangeID = UUID()
    
    // Efficient caching for filtered habits
    @State var filteredHabitsCache: [String: [Habit]] = [:]
    
    @AppStorage("showInactiveHabits") private var showInactiveHabits = true
    @AppStorage("groupCompletedHabits") private var groupCompletedHabits = false
    
    @State private var lastScrollUpdateTime: Date = .distantPast
    @State private var scrollUpdateThrottle: TimeInterval = 0.05
    
    // Reference to the HabitListTabView
    @State private var habitListTabView = HabitListTabReference()
    
    @State var showArchivedHabits: Bool = false
    @State var habitsVersion = UUID()
    
    @State private var previousListIndex: Int = 0
    @State private var listChangeDirection: ListChangeDirection = .none
    
    // Sheet state for comprehensive analytics
    @State private var showingInsightsView = false
    @State private var showingComprehensiveAnalytics = false
    @State private var weekTimelineID = UUID()

    
    
    enum ListChangeDirection {
        case left, right, none
    }
    
    let calendar = Calendar.current
    
    init() {
        let request = FetchRequest<Habit>(
            sortDescriptors: [NSSortDescriptor(keyPath: \Habit.order, ascending: true)],
            animation: .easeInOut
        )
        _habits = request
        _sortOption = State(initialValue: HabitSortOption.load())
        _selectedListIndex = State(initialValue: UserDefaults.loadSelectedListIndex())
    }
    
    private func updateFetchRequest() {
        let request = NSFetchRequest<Habit>(entityName: "Habit")
        request.sortDescriptors = [sortOption.sortDescriptor]
        
        let controller = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: viewContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        
        try? controller.performFetch()
    }
    
    // MARK: - Updated Computed Properties
    
    // Use preloaded habits when available, fallback to FetchRequest
    var effectiveHabits: [Habit] {
        print("🔍 effectiveHabits called - habitManager.isLoaded: \(habitManager.isLoaded)")
        
        if habitManager.isLoaded {
            let result = habitManager.getHabitsForList(selectedListIndex)
            print("📊 Returning \(result.count) habits from habitManager")
            return result
        } else {
            let result = Array(habits.filter { !$0.isArchived })
            print("📊 Returning \(result.count) habits from FetchRequest")
            return result
        }
    }
    
    // Use preloaded habit lists when available
    var effectiveHabitLists: [HabitList] {
        if habitManager.isLoaded {
            return habitManager.habitLists
        } else {
            return Array(habitLists)
        }
    }
    
    var selectedList: HabitList? {
        if selectedListIndex == 0 || selectedListIndex > effectiveHabitLists.count {
            return nil
        }
        return effectiveHabitLists[selectedListIndex - 1]
    }
    
    func getSelectedHabitList() -> HabitList? {
        return getCurrentList()
    }

    func getListColor(from list: HabitList) -> Color? {
        guard let colorData = list.color,
              let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) else {
            return nil
        }
        return Color(uiColor)
    }
    /*
    private var backgroundGradient: some View {
        let baseColors: [Color]
        
        if let selectedList = getSelectedHabitList(),
           let listColor = getListColor(from: selectedList) {
            // Use list color when available
            baseColors = [
                colorScheme == .dark ? listColor.opacity(0.15) : listColor.opacity(0.2),
                colorScheme == .dark ? Color(hex: "2A2A2A") : listColor.opacity(0.1)
            ]
        } else {
            // Default colors when no list or no color
            baseColors = [
                colorScheme == .dark ? Color(hex: "1A1A1A") : Color(hex: "F8F8FF"),
                colorScheme == .dark ? Color(hex: "2A2A2A") : Color(hex: "E8E8FF")
            ]
        }
        
        return LinearGradient(
            gradient: Gradient(colors: baseColors),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
     */
    
    
    private var backgroundGradient: some View {
        let baseColors: [Color]
        
        if let selectedList = getSelectedHabitList(),
           let listColor = getListColor(from: selectedList) {
            // Use list color when available - more visible but still fades fast
            baseColors = [
                colorScheme == .dark ? listColor.opacity(0.18) : listColor.opacity(0.25), // Top opacity
                colorScheme == .dark ? listColor.opacity(0.10) : listColor.opacity(0.15), // Middle
                colorScheme == .dark ? listColor.opacity(0.04) : listColor.opacity(0.06), // Still fades fast
                colorScheme == .dark ? Color(hex: "0A0A0A") : Color.clear                  // Nearly black
            ]
        } else {
            // Default colors with more visible secondary gradient for "All Habits"
            baseColors = [
                colorScheme == .dark ? Color.primary.opacity(0.20) : Color.primary.opacity(0.15), // More visible top
                colorScheme == .dark ? Color.secondary.opacity(0.12) : Color.secondary.opacity(0.08), // Visible middle
                colorScheme == .dark ? Color.secondary.opacity(0.08) : Color.secondary.opacity(0.04), // Fade
                colorScheme == .dark ? Color(hex: "0A0A0A") : Color.clear                              // Nearly black to clear
            ]
        }
        
        return LinearGradient(
            gradient: Gradient(colors: baseColors),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    var body: some View {
        
            Group {
                if #available(iOS 16.0, *) {
                    NavigationStack {
                        mainContentView
                    }
                } else {
                    NavigationView {
                        mainContentView
                    }
                    .navigationViewStyle(StackNavigationViewStyle())
                }
            }
        
        .sheet(isPresented: $showHabitSortView) {
            HabitSortView(selectedList: getCurrentList())
                .presentationCornerRadius(50)
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(isPresented: $showingCreateHabitView) {
            MainCreateHabitView(
                onHabitCreated: {
                    // Invalidate cache when habit is created
                    invalidateCaches()
                    // Dismiss the sheet
                    showingCreateHabitView = false
                }
            )
            .presentationCornerRadius(50)
            .environment(\.managedObjectContext, viewContext)
        }
        .sheet(item: $showingEditHabitView) { habit in
            EditHabitView(habit: habit)
                .presentationCornerRadius(50)
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(isPresented: $showingSettingsView) {
            SettingsView()
                .presentationCornerRadius(50)
                .environment(\.managedObjectContext, viewContext)
        }
        
        
        .onChange(of: showArchivedHabits) { _, _ in invalidateCaches() }
        .onChange(of: selectedListIndex) { oldValue, newValue in
            // IMPORTANT: Update list index FIRST before any date changes
            habitManager.currentListIndex = newValue
            
            // ✅ FIX #1: Use your existing cached method + new earliest date cache
            let newFilteredHabits = habitManager.getHabitsForList(newValue)
            let newEarliestDate = habitManager.getCachedEarliestDate(newValue)
            
            // Check if current selectedDate is invalid for the new list
            let calendar = Calendar.current
            if calendar.startOfDay(for: selectedDate) < calendar.startOfDay(for: newEarliestDate) {
                // Jump to the earliest valid date WITHOUT animation to prevent conflicts
                selectedDate = habitManager.navigateToEarliestValidDate()
                
                // ✅ FIX #2: Remove DispatchQueue delay - execute immediately
                NotificationCenter.default.post(
                    name: NSNotification.Name("ForceCalendarUpdate"),
                    object: nil,
                    userInfo: ["newDate": selectedDate, "listIndex": newValue]
                )
            }
            
            // Notify calendar components about the constraint changes
            NotificationCenter.default.post(
                name: NSNotification.Name("CalendarConstraintsChanged"),
                object: nil
            )
            
            // Update cached selection
            UserDefaults.saveSelectedListIndex(newValue)
            
            // ✅ FIX #3: Smart cache invalidation instead of destroying everything
            invalidateListSpecificCache(oldList: oldValue, newList: newValue)
            
            // Rest of your existing code...
            previousListIndex = oldValue
            if newValue > oldValue {
                listChangeDirection = .right
            } else if newValue < oldValue {
                listChangeDirection = .left
            } else {
                listChangeDirection = .none
            }
            
            habitsVersion = UUID()
            weekTimelineID = UUID()
        }
        .onDisappear {
            UserDefaults.saveSelectedListIndex(selectedListIndex)
        }
        .onAppear {
            
            sortOption = HabitSortOption.load()
            habitManager.currentListIndex = selectedListIndex
            // If habits aren't preloaded yet, refresh the habit manager
            if !habitManager.isLoaded {
                habitManager.refresh(context: viewContext)
            }
            
            
            /*
            // Initialize StatsView instance on first load
            if statsViewInstance == nil {
                statsViewInstance = StatsView().environment(\.managedObjectContext, viewContext) as? StatsView
            }
             */
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("HabitCompleted"))) { _ in
            // Refresh preloaded data when habits are completed
            habitManager.refresh(context: viewContext)
            invalidateCaches()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("HabitCreated"))) { _ in
            // Refresh preloaded data when new habits are created
            habitManager.refresh(context: viewContext)
            invalidateCaches()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("HabitIntervalCompleted"))) { _ in
            // Refresh your view
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("TabBarListSelectionChanged"))) { notification in
            guard let userInfo = notification.userInfo,
                  let listIndex = userInfo["selectedListIndex"] as? Int,
                  let showArchived = userInfo["showArchivedHabits"] as? Bool else { return }
            
            // Update the state variables to match the tab bar selection
            withAnimation(.easeInOut(duration: 0.4)) {
                selectedListIndex = listIndex
                showArchivedHabits = showArchived
            }
            
            // Save the selection to UserDefaults (like the existing onChange does)
            UserDefaults.saveSelectedListIndex(listIndex)
            
            // Invalidate caches to refresh the view
            invalidateCaches()
            
            // Force refresh habits version to trigger view updates
            habitsVersion = UUID()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("HabitUpdated"))) { _ in
            // Refresh preloaded data when habits are updated (including startDate changes)
            habitManager.refresh(context: viewContext)
            invalidateCaches()
        }
    }
    
    
    private var mainContentView: some View {
        ZStack {
            backgroundGradient
            VStack(spacing: 0) {
                // Remove navigationLayer, just have content
                contentLayer
                    .padding(.bottom, 5)
                    .padding(.horizontal, 10)
            }
        }
        .ignoresSafeArea(.all, edges: .bottom)
        .overlay(
            NavBarMainHabitView(
                showingCreateHabitView: $showingCreateHabitView,
                selectedDate: $selectedDate,
                sortOption: $sortOption,
                title: "Habits",
                showArchivedHabits: $showArchivedHabits,
                selectedListIndex: $selectedListIndex
            )
            .opacity(0)  // Hidden overlay to apply toolbar
        )
    }
    
    private func invalidateListSpecificCache(oldList: Int, newList: Int) {
        filteredHabitsCache.removeAll()
            
            // 2. Reset cached list index
            cachedListIndex = -1
            
            
            
            
            
            // 4. Clear DayKeyCache for affected habits
            DayKeyCache.shared.invalidateAll()
    }
    
    // MARK: - Layer Components
    
    
    
    private var contentLayer: some View {
        Group {
            if showStatsView {
                // Stats content
                statsContentView
            } else {
                // Habits content
                habitsContentView
            }
        }
    }
    
    private var tabContainerLayer: some View {
        MinimalHabitTabContainer(
            habitLists: habitLists,
            selectedListIndex: $selectedListIndex,
            showArchivedhabits: $showArchivedHabits,
            leftButtonIcon: showStatsView ? "chevron.left" : "gear",
            leftButtonAction: {
                if showStatsView {
                    navigateToHabits()
                } else {
                    showingSettingsView = true
                }
            },
            rightButtonIcon: showStatsView ? "brain.head.profile" : "chart.bar.xaxis", // Changed icon for insights
            rightButtonAction: {
                if showStatsView {
                    // Show insights view instead of dummy action
                    showingInsightsView = true
                } else {
                    navigateToStats()
                }
            },
            showStatsView: showStatsView,
            showAnalyticsAction: showStatsView ? {
                showingComprehensiveAnalytics = true
            } : nil
        )
        .environmentObject(habitListTabView)
    }
    
    // MARK: - Content Views
    @State private var dateAnimationTrigger = UUID()
    private var habitsContentView: some View {
        ZStack(alignment: .bottom) {
            //BlurredScrollView(blurHeight: 10) {
            ScrollView {
                VStack(spacing: 0) {
                    
                    if !showArchivedHabits {
                        WeekTimelineView(
                            selectedDate: $selectedDate,
                            weekOffset: $weekOffset,
                            onDateSelected: { newDate in
                                guard !self.isAnimatingDateChange else { return }
                                self.selectedDate = newDate
                                self.isAnimatingDateChange = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    self.isAnimatingDateChange = false
                                }
                            },
                            getFilteredHabits: { date in
                                // During animation prefer the cached result; fall back to fresh compute.
                                if isAnimatingDateChange, let cached = cachedFilteredHabits(for: date) {
                                    return cached
                                }
                                return filteredHabits(for: date)
                            }
                        )
                        .padding(.top, 7)
                        .id(weekTimelineID)
                    }
                    
                    DailyHabitsView(
                        date: selectedDate,
                        habits: {
                                let result = filteredHabits(for: selectedDate)
                                print("🎯 Passing \(result.count) habits to DailyHabitsView")
                                return result
                            }(),
                        isHabitActive: { habit in
                            HabitUtilities.isHabitActive(habit: habit, on: selectedDate)
                        },
                        isHabitCompleted: { habit in
                            //isHabitCompletedForDate(habit, on: selectedDate)
                            toggleManager.isHabitCompletedForDate(habit, on: selectedDate)
                        },
                        toggleCompletion: { habit in
                            //toggleCompletion(for: habit, on: selectedDate)
                            toggleManager.toggleCompletion(for: habit, on: selectedDate, dataManager: dataManager)
                        },
                        getNextOccurrenceText: { habit in
                            HabitUtilities.getNextOccurrenceText(for: habit, selectedDate: selectedDate)
                        },
                        onHabitDeleted: {
                            invalidateCaches()
                        },
                        showArchivedHabits: $showArchivedHabits,
                        listChangeDirection: listChangeDirection,
                        listChangeID: selectedListIndex
                    )
                    .id("dailyHabits-\(habitsVersion)")
                    //.animation(.spring(response: 0.4, dampingFraction: 0.8), value: habits.map { $0.id })
                    //.animation(.spring(response: 0.4, dampingFraction: 0.9), value: selectedDate)
                    
                    Color.clear.frame(height: 90)
                }
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
        }
    }
    
    func showDailyProgressOverlay(for date: Date) {
        // Only update progress without heavy calculations during animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let progress = self.calculateDailyProgressOptimized(for: date)
            self.progressOverlayManager.showProgress(progress)
            
        }
    }


    // MARK: - Optional: Add method to manually hide the progress overlay
    private func hideDailyProgressOverlay() {
        progressOverlayManager.setIdleState()
    }
    
    private var statsContentView: some View {
        StatsView(filteredHabits: filteredStatsHabits)
            .environment(\.managedObjectContext, viewContext)
    }
    
    @State private var selectedStatsListIndex = 0 // 0 = All Habits, 1+ = specific lists
    @State private var showStatsListSelection = false
    
    private var filteredStatsHabits: [Habit] {
        let allHabits = Array(effectiveHabits.filter { !$0.isArchived }) // Use effective habits
        
        if selectedStatsListIndex == 0 {
            // All habits
            return allHabits
        } else if selectedStatsListIndex <= effectiveHabitLists.count {
            // Specific list
            let selectedList = effectiveHabitLists[selectedStatsListIndex - 1]
            return allHabits.filter { $0.habitList == selectedList }
        }
        
        return allHabits
    }

    private var currentStatsListName: String {
        if selectedStatsListIndex == 0 {
            return "All Habits"
        } else if selectedStatsListIndex <= effectiveHabitLists.count {
            return effectiveHabitLists[selectedStatsListIndex - 1].name ?? "Unnamed List"
        }
        return "All Habits"
    }
    
    private var statsNavigationBar: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .mask {
                    VStack(spacing: 0) {
                        Rectangle()
                        LinearGradient(
                            colors: [
                                Color.black,
                                Color.black.opacity(colorScheme == .dark ? 0.1 : 0.2),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                }
                .blendMode(.overlay)
            
            Capsule()
                .strokeBorder(
                    Color.white.opacity(colorScheme == .dark ? 0.25 : 0.4),
                    lineWidth: 0.5
                )
        }
        .frame(height: 60)
        .padding(.horizontal, 20)
    }
    
    // MARK: - Helper Functions
    
    private func calculateOpacity() -> Double {
        return isAnimatingDateChange ? 0.6 : 1.0
    }
    
    // MARK: - Navigation Functions
    
    private func navigateToStats() {
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Instant switch
        withAnimation {
            showStatsView = true
        }
    }
    
    private func navigateToHabits() {
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Instant switch
        showStatsView = false
    }
    
    // MARK: - Updated Helper Functions
    
    private func getCurrentList() -> HabitList? {
        if selectedListIndex == 0 || selectedListIndex > effectiveHabitLists.count {
            return nil
        }
        return effectiveHabitLists[selectedListIndex - 1]
    }
    
    // Centralized method to invalidate all caches and refresh preloaded data
    func invalidateCaches() {
        HabitUtilities.clearHabitActivityCache()
        filteredHabitsCache = [:]
        
        // Refresh preloaded data
        habitManager.refresh(context: viewContext)
    }
    
    private func handlePullToOpen() {
        // You can customize what happens when the user pulls to open
        // For example, you could:
        
        // 1. Show the create habit view
        // showingCreateHabitView = true
        
        // 2. Show settings
        // showingSettingsView = true
        
        // 3. Show a quick actions menu (handled by the overlay)
        // This is already handled by the PullToOpenOverlay
        
        // 4. Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        print("Pull to open triggered!")
    }
    
    // Find completion for a given date
    func findCompletion(for habit: Habit, on date: Date) -> Completion? {
        guard let completions = habit.completion as? Set<Completion> else {
            return nil
        }
        
        // Find a completion whose date matches the selected date
        return completions.first { completion in
            guard let completionDate = completion.date else { return false }
            return calendar.isDate(completionDate, inSameDayAs: date)
        }
    }
    @State private var debugCallCount = 0
    
    func filteredHabits(for date: Date) -> [Habit] {
        let calendar = Calendar.current
        let normalizedDate = calendar.startOfDay(for: date)

        // Fast path: cached (use helper)
        if let cached = filteredHabitsCache[cacheKey(for: date)] {
            return cached
        }

        // Always start from the unified source
        var habitArray = effectiveHabits

        // Archived filtering
        habitArray = habitArray.filter { showArchivedHabits ? $0.isArchived : !$0.isArchived }

        // List filtering (compare by objectID to avoid instance-identity pitfalls)
        if let selectedList = selectedList {
            let selectedID = selectedList.objectID
            habitArray = habitArray.filter { $0.habitList?.objectID == selectedID }
        }

        // Start date guard
        let filtered = habitArray.filter { habit in
            let startDate = habit.startDate ?? Date()
            return calendar.startOfDay(for: startDate) <= normalizedDate
        }

        // Sorting
        let sorted = filtered.sorted { h1, h2 in
            let isActive1 = HabitUtilities.isHabitActive(habit: h1, on: date)
            let isActive2 = HabitUtilities.isHabitActive(habit: h2, on: date)

            if isActive1 != isActive2 { return isActive1 }              // active first
            if h1.isBadHabit != h2.isBadHabit { return !h1.isBadHabit } // bad last

            switch sortOption {
            case .completion where isActive1 && isActive2:
                let c1 = toggleManager.isHabitCompletedForDate(h1, on: date)
                let c2 = toggleManager.isHabitCompletedForDate(h2, on: date)
                if c1 != c2 { return !c1 } // incomplete first
                return (h1.name ?? "") < (h2.name ?? "")
            case .streak:
                let s1 = h1.calculateStreak(upTo: date)
                let s2 = h2.calculateStreak(upTo: date)
                if s1 != s2 { return s1 > s2 }
                return (h1.name ?? "") < (h2.name ?? "")
            case .recentCompletion:
                let sc1 = HabitUtilities.calculateRecentCompletionScore(for: h1, referenceDate: date)
                let sc2 = HabitUtilities.calculateRecentCompletionScore(for: h2, referenceDate: date)
                if sc1 != sc2 { return sc1 > sc2 }
                return (h1.name ?? "") < (h2.name ?? "")
            case .ascending:
                return (h1.name ?? "") < (h2.name ?? "")
            case .descending:
                return (h1.name ?? "") > (h2.name ?? "")
            case .custom:
                return h1.order < h2.order
            default:
                return (h1.name ?? "") < (h2.name ?? "")
            }
        }

        // Async cache write on main actor
        let key = cacheKey(for: date)
        Task { @MainActor in
            filteredHabitsCache[key] = sorted
        }

        return sorted
    }

    private func cacheKey(for date: Date) -> String {
        let d = Calendar.current.startOfDay(for: date).timeIntervalSince1970
        return "\(d)|\(selectedListIndex)|\(showArchivedHabits ? 1 : 0)|\(sortOption.rawValue)"
    }

    // ADD
    private func cachedFilteredHabits(for date: Date) -> [Habit]? {
        filteredHabitsCache[cacheKey(for: date)]
    }
    
    // Add this property to your MainHabitsView
    @State private var cachedListIndex: Int = -1
    
    // Original single completion toggle logic
    private func toggleSingleCompletion(for habit: Habit, on date: Date) {
        // Get the normalized date (start of day)
        let normalizedDate = calendar.startOfDay(for: date)
        
        // Check if there's already a completion for the selected date
        if let existingCompletion = findCompletion(for: habit, on: date) {
            // Toggle the completion status
            existingCompletion.completed.toggle()
            
            // If toggled to "not completed", we could remove the completion entity entirely
            if !existingCompletion.completed {
                viewContext.delete(existingCompletion)
            }
        } else {
            // Create a new completion for this date
            let newCompletion = Completion(context: viewContext)
            newCompletion.completed = true
            newCompletion.date = normalizedDate
            
            // Add the completion to the habit
            habit.addToCompletion(newCompletion)
            
            // Update lastCompletionDate only if this is the most recent completion
            if normalizedDate > (habit.lastCompletionDate ?? Date.distantPast) {
                habit.lastCompletionDate = normalizedDate
            }
        }
        
        do {
            try viewContext.save()
            // Invalidate caches after updating
            invalidateCaches()
        } catch {
            print("Error updating completion status: \(error)")
        }
    }
    
    private func formatSelectedDate() -> String {
        let today = Calendar.current.startOfDay(for: Date())
        let selectedDay = Calendar.current.startOfDay(for: selectedDate)
        
        let daysDifference = Calendar.current.dateComponents([.day], from: today, to: selectedDay).day ?? 0
        
        let formatter = DateFormatter()
        if abs(daysDifference) <= 6 {
            // Within a week - show day name
            formatter.dateFormat = "EEEE"
        } else {
            // More than a week away - show day and month
            formatter.dateFormat = "dd. MMMM"
        }
        
        return formatter.string(from: selectedDate)
    }
    private func createProgressCacheKey(for date: Date) -> String {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        return "progress-\(normalizedDate.timeIntervalSince1970)-\(selectedListIndex)"
    }
    
    // ULTRA OPTIMIZED: Minimal calculation with early exits and bad habit fix
    func calculateDailyProgressOptimized(for date: Date) -> Double {
        // OPTIMIZATION 2: Use your existing filteredHabits cache (this is already optimized)
        let habits = filteredHabits(for: date)
        
        // OPTIMIZATION 3: Ultra-fast path for empty habits
        if habits.isEmpty { return 0.0 }
        
        // OPTIMIZATION 4: Single loop with bad habit fix
        var activeCount = 0
        var completedCount = 0
        
        // Single loop through habits (most efficient)
        for habit in habits {
            // Use cached activity check (your existing optimization)
            if HabitUtilities.isHabitActive(habit: habit, on: date) {
                activeCount += 1
                
                // FIX: Proper bad habit logic
                let isCompleted = toggleManager.isHabitCompletedForDate(habit, on: date)
                let isSuccessful: Bool
                
                if habit.isBadHabit {
                    // For bad habits: NOT completed = success
                    isSuccessful = !isCompleted
                } else {
                    // For good habits: completed = success
                    isSuccessful = isCompleted
                }
                
                if isSuccessful {
                    completedCount += 1
                }
            }
        }
        
        return activeCount > 0 ? Double(completedCount) / Double(activeCount) : 0.0
    }
    
    // OPTIMIZATION: Lightweight progress update that uses caching
    func updateProgressOverlaySilently(for date: Date) {
        let progress = calculateDailyProgressOptimized(for: date)
        progressOverlayManager.updateProgressSilently(progress)
    }
}

// Add a class to reference the HabitListTabView state
class HabitListTabReference: ObservableObject {
    @Published var selectedIndex = 0
    @Published var totalTabs = 0
    
    func isArchiveSelected() -> Bool {
        // The archive tab is the last tab
        return selectedIndex == totalTabs - 1 && totalTabs > 0
    }
}

// Extension to track changes in a Binding
extension Binding {
    func onChange(_ handler: @escaping (Value) -> Void) -> Binding<Value> {
        Binding(
            get: { self.wrappedValue },
            set: { newValue in
                self.wrappedValue = newValue
                handler(newValue)
            }
        )
    }
}

#Preview {
    MainHabitsView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

// Create a class for habit activity caching
class HabitActivityCache: ObservableObject {
    // Use TimeInterval as keys for dates for better performance
    private var cache: [String: [TimeInterval: Bool]] = [:]
    
    func isHabitActive(habit: Habit, on date: Date, startDate: Date) -> Bool {
        let calendar = Calendar.current
        let normalizedDate = calendar.startOfDay(for: date)
        let dateKey = normalizedDate.timeIntervalSince1970
        
        guard let habitID = habit.id?.uuidString else {
            return HabitUtilities.isHabitActive(on: date, startDate: startDate, repeatPattern: habit)
        }
        
        // Check cache
        if let dateCache = cache[habitID], let result = dateCache[dateKey] {
            return result
        }
        
        // Calculate result
        let result = HabitUtilities.isHabitActive(on: date, startDate: startDate, repeatPattern: habit)
        
        // Update cache
        if cache[habitID] == nil {
            cache[habitID] = [:]
        }
        cache[habitID]?[dateKey] = result
        
        return result
    }
    
    func clearCache() {
        cache = [:]
    }
}

