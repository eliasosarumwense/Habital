//
//  HabitalApp.swift
//  Habital
//
//  Created by Elias Osarumwense on 29.03.25.
//

import SwiftUI
import CoreData

import SwiftUI
import CoreData

@main
struct HabitalApp: App {
    
    let persistenceController = PersistenceController.shared
    
    // Create the cache manager instance
    @StateObject private var cacheManager = CalendarCacheManager()
    
    @StateObject private var sharedStatsDataManager = StatsDataManager(
        viewContext: PersistenceController.shared.container.viewContext
    )
    
    // Create a shared habit manager for preloading
    @StateObject private var habitManager = HabitPreloadManager()
    
    // NEW: Stats summary data manager for preloading summary calculations
    @StateObject private var statsSummaryManager = StatsSummaryDataManager()
    
    // OPTIMIZATION: Progressive loading states
    @State private var basicDataReady = false
    @State private var fullDataReady = false
    
    // 🆕 NEW: Migration states
    @State private var migrationCompleted = false
    @State private var migrationProgress: String = "Checking for migration..."
    
    var body: some Scene {
        WindowGroup {
            Group {
                /*
                if basicDataReady {
                    ContentView()
                        .environment(\.managedObjectContext, persistenceController.container.viewContext)
                        .environmentObject(cacheManager)
                        .environmentObject(sharedStatsDataManager)
                        .environmentObject(habitManager)
                        .environmentObject(statsSummaryManager)
                        .overlay(
                            // Show subtle loading indicator for background tasks
                            fullDataReady ? nil : ProgressiveLoadingOverlay()
                        )
                } else {
                    // Show a launch screen while initializing
                    OptimizedLaunchScreenView(migrationProgress: migrationProgress)
                        .task {
                            //await initializeAppOptimized()
                            //await performDayKeyMigrationIfNeeded()
                            //await remigrateTotalCompletions()
                        }
                    
                }
                 */
                
                ContentView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .environmentObject(cacheManager)
                    .environmentObject(sharedStatsDataManager)
                    .environmentObject(habitManager)
                    .environmentObject(statsSummaryManager)
                 
            }
        }
    }
    
    private func remigrateTotalCompletions() async {
        await MainActor.run {
            migrationProgress = "Recalculating total completions..."
        }
        
        let context = persistenceController.container.viewContext
        
        do {
            print("🔄 Starting total completions RE-migration...")
            
            // Fetch ALL habits (don't filter by totalCompletions = 0)
            let fetchRequest: NSFetchRequest<Habit> = Habit.fetchRequest()
            
            let allHabits = try await context.perform {
                try context.fetch(fetchRequest)
            }
            
            print("📊 Re-migrating total completions for \(allHabits.count) habits")
            
            var correctedCount = 0
            var totalRecalculated = 0
            
            for (index, habit) in allHabits.enumerated() {
                // Update progress
                await MainActor.run {
                    migrationProgress = "Recalculating habit \(index + 1) of \(allHabits.count)..."
                }
                
                // Store old value for comparison
                let oldTotal = habit.totalCompletions
                
                // Calculate ACTUAL total completions by counting completed entries
                let actualTotal = await Task.detached {
                    guard let completions = habit.completion as? Set<Completion> else { return 0 }
                    return completions.filter { completion in
                        completion.completed == true
                    }.count
                }.value
                
                // Update the habit if values differ
                await context.perform {
                    if Int32(actualTotal) != habit.totalCompletions {
                        print("🔧 Correcting '\(habit.name ?? "Unknown")': \(habit.totalCompletions) → \(actualTotal)")
                        correctedCount += 1
                    } else {
                        print("✅ '\(habit.name ?? "Unknown")': \(actualTotal) (already correct)")
                    }
                    
                    // Always set to calculated value to ensure consistency
                    habit.totalCompletions = Int32(actualTotal)
                    totalRecalculated += 1
                }
            }
            
            // Save all changes
            try await context.perform {
                try context.save()
            }
            
            print("🎉 Total completions re-migration completed!")
            print("📊 Recalculated: \(totalRecalculated) habits")
            print("🔧 Corrected: \(correctedCount) habits had incorrect values")
            
            await MainActor.run {
                migrationProgress = "Migration completed!"
            }
            
        } catch {
            print("❌ Total completions re-migration failed: \(error)")
            await MainActor.run {
                migrationProgress = "Migration failed, continuing..."
            }
        }
    }
    func migrateAllHabitsToRepetitions(context: NSManagedObjectContext) async {
        await context.perform {
            let fetchRequest: NSFetchRequest<RepeatPattern> = RepeatPattern.fetchRequest()
            
            do {
                let patterns = try context.fetch(fetchRequest)
                
                for pattern in patterns {
                    // Set all existing habits to repetition tracking type
                    if pattern.trackingType == nil || pattern.trackingType!.isEmpty {
                        pattern.trackingType = "repetitions"
                    }
                }
                
                try context.save()
                print("Migration completed: Set \(patterns.count) patterns to repetition tracking")
                
            } catch {
                print("Migration failed: \(error)")
            }
        }
    }
    private func performDayKeyMigrationIfNeeded() async {
            let context = persistenceController.container.viewContext
            
            if DayKeyMigration.isMigrationNeeded(in: context) {
                do {
                    try await DayKeyMigration.backfillDayKeys(in: context)
                } catch {
                    print("Failed to migrate dayKeys: \(error)")
                }
            }
        }
    // MARK: - 🆕 Best Streak Migration Function
    
