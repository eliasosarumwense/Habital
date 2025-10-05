import SwiftUI
import CoreData

extension UserDefaults {
    private enum Keys {
        static let selectedHabitListId = "selectedHabitListId"
        static let selectedHabitListName = "selectedHabitListName"
        static let selectedHabitListIcon = "selectedHabitListIcon"
    }
    
    static func saveSelectedHabitList(_ habitList: HabitListItem?) {
        if let habitList = habitList {
            UserDefaults.standard.set(habitList.id.uuidString, forKey: Keys.selectedHabitListId)
            UserDefaults.standard.set(habitList.name, forKey: Keys.selectedHabitListName)
            UserDefaults.standard.set(habitList.icon, forKey: Keys.selectedHabitListIcon)
        } else {
            UserDefaults.standard.removeObject(forKey: Keys.selectedHabitListId)
            UserDefaults.standard.removeObject(forKey: Keys.selectedHabitListName)
            UserDefaults.standard.removeObject(forKey: Keys.selectedHabitListIcon)
        }
    }
    
    static func loadSelectedHabitList() -> HabitListItem? {
        guard let idString = UserDefaults.standard.string(forKey: Keys.selectedHabitListId),
              let id = UUID(uuidString: idString),
              let name = UserDefaults.standard.string(forKey: Keys.selectedHabitListName),
              let icon = UserDefaults.standard.string(forKey: Keys.selectedHabitListIcon) else {
            return nil
        }
        
        return HabitListItem(
            id: id,
            name: name,
            icon: icon,
            color: .blue, // Will be updated when real data is loaded
            habitCount: 0 // Will be updated when real data is loaded
        )
    }
}

// MARK: - Global State Manager
class GlobalTabState: ObservableObject {
    static let shared = GlobalTabState()
    @Published var selectedHabitList: HabitListItem? = nil
    
    private init() {
        loadSavedSelection()
    }
    
    func loadSavedSelection() {
        selectedHabitList = UserDefaults.loadSelectedHabitList()
    }
    
    func selectHabitList(_ habitList: HabitListItem?, habitLists: [HabitListItem]) {
        selectedHabitList = habitList
        UserDefaults.saveSelectedHabitList(habitList)
        
        let (listIndex, showArchived) = convertHabitListToMainHabitsFormat(habitList, habitLists: habitLists)
        NotificationCenter.default.post(
            name: NSNotification.Name("TabBarListSelectionChanged"),
            object: nil,
            userInfo: [
                "selectedListIndex": listIndex,
                "showArchivedHabits": showArchived,
                "selectedHabitListName": habitList?.name ?? "All Habits",
                "selectedHabitListIcon": habitList?.icon ?? "tray.full"
            ]
        )
    }
    
    func clearSelection() {
        selectedHabitList = nil
        UserDefaults.saveSelectedHabitList(nil)
        
        NotificationCenter.default.post(
            name: NSNotification.Name("TabBarListSelectionChanged"),
            object: nil,
            userInfo: [
                "selectedListIndex": 0,
                "showArchivedHabits": false,
                "selectedHabitListName": "All Habits",
                "selectedHabitListIcon": "tray.full"
            ]
        )
    }
    
    private func convertHabitListToMainHabitsFormat(_ habitList: HabitListItem?, habitLists: [HabitListItem]) -> (Int, Bool) {
        guard let habitList = habitList else {
            return (0, false)
        }
        
        if habitList.name == "All Habits" {
            return (0, false)
        }
        
        if habitList.name == "Archived" {
            return (0, true)
        }
        
        let actualHabitLists = habitLists.filter { $0.name != "All Habits" && $0.name != "Archived" }
        
        if let index = actualHabitLists.firstIndex(where: { $0.id == habitList.id }) {
            return (index + 1, false)
        }
        
        return (0, false)
    }
}

// MARK: - Tab Item Model
struct FloatingTabItem {
    let icon: String
    let title: String
    let tag: Int
}

// MARK: - Habit List Item Model
struct HabitListItem: Equatable {
    let id: UUID
    let name: String
    let icon: String
    let color: Color
    let habitCount: Int
    
    static func == (lhs: HabitListItem, rhs: HabitListItem) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.icon == rhs.icon &&
               lhs.habitCount == rhs.habitCount
    }
}

