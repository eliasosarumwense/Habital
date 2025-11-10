//
//  HabitOverviewView.swift
//  Habital
//
//  Created by Assistant on 14.08.25.
//  Overview screen displaying all habits in GitHub-style grid view
//

import SwiftUI
import CoreData

// MARK: - Habit Data Cache with Loading State
class HabitOverviewCache: ObservableObject {
    @Published var isLoading = false
    @Published var cachedHabits: [Habit] = []
    
    private var loadingTask: Task<Void, Never>?
    
    func loadHabits(from habits: FetchedResults<Habit>) {
        // Cancel any existing loading task
        loadingTask?.cancel()
        
        // Always show loading when this method is called
        isLoading = true
        
        loadingTask = Task {
            // Cache the habits and do any heavy preprocessing here
            let habitArray = Array(habits)
            
            // Simulate processing time (you can add actual preprocessing here)
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            await MainActor.run {
                if !Task.isCancelled {
                    self.cachedHabits = habitArray
                    withAnimation(.easeInOut(duration: 0.4)) {
                        self.isLoading = false
                    }
                }
            }
        }
    }
    
    func getSortedHabits(sortOption: HabitOverviewSortOption) -> [Habit] {
        switch sortOption {
        case .nameAscending:
            return cachedHabits.sorted { ($0.name ?? "").localizedCaseInsensitiveCompare($1.name ?? "") == .orderedAscending }
        case .nameDescending:
            return cachedHabits.sorted { ($0.name ?? "").localizedCaseInsensitiveCompare($1.name ?? "") == .orderedDescending }
        case .oldestFirst:
            return cachedHabits.sorted { ($0.startDate ?? Date.distantFuture) < ($1.startDate ?? Date.distantFuture) }
        case .newestFirst:
            return cachedHabits.sorted { ($0.startDate ?? Date.distantPast) > ($1.startDate ?? Date.distantPast) }
        }
    }
}



// MARK: - Overview Sorting Options
enum HabitOverviewSortOption: String, CaseIterable {
    case nameAscending = "Name (A-Z)"
    case nameDescending = "Name (Z-A)"
    case oldestFirst = "Oldest First"
    case newestFirst = "Newest First"
    
    var systemImage: String {
        switch self {
        case .nameAscending:
            return "textformat.abc"
        case .nameDescending:
            return "textformat.abc.dottedunderline"
        case .oldestFirst:
            return "calendar.badge.clock"
        case .newestFirst:
            return "calendar.badge.plus"
        }
    }
}