    private func migrateExistingHabitsForBestStreak() async {
        await MainActor.run {
            migrationProgress = "Migrating best streaks..."
        }
        
        let context = persistenceController.container.viewContext
        
        do {
            print("🔄 Starting best streak migration...")
            
            // Check if migration is needed by looking for habits with bestStreakEver = 0
            let fetchRequest: NSFetchRequest<Habit> = Habit.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "bestStreakEver == 0")
            
            let habitsNeedingMigration = try await context.perform {
                try context.fetch(fetchRequest)
            }
            
            if habitsNeedingMigration.isEmpty {
                print("✅ No migration needed - all habits already have best streaks")
                await MainActor.run {
                    migrationCompleted = true
                }
                return
            }
            
            print("📊 Found \(habitsNeedingMigration.count) habits needing migration")
            
            // Fetch all habits for migration
            let allHabitsRequest: NSFetchRequest<Habit> = Habit.fetchRequest()
            let allHabits = try await context.perform {
                try context.fetch(allHabitsRequest)
            }
            
            var migratedCount = 0
            let totalCount = allHabits.count
            
            for (index, habit) in allHabits.enumerated() {
                // Update progress
                await MainActor.run {
                    migrationProgress = "Migrating habit \(index + 1) of \(totalCount)..."
                }
                
                // Calculate best streak using the habit's optimized method
                let longestStreak = await Task.detached {
                    return habit.calculateLongestStreak()
                }.value
                
                // Update the habit
                await context.perform {
                    habit.bestStreakEver = Int32(longestStreak)
                }
                
                migratedCount += 1
                print("✅ Migrated '\(habit.name ?? "Unknown")' - Best streak: \(longestStreak)")
            }
            
            // Save all changes
            try await context.perform {
                try context.save()
            }
            
            print("🎉 Best streak migration completed successfully!")
            print("💾 Migrated \(migratedCount) out of \(totalCount) habits")
            
            await MainActor.run {
                migrationCompleted = true
            }
            
        } catch {
            print("❌ Best streak migration failed: \(error)")
            // Don't block app launch if migration fails
            await MainActor.run {
                migrationCompleted = true
                migrationProgress = "Migration failed, continuing..."
            }
        }
    }
    
    private func migrateTotalCompletions() async {
        await MainActor.run {
            migrationProgress = "Migrating total completions..."
        }
        
        let context = persistenceController.container.viewContext
        
        do {
            print("🔄 Starting total completions migration...")
            
            // ✅ Check if migration is needed by looking for habits with totalCompletions = 0
            let fetchRequest: NSFetchRequest<Habit> = Habit.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "totalCompletions == 0")
            
            let habitsNeedingMigration = try await context.perform {
                try context.fetch(fetchRequest)
            }
            
            if habitsNeedingMigration.isEmpty {
                print("✅ No total completions migration needed - all habits already have totals")
                return
            }
            
            print("📊 Found \(habitsNeedingMigration.count) habits needing total completions migration")
            
            var migratedCount = 0
            
            for (index, habit) in habitsNeedingMigration.enumerated() {
                // Update progress
                await MainActor.run {
                    migrationProgress = "Migrating completions \(index + 1) of \(habitsNeedingMigration.count)..."
                }
                
                // ⚠️ ONLY calculate during migration - this is the LAST time we do this!
                let totalCompletions = await Task.detached {
                    guard let completions = habit.completion as? Set<Completion> else { return 0 }
                    return completions.filter { $0.completed }.count
                }.value
                
                // Update the habit with cached value
                await context.perform {
                    habit.totalCompletions = Int32(totalCompletions)
                }
                
                migratedCount += 1
                print("✅ Migrated '\(habit.name ?? "Unknown")' - Total completions: \(totalCompletions)")
            }
            
            // Save all changes
            try await context.perform {
                try context.save()
            }
            
            print("🎉 Total completions migration completed successfully!")
            print("💾 Migrated \(migratedCount) out of \(habitsNeedingMigration.count) habits")
            
        } catch {
            print("❌ Total completions migration failed: \(error)")
            // Don't block app launch if migration fails
        }
    }

    // 🆕 UPDATED: initializeAppOptimized function
    // REPLACE the existing initializeAppOptimized function with this:

    private func initializeAppOptimized() async {
        await Task.detached(priority: .high) { // High priority for faster loading
            let context = persistenceController.container.viewContext
            
            // Phase 1: Run migrations first if needed
            //await migrateTotalCompletions() // 🆕 NEW - Add this line
            //await migrateExistingHabitsForBestStreak()
            
            await MainActor.run {
                migrationCompleted = true
            }
            // Phase 1: Run migrations first if needed
                    await MainActor.run {
                        migrationProgress = "Migrating tracking types..."
                    }
                    
                    // Run the migration synchronously within the task
                    await Task { @MainActor in
                        await migrateAllHabitsToRepetitions(context: context)
                    }.value
            // Phase 2: Load critical data only (show app ASAP)
            await MainActor.run {
                migrationProgress = "Loading habits..."
                habitManager.preloadHabits(context: context)
                basicDataReady = true // ✅ App becomes interactive here
            }
            
            // Phase 3: Load everything else in parallel (background)
            async let statsDataTask = Task.detached(priority: .userInitiated) {
                await MainActor.run {
                    migrationProgress = "Loading stats data..."
                    sharedStatsDataManager.loadInitialData()
                    print("🔄 Preloading StatsView data...")
                }
                await sharedStatsDataManager.refreshAllData()
                print("✅ StatsView data preloaded and ready")
            }
            
            async let summaryDataTask = Task.detached(priority: .utility) {
                await MainActor.run {
                    migrationProgress = "Loading summary data..."
                    statsSummaryManager.preloadSummaryData(habits: habitManager.habits)
                    print("✅ StatsSummaryView data preloaded and ready")
                }
            }
            
            async let cacheTask = Task.detached(priority: .utility) {
                await MainActor.run {
                    migrationProgress = "Loading calendar cache..."
                    print("🔄 Preloading calendar cache for last 3 months...")
                    cacheManager.preloadLastMonths(3, habits: habitManager.habits)
                    print("✅ Calendar cache preloaded and ready")
                }
            }
            
            // Wait for all parallel tasks to complete
            await statsDataTask.value
            await summaryDataTask.value
            await cacheTask.value
            
            await MainActor.run {
                fullDataReady = true
                migrationProgress = "Ready!"
            }
        }.value
    }
   
}

