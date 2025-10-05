//
//  NotificationStyleStack.swift
//  Habital
//
//  Created by Elias Osarumwense on 06.04.25.
//
import SwiftUI

struct NotificationStyleCompletedHabitsStack: View {
    let habits: [Habit]
    let date: Date
    let isHabitCompleted: (Habit) -> Bool
    let toggleCompletion: (Habit) -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var isExpanded = false
    @State private var dragOffset: CGFloat = 0
    @AppStorage("accentColorIndex") private var accentColorIndex: Int = 0
    
    private var completedHabits: [Habit] {
        return habits.filter { isHabitCompleted($0) }
    }
    
    private var accentColor: Color {
        return ColorPalette.color(at: accentColorIndex)
    }
    
    // Calculate stacked transforms for each card
    private func stackTransform(for index: Int, totalCount: Int) -> (offset: CGFloat, scale: CGFloat, opacity: Double) {
        if isExpanded {
            // When expanded, show as a list with proper spacing
            return (offset: 0, scale: 1.0, opacity: 1.0)
        } else {
            // When collapsed, stack like iOS notifications
            let maxVisibleCards = min(3, totalCount)
            let cardIndex = min(index, maxVisibleCards - 1)
            
            // Each card is offset and scaled smaller
            let offset = CGFloat(cardIndex) * 8 // Stacking offset
            let scale = 1.0 - (CGFloat(cardIndex) * 0.025) // Subtle scale reduction
            let opacity = 1.0 - (Double(cardIndex) * 0.1) // Slight opacity reduction
            
            return (offset: offset, scale: scale, opacity: max(opacity, 0.7))
        }
    }
    
    var body: some View {
        if !completedHabits.isEmpty {
            VStack(spacing: 0) {
                if isExpanded {
                    // Expanded state - show all cards
                    expandedView
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.95).combined(with: .opacity),
                            removal: .scale(scale: 0.95).combined(with: .opacity)
                        ))
                } else {
                    // Collapsed state - show stacked cards
                    collapsedStackView
                        .transition(.asymmetric(
                            insertion: .scale(scale: 1.05).combined(with: .opacity),
                            removal: .scale(scale: 1.05).combined(with: .opacity)
                        ))
                }
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isExpanded)
        }
    }
    
    // MARK: - Collapsed Stack View (Like iOS Notifications)
    private var collapsedStackView: some View {
        ZStack {
            // Stack the cards behind each other
            ForEach(Array(completedHabits.reversed().enumerated()), id: \.element.id) { index, habit in
                let reverseIndex = completedHabits.count - 1 - index
                let transform = stackTransform(for: reverseIndex, totalCount: completedHabits.count)
                
                NotificationCard(
                    habit: habit,
                    date: date,
                    accentColor: accentColor,
                    isTopCard: reverseIndex == 0,
                    totalCount: completedHabits.count,
                    onToggle: { toggleCompletion(habit) }
                )
                .scaleEffect(transform.scale)
                .opacity(transform.opacity)
                .offset(y: transform.offset)
                .zIndex(Double(index))
                .allowsHitTesting(reverseIndex == 0) // Only top card is interactive when collapsed
            }
        }
        .offset(y: dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    // Allow slight drag for tactile feedback
                    dragOffset = min(max(value.translation.height, -20), 20)
                }
                .onEnded { value in
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        dragOffset = 0
                        
                        // Expand if dragged down significantly
                        if value.translation.height > 50 {
                            isExpanded = true
                        }
                    }
                }
        )
        .onTapGesture {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isExpanded = true
            }
            
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        }
    }
    
    // MARK: - Expanded View (All Cards Visible)
    private var expandedView: some View {
        VStack(spacing: 12) {
            // Header with collapse button
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Completed Habits")
                        .customFont("Lexend", .semiBold, 18)
                        .foregroundColor(.primary)
                    
                    Text("\(completedHabits.count) habit\(completedHabits.count == 1 ? "" : "s") today")
                        .customFont("Lexend", .medium, 14)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        isExpanded = false
                    }
                    
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                }) {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "chevron.up")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(accentColor)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            // All habit cards
            VStack(spacing: 8) {
                ForEach(Array(completedHabits.enumerated()), id: \.element.id) { index, habit in
                    NotificationCard(
                        habit: habit,
                        date: date,
                        accentColor: accentColor,
                        isTopCard: true,
                        totalCount: completedHabits.count,
                        onToggle: { toggleCompletion(habit) }
                    )
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.9).combined(with: .opacity),
                        removal: .scale(scale: 0.9).combined(with: .opacity)
                    ))
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(accentColor.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

// MARK: - Individual Notification Card
struct NotificationCard: View {
    let habit: Habit
    let date: Date
    let accentColor: Color
    let isTopCard: Bool
    let totalCount: Int
    let onToggle: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false
    
    private var habitColor: Color {
        if let colorData = habit.color,
           let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
            return Color(uiColor)
        }
        return .green
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Habit icon with completion indicator
            ZStack {
                Circle()
                    .fill(habitColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Circle()
                    .stroke(habitColor.opacity(0.3), lineWidth: 1.5)
                    .frame(width: 36, height: 36)
                
                // Habit icon
                habitIconContent
                
                // Completion checkmark overlay
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        
                        ZStack {
                            Circle()
                                .fill(.green)
                                .frame(width: 14, height: 14)
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .offset(x: 3, y: 3)
                    }
                }
                .frame(width: 36, height: 36)
            }
            
            // Habit details
            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name ?? "Unnamed Habit")
                    .customFont("Lexend", .semiBold, 14)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    if let completionTime = getCompletionTime() {
                        HStack(spacing: 3) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                            
                            Text(completionTime)
                                .customFont("Lexend", .medium, 11)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Show count if this is the top card and there are multiple
                    if isTopCard && totalCount > 1 {
                        Text("• \(totalCount) completed")
                            .customFont("Lexend", .medium, 11)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Undo button
            Button(action: {
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
                onToggle()
            }) {
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.1))
                        .frame(width: 28, height: 28)
                    
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(accentColor)
                }
            }
            .scaleEffect(isPressed ? 0.9 : 1.0)
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = pressing
                }
            }, perform: {})
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(habitColor.opacity(0.1), lineWidth: 0.5)
                )
        )
    }
    
    @ViewBuilder
    private var habitIconContent: some View {
        if let iconName = habit.icon, !iconName.isEmpty {
            if iconName.count == 1 || iconName.first?.isEmoji == true {
                Text(iconName)
                    .font(.system(size: 16))
            } else if UIImage(systemName: iconName) != nil {
                Image(systemName: iconName)
                    .font(.system(size: 14, weight: .medium))
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