struct HabitOverviewView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var cache = HabitOverviewCache()
    @State private var sortOption: HabitOverviewSortOption = .nameAscending
    @State private var showHeatmapSheet = false
    
    // Dynamic fetch request that updates based on sort option
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Habit.order, ascending: true)],
        predicate: NSPredicate(format: "isArchived == false OR isArchived == nil"),
        animation: .default
    ) private var habits: FetchedResults<Habit>
    
    // Use cached and sorted habits
    private var sortedHabits: [Habit] {
        cache.getSortedHabits(sortOption: sortOption)
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                colorScheme == .dark ? Color.secondary.opacity(0.20) : Color.secondary.opacity(0.24),
                colorScheme == .dark ? Color.secondary.opacity(0.12) : Color.secondary.opacity(0.16),
                colorScheme == .dark ? Color.secondary.opacity(0.08) : Color.secondary.opacity(0.10),
                colorScheme == .dark ? Color(hexString: "0A0A0A") : Color(hexString: "E8E8FF")
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Beautiful Shimmer Components
    @State private var shimmerPhase: CGFloat = 0
    @State private var shimmerOpacity: Double = 0.3
    
    // Proper shimmer effect with gradient animation
    private var shimmerGradient: LinearGradient {
        let shimmerColors = [
            Color.gray.opacity(0.3),
            Color.white.opacity(0.8),
            Color.gray.opacity(0.3)
        ]
        return LinearGradient(
            colors: shimmerColors,
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    // Beautiful shimmering habit grid placeholder
    private var habitShimmerPlaceholder: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header shimmer
            HStack(spacing: 8) {
                // Leading icon shimmer
                Circle()
                    .fill(shimmerGradient)
                    .frame(width: 22, height: 22)
                    .mask(
                        Rectangle()
                            .offset(x: shimmerPhase)
                    )
                
                VStack(alignment: .leading, spacing: 6) {
                    // Habit name shimmer
                    RoundedRectangle(cornerRadius: 4)
                        .fill(shimmerGradient)
                        .frame(width: 160, height: 16)
                        .mask(
                            Rectangle()
                                .offset(x: shimmerPhase)
                        )
                    
                    // Subtitle shimmer
                    RoundedRectangle(cornerRadius: 4)
                        .fill(shimmerGradient)
                        .frame(width: 110, height: 10)
                        .mask(
                            Rectangle()
                                .offset(x: shimmerPhase)
                        )
                }
                
                Spacer()
                
                // Progress circle shimmer
                Circle()
                    .stroke(shimmerGradient, lineWidth: 3)
                    .frame(width: 28, height: 28)
                    .mask(
                        Rectangle()
                            .offset(x: shimmerPhase)
                    )
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 8)
            
            // Main grid area shimmer
            RoundedRectangle(cornerRadius: 8)
                .fill(shimmerGradient)
                .frame(maxWidth: .infinity)
                .frame(height: 120)
                .mask(
                    Rectangle()
                        .offset(x: shimmerPhase)
                )
                .padding(.horizontal, 6)
                .padding(.bottom, 6)
        }
        .padding(7)
        .sheetGlassBackground()
        .frame(maxWidth: .infinity)
        .onAppear {
            startShimmerAnimation()
        }
    }
    
    private func startShimmerAnimation() {
        shimmerPhase = -400
        withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
            shimmerPhase = 400
        }
    }
    
    // Very simple placeholder matching HabitGitHubGrid overall layout:
    // - Title line shimmer
    // - One big rectangle where the grid would be
    private var habitGitHubGridShimmer: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header placeholder (approximate height similar to real header)
            HStack(spacing: 8) {
                // Simulated small leading icon
                Circle()
                    .fill(Color.gray.opacity(shimmerOpacity * 0.6))
                    .frame(width: 22, height: 22)
                
                VStack(alignment: .leading, spacing: 6) {
                    // Habit name placeholder
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(shimmerOpacity))
                        .frame(width: 160, height: 16)
                    
                    // Small subtitle line
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(shimmerOpacity * 0.8))
                        .frame(width: 110, height: 10)
                }
                
                Spacer()
                
                // Small circular progress placeholder
                Circle()
                    .stroke(Color.gray.opacity(shimmerOpacity * 0.6), lineWidth: 3)
                    .frame(width: 28, height: 28)
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 8)
            
            // Big rectangle placeholder where the grid normally is.
            // Height approximates the grid’s 7 rows + header row + paddings.
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(shimmerOpacity * 0.5))
                .frame(maxWidth: .infinity)
                .frame(height: 120) // approximate grid area height
                .padding(.horizontal, 6) // similar inner padding as real grid container
                .padding(.bottom, 6)
        }
        .padding(7)
        .sheetGlassBackground()
        .frame(maxWidth: .infinity)
        .onAppear {
            startSimpleShimmer()
        }
    }
    
    // Simple shimmer animation
    private func startSimpleShimmer() {
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            shimmerOpacity = 0.6
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundGradient
                
                if !cache.isLoading {
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(sortedHabits, id: \.self) { habit in
                                HabitGitHubGrid(habit: habit, showHeader: true)
                                    .padding(.horizontal, 16)
                            }
                            Spacer(minLength: 50)
                        }
                        .padding(.top, 20)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 10) {
                            // Show exactly 3 beautiful shimmer placeholders while loading
                            ForEach(0..<3, id: \.self) { _ in
                                habitShimmerPlaceholder
                                    .padding(.horizontal, 16)
                            }
                            
                            Spacer(minLength: 50)
                        }
                        .padding(.top, 20)
                    }
                }
            }
            .navigationTitle("Overview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showHeatmapSheet = true
                    } label: {
                        Image(systemName: "chart.xyaxis.line")
                            .foregroundColor(.accentColor)
                            .font(.system(size: 16, weight: .medium))
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if #available(iOS 18.0, *) {
                        Menu {
                            ForEach(HabitOverviewSortOption.allCases, id: \.self) { option in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        sortOption = option
                                    }
                                } label: {
                                    HStack {
                                        Text(option.rawValue)
                                        Spacer()
                                        if sortOption == option {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.accentColor)
                                        }
                                    }
                                }
                            }
                        } label: {
                            Label("Sort", systemImage: "arrow.up.arrow.down")
                                .symbolVariant(sortOption == .nameAscending || sortOption == .oldestFirst ? .none : .fill)
                        }
                        .menuStyle(.borderlessButton)
                    } else {
                        Menu {
                            ForEach(HabitOverviewSortOption.allCases, id: \.self) { option in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        sortOption = option
                                    }
                                } label: {
                                    Label(option.rawValue, systemImage: option.systemImage)
                                        .foregroundColor(sortOption == option ? .accentColor : .primary)
                                }
                            }
                        } label: {
                            Image(systemName: "arrow.up.arrow.down")
                                .foregroundColor(.accentColor)
                                .font(.system(size: 16, weight: .medium))
                        }
                    }
                }
            }
        }
        .onAppear {
            fixExistingHabitsSync()
            cache.loadHabits(from: habits)
        }
        .sheet(isPresented: $showHeatmapSheet) {
            HeatmapSheetView(habits: cache.cachedHabits)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
    
    /// Fix existing habits that might have isArchived as nil (synchronous version)
    private func fixExistingHabitsSync() {
        let request: NSFetchRequest<Habit> = Habit.fetchRequest()
        request.predicate = NSPredicate(format: "isArchived == nil")
        
        do {
            let habitsToFix = try viewContext.fetch(request)
            
            for habit in habitsToFix {
                habit.isArchived = false
            }
            
            if !habitsToFix.isEmpty {
                try viewContext.save()
            }
        } catch {
            print("Error fixing habits: \(error)")
        }
    }
}

