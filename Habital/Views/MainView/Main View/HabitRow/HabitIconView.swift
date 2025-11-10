//
//  HabitIconView.swift
//  Habital
//
//  Created by Elias Osarumwense on 11.04.25.
//

import SwiftUI

struct HabitIconView: View {
    // Icon properties
    let iconName: String?
    let isActive: Bool
    let habitColor: Color
    let streak: Int
    let showStreaks: Bool
    let useModernBadges: Bool
    let isFutureDate: Bool
    
    // Optional property for isBadHabit with default value
    let isBadHabit: Bool
    
    // Optional property for intensity with default value
    let intensityLevel: Int16
    
    // NEW: Optional duration in minutes
    let durationMinutes: Int16?
    
    // App storage for appearance settings
    @AppStorage("iconColorType") private var iconColorType = "habit"
    @AppStorage("iconBackgroundColorType") private var iconBackgroundColorType = "habit"
    @AppStorage("showIntensityIndicator") private var showIntensityIndicator = true
    @AppStorage("intensityIndicatorStyle") private var intensityIndicatorStyle = "dots"
    
    // Environment values
    @Environment(\.colorScheme) private var colorScheme
    
    // Removed pulse animation for better performance
    
    // Initialize with default values for new parameters
    init(iconName: String?, isActive: Bool, habitColor: Color, streak: Int, showStreaks: Bool,
         useModernBadges: Bool, isFutureDate: Bool, isBadHabit: Bool = false, intensityLevel: Int16 = 0, durationMinutes: Int16? = nil) {
        self.iconName = iconName
        self.isActive = isActive
        self.habitColor = habitColor
        self.streak = streak
        self.showStreaks = showStreaks
        self.useModernBadges = useModernBadges
        self.isFutureDate = isFutureDate
        self.isBadHabit = isBadHabit
        self.intensityLevel = intensityLevel
        self.durationMinutes = durationMinutes
    }
    
    // Helper to convert raw value to enum
    private var habitIntensity: HabitIntensity {
        return HabitIntensity(rawValue: intensityLevel) ?? .light
    }
    
