//
//  CreateHabitCoreSection.swift
//  Habital
//
//  Created by Elias Osarumwense on 23.08.25.
//

import SwiftUI

struct CreateHabitCoreSection: View {
    @Binding var name: String
    @Binding var icon: String
    @Binding var selectedColor: Color
    let isTextFieldFocused: FocusState<Bool>.Binding
    
    let colors: [Color]
    @Binding var isBadHabit: Bool
    @Binding var selectedIntensity: HabitIntensity
    let showIconPicker: () -> Void
    
    let showWallpaperPicker: () -> Void
    let hasWallpaper: Bool
    let hasExistingHabits: Bool
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 11) {
            // Habit Icon - Centered and prominent
            Button(action: showIconPicker) {
                HabitIconView(
                    iconName: icon,
                    isActive: true,
                    habitColor: selectedColor,
                    streak: 0,
                    showStreaks: false,
                    useModernBadges: false,
                    isFutureDate: false,
                    isBadHabit: isBadHabit,
                    intensityLevel: selectedIntensity.rawValue
                )
                .scaleEffect(2.5)
                .frame(width: 84, height: 84)
            }
            .padding(.top, 5)
            .padding(.bottom, 8)
            .buttonStyle(PlainButtonStyle())
            
            VStack(spacing: 15) {
                // Habit name field - minimal and unique design
                VStack(alignment: .center, spacing: 7) {
                    TextField("", text: $name, prompt: Text("Enter your habit name")
                        .foregroundColor(.secondary.opacity(0.5))
                        .font(.custom("Lexend-Regular", size: 18))
                    )
                    .font(.custom("Lexend-Medium", size: 19))
                    .focused(isTextFieldFocused)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(.primary)
                    .tint(.accentColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .frame(maxWidth: 260) // Limit the width
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(
                                        Color.primary.opacity(0.1),
                                        lineWidth: 1
                                    )
                            )
                    )
                    .onTapGesture {
                        isTextFieldFocused.wrappedValue = true
                    }
                }
                .padding(.top, 8)
                
                // Custom Color picker section - moved down
                VStack(spacing: 7) {
                    CustomColorPicker(
                        colors: colors,
                        selectedColor: $selectedColor
                    )
                }
                
                // Habit Type and Intensity Selection
                HStack(spacing: 11) {
                    // Good/Bad Habit Toggle with labels
                    VStack(alignment: .leading, spacing: 7) {
                        Text("Habit Type")
                            .font(.custom("Lexend-Medium", size: 11))
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 8) {
                            Text("Good Habit")
                                .font(.custom("Lexend-Regular", size: 10))
                                .foregroundColor(.secondary)
                            
                            HabitTypeToggle(isBadHabit: $isBadHabit)
                            
                            Text("Bad Habit")
                                .font(.custom("Lexend-Regular", size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Intensity Selector
                    VStack(alignment: .trailing, spacing: 7) {
                        Text("Intensity")
                            .font(.custom("Lexend-Medium", size: 11))
                            .foregroundColor(.secondary)
                        
                        Menu {
                            ForEach(HabitIntensity.allCases) { intensity in
                                Button(action: {
                                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                        selectedIntensity = intensity
                                    }
                                    // Haptic feedback
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                    impactFeedback.impactOccurred()
                                }) {
                                    HStack {
                                        Text(intensity.title)
                                        Spacer()
                                        Circle()
                                            .fill(intensity.color)
                                            .frame(width: 8, height: 8)
                                        if selectedIntensity == intensity {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.green)
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(selectedIntensity.color)
                                    .frame(width: 14, height: 14)
                                
                                Text(selectedIntensity.title)
                                    .font(.custom("Lexend-Regular", size: 11))
                                    .foregroundColor(.primary)
                                
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 7, weight: .medium))
                                    .foregroundColor(.secondary.opacity(0.7))
                            }
                            .padding(.horizontal, 11)
                            .padding(.vertical, 7)
                            .background(
                                Capsule()
                                    .fill(selectedIntensity.color.opacity(0.08))
                                    .overlay(
                                        Capsule()
                                            .stroke(selectedIntensity.color.opacity(0.2), lineWidth: 0.5)
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.top, 4)
            }
            
        }
        .padding(.horizontal, 13)
        .padding(.top, 18)
        
    }

}

// MARK: - Custom Color Picker
struct CustomColorPicker: View {
    let colors: [Color]
    @Binding var selectedColor: Color
    @State private var showColorPicker = false
    @State private var rotation: Double = 0
    
    // Layout constants - slightly bigger size
    private let itemSize: CGFloat = 34
    private let itemRadius: CGFloat = 10
    
    var body: some View {
        VStack(spacing: 7) {
            // First row - 8 colors
            HStack(spacing: 7) {
                ForEach(0..<min(8, colors.count), id: \.self) { index in
                    colorButton(for: colors[index])
                }
                
                // Add eyedropper in first row if we have less than 8 colors
                if colors.count < 8 {
                    eyedropperButton
                }
            }
            
            // Second row - remaining colors + eyedropper if needed
            HStack(spacing: 7) {
                if colors.count > 8 {
                    ForEach(8..<min(16, colors.count), id: \.self) { index in
                        colorButton(for: colors[index])
                    }
                }
                
                // Add eyedropper in second row if we have 8 or more colors
                if colors.count >= 8 {
                    eyedropperButton
                }
                
                // Fill remaining spaces with spacers to maintain layout
                let secondRowCount = colors.count > 8 ? min(8, colors.count - 8) : 0
                let totalSecondRowItems = secondRowCount + (colors.count >= 8 ? 1 : 0) // +1 for eyedropper
                
                ForEach(0..<(8 - totalSecondRowItems), id: \.self) { _ in
                    Spacer()
                        .frame(width: itemSize, height: itemSize)
                }
            }
        }
        .sheet(isPresented: $showColorPicker) {
            ColorPicker("Select Color", selection: $selectedColor)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }
    
    private func colorButton(for color: Color) -> some View {
        Button(action: {
            selectedColor = color
            
            // Haptic feedback (same as FloatingColorPicker)
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            // Same animation as FloatingColorPicker
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                rotation += 180
            }
        }) {
            RoundedRectangle(cornerRadius: itemRadius)
                .fill(color)
                .frame(width: itemSize, height: itemSize)
                .overlay {
                    if selectedColor == color {
                        RoundedRectangle(cornerRadius: itemRadius)
                            .stroke(Color.white, lineWidth: 2)
                    }
                }
                // Rotation effect like FloatingColorPicker
                .rotationEffect(selectedColor == color ? .degrees(rotation) : .degrees(0), anchor: .center)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var eyedropperButton: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            showColorPicker = true
        }) {
            RoundedRectangle(cornerRadius: itemRadius)
                .fill(Color.gray.opacity(0.3))
                .frame(width: itemSize, height: itemSize)
                .overlay {
                    Image(systemName: "eyedropper.halffull")
                        .foregroundColor(.primary)
                        .font(.system(size: 13, weight: .medium))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: itemRadius)
                        .stroke(Color.primary.opacity(0.3), lineWidth: 1)
                }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Habit Type Toggle
struct HabitTypeToggle: View {
    @Binding var isBadHabit: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Toggle("", isOn: $isBadHabit)
            .toggleStyle(AppleCapsuleHabitToggle())
            .labelsHidden()
    }
}

// MARK: - Apple-Style Capsule Toggle Implementation
struct AppleCapsuleHabitToggle: ToggleStyle {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPressed = false
    
    // Constants - smaller size
    private let toggleWidth: CGFloat = 60
    private let toggleHeight: CGFloat = 28
    private let knobSize: CGFloat = 24
    private let knobPadding: CGFloat = 2
    
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            // Background capsule with animated color transition
            Capsule()
                .fill(
                    !configuration.isOn ? 
                    Color(.systemGreen) : 
                    Color(.systemRed)
                )
                .frame(width: toggleWidth, height: toggleHeight)
                .shadow(
                    color: .black.opacity(colorScheme == .dark ? 0.3 : 0.15),
                    radius: 1.5,
                    x: 0,
                    y: 1
                )
                .animation(
                    reduceMotion ? 
                        .easeInOut(duration: 0.25) : 
                        .interactiveSpring(response: 0.4, dampingFraction: 0.75),
                    value: configuration.isOn
                )
            
            // Animated gradient overlay for more color animation
            Capsule()
                .fill(
                    LinearGradient(
                        colors: !configuration.isOn ? 
                            [Color(.systemGreen).opacity(0.9), Color(.systemGreen)] :
                            [Color(.systemRed).opacity(0.9), Color(.systemRed)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: toggleWidth, height: toggleHeight)
                .animation(
                    reduceMotion ? 
                        .easeInOut(duration: 0.3) : 
                        .interactiveSpring(response: 0.5, dampingFraction: 0.8),
                    value: configuration.isOn
                )
            
            // Background icons
            HStack {
                // Checkmark for good habit (left side)
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
                    .opacity(!configuration.isOn ? 1.0 : 0.0)
                    .animation(
                        reduceMotion ? 
                            .easeInOut(duration: 0.25) : 
                            .interactiveSpring(response: 0.4, dampingFraction: 0.75),
                        value: configuration.isOn
                    )
                
                Spacer()
                
                // X mark for bad habit (right side)
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
                    .opacity(configuration.isOn ? 1.0 : 0.0)
                    .animation(
                        reduceMotion ? 
                            .easeInOut(duration: 0.25) : 
                            .interactiveSpring(response: 0.4, dampingFraction: 0.75),
                        value: configuration.isOn
                    )
            }
            .padding(.horizontal, 8)
            .frame(width: toggleWidth, height: toggleHeight)
            .clipShape(Capsule()) // Ensure icons are clipped to capsule shape
            
            // Knob
            Circle()
                .fill(Color.white)
                .frame(width: knobSize, height: knobSize)
                .shadow(
                    color: .black.opacity(colorScheme == .dark ? 0.4 : 0.25),
                    radius: 2.5,
                    x: 0,
                    y: 1.5
                )
                .overlay(
                    Circle()
                        .stroke(
                            Color.white.opacity(0.8),
                            lineWidth: 0.5
                        )
                )
                .scaleEffect(isPressed ? 0.92 : 1.0)
                .offset(
                    x: !configuration.isOn ? 
                        -(toggleWidth - knobSize) / 2 + knobPadding : 
                        (toggleWidth - knobSize) / 2 - knobPadding
                )
                .animation(
                    reduceMotion ? 
                        .easeInOut(duration: 0.25) : 
                        .interactiveSpring(response: 0.4, dampingFraction: 0.75),
                    value: configuration.isOn
                )
        }
        .contentShape(Capsule())
        .accessibilityLabel(!configuration.isOn ? "Good habit" : "Bad habit")
        .accessibilityHint("Double tap to toggle between good and bad habit")
        .accessibilityAddTraits(.isButton)
        .onTapGesture {
            // Haptic feedback when knob changes
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            // Toggle with animation
            let animation: Animation = reduceMotion ? .easeInOut(duration: 0.25) : .interactiveSpring(response: 0.4, dampingFraction: 0.75)
            withAnimation(animation) {
                configuration.isOn.toggle()
            }
        }
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }) { }
    }
}



// Helper function for haptic feedback
private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
    let impactFeedback = UIImpactFeedbackGenerator(style: style)
    impactFeedback.impactOccurred()
}