// MARK: - Optimized Launch Screen with Migration Progress
struct OptimizedLaunchScreenView: View {
    let migrationProgress: String
    @State private var isAnimating = false
    @State private var loadingProgress: CGFloat = 0
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [
                    colorScheme == .dark ? Color.black : Color.white,
                    colorScheme == .dark ? Color.gray.opacity(0.1) : Color.gray.opacity(0.05)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // App icon/logo
                VStack(spacing: 15) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .purple]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(isAnimating ? 1.05 : 0.95) // Subtle animation
                        .rotationEffect(.degrees(isAnimating ? 5 : -5)) // Gentle rotation
                    
                    Text("Habital")
                        .font(.largeTitle)
                        .fontWeight(.ultraLight)
                        .foregroundColor(.primary)
                        .opacity(isAnimating ? 1 : 0.8)
                }
                
                // Loading indicator
                VStack(spacing: 10) {
                    Text(migrationProgress)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .opacity(isAnimating ? 1 : 0)
                        .animation(.easeInOut(duration: 0.3), value: migrationProgress)
                    
                    // Progress bar
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 120, height: 3)
                        
                        Capsule()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [.blue, .purple]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 120 * loadingProgress, height: 3)
                    }
                }
            }
        }
        .onAppear {
            // Faster, subtler animations
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
            
            // Animate loading progress based on migration progress
            animateProgressBasedOnText()
        }
        .onChange(of: migrationProgress) { _, _ in
            animateProgressBasedOnText()
        }
    }
    
    private func animateProgressBasedOnText() {
        let progress: CGFloat
        
        switch migrationProgress {
        case let text where text.contains("Checking"):
            progress = 0.1
        case let text where text.contains("Migrating"):
            progress = 0.4
        case let text where text.contains("Loading habits"):
            progress = 0.6
        case let text where text.contains("Loading stats"):
            progress = 0.8
        case let text where text.contains("Ready"):
            progress = 1.0
        default:
            progress = 0.3
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            loadingProgress = progress
        }
    }
}