    // NEW: Format duration text
    private var durationText: String? {
        guard let duration = durationMinutes, duration > 0 else { return nil }
        
        let minutes = Int(duration)
        
        if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            
            if remainingMinutes == 0 {
                return "\(hours)h"
            } else {
                return "\(hours)h\(remainingMinutes)m"
            }
        }
    }
    
    // MARK: - Enhanced Streak-Based Styling System
    
    private var streakGlowRadius: CGFloat {
        if streak >= 100 { return 10 }
        else if streak >= 90 { return 9 }
        else if streak >= 80 { return 8 }
        else if streak >= 70 { return 7 }
        else if streak >= 60 { return 6 }
        else if streak >= 50 { return 5 }
        else if streak >= 40 { return 4 }
        else if streak >= 30 { return 3.5 }
        else if streak >= 20 { return 3 }
        else if streak >= 10 { return 2 }
        else { return 0 }
    }
    
    private var streakGlowOpacity: Double {
        if streak >= 100 { return 0.7 }
        else if streak >= 90 { return 0.65 }
        else if streak >= 80 { return 0.6 }
        else if streak >= 70 { return 0.55 }
        else if streak >= 60 { return 0.5 }
        else if streak >= 50 { return 0.45 }
        else if streak >= 40 { return 0.35 }
        else if streak >= 30 { return 0.3 }
        else if streak >= 20 { return 0.25 }
        else if streak >= 10 { return 0.2 }
        else { return 0 }
    }
    
    // NEW: Enhanced circle scale based on streak
    private var streakCircleScale: CGFloat {
        if streak >= 100 { return 1.08 }
        else if streak >= 75 { return 1.06 }
        else if streak >= 50 { return 1.04 }
        else if streak >= 30 { return 1.03 }
        else if streak >= 15 { return 1.02 }
        else { return 1.0 }
    }
    
    // NEW: Inner accent glow for high streaks
    private var streakInnerGlow: Color {
        if streak >= 100 { return habitColor.opacity(0.2) }
        else if streak >= 50 { return habitColor.opacity(0.15) }
        else if streak >= 30 { return habitColor.opacity(0.1) }
        else if streak >= 15 { return habitColor.opacity(0.05) }
        else { return Color.clear }
    }
    
    // NEW: Border width enhancement
    private var streakBorderWidth: CGFloat {
        if streak >= 100 { return 1.8 }
        else if streak >= 75 { return 1.5 }
        else if streak >= 50 { return 1.3 }
        else if streak >= 25 { return 1.1 }
        else { return 1.0 }
    }
    
    // NEW: Inner accent ring visibility
    private var showInnerAccent: Bool {
        return streak >= 25 && isActive
    }
    
    // NEW: Streak pattern for very high streaks
    private var showStreakPattern: Bool {
        return streak >= 60 && isActive
    }
    
    // NEW: Static rotation for elite streaks (no animation)
    private var streakRotation: Double {
        return 0 // Disabled for performance
    }
    
    // Removed pulse for performance - static scaling only
    private var shouldPulse: Bool {
        return false
    }
    
    // Icon color based on settings
    private var iconColor: Color {
        if !isActive {
            return .gray
        }
        
        switch iconColorType {
        case "habit":
            return habitColor
        case "primary":
            if colorScheme == .dark {
                // Make icons a bit darker in dark mode
                return iconBackgroundColorType == "primary" ? Color(.darkGray) : .white.opacity(0.85)
            } else {
                return .white
            }
        default:
            return habitColor
        }
    }

    // Background color based on settings
    private var backgroundColor: Color {
        if !isActive {
            return .gray.opacity(0.1)
        }
        
        switch iconBackgroundColorType {
        case "habit":
            return habitColor
        case "primary":
            return colorScheme == .dark ? .black : Color(.lightGray)
        default:
            return habitColor
        }
    }
    
    var body: some View {
        ZStack {
            // Main icon content (no longer flips)
            frontFace
            
            // Enhanced streak badge (this will flip)
            if showStreaks && streak > 0 && !isFutureDate {
                enhancedStreakBadge
            }
        }
        .animation(.smooth(duration: 0.4), value: isActive)
        .animation(.smooth(duration: 0.4), value: habitColor)
        .animation(.smooth(duration: 0.6), value: streak)
        .onChange(of: streak) { oldValue, newValue in
            // Trigger celebration when we *increase* across a tens boundary (…9 → …0), up to 100
            let crossedUpAMultipleOf10 =
                newValue > oldValue &&
                newValue % 10 == 0 &&
                (newValue / 10) > (oldValue / 10)

            if crossedUpAMultipleOf10 && newValue <= 100 {
                triggerStreakCelebration()    // e.g. celebrate "20", "30", …, "100"
            } else if newValue % 10 == 0 && newValue > oldValue && newValue >= 10 {
                // keep your existing haptics on other milestones (e.g. > 100)
                triggerStreakCelebration()
            }
        }
    }
    
    private var frontFace: some View {
        ZStack {
            // Enhanced main icon background with streak scaling
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            backgroundColor.opacity(isBadHabit ? 0.4 : 0.6),
                            backgroundColor.opacity(isBadHabit ? 0.7 : 0.4)
                        ]),
                        startPoint: isBadHabit ? .topLeading : .bottomTrailing,
                        endPoint: isBadHabit ? .bottomTrailing : .topLeading
                    )
                )
                .frame(width: 41, height: 41)
                .scaleEffect(streakCircleScale) // Enhanced scale based on streak
                .rotationEffect(.degrees(streakRotation)) // Subtle rotation for 100+ streaks
                .background(
                    // Enhanced outer glow
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    backgroundColor.opacity(streak >= 30 ? 0.12 : 0.08),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 20,
                                endRadius: streak >= 50 ? 32 : 29
                            )
                        )
                        .frame(width: streak >= 50 ? 48 : 45, height: streak >= 50 ? 48 : 45)
                )
                .background(
                    // NEW: Inner accent glow for high streaks
                    Circle()
                        .fill(streakInnerGlow)
                        .frame(width: 35, height: 35)
                        .opacity(showInnerAccent ? 1 : 0)
                        .blur(radius: 2)
                )
                .overlay(
                    // Enhanced border with dynamic width
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    backgroundColor.opacity(0.1),
                                    backgroundColor.opacity(streak >= 50 ? 0.5 : 0.4),
                                    backgroundColor.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: streakBorderWidth
                        )
                )
                .overlay(
                    // NEW: Inner accent ring for milestone streaks
                    Circle()
                        .strokeBorder(
                            habitColor.opacity(streak >= 50 ? 0.3 : 0.2),
                            lineWidth: 0.5
                        )
                        .frame(width: 37, height: 37)
                        .opacity(showInnerAccent ? 1 : 0)
                )
                .overlay(
                    // Static streak pattern for elite habits (no rotation for performance)
                    Circle()
                        .strokeBorder(
                            AngularGradient(
                                gradient: Gradient(colors: [
                                    habitColor.opacity(0.15),
                                    Color.clear,
                                    habitColor.opacity(0.15),
                                    Color.clear,
                                    habitColor.opacity(0.1),
                                    Color.clear
                                ]),
                                center: .center
                            ),
                            lineWidth: 0.8
                        )
                        .frame(width: 43, height: 43)
                        .opacity(showStreakPattern ? 1 : 0)
                )
                // Removed shadow for better performance
                .scaleEffect(1.0) // Static scale for performance
            
            // Icon content (behind the prohibition line)
            if let iconName = iconName, !iconName.isEmpty {
                if iconName.count == 1 || (iconName.first?.isEmoji ?? false) {
                    // It's an emoji
                    Text(iconName)
                        .font(.system(size: 25))
                        .contentTransition(.interpolate)
                        .saturation(isActive ? 1.0 : 0.0)
                        .opacity(isActive ? 1.0 : 0.6)
                        .scaleEffect(streak >= 100 ? 1.05 : 1.0) // Slightly larger emoji for elite streaks
                    
                } else {
                    // It's a system symbol
                    Image(systemName: iconName)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                        .foregroundColor(iconColor.opacity(0.75)) // Slightly darker overall
                        .contentTransition(.symbolEffect(.replace))
                        .scaleEffect(streak >= 100 ? 1.05 : 1.0) // Slightly larger icon for elite streaks
                }
            } else {
                // Default icon if none provided
                defaultIcon
            }
            
            // Bad habit prohibition indicator (appears IN FRONT of icon)
            if isBadHabit {
                ProhibitionSymbolView(
                    isActive: isActive,
                    iconSize: 41 // Match the base circle size
                )
                .accessibilityLabel("Bad habit")
                .accessibilityAddTraits(.isImage)
            }
            
            // Intensity indicator (only show if enabled in settings AND intensity is higher than light)
            // This appears LAST so it's in front of everything else
            if showIntensityIndicator && intensityLevel >= 1 {
                intensityIndicator
            }
            
            // Duration display on left bottom
            if let duration = durationText {
                durationDisplay(duration)
                    .offset(x: -15, y: 15)
            }
        }
        /*
        .animation(.smooth(duration: 0.4), value: isActive)
        .animation(.smooth(duration: 0.4), value: habitColor)
        .animation(.smooth(duration: 0.6), value: streak)
        .onChange(of: streak) { oldValue, newValue in
            // Enhanced celebration on milestones
            if newValue % 10 == 0 && newValue > oldValue && newValue >= 10 {
                triggerStreakCelebration()
            }
        }
         */
    }

    // MARK: - Enhanced Streak Badge
    
    private var enhancedStreakBadge: some View {
        ZStack {
            
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: streak >= 100 ? 16 : 14, height: streak >= 100 ? 16 : 14) // Larger for high streaks
                    
                Text("\(streak)")
                    .font(.customFont("Lexend", .bold, streak >= 100 ? 7 : (streak >= 50 ? 8 : 9)))
                    .foregroundColor(isActive ? .primary.opacity(0.85) : .gray)
                    .contentTransition(.numericText(value: Double(streak)))
                    .animation(.easeInOut(duration: 0.6), value: streak)
            
        }
        .offset(x: 15, y: 15)
        .transition(.scale.combined(with: .opacity))
        .animation(.bouncy(duration: 0.8), value: streak)
        .scaleEffect(1.0) // Static scale for performance
    }
    

    private func triggerStreakCelebration() {
        // Enhanced haptic feedback based on milestone
        let impactStyle: UIImpactFeedbackGenerator.FeedbackStyle = streak >= 50 ? .heavy : (streak >= 20 ? .medium : .light)
        let impactFeedback = UIImpactFeedbackGenerator(style: impactStyle)
        impactFeedback.impactOccurred()
        
        // Brief scale animation with more emphasis for higher streaks
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            // The existing scale animation will handle the visual feedback
        }
    }
    
    // Duration display component
    private func durationDisplay(_ duration: String) -> some View {
        Text(duration)
            .font(.system(size: 8, weight: .medium))
            .foregroundColor(.primary.opacity(0.6))
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule()
                            .strokeBorder(
                                isActive ? habitColor.opacity(0.2) : .gray.opacity(0.1),
                                lineWidth: 0.5
                            )
                    )
            )
            .transition(.scale.combined(with: .opacity))
            .animation(.smooth(duration: 0.3), value: isActive)
    }
    
    @ViewBuilder
    private var intensityIndicator: some View {
        switch intensityIndicatorStyle {
        case "dots":
            dotsIndicator
        case "chevron":
            chevronIndicator
        case "chevron_original":
            chevronOriginalIndicator
        case "arc":
            arcIndicator
        case "minimal":
            minimalIndicator
        default:
            dotsIndicator
        }
    }
    
    // MARK: - Intensity Indicator Styles
    
    private var dotsIndicator: some View {
        HStack(spacing: 2) {
            ForEach(0..<Int(intensityLevel), id: \.self) { index in
                Circle()
                    .fill(isActive ? habitIntensity.color : habitIntensity.color.opacity(0.3))
                    .frame(width: 4, height: 4)
                    .scaleEffect(index == Int(intensityLevel) - 1 ? 1.2 : 1.0)
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
        )
        .offset(x: 0, y: -20)
        .transition(.scale.combined(with: .opacity))
    }
    
    private var chevronIndicator: some View {
        VStack(spacing: 1) {
            ForEach(0..<Int(intensityLevel), id: \.self) { _ in
                Image(systemName: "chevron.up")
                    .font(.system(size: 4, weight: .bold))
                    .foregroundColor(isActive ? habitIntensity.color : habitIntensity.color.opacity(0.3))
            }
        }
        .offset(x: -20, y: -20)
        .transition(.scale.combined(with: .opacity))
    }
    
    private var arcIndicator: some View {
        Circle()
            .trim(from: 0, to: CGFloat(intensityLevel) / 4.0)
            .stroke(
                isActive ? habitIntensity.color : habitIntensity.color.opacity(0.3),
                style: StrokeStyle(lineWidth: 2, lineCap: .round)
            )
            .frame(width: 50, height: 50)
            .rotationEffect(.degrees(-90))
            .transition(.scale.combined(with: .opacity))
    }
    
    private var chevronOriginalIndicator: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 15, height: 15)
                .background(
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    (colorScheme == .dark ? Color.white : Color.black).opacity(0.08),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 7.5,
                                endRadius: 8
                            )
                        )
                        .frame(width: 20, height: 20)
                )
            
            Image(systemName: "chevron.up")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(isActive ? habitIntensity.color : habitIntensity.color.opacity(0.3))
                .contentTransition(.symbolEffect(.replace))
        }
        .offset(x: -15, y: -15)
        .transition(.scale.combined(with: .opacity))
    }
    
    private var minimalIndicator: some View {
        Rectangle()
            .fill(isActive ? habitIntensity.color : habitIntensity.color.opacity(0.3))
            .frame(width: CGFloat(intensityLevel) * 3, height: 2)
            .cornerRadius(1)
            .offset(x: 0, y: 25)
            .transition(.scale.combined(with: .opacity))
    }
    
    private var defaultIcon: some View {
        Image(systemName: "star")
            .resizable()
            .scaledToFit()
            .frame(width: 22, height: 22)
            .foregroundColor(iconColor)
            .contentTransition(.symbolEffect(.replace))
            .scaleEffect(streak >= 100 ? 1.05 : 1.0)
    }
}