// MARK: - Heatmap Sheet View
struct HeatmapSheetView: View {
    let habits: [Habit]
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    private let daysOfWeek = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    private let dayLabels = ["", "Tue", "", "Thu", "", "Sat", ""]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("All Habits Heatmap")
                            .font(.customFont("Lexend", .bold, 24))
                        
                        Text("Combined activity view across all your habits")
                            .font(.customFont("Lexend", .regular, 14))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    
                    // Combined Heatmap Grid - Exact same structure as HabitGitHubGrid
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 2) {
                            VStack(spacing: 2) {
                                Color.clear
                                    .frame(width: 25, height: 12)
                                
                                ForEach(0..<7, id: \.self) { dayIndex in
                                    Text(dayLabels[dayIndex])
                                        .font(.customFont("Lexend", .regular, 9))
                                        .foregroundColor(.secondary)
                                        .frame(width: 25, height: 12, alignment: .trailing)
                                }
                            }
                            .padding(.trailing, 3)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                VStack(spacing: 2) {
                                    // Month header row
                                    HStack(spacing: 2) {
                                        ForEach(0..<52, id: \.self) { weekIndex in
                                            Text(getMonthLabel(for: weekIndex))
                                                .font(.customFont("Lexend", .medium, 6.5))
                                                .foregroundColor(.secondary)
                                                .frame(width: 12, height: 12, alignment: .center)
                                                .lineLimit(1)
                                                .truncationMode(.tail)
                                        }
                                    }
                                    
                                    // Data grid
                                    ForEach(0..<7, id: \.self) { dayOfWeekIndex in
                                        HStack(spacing: 2) {
                                            ForEach(0..<52, id: \.self) { weekIndex in
                                                let activityLevel = getActivityLevel(dayOfWeek: dayOfWeekIndex, weekIndex: weekIndex)
                                                
                                                RoundedRectangle(cornerRadius: 5)
                                                    .fill(getHeatmapColor(for: activityLevel))
                                                    .frame(width: 12, height: 12)
                                            }
                                        }
                                    }
                                }
                                .padding(.vertical, 6)
                                .padding(.leading, 2)
                                .padding(.trailing, 6)
                            }
                            .defaultScrollAnchor(.trailing)
                        }
                        .offset(x: -5)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 5)
                    }
                    .padding(7)
                    .sheetGlassBackground()
                    .padding(.horizontal, 16)
                    
                    // Legend
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Activity Level")
                            .font(.customFont("Lexend", .semiBold, 16))
                        
                        HStack(spacing: 4) {
                            Text("Less")
                                .font(.customFont("Lexend", .regular, 11))
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 2) {
                                ForEach(0..<5) { index in
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(getLegendColor(for: index))
                                        .frame(width: 12, height: 12)
                                }
                            }
                            
                            Text("More")
                                .font(.customFont("Lexend", .regular, 11))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(.horizontal, 20)
                    
                    // Stats Summary
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Summary")
                            .font(.customFont("Lexend", .semiBold, 16))
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                            StatCardOverview(title: "Active Habits", value: "\(habits.count)", icon: "list.bullet")
                            StatCardOverview(title: "Total Days", value: getTotalActiveDays(), icon: "calendar")
                            StatCardOverview(title: "Best Streak", value: getBestStreak(), icon: "flame")
                            StatCardOverview(title: "This Week", value: getThisWeekActivity(), icon: "chart.bar")
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 50)
                }
                .padding(.top, 20)
            }
            .navigationTitle("Heatmap")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // Helper functions
    private func getMonthLabel(for weekIndex: Int) -> String {
        let calendar = Calendar.current
        let today = Date()
        
        let todayWeekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (todayWeekday == 1) ? 6 : todayWeekday - 2
        let mondayOfCurrentWeek = calendar.date(byAdding: .day, value: -daysFromMonday, to: today) ?? today
        
        let gridStartWeek = calendar.date(byAdding: .weekOfYear, value: -(52 - 1), to: mondayOfCurrentWeek) ?? mondayOfCurrentWeek
        let gridStartMonday = calendar.startOfDay(for: gridStartWeek)
        
        guard let weekStartDate = calendar.date(byAdding: .day, value: weekIndex * 7, to: gridStartMonday) else { return "" }
        
        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: weekStartDate) else { continue }
            let dayOfMonth = calendar.component(.day, from: date)
            
            if dayOfMonth == 1 {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM"
                return formatter.string(from: date)
            }
        }
        
        return ""
    }
    
    private func getActivityLevel(dayOfWeek: Int, weekIndex: Int) -> Double {
        let calendar = Calendar.current
        let today = Date()
        
        let todayWeekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (todayWeekday == 1) ? 6 : todayWeekday - 2
        let mondayOfCurrentWeek = calendar.date(byAdding: .day, value: -daysFromMonday, to: today) ?? today
        
        let gridStartWeek = calendar.date(byAdding: .weekOfYear, value: -(52 - 1), to: mondayOfCurrentWeek) ?? mondayOfCurrentWeek
        let gridStartMonday = calendar.startOfDay(for: gridStartWeek)
        
        guard let weekStartDate = calendar.date(byAdding: .day, value: weekIndex * 7, to: gridStartMonday),
              let targetDate = calendar.date(byAdding: .day, value: dayOfWeek, to: weekStartDate) else {
            return 0.0
        }
        
        let targetDateNormalized = calendar.startOfDay(for: targetDate)
        let todayNormalized = calendar.startOfDay(for: today)
        
        // Don't show future dates
        if targetDateNormalized > todayNormalized {
            return 0.0
        }
        
        var totalActivity = 0.0
        var activeHabits = 0
        
        for habit in habits {
            guard let habitStartDate = habit.startDate,
                  targetDateNormalized >= calendar.startOfDay(for: habitStartDate) else { continue }
            
            // Check if habit is active on this date
            if HabitUtilities.isHabitActive(habit: habit, on: targetDate) {
                activeHabits += 1
                
                // Check completions for this date
                let dayKey = DayKeyFormatter.localKey(from: targetDate)
                let completions = (habit.completion as? Set<Completion>) ?? []
                let dayCompletions = completions.filter { $0.dayKey == dayKey && $0.completed }
                
                // Calculate completion ratio for this habit on this day
                let requiredRepeats = habit.currentRepeatsPerDay(on: targetDate)
                let completedRepeats = dayCompletions.count
                
                if requiredRepeats > 0 {
                    let ratio = min(1.0, Double(completedRepeats) / Double(requiredRepeats))
                    totalActivity += ratio
                }
            }
        }
        
        // Return average activity across all active habits (0.0 to 1.0)
        return activeHabits > 0 ? totalActivity / Double(activeHabits) : 0.0
    }
    
    private func getHeatmapColor(for activityLevel: Double) -> Color {
        if activityLevel == 0.0 {
            return Color.gray.opacity(0.1)
        }
        
        // Use a blue color scheme for the combined heatmap
        let baseColor = Color.blue
        let opacity = 0.2 + (activityLevel * 0.8) // Range from 0.2 to 1.0
        return baseColor.opacity(opacity)
    }
    
    private func getLegendColor(for index: Int) -> Color {
        switch index {
        case 0: return Color.gray.opacity(0.1)
        case 1: return Color.blue.opacity(0.35)
        case 2: return Color.blue.opacity(0.55)
        case 3: return Color.blue.opacity(0.75)
        case 4: return Color.blue.opacity(1.0)
        default: return Color.gray.opacity(0.1)
        }
    }
    
    private func getTotalActiveDays() -> String {
        var totalDays = 0
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        for habit in habits {
            guard let startDate = habit.startDate else { continue }
            let daysBetween = calendar.dateComponents([.day], from: startDate, to: today).day ?? 0
            totalDays += max(0, daysBetween + 1)
        }
        
        return "\(totalDays)"
    }
    
    private func getBestStreak() -> String {
        var bestStreak = 0
        
        for habit in habits {
            let habitStreak = habit.calculateStreak(upTo: Date())
            bestStreak = max(bestStreak, habitStreak)
        }
        
        return "\(bestStreak)"
    }
    
    private func getThisWeekActivity() -> String {
        let calendar = Calendar.current
        let today = Date()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        
        var completedToday = 0
        var totalToday = 0
        
        for habit in habits {
            if HabitUtilities.isHabitActive(habit: habit, on: today) {
                let dayKey = DayKeyFormatter.localKey(from: today)
                let completions = (habit.completion as? Set<Completion>) ?? []
                let todayCompletions = completions.filter { $0.dayKey == dayKey && $0.completed }
                let requiredRepeats = habit.currentRepeatsPerDay(on: today)
                
                totalToday += requiredRepeats
                completedToday += min(todayCompletions.count, requiredRepeats)
            }
        }
        
        if totalToday == 0 {
            return "0%"
        }
        
        let percentage = Int((Double(completedToday) / Double(totalToday)) * 100)
        return "\(percentage)%"
    }
}

// MARK: - Stat Card Component
struct StatCardOverview: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.accentColor)
                    .font(.system(size: 16, weight: .medium))
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.customFont("Lexend", .bold, 20))
                
                Text(title)
                    .font(.customFont("Lexend", .regular, 12))
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .lightGlassBackground(cornerRadius: 12)
    }
}