// MARK: - Progressive Loading Overlay (Minimal interference)
struct ProgressiveLoadingOverlay: View {
    @State private var opacity: Double = 0.4
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                HStack(spacing: 6) {
                    ProgressView()
                        .scaleEffect(0.5)
                    Text("Finishing up...")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                )
                .opacity(opacity)
                .padding()
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                opacity = 0.2
            }
        }
    }
}

// MARK: - Stats Summary Data Manager with Best Streak Support
@MainActor
class StatsSummaryDataManager: ObservableObject {
    @Published var isDataReady: Bool = false
    @Published var totalCompletions: Int = 0
    @Published var bestHistoricalStreak: (Habit, Int)?
    @Published var bestCurrentStreak: (Habit, Int)?
    @Published var bestStreakEver: (Habit, Int)? // 🆕 NEW
    @Published var averageConsistency: Double = 0.0
    @Published var totalGoodHabits: Int = 0
    @Published var totalBadHabits: Int = 0
    
    // Cache for expensive calculations
    private var consistencyCache: [UUID: Double] = [:]
    private var streakCache: [UUID: StreakData] = [:]
    private var lastRefreshDate: Date = Date.distantPast
    
    // StreakManager instance
    private var streakManager: StreakManager?
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
        self.streakManager = StreakManager(context: context)
    }
    
    // Default initializer for @StateObject usage
    convenience init() {
        // Use shared persistence controller context as default
        self.init(context: PersistenceController.shared.container.viewContext)
    }
    
    func preloadSummaryData(habits: [Habit]) {
        Task {
            await refreshData(habits: habits)
        }
    }
    
    func refreshData(habits: [Habit]) async {
        guard !habits.isEmpty else {
            resetData()
            return
        }
        
        let currentDate = Date()
        
        // Skip refresh if data is recent (within 2 minutes)
        if currentDate.timeIntervalSince(lastRefreshDate) < 120 && isDataReady {
            return
        }
        
        // Calculate total completions (this is fast)
        let completions = habits.reduce(0) { total, habit in
            total + habit.getTotalCompletionCount()
        }
        
        await MainActor.run {
            totalCompletions = completions
            totalGoodHabits = habits.filter { !$0.isBadHabit }.count
            totalBadHabits = habits.filter { $0.isBadHabit }.count
        }
        
        // Use StreakManager for optimized streak calculations
        await loadStreaksWithStreakManager(habits: habits)
        
        await MainActor.run {
            lastRefreshDate = currentDate
            isDataReady = true
        }
    }
    
    // MARK: - StreakManager Integration with Best Streak Support
    
    private func loadStreaksWithStreakManager(habits: [Habit]) async {
        guard let streakManager = streakManager else {
            // Fallback to old method if StreakManager is unavailable
            await loadStreaksClassic(habits: habits)
            return
        }
        
        do {
            // Preload all streak data for better performance
            try await streakManager.preloadStreaksForHabits(habits)
            
            var bestCurrent: (Habit, Int)?
            var bestHistorical: (Habit, Int)?
            var bestEver: (Habit, Int)? // 🆕 NEW
            
            // Process each habit's streak data
            for habit in habits {
                guard let habitID = habit.id else { continue }
                
                let streakData = try await streakManager.getCurrentStreak(for: habit)
                streakCache[habitID] = streakData
                
                // Find best current streak
                if let current = bestCurrent {
                    if streakData.currentStreak > current.1 {
                        bestCurrent = (habit, streakData.currentStreak)
                    }
                } else {
                    bestCurrent = (habit, streakData.currentStreak)
                }
                
                // Find best historical streak
                if let historical = bestHistorical {
                    if streakData.longestStreak > historical.1 {
                        bestHistorical = (habit, streakData.longestStreak)
                    }
                } else {
                    bestHistorical = (habit, streakData.longestStreak)
                }
                
                // 🆕 NEW: Find best streak ever
                if let ever = bestEver {
                    if streakData.bestStreakEver > ever.1 {
                        bestEver = (habit, streakData.bestStreakEver)
                    }
                } else {
                    bestEver = (habit, streakData.bestStreakEver)
                }
            }
            
            await MainActor.run {
                self.bestCurrentStreak = bestCurrent
                self.bestHistoricalStreak = bestHistorical
                self.bestStreakEver = bestEver // 🆕 NEW
            }
            
        } catch {
            print("Error loading streaks with StreakManager: \(error)")
            // Fallback to classic method
            await loadStreaksClassic(habits: habits)
        }
    }
    
    // MARK: - Fallback Classic Streak Loading with Best Streak Support
    
    private func loadStreaksClassic(habits: [Habit]) async {
        let currentDate = Date()
        
        var bestHistorical: (Habit, Int)?
        var bestCurrent: (Habit, Int)?
        var bestEver: (Habit, Int)? // 🆕 NEW
        
        for habit in habits {
            guard let habitID = habit.id else { continue }
            
            // Calculate streaks using classic methods
            let historicalStreak = habit.calculateLongestStreak()
            let currentStreak = habit.calculateStreak(upTo: currentDate)
            let bestStreakEver = Int(habit.bestStreakEver) // 🆕 NEW
            
            // Cache the results as StreakData
            let streakData = StreakData(
                currentStreak: currentStreak,
                longestStreak: historicalStreak,
                bestStreakEver: bestStreakEver, // 🆕 NEW
                startDate: Date(), // Not calculated in classic method
                lastActiveDate: nil, // Not calculated in classic method
                isActive: currentStreak > 0
            )
            streakCache[habitID] = streakData
            
            // Find best historical streak
            if let current = bestHistorical {
                if historicalStreak > current.1 {
                    bestHistorical = (habit, historicalStreak)
                }
            } else {
                bestHistorical = (habit, historicalStreak)
            }
            
            // Find best current streak
            if let current = bestCurrent {
                if currentStreak > current.1 {
                    bestCurrent = (habit, currentStreak)
                }
            } else {
                bestCurrent = (habit, currentStreak)
            }
            
            // 🆕 NEW: Find best streak ever
            if let ever = bestEver {
                if bestStreakEver > ever.1 {
                    bestEver = (habit, bestStreakEver)
                }
            } else {
                bestEver = (habit, bestStreakEver)
            }
        }
        
        await MainActor.run {
            self.bestHistoricalStreak = bestHistorical
            self.bestCurrentStreak = bestCurrent
            self.bestStreakEver = bestEver // 🆕 NEW
        }
    }
    
    // MARK: - Cache Access Methods
    
    func getCachedStreakData(for habitID: UUID) -> StreakData? {
        return streakCache[habitID]
    }
    
    func getCachedCurrentStreak(for habitID: UUID) -> Int? {
        return streakCache[habitID]?.currentStreak
    }
    
    func getCachedHistoricalStreak(for habitID: UUID) -> Int? {
        return streakCache[habitID]?.longestStreak
    }
    
    func getCachedBestStreakEver(for habitID: UUID) -> Int? { // 🆕 NEW
        return streakCache[habitID]?.bestStreakEver
    }
    
    func getCachedConsistency(for habitID: UUID) -> Double? {
        return consistencyCache[habitID]
    }
    
    // MARK: - Utility Methods
    
    private func resetData() {
        totalCompletions = 0
        bestHistoricalStreak = nil
        bestCurrentStreak = nil
        bestStreakEver = nil // 🆕 NEW
        averageConsistency = 0.0
        totalGoodHabits = 0
        totalBadHabits = 0
        isDataReady = false
        
        // Clear caches
        consistencyCache.removeAll()
        streakCache.removeAll()
    }
    
    // MARK: - Public Interface for Individual Habit Updates
    
    func updateHabitStreak(_ habit: Habit) async {
        guard let habitID = habit.id,
              let streakManager = streakManager else { return }
        
        do {
            let streakData = try await streakManager.getCurrentStreak(for: habit)
            
            await MainActor.run {
                streakCache[habitID] = streakData
            }
            
            // Check if this habit now has the best streak
            await checkForNewBestStreaks(updatedHabit: habit, streakData: streakData)
            
        } catch {
            print("Error updating streak for habit \(habit.name ?? "Unknown"): \(error)")
        }
    }
    
    private func checkForNewBestStreaks(updatedHabit: Habit, streakData: StreakData) async {
        await MainActor.run {
            // Check if this is now the best current streak
            if let current = bestCurrentStreak {
                if streakData.currentStreak > current.1 {
                    bestCurrentStreak = (updatedHabit, streakData.currentStreak)
                }
            } else {
                bestCurrentStreak = (updatedHabit, streakData.currentStreak)
            }
            
            // Check if this is now the best historical streak
            if let historical = bestHistoricalStreak {
                if streakData.longestStreak > historical.1 {
                    bestHistoricalStreak = (updatedHabit, streakData.longestStreak)
                }
            } else {
                bestHistoricalStreak = (updatedHabit, streakData.longestStreak)
            }
            
            // 🆕 NEW: Check if this is now the best streak ever
            if let ever = bestStreakEver {
                if streakData.bestStreakEver > ever.1 {
                    bestStreakEver = (updatedHabit, streakData.bestStreakEver)
                }
            } else {
                bestStreakEver = (updatedHabit, streakData.bestStreakEver)
            }
        }
    }
    
    // MARK: - Cache Invalidation
    
    func invalidateCache() async {
        await MainActor.run {
            isDataReady = false
            lastRefreshDate = Date.distantPast
        }
        
        // Invalidate StreakManager cache
        if let streakManager = streakManager {
            do {
                try await streakManager.invalidateAllStreakCaches()
            } catch {
                print("Error invalidating StreakManager cache: \(error)")
            }
        }
    }
    
    func invalidateCacheForHabit(_ habit: Habit) async {
        guard let habitID = habit.id else { return }
        
        await MainActor.run {
            consistencyCache.removeValue(forKey: habitID)
            streakCache.removeValue(forKey: habitID)
        }
        
        // Invalidate specific habit in StreakManager
        if let streakManager = streakManager {
            do {
                try await streakManager.invalidateCache(for: habit)
            } catch {
                print("Error invalidating cache for habit \(habit.name ?? "Unknown"): \(error)")
            }
        }
    }
}

