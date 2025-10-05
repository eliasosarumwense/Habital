//
//  HabitStreaksView.swift
//  Habital
//
//  Created by Elias Osarumwense on 23.04.25.
//  🆕 UPDATED: Now uses habit.totalCompletions for performance

import SwiftUI

struct HabitStreaksView: View {
    let habit: Habit
    let date: Date
    let showStreaks: Bool
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var animatedCurrentStreak: Int = 0
    @State private var animatedBestStreakEver: Int = 0 // Only this one!
    @State private var animatedTotalCompletions: Int = 0
    
    // Cached streak data
    @State private var streakData: StreakData?
    @State private var isLoading = true
    
    // Performance optimization: Debounce rapid updates
    @State private var updateTask: Task<Void, Never>?
    
    // Get the habit color
    private var habitColor: Color {
        if let colorData = habit.color,
           let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
            return Color(uiColor)
        }
        return .blue // Default color
    }
    
    var body: some View {
        mainContent
            .task {
                await loadStreakDataOptimized()
            }
            .modifier(NotificationListenerModifier(
                habit: habit,
                loadStreakDataImmediately: loadStreakDataImmediatelyOptimized
            ))
            .modifier(ChangeListenerModifier(
                habit: habit,
                date: date,
                loadStreakDataImmediately: loadStreakDataImmediatelyOptimized
            ))
            .modifier(BestStreakListenerModifier(
                habit: habit,
                loadStreakDataImmediately: loadStreakDataImmediatelyOptimized
            ))
    }
    
    // MARK: - Main Content (3 sections only)
    
    @ViewBuilder
    private var mainContent: some View {
        HStack(spacing: 0) {
            currentStreakSection
            Divider().padding(.vertical, 10)
            bestStreakEverSection // Use habit.bestStreakEver
            Divider().padding(.vertical, 10)
            totalCompletionsSection
        }
        .glassBackground()
    }
    
    @ViewBuilder
    private var currentStreakSection: some View {
        VStack(spacing: 3) {
            Text("Current")
                .font(.customFont("Lexend", .medium, 11))
                .foregroundColor(.secondary)
            
            if isLoading {
                ProgressView()
                    .frame(height: 24)
            } else {
                Text("\(streakData?.currentStreak ?? 0)")
                    .font(.customFont("Lexend", .bold, 22))
                    .foregroundColor(.primary)
                    .contentTransition(.numericText())
                    .animation(.easeOut(duration: 0.3), value: streakData?.currentStreak)
            }
            
            Text((streakData?.currentStreak ?? 0) == 1 ? "day" : "days")
                .font(.customFont("Lexend", .medium, 10))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
    
    // Use habit.bestStreakEver directly from CoreData (always up-to-date)
    @ViewBuilder
    private var bestStreakEverSection: some View {
        VStack(spacing: 3) {
            HStack(spacing: 2) {
                Text("Best Ever")
                    .font(.customFont("Lexend", .medium, 11))
                    .foregroundColor(.secondary)
                
                // 🏆 Trophy icon if current streak equals best ever
                if let streakData = streakData,
                   streakData.currentStreak > 0 &&
                   streakData.currentStreak == Int(habit.bestStreakEver) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.yellow)
                        .opacity(0.8)
                }
            }
            
            if isLoading {
                ProgressView()
                    .frame(height: 24)
            } else {
                Text("\(Int(habit.bestStreakEver))")
                    .font(.customFont("Lexend", .bold, 22))
                    .foregroundColor(Int(habit.bestStreakEver) == streakData?.currentStreak ? habitColor : .primary)
                    .contentTransition(.numericText())
                    .animation(.easeOut(duration: 0.3), value: Int(habit.bestStreakEver))
                    // 🎉 Celebration animation for personal bests
                    .scaleEffect(Int(habit.bestStreakEver) == streakData?.currentStreak &&
                               (streakData?.currentStreak ?? 0) > 0 ? 1.1 : 1.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8),
                              value: Int(habit.bestStreakEver) == streakData?.currentStreak)
            }
            
            Text(Int(habit.bestStreakEver) == 1 ? "day" : "days")
                .font(.customFont("Lexend", .medium, 10))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
    
    @ViewBuilder
    private var totalCompletionsSection: some View {
        VStack(spacing: 3) {
            Text("Total")
                .font(.customFont("Lexend", .medium, 11))
                .foregroundColor(.secondary)
            
            if isLoading {
                ProgressView()
                    .frame(height: 24)
            } else {
                Text("\(animatedTotalCompletions)")
                    .font(.customFont("Lexend", .bold, 22))
                    .foregroundColor(.primary)
                    .contentTransition(.numericText())
                    .animation(.easeOut(duration: 0.3), value: animatedTotalCompletions)
            }
            
            if !habit.isBadHabit {
                Text(animatedTotalCompletions == 1 ? "completion" : "completions")
                    .font(.customFont("Lexend", .medium, 10))
                    .foregroundColor(.secondary)
            } else {
                Text(animatedTotalCompletions == 1 ? "day avoided" : "days avoided")
                    .font(.customFont("Lexend", .medium, 10))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
    
    // MARK: - 🆕 OPTIMIZED: Simplified data loading using cached totalCompletions
    
    private func loadStreakDataOptimized() async {
        updateTask?.cancel()
        
        // 🆕 PERFORMANCE: Only calculate current streak - use cached totalCompletions
        let currentStreak = await calculateCurrentStreak()
        let totalCompletions = Int(habit.totalCompletions) // 🆕 Use cached value!
        
        await MainActor.run {
            withAnimation(.easeOut(duration: 0.3)) {
                self.streakData = StreakData(
                    currentStreak: currentStreak,
                    longestStreak: Int(habit.bestStreakEver), // From CoreData
                    bestStreakEver: Int(habit.bestStreakEver), // From CoreData
                    startDate: habit.startDate ?? Date(),
                    lastActiveDate: nil,
                    isActive: currentStreak > 0
                )
                self.animatedTotalCompletions = totalCompletions
                self.isLoading = false
            }
        }
    }
    
    private func loadStreakDataImmediatelyOptimized() async {
        updateTask?.cancel()
        
        updateTask = Task {
            try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
            
            guard !Task.isCancelled else { return }
            
            // 🆕 PERFORMANCE: Use cached totalCompletions
            let currentStreak = await calculateCurrentStreak()
            let totalCompletions = Int(habit.totalCompletions) // 🆕 Use cached value!
            
            guard !Task.isCancelled else { return }
            
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.4)) {
                    self.streakData = StreakData(
                        currentStreak: currentStreak,
                        longestStreak: Int(habit.bestStreakEver), // From CoreData
                        bestStreakEver: Int(habit.bestStreakEver), // From CoreData
                        startDate: habit.startDate ?? Date(),
                        lastActiveDate: nil,
                        isActive: currentStreak > 0
                    )
                    self.animatedTotalCompletions = totalCompletions
                    self.isLoading = false
                }
            }
        }
        
        await updateTask?.value
    }
    
    // MARK: - 🆕 SIMPLIFIED: Only current streak calculation needed
    
    private func calculateCurrentStreak() async -> Int {
        return await MainActor.run {
            return habit.calculateStreak(upTo: date)
        }
    }
    
    // 🚫 REMOVED: getTotalCompletionsSync() - no longer needed!
    // Now we just use Int(habit.totalCompletions) which is instant ⚡️
}