// MARK: - Prohibition Symbol View

struct ProhibitionSymbolView: View {
    let isActive: Bool
    let iconSize: CGFloat
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var drawProgress: CGFloat = 0
    
    // Design constants based on icon size
    private var ringStrokeWidth: CGFloat {
        iconSize * 0.08 // 8% of icon size (reduced from 12%)
    }
    
    private var slashStrokeWidth: CGFloat {
        ringStrokeWidth // Match ring width
    }
    
    private var innerMargin: CGFloat {
        0 // No inner margin - ring at the exact edge
    }
    
    private var prohibitionRingSize: CGFloat {
        iconSize - (innerMargin * 2)
    }
    
    private var slashLength: CGFloat {
        prohibitionRingSize * 0.7 // Diagonal length inside the ring
    }
    
    // Minimal black color for the prohibition slash
    private var prohibitionColor: Color {
        Color.black.opacity(0.6) // Black in both light and dark mode
    }
    
    var body: some View {
        ZStack {
            // Diagonal slash (45° from top-right to bottom-left) - draws from bottom-left to top-right
            Capsule()
                .trim(from: 0, to: drawProgress)
                .stroke(prohibitionColor, lineWidth: slashStrokeWidth)
                .frame(width: slashLength, height: slashStrokeWidth)
                .rotationEffect(.degrees(45)) // 45° rotation - no wiggle
                .opacity(isActive ? 1.0 : 0.5) // Clearer visibility
        }
        .scaleEffect(isActive ? 1.0 : 0.9)
        .opacity(isActive ? 1.0 : 0.6)
        .onAppear {
            // Animate the line drawing from bottom-left to top-right (slower)
            withAnimation(.easeOut(duration: 0.5)) {
                drawProgress = 1.0
            }
        }
        .onChange(of: isActive) { _, newValue in
            // Animate the drawing progress when active state changes
            withAnimation(.easeInOut(duration: 0.4)) {
                drawProgress = newValue ? 1.0 : 0.0
            }
        }
        .animation(.easeOut(duration: 0.18), value: isActive)
    }
}