// MARK: - Modern Minimal Floating Tab Bar
struct FloatingTabBar: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var selectedTab: Int
    @Binding var isExpanded: Bool
    @Binding var selectedHabitList: HabitListItem?
    let tabs: [FloatingTabItem]
    
    // Access global state
    @StateObject private var globalState = GlobalTabState.shared
    @AppStorage("useGlassEffect") private var useGlassEffect = true
    
    // Fetch habit lists from Core Data
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \HabitList.order, ascending: true)],
        animation: .default
    )
    private var habitLists: FetchedResults<HabitList>
    
    private var selectedCoreDataList: HabitList? {
        guard let selectedId = globalState.selectedHabitList?.id else { return nil }
        return habitLists.first { $0.id == selectedId }
    }
    
    // Convert Core Data objects to HabitListItem
    private var availableHabitLists: [HabitListItem] {
        var lists: [HabitListItem] = []
        
        // Add "All Habits" option with secondary color
        lists.append(HabitListItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000000") ?? UUID(),
            name: "All Habits",
            icon: "tray.full",
            color: .secondary,
            habitCount: getAllHabitsCount()
        ))
        
        // Add habit lists
        for habitList in habitLists {
            lists.append(HabitListItem(
                id: habitList.id ?? UUID(),
                name: habitList.name ?? "Unnamed List",
                icon: habitList.icon ?? "list.bullet",
                color: getListColor(habitList),
                habitCount: getHabitCount(habitList)
            ))
        }
        
        // Add "Archived" option
        lists.append(HabitListItem(
            id: UUID(uuidString: "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF") ?? UUID(),
            name: "Archived",
            icon: "archivebox",
            color: .gray,
            habitCount: getArchivedHabitsCount()
        ))
        
        return lists
    }
    
    // Helper functions
    private func getListColor(_ list: HabitList) -> Color {
        if let colorData = list.color,
           let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
            return Color(uiColor)
        }
        return .blue
    }
    
    private func getHabitCount(_ list: HabitList) -> Int {
        return list.habits?.count ?? 0
    }
    
    private func getAllHabitsCount() -> Int {
        let request: NSFetchRequest<Habit> = Habit.fetchRequest()
        request.predicate = NSPredicate(format: "isArchived == NO")
        return (try? viewContext.count(for: request)) ?? 0
    }
    
    private func getArchivedHabitsCount() -> Int {
        let request: NSFetchRequest<Habit> = Habit.fetchRequest()
        request.predicate = NSPredicate(format: "isArchived == YES")
        return (try? viewContext.count(for: request)) ?? 0
    }
    
    // Enhanced initial state setup
    private var currentSelectedHabitList: HabitListItem? {
        // If no selection in global state, default to "All Habits"
        if globalState.selectedHabitList == nil {
            return availableHabitLists.first { $0.name == "All Habits" }
        }
        
        // Find the current selection in available lists and update colors
        if let selected = globalState.selectedHabitList,
           let foundList = availableHabitLists.first(where: { $0.id == selected.id }) {
            return foundList // Return the list with updated colors
        }
        
        // Fallback to "All Habits"
        return availableHabitLists.first { $0.name == "All Habits" }
    }
    
    var body: some View {
        ZStack {
            // Modern minimal expanded list overlay
            if isExpanded {
                modernExpandedListOverlay
            }
            
            // Main tab bar container
            modernTabBarContainer
        }
        .onReceive(globalState.$selectedHabitList) { newSelection in
            selectedHabitList = newSelection
        }
        .onAppear {
            globalState.loadSavedSelection()
            // Set initial selection to ensure colors are correct on first load
            if globalState.selectedHabitList == nil {
                selectedHabitList = currentSelectedHabitList
            } else {
                selectedHabitList = currentSelectedHabitList
            }
        }
    }
    
    // MARK: - Modern Expanded List Overlay
    @ViewBuilder
    private var modernExpandedListOverlay: some View {
        VStack {
            Spacer()
            
            // Modern popup container using the separate component
            HabitListSelectionPopover(
                availableHabitLists: availableHabitLists,
                globalState: globalState,
                selectedHabitList: $selectedHabitList,
                isExpanded: $isExpanded,
                selectedCoreDataList: selectedCoreDataList,
                viewContext: viewContext
            )
            
            .padding(.horizontal, 24)
            .scaleEffect(isExpanded ? 1 : 0.8, anchor: .bottom)
            .opacity(isExpanded ? 1 : 0)
            //.offset(y: isExpanded ? 0 : 20)
            //.animation(.smooth(duration: 0.5, extraBounce: 0.15), value: isExpanded)
            
            Spacer()
                .frame(height: 30) // Space for tab bar
        }
        .zIndex(50)
        
    }
    
    // MARK: - Modern Glass Background
    @ViewBuilder
    private var modernGlassBackground: some View {
        if useGlassEffect {
            ZStack {
                // Base ultra-thin material
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
                
                // Subtle glass reflection
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.08 : 0.15),
                                Color.clear,
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                // Clean glass edge
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(
                        Color.white.opacity(colorScheme == .dark ? 0.2 : 0.3),
                        lineWidth: 0.6
                    )
            }
            .shadow(color: .black.opacity(0.1), radius: 25, x: 0, y: 10)
        } else {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 8)
        }
    }
    
    // MARK: - Modern Tab Bar Container
    @ViewBuilder
    private var modernTabBarContainer: some View {
        VStack {
            Spacer()
            
            ZStack {
                // Tab bar background
                Color.clear
                    .frame(height: 120)
                    //.glassBackground(cornerRadius: 0)
                    .background(.ultraThinMaterial)
                // Tab items
                HStack(spacing: 0) {
                    // Left tabs
                    ForEach(tabs.prefix(2), id: \.tag) { tab in
                        FloatingTabButton(
                            tab: tab,
                            isSelected: selectedTab == tab.tag,
                            onTap: {
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                                
                                selectedTab = tab.tag
                                withAnimation(.smooth(duration: 0.4)) {
                                    isExpanded = false
                                }
                            }
                        )
                    }
                    /*
                    // Center list button using the separate component
                    CenterListButton(
                        isExpanded: $isExpanded,
                        selectedHabitList: currentSelectedHabitList,
                        availableHabitLists: availableHabitLists,
                        globalState: globalState,
                        selectedCoreDataList: selectedCoreDataList,
                        viewContext: viewContext,
                        onTap: {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                isExpanded.toggle()
                            }
                        }
                    )
                    */
                    // Right tabs
                    ForEach(tabs.suffix(2), id: \.tag) { tab in
                        FloatingTabButton(
                            tab: tab,
                            isSelected: selectedTab == tab.tag,
                            onTap: {
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                                
                                selectedTab = tab.tag
                                withAnimation(.smooth(duration: 0.4)) {
                                    isExpanded = false
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .offset(y: -25)
            }
        }
        .zIndex(100)
    }
}

// MARK: - Tab Bar Button Component
struct FloatingTabButton: View {
    let tab: FloatingTabItem
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 20, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? .primary : .secondary)
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                
                Text(tab.title)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? .primary : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .animation(.smooth(duration: 0.3), value: isSelected)
    }
}