// MARK: - 🆕 UPDATED: View Modifiers with totalCompletions listener

struct NotificationListenerModifier: ViewModifier {
    let habit: Habit
    let loadStreakDataImmediately: () async -> Void
    
    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("HabitToggled"))) { notification in
                guard let userInfo = notification.userInfo,
                      let habitID = userInfo["habitID"] as? UUID,
                      habitID == habit.id else {
                    return  // Ignore if not for this habit
                }
                
                Task.detached(priority: .userInitiated) {
                    await loadStreakDataImmediately()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("StreakUpdated"))) { notification in
                if let updatedHabit = notification.object as? Habit,
                   updatedHabit.id == habit.id {
                    Task.detached(priority: .userInitiated) {
                        await loadStreakDataImmediately()
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("HabitUIRefreshNeeded"))) { notification in
                if let refreshHabit = notification.object as? Habit,
                   refreshHabit.id == habit.id {
                    Task.detached(priority: .background) {
                        try? await Task.sleep(nanoseconds: 100_000_000)
                        await loadStreakDataImmediately()
                    }
                }
            }
    }
}

struct BestStreakListenerModifier: ViewModifier {
    let habit: Habit
    let loadStreakDataImmediately: () async -> Void
    
    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("BestStreakChanged"))) { notification in
                if let achievementHabit = notification.object as? Habit,
                   achievementHabit.id == habit.id {
                    Task.detached(priority: .userInitiated) {
                        await loadStreakDataImmediately()
                    }
                }
            }
    }
}

struct ChangeListenerModifier: ViewModifier {
    let habit: Habit
    let date: Date
    let loadStreakDataImmediately: () async -> Void
    
    func body(content: Content) -> some View {
        content
            .onChange(of: date) { _, _ in
                Task.detached(priority: .userInitiated) {
                    await loadStreakDataImmediately()
                }
            }
            .onChange(of: habit.completion?.count ?? 0) { _, _ in
                Task.detached(priority: .background) {
                    try? await Task.sleep(nanoseconds: 150_000_000)
                    await loadStreakDataImmediately()
                }
            }
            .onChange(of: habit.lastCompletionDate) { _, _ in
                Task.detached(priority: .background) {
                    try? await Task.sleep(nanoseconds: 100_000_000)
                    await loadStreakDataImmediately()
                }
            }
            // Listen for best streak changes from CoreData
            .onChange(of: habit.bestStreakEver) { _, _ in
                Task.detached(priority: .userInitiated) {
                    await loadStreakDataImmediately()
                }
            }
            // 🆕 NEW: Listen for totalCompletions changes
            .onChange(of: habit.totalCompletions) { _, _ in
                Task.detached(priority: .userInitiated) {
                    await loadStreakDataImmediately()
                }
            }
    }
}