// MARK: - Reusable Apple Capsule Toggle
struct AppleCapsuleToggle: View {
    @Binding var isOn: Bool
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPressed = false
    
    // Customizable properties
    let width: CGFloat
    let height: CGFloat
    let onColor: Color
    let offColor: Color
    let knobColor: Color
    let goodLabel: String
    let badLabel: String
    
    // Default initializer - smaller default size
    init(
        isOn: Binding<Bool>,
        width: CGFloat = 60,
        height: CGFloat = 28,
        onColor: Color = Color(.systemRed),
        offColor: Color = Color(.systemGreen),
        knobColor: Color = .white,
        goodLabel: String = "Good habit",
        badLabel: String = "Bad habit"
    ) {
        self._isOn = isOn
        self.width = width
        self.height = height
        self.onColor = onColor
        self.offColor = offColor
        self.knobColor = knobColor
        self.goodLabel = goodLabel
        self.badLabel = badLabel
    }
    
    private var knobSize: CGFloat {
        height - 4 // 2pt padding on each side
    }
    
    private var knobOffset: CGFloat {
        let maxOffset = (width - knobSize) / 2 - 2 // 2pt padding
        return !isOn ? -maxOffset : maxOffset // Left = good (off), Right = bad (on)
    }
    
    var body: some View {
        ZStack {
            // Background capsule with gradient animation
            Capsule()
                .fill(
                    LinearGradient(
                        colors: !isOn ? 
                            [offColor.opacity(0.9), offColor] :
                            [onColor.opacity(0.9), onColor],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: width, height: height)
                .shadow(
                    color: .black.opacity(colorScheme == .dark ? 0.3 : 0.15),
                    radius: 1.5,
                    x: 0,
                    y: 1
                )
                .animation(
                    reduceMotion ? 
                        .easeInOut(duration: 0.25) : 
                        .interactiveSpring(response: 0.4, dampingFraction: 0.75),
                    value: isOn
                )
            
            // Knob
            Circle()
                .fill(knobColor)
                .frame(width: knobSize, height: knobSize)
                .shadow(
                    color: .black.opacity(colorScheme == .dark ? 0.4 : 0.25),
                    radius: 2.5,
                    x: 0,
                    y: 1.5
                )
                .overlay(
                    Circle()
                        .stroke(
                            knobColor.opacity(0.8),
                            lineWidth: 0.5
                        )
                )
                .scaleEffect(isPressed ? 0.92 : 1.0)
                .offset(x: knobOffset)
                .animation(
                    reduceMotion ? 
                        .easeInOut(duration: 0.25) : 
                        .interactiveSpring(response: 0.4, dampingFraction: 0.75),
                    value: isOn
                )
        }
        .contentShape(Capsule())
        .accessibilityLabel(!isOn ? goodLabel : badLabel)
        .accessibilityHint("Double tap to toggle")
        .accessibilityAddTraits(.isButton)
        .onTapGesture {
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            // Toggle with animation
            let animation: Animation = reduceMotion ? 
                .easeInOut(duration: 0.25) : 
                .interactiveSpring(response: 0.4, dampingFraction: 0.75)
            
            withAnimation(animation) {
                isOn.toggle()
            }
        }
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }) { }
        .dynamicTypeSize(...DynamicTypeSize.accessibility2) // Support for Dynamic Type
    }
}
struct CreateHabitCoreSection_Previews: PreviewProvider {
    @State static var name = "Morning Meditation"
    @State static var icon = "leaf.fill"
    @State static var selectedColor = Color.green
    @State static var isBadHabit = false
    @State static var selectedIntensity = HabitIntensity.moderate
    @FocusState static var isTextFieldFocused: Bool
    