// MARK: - Previews

struct HabitIconView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            Text("Enhanced Streak Effects")
                .font(.headline)
            
            // Streak progression examples
            HStack(spacing: 15) {
                VStack {
                    Text("5 days")
                    HabitIconView(
                        iconName: "book.fill",
                        isActive: true,
                        habitColor: .blue,
                        streak: 5,
                        showStreaks: true,
                        useModernBadges: true,
                        isFutureDate: false,
                        intensityLevel: 1,
                        durationMinutes: 5
                    )
                }
                
                VStack {
                    Text("30 days")
                    HabitIconView(
                        iconName: "dumbbell.fill",
                        isActive: true,
                        habitColor: .red,
                        streak: 30,
                        showStreaks: true,
                        useModernBadges: false,
                        isFutureDate: false,
                        intensityLevel: 3,
                        durationMinutes: 45
                    )
                }
                
                VStack {
                    Text("75 days")
                    HabitIconView(
                        iconName: "🏃",
                        isActive: true,
                        habitColor: .green,
                        streak: 75,
                        showStreaks: true,
                        useModernBadges: true,
                        isFutureDate: false,
                        intensityLevel: 2,
                        durationMinutes: 30
                    )
                }
                
                VStack {
                    Text("100 days")
                    HabitIconView(
                        iconName: "star.fill",
                        isActive: true,
                        habitColor: .purple,
                        streak: 100,
                        showStreaks: true,
                        useModernBadges: true,
                        isFutureDate: false,
                        intensityLevel: 4,
                        durationMinutes: 90
                    )
                }
            }
            
            Divider()
            
            Text("Bad Habits with Prohibition Design")
                .font(.subheadline)
            
            HStack(spacing: 15) {
                VStack {
                    Text("Active")
                    HabitIconView(
                        iconName: "cigarette.fill",
                        isActive: true,
                        habitColor: .red,
                        streak: 15,
                        showStreaks: true,
                        useModernBadges: true,
                        isFutureDate: false,
                        isBadHabit: true,
                        intensityLevel: 2
                    )
                }
                
                VStack {
                    Text("Inactive")
                    HabitIconView(
                        iconName: "wineglass.fill",
                        isActive: false,
                        habitColor: .red,
                        streak: 8,
                        showStreaks: true,
                        useModernBadges: true,
                        isFutureDate: false,
                        isBadHabit: true,
                        intensityLevel: 1
                    )
                }
            }
            
            Divider()
            
            Text("Different Habit Colors with Enhanced Streaks")
                .font(.subheadline)
            
            HStack(spacing: 15) {
                ForEach([
                    (color: Color.orange, streak: 25),
                    (color: Color.cyan, streak: 45),
                    (color: Color.pink, streak: 65),
                    (color: Color.indigo, streak: 90)
                ], id: \.streak) { item in
                    VStack {
                        Text("\(item.streak) days")
                            .font(.caption)
                        HabitIconView(
                            iconName: "flame.fill",
                            isActive: true,
                            habitColor: item.color,
                            streak: item.streak,
                            showStreaks: true,
                            useModernBadges: true,
                            isFutureDate: false,
                            intensityLevel: 2
                        )
                    }
                }
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
