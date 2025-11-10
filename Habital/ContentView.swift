//
//  ContentView.swift
//  Habital
//
//  Created by Elias Osarumwense on 29.03.25.
//

import SwiftUI
import CoreData

// MARK: - Tab Bar Item Enum
enum TabBarItem: Int, CaseIterable {
    case main = 0
    case stats = 1
    case overview = 2
    case settings = 3
    
    var title: String {
        switch self {
        case .main: return "Habits"
        case .stats: return "Stats"
        case .overview: return "More"
        case .settings: return "Settings"
        }
    }
    
    var icon: String {
        switch self {
        case .main: return "checklist"
        case .stats: return "chart.bar"
        case .overview: return "ellipsis"
        case .settings: return "gearshape"
        }
    }
}

// MARK: - Main Content View with Stock TabView
struct ContentView: View {
    @State private var selectedTab: TabBarItem = .main
    @StateObject private var sharedLevelData = SharedLevelData.shared
    @StateObject private var tabStateManager = GlobalTabState.shared
    
    // Get managers from environment
    @EnvironmentObject var habitManager: HabitPreloadManager
    @EnvironmentObject var statsSummaryManager: StatsSummaryDataManager
    @EnvironmentObject var dataManager: StatsDataManager
    
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var allViewsInitialized = false
    @State private var isInitializing = true
    
    var body: some View {
        Group {
            if #available(iOS 18, *) {
                // iOS 18+ uses new tab style
                TabView(selection: $selectedTab) {
                    ForEach(TabBarItem.allCases, id: \.self) { tab in
                        Tab(tab.title, systemImage: tab.icon, value: tab) {
                            tabContent(for: tab)
                        }
                    }
                }
                .tabViewStyle(.sidebarAdaptable)
                .tint(colorScheme == .dark ? Color(hex: "C9D4FF") : Color(hex: "4050B5"))



            } else {
                // iOS 17 and below uses traditional TabView
                TabView(selection: $selectedTab) {
                    // Main Tab
                    tabContent(for: .main)
                        .tabItem {
                            Label(TabBarItem.main.title, systemImage: TabBarItem.main.icon)
                        }
                        .tag(TabBarItem.main)
                    
                    // Stats Tab
                    tabContent(for: .stats)
                        .tabItem {
                            Label(TabBarItem.stats.title, systemImage: TabBarItem.stats.icon)
                        }
                        .tag(TabBarItem.stats)
                    
                    // Overview Tab
                    tabContent(for: .overview)
                        .tabItem {
                            Label(TabBarItem.overview.title, systemImage: TabBarItem.overview.icon)
                        }
                        .tag(TabBarItem.overview)
                    
                    // Settings Tab
                    tabContent(for: .settings)
                        .tabItem {
                            Label(TabBarItem.settings.title, systemImage: TabBarItem.settings.icon)
                        }
                        .tag(TabBarItem.settings)
                }
                .tint(colorScheme == .dark ? Color(hex: "C9D4FF") : Color(hex: "4050B5"))
            }
        }
        .environmentObject(sharedLevelData)
        .onAppear {
            initializeAppData()
            tabStateManager.loadSavedSelection()
            initializeAllViewsOnStartup()
            
        }
    }
    
    // MARK: - Tab Content View Builder
    @ViewBuilder
    private func tabContent(for tab: TabBarItem) -> some View {
        switch tab {
        case .main:
            MainHabitsView()
                .environmentObject(habitManager)
                .environmentObject(statsSummaryManager)
                .environmentObject(tabStateManager)
        
        case .stats:
            StatsView()
                .environmentObject(dataManager)
                .environmentObject(statsSummaryManager)
                .environmentObject(tabStateManager)
        
        case .overview:
            HabitOverviewView()
        
        case .settings:
            SettingsView()
        }
    }
    
    // MARK: - Initialize All Views on Startup
    private func initializeAllViewsOnStartup() {
        Task {
            print("🔄 ContentView: Starting initialization of all views...")
            
            // Ensure all data managers are ready
            await ensureDataManagersReady()
            
            // Mark views as initialized
            await MainActor.run {
                allViewsInitialized = true
                isInitializing = false
                print("✅ ContentView: All views initialized and ready")
            }
        }
    }
    
    private func ensureDataManagersReady() async {
        // Ensure StatsDataManager is ready
        if !dataManager.dataReady {
            print("🔄 ContentView: Loading StatsDataManager...")
            await MainActor.run {
                dataManager.loadInitialData()
            }
            
            // Wait for data to be ready or timeout after 3 seconds
            let startTime = CFAbsoluteTimeGetCurrent()
            while !dataManager.dataReady && (CFAbsoluteTimeGetCurrent() - startTime) < 3.0 {
                do {
                    try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
                } catch {
                    print("⚠️ ContentView: Task sleep interrupted: \(error)")
                    break
                }
            }
            
            if dataManager.dataReady {
                print("✅ ContentView: StatsDataManager ready")
            } else {
                print("⚠️ ContentView: StatsDataManager timeout - proceeding anyway")
            }
        } else {
            print("✅ ContentView: StatsDataManager was already ready")
        }
        
        // Ensure StatsSummaryDataManager has data
        await MainActor.run {
            if habitManager.isLoaded && !habitManager.habits.isEmpty {
                statsSummaryManager.preloadSummaryData(habits: habitManager.habits)
                print("✅ ContentView: StatsSummaryDataManager preloaded with \(habitManager.habits.count) habits")
            }
        }
    }
    
    // MARK: - Helper Functions
    private func initializeAppData() {
        // Use preloaded habits for XP calculation
        let habitsToProcess: [Habit]
        if habitManager.isLoaded {
            habitsToProcess = habitManager.habits
        } else {
            // Fallback (should rarely happen since habits are preloaded)
            let context = PersistenceController.shared.container.viewContext
            let request = NSFetchRequest<Habit>(entityName: "Habit")
            do {
                habitsToProcess = try context.fetch(request)
            } catch {
                print("Error fetching habits: \(error)")
                habitsToProcess = []
            }
        }
        
        // Uncomment if needed:
        // SharedLevelData.shared.recalculateAllXP(from: habitsToProcess)
    }
}


