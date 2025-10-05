//
//  AnimatedCompletedHabitsStack.swift
//  Habital
//
//  Minimal design matching HabitRowView background styling
//

import SwiftUI

struct AnimatedCompletedHabitsStack: View {
    let habits: [Habit]
    let date: Date
    let isHabitCompleted: (Habit) -> Bool
    let toggleCompletion: (Habit) -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var isExpanded = false
    @AppStorage("accentColorIndex") private var accentColorIndex: Int = 0
    
    private var completedHabits: [Habit] {
        return habits.filter { isHabitCompleted($0) }
    }
    
    private var accentColor: Color {
        return ColorPalette.color(at: accentColorIndex)
    }
    
    // Helper function to get habit color
    private func getHabitColor(_ habit: Habit) -> Color {
        if let colorData = habit.color,
           let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
            return Color(uiColor)
        }
        return accentColor
    }
    
    // Calculate how many icons can fit in the header
    private var maxVisibleIcons: Int {
        let screenWidth = UIScreen.main.bounds.width
        let availableWidth = screenWidth - 250
        let iconWidth: CGFloat = 32
        return max(3, min(6, Int(availableWidth / iconWidth)))
    }
    
    private var visibleHabits: [Habit] {
        return Array(completedHabits.prefix(maxVisibleIcons))
    }
    
    private var remainingCount: Int {
        return max(0, completedHabits.count - maxVisibleIcons)
    }
    
    var body: some View {
        if !completedHabits.isEmpty {
            VStack(spacing: 0) {
                // Header section
                headerSection
                
                // Expandable content
                if isExpanded {
                    expandedContent
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        ))
                }
            }
            .background(minimalBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }
    
    // MARK: - Minimal Background (Same as HabitRowView)
    private var minimalBackground: some View {
        ZStack {
            // Simulated soft shadow (dark mode aware)
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    colorScheme == .dark
                        ? Color.black.opacity(0.4) // Darker in dark mode for contrast
                        : Color.black.opacity(0.15) // Softer in light mode
                )
                .blur(radius: 8)   // More blur = softer shadow
                .offset(y: 4)       // Direction of shadow
                .padding(-2)        // Prevent blur cutoff

            // Main background fill - matches HabitRowView active state
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    colorScheme == .dark
                        ? Color(red: 0.11, green: 0.11, blue: 0.12)
                        : Color(red: 0.94, green: 0.94, blue: 0.96)
                )

            // Gradient border
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            accentColor.opacity(colorScheme == .dark ? 0.2 : 0.35),
                            Color.primary.opacity(colorScheme == .dark ? 0.05 : 0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                isExpanded.toggle()
            }
            
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        }) {
            ZStack {
                // Background layer with floating habit icons
                HStack {
                    Spacer()
                    floatingHabitIcons
                        .opacity(isExpanded ? 0 : 1)
                        .animation(.easeInOut(duration: 0.4), value: isExpanded)
                    minimalChevron
                }
                .padding(.horizontal, 20)
                
                // Foreground layer with content
                HStack(spacing: 16) {
                    minimalSuccessIndicator
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Completed")
                            .customFont("Lexend", .semiBold, 18)
                            .foregroundColor(.primary)
                        
                        Text("\(completedHabits.count) habit\(completedHabits.count == 1 ? "" : "s") done")
                            .customFont("Lexend", .medium, 14)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Minimal Success Indicator
    private var minimalSuccessIndicator: some View {
        ZStack {
            // Simple background circle
            Circle()
                .fill(Color.green.opacity(0.15))
                .frame(width: 36, height: 36)
                .overlay(
                    Circle()
                        .stroke(Color.green.opacity(0.3), lineWidth: 2)
                        .scaleEffect(isExpanded ? 1.1 : 1.0)
                        .opacity(isExpanded ? 0.7 : 1.0)
                        .animation(.easeInOut(duration: 0.3), value: isExpanded)
                )
            
            // Checkmark
            Image(systemName: "checkmark")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.green)
                .scaleEffect(isExpanded ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.3), value: isExpanded)
        }
    }
    
    // MARK: - Floating Habit Icons (Minimal Style)
    private var floatingHabitIcons: some View {
        HStack(spacing: -8) {
            ForEach(Array(visibleHabits.enumerated()), id: \.element.objectID) { index, habit in
                MinimalStackedIcon(
                    habit: habit,
                    size: 32,
                    stackIndex: index,
                    accentColor: accentColor
                )
                .zIndex(Double(visibleHabits.count - index))
            }
            
            if remainingCount > 0 {
                ZStack {
                    // Simple counter bubble
                    Circle()
                        .fill(colorScheme == .dark
                              ? Color(UIColor.systemGray6)
                              : Color.white)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Circle()
                                .strokeBorder(accentColor.opacity(0.4), lineWidth: 1.5)
                        )
                        .shadow(color: colorScheme == .dark ? .white.opacity(0.1) : .black.opacity(0.15), radius: 2)
                    
                    Text("+\(remainingCount)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(accentColor)
                }
                .offset(x: -6)
                .zIndex(0)
            }
        }
    }
    
    // MARK: - Minimal Chevron
    private var minimalChevron: some View {
        ZStack {
            // Simple background circle
            Circle()
                .fill(colorScheme == .dark
                      ? Color(UIColor.systemGray6)
                      : Color.white)
                .frame(width: 32, height: 32)
                .overlay(
                    Circle()
                        .strokeBorder(accentColor.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: colorScheme == .dark ? .white.opacity(0.1) : .black.opacity(0.15), radius: 2)
            
            Image(systemName: "chevron.down")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(isExpanded ? accentColor : .secondary)
                .rotationEffect(.degrees(isExpanded ? 180 : 0))
                .animation(.easeInOut(duration: 0.3), value: isExpanded)
        }
    }
    
    // MARK: - Expanded Content
    private var expandedContent: some View {
        VStack(spacing: 0) {
            // Simple divider
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            accentColor.opacity(0.3),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
            
            // Habit list
            LazyVStack(spacing: 6) {
                ForEach(Array(completedHabits.enumerated()), id: \.element.objectID) { index, habit in
                    MinimalCompletedHabitRow(
                        habit: habit,
                        date: date,
                        toggleCompletion: { toggleCompletion(habit) },
                        accentColor: accentColor,
                        index: index
                    )
                    .transition(.opacity)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
    }
}

// MARK: - Minimal Stacked Icon Component
struct MinimalStackedIcon: View {
    let habit: Habit
    let size: CGFloat
    let stackIndex: Int
    let accentColor: Color
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var habitColor: Color {
        if let colorData = habit.color,
           let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
            return Color(uiColor)
        }
        return accentColor
    }
    
    var body: some View {
        ZStack {
            // Simple background matching HabitRowView style
            Circle()
                .fill(colorScheme == .dark
                      ? Color(UIColor.systemGray6)
                      : Color.white)
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .stroke(habitColor.opacity(0.4), lineWidth: 1.5)
                )
                .shadow(color: colorScheme == .dark ? .white.opacity(0.1) : .black.opacity(0.15), radius: 2)
            
            // Icon content
            iconContent
        }
        .scaleEffect(1.0 - (CGFloat(stackIndex) * 0.04))
        .offset(x: CGFloat(stackIndex) * -6)
        .opacity(1.0 - (Double(stackIndex) * 0.08))
    }
    
    @ViewBuilder
    private var iconContent: some View {
        if let iconName = habit.icon, !iconName.isEmpty {
            if iconName.count == 1 || iconName.first?.isEmoji == true {
                Text(iconName)
                    .font(.system(size: size * 0.42, weight: .medium, design: .rounded))
            } else if UIImage(systemName: iconName) != nil {
                Image(systemName: iconName)
                    .font(.system(size: size * 0.35, weight: .medium, design: .rounded))
                    .foregroundColor(habitColor)
            } else {
                Circle()
                    .fill(habitColor)
                    .frame(width: size * 0.28, height: size * 0.28)
            }
        } else {
            Circle()
                .fill(habitColor)
                .frame(width: size * 0.28, height: size * 0.28)
        }
    }
}

// MARK: - Minimal Completed Habit Row
struct MinimalCompletedHabitRow: View {
    let habit: Habit
    let date: Date
    let toggleCompletion: () -> Void
    let accentColor: Color
    let index: Int
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var habitColor: Color {
        if let colorData = habit.color,
           let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
            return Color(uiColor)
        }
        return accentColor
    }
    
    var body: some View {
        HStack(spacing: 14) {
            // Simple habit icon
            ZStack {
                // Background matching HabitRowView icon style
                Circle()
                    .fill(colorScheme == .dark
                          ? Color(UIColor.systemGray6)
                          : Color.white)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle()
                            .stroke(habitColor.opacity(0.4), lineWidth: 1.2)
                    )
                    .shadow(color: colorScheme == .dark ? .white.opacity(0.1) : .black.opacity(0.15), radius: 2)
                
                if let iconName = habit.icon, !iconName.isEmpty {
                    if iconName.count == 1 || iconName.first?.isEmoji == true {
                        Text(iconName)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                    } else if UIImage(systemName: iconName) != nil {
                        Image(systemName: iconName)
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(habitColor)
                    } else {
                        Circle()
                            .fill(habitColor)
                            .frame(width: 10, height: 10)
                    }
                } else {
                    Circle()
                        .fill(habitColor)
                        .frame(width: 10, height: 10)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name ?? "Unnamed Habit")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                if let completionTime = getCompletionTime() {
                    Text("Completed at \(completionTime)")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            minimalUndoButton
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(minimalRowBackground)
    }
    
    // MARK: - Minimal Row Background (Same as HabitRowView inactive state)
    private var minimalRowBackground: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(
                colorScheme == .dark
                    ? Color(UIColor.systemGray5).opacity(0.5)
                    : Color.gray.opacity(0.1)
            )
            .shadow(color: colorScheme == .dark ? .white.opacity(0.08) : .black.opacity(0.08), radius: 2)
    }
    
    private var minimalUndoButton: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            
            withAnimation(.easeInOut(duration: 0.3)) {
                toggleCompletion()
            }
        }) {
            ZStack {
                // Simple background
                Circle()
                    .fill(colorScheme == .dark
                          ? Color(UIColor.systemGray6)
                          : Color.white)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle()
                            .strokeBorder(accentColor.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: colorScheme == .dark ? .white.opacity(0.1) : .black.opacity(0.15), radius: 2)
                
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(accentColor)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func getCompletionTime() -> String? {
        guard let completions = habit.completion as? Set<Completion>,
              let completion = completions.first(where: { completion in
                  guard let completionDate = completion.date else { return false }
                  return Calendar.current.isDate(completionDate, inSameDayAs: date)
              }),
              let whenCompleted = completion.loggedAt else {
            return nil
        }
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: whenCompleted)
    }
}