    static let colors: [Color] = [
        .red, .orange, .yellow, .green, .mint, .cyan, .blue, .indigo,
        .purple, .pink, Color(red: 1.0, green: 0.3, blue: 0.3), Color(red: 0.9, green: 0.6, blue: 0.2),
        Color(red: 0.4, green: 0.8, blue: 0.4), Color(red: 0.3, green: 0.7, blue: 0.9), Color(red: 0.6, green: 0.4, blue: 0.8), .brown
    ]
    
    static var previews: some View {
        Group {
            VStack {
                CreateHabitCoreSection(
                    name: $name,
                    icon: $icon,
                    selectedColor: $selectedColor,
                    isTextFieldFocused: $isTextFieldFocused,
                    colors: colors,
                    isBadHabit: $isBadHabit,
                    selectedIntensity: $selectedIntensity,
                    showIconPicker: { print("Icon picker tapped") },
                    showWallpaperPicker: { print("Wallpaper picker tapped") },
                    hasWallpaper: false,
                    hasExistingHabits: false
                )
            }
            .padding()
            .previewDisplayName("Light")
            
            CreateHabitCoreSection(
                name: $name,
                icon: $icon,
                selectedColor: $selectedColor,
                isTextFieldFocused: $isTextFieldFocused,
                colors: colors,
                isBadHabit: $isBadHabit,
                selectedIntensity: $selectedIntensity,
                showIconPicker: { },
                showWallpaperPicker: { },
                hasWallpaper: true,
                hasExistingHabits: true
            )
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark with Wallpaper")
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    
    }
}