// MARK: - Enhanced Habit Preload Manager (Unchanged)
@MainActor
class HabitPreloadManager: ObservableObject {
    @Published var currentListIndex: Int = 0
    @Published var habits: [Habit] = []
    @Published var habitLists: [HabitList] = []
    @Published var isLoaded = false
    
    @Published var earliestStartDate: Date = Date()
    
    private var earliestDateCache: [Int: Date] = [:]
    
    // Cache for performance
    private var habitsByList: [Int: [Habit]] = [:]
    private var lastUpdateTime = Date()
    
    private var filteredEarliestStartDate: Date {
        let filteredHabits = getHabitsForList(currentListIndex)
        return filteredHabits.compactMap { $0.startDate }.min() ?? Date()
    }
    
    func preloadHabits(context: NSManagedObjectContext) {
        // Fetch all habits
        let habitRequest = NSFetchRequest<Habit>(entityName: "Habit")
        habitRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Habit.order, ascending: true)]
        
        // Fetch all habit lists
        let listRequest = NSFetchRequest<HabitList>(entityName: "HabitList")
        listRequest.sortDescriptors = [NSSortDescriptor(keyPath: \HabitList.order, ascending: true)]
        
        do {
            habits = try context.fetch(habitRequest)
            habitLists = try context.fetch(listRequest)
            
            earliestStartDate = habits.compactMap { $0.startDate }.min() ?? Date()
            
            // Build the cache for filtered habits
            buildHabitsByListCache()
            
            isLoaded = true
            lastUpdateTime = Date()
            
            print("✅ Preloaded \(habits.count) habits and \(habitLists.count) lists")
        } catch {
            print("❌ Error preloading habits: \(error)")
        }
    }
    
    func getCachedEarliestDate(_ listIndex: Int) -> Date {
        // Check cache first
        if let cachedDate = earliestDateCache[listIndex] {
            return cachedDate
        }
        
        // Calculate and cache using your existing getHabitsForList method
        let habits = getHabitsForList(listIndex)
        let earliestDate = habits.compactMap { $0.startDate }.min() ?? Date()
        earliestDateCache[listIndex] = earliestDate
        
        return earliestDate
    }
    
    private func buildHabitsByListCache() {
        habitsByList.removeAll()
        earliestDateCache.removeAll()
        
        // All habits (index 0)
        let allActiveHabits = habits.filter { !$0.isArchived }
        habitsByList[0] = allActiveHabits
        earliestDateCache[0] = allActiveHabits.compactMap { $0.startDate }.min() ?? Date()
        
        // Habits by specific lists
        for (index, list) in habitLists.enumerated() {
            let listIndex = index + 1
            let listHabits = habits.filter { $0.habitList == list && !$0.isArchived }
            habitsByList[listIndex] = listHabits
            earliestDateCache[listIndex] = listHabits.compactMap { $0.startDate }.min() ?? Date()
        }
        
        print("✅ Built cache for \(habitsByList.count) lists with earliest dates")
    }
    
    // Get habits for a specific list index
    func getHabitsForList(_ listIndex: Int) -> [Habit] {
        // Return cached result if available and recent
        if Date().timeIntervalSince(lastUpdateTime) < 5.0, // 5 second cache
           let cachedHabits = habitsByList[listIndex] {
            return cachedHabits
        }
        
        // Fallback to real-time filtering
        if listIndex == 0 {
            return habits.filter { !$0.isArchived }
        } else if listIndex <= habitLists.count {
            let selectedList = habitLists[listIndex - 1]
            return habits.filter { $0.habitList == selectedList && !$0.isArchived }
        }
        
        return []
    }
    
    // Refresh data when needed
    func refresh(context: NSManagedObjectContext) {
        preloadHabits(context: context)
    }
    
    func isDateBeforeEarliest(_ date: Date) -> Bool {
        guard isLoaded else { return false }
        
        let calendar = Calendar.current
        let normalizedDate = calendar.startOfDay(for: date)
        let normalizedEarliest = calendar.startOfDay(for: filteredEarliestStartDate)
        return normalizedDate < normalizedEarliest
    }
    
    // Check if a week has ANY valid days (with safety checks)
    func weekHasValidDays(_ week: Week) -> Bool {
        guard isLoaded, !week.days.isEmpty else { return true } // Safety: allow if not loaded or empty
        
        return week.days.contains { !isDateBeforeEarliest($0) }
    }
    
    // Validate if navigation to a specific date should be allowed (with safety checks)
    func canNavigateToDate(_ date: Date) -> Bool {
        guard isLoaded else { return true }
        
        let calendar = Calendar.current
        let normalizedDate = calendar.startOfDay(for: date)
        let normalizedEarliest = calendar.startOfDay(for: filteredEarliestStartDate)
        
        return normalizedDate >= normalizedEarliest
    }
    
    // Get the earliest valid week (with safety checks)
    func getEarliestValidWeek() -> Week {
        guard isLoaded else {
            let nearestMonday = Calendar.nearestMonday(from: Date())
            return Week(days: Calendar.currentWeek(from: nearestMonday), order: .current)
        }
        
        let calendar = Calendar.current
        let nearestMonday = Calendar.nearestMonday(from: filteredEarliestStartDate)
        return Week(days: Calendar.currentWeek(from: nearestMonday), order: .current)
    }
    
    func getEarliestValidMonth() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: filteredEarliestStartDate)
        return calendar.date(from: components) ?? filteredEarliestStartDate
    }
    
    func navigateToEarliestValidDate() -> Date {
        let earliestDate = getEarliestValidDate()
        print("🗓️ Navigating to earliest valid date: \(earliestDate) for list index: \(currentListIndex)")
        return earliestDate
    }
    
    func getEarliestValidDate() -> Date {
        return filteredEarliestStartDate
    }
    
    func monthHasValidDays(_ month: Month) -> Bool {
        guard isLoaded else { return true }
        
        let allDaysInMonth = month.weeks.flatMap(\.days)
        return allDaysInMonth.contains { !isDateBeforeEarliest($0) }
    }
}
