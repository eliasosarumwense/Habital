//
//  CreateHabitCoreSection.swift
//  Habital
//
//  Created by Elias Osarumwense on 23.08.25.
//

import SwiftUI

struct CreateHabitCoreSection: View {
    @Binding var name: String
    @Binding var habitDescription: String
    @Binding var icon: String
    @Binding var selectedColor: Color
    let isTextFieldFocused: FocusState<Bool>.Binding
    
    let colors: [Color]
    let isBadHabit: Bool
    let selectedIntensity: HabitIntensity
    let showIconPicker: () -> Void
    
    let showWallpaperPicker: () -> Void
    let hasWallpaper: Bool
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 12) {
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
            .padding(.bottom, 3)
            .buttonStyle(PlainButtonStyle())
            // Color picker section
            VStack(spacing: 5) {
                HStack {
                    Text("Color")
                        .font(.custom("Lexend-Medium", size: 11))
                        .foregroundColor(.primary)
                        .opacity(0.7)
                        .textCase(.uppercase)
                        .kerning(0.5)
                    
                    Spacer()
                    
                    // Selected color preview with elegant indicator
                    HStack(spacing: 3) {
                        Circle()
                            .fill(selectedColor)
                            .frame(width: 8, height: 8)
                            .shadow(color: selectedColor.opacity(0.3), radius: 2, x: 0, y: 1)
                        
                        Text("Selected")
                            .font(.custom("Lexend-Regular", size: 10))
                            .foregroundColor(.secondary.opacity(0.6))
                    }
                    .opacity(colors.prefix(7).contains(selectedColor) ? 0 : 1)
                    .animation(.easeOut(duration: 0.2), value: selectedColor)
                }
                
                HStack(spacing: 0) {
                    // Preset colors with enhanced styling
                    HStack(spacing: 5) {
                        ForEach(colors.prefix(8), id: \.self) { color in
                            premiumColorButton(color)
                        }
                    }
                    
                    
                    
                    // Enhanced custom color picker
                    ZStack {
                        // Background with subtle gradient
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        .white.opacity(0.1),
                                        .clear
                                    ],
                                    center: .topLeading,
                                    startRadius: 2,
                                    endRadius: 14
                                )
                            )
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                            )
                            .overlay(
                                Circle()
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [
                                                .white.opacity(0.3),
                                                .white.opacity(0.1)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 0.8
                                    )
                            )
                        
                        // Color picker with refined styling
                        ColorPicker("", selection: $selectedColor)
                            .labelsHidden()
                            .scaleEffect(0.85)
                            .frame(width: 32, height: 32)
                    }
                    .frame(width: 32, height: 32)
                    .onChange(of: selectedColor) { _ in
                        triggerHaptic(.impactLight)
                    }
                }
            }
            VStack(spacing: 10) {
                // Habit name field
                Button(action: showWallpaperPicker) {
                    HStack(spacing: 8) {
                        Image(systemName: hasWallpaper ? "photo.fill" : "photo.badge.plus")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(hasWallpaper ? selectedColor : .secondary)
                        
                        Text(hasWallpaper ? "Change Wallpaper" : "Add Wallpaper")
                            .font(.custom("Lexend-Medium", size: 13))
                            .foregroundColor(hasWallpaper ? selectedColor : .primary)
                        
                        Spacer()
                        
                        if hasWallpaper {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(selectedColor)
                        } else {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary.opacity(0.6))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(
                                        hasWallpaper ? selectedColor.opacity(0.2) : Color.primary.opacity(0.1),
                                        lineWidth: 1
                                    )
                            )
                    )
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.horizontal, 24)
                .padding(.top, 8)
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text("Name")
                            .font(.custom("Lexend-Medium", size: 11))
                            .foregroundColor(.primary)
                            .opacity(0.7)
                            .textCase(.uppercase)
                            .kerning(0.5)
                        
                        Spacer()
                        
                        // Character count indicator (premium touch)
                        if !name.isEmpty {
                            Text("\(name.count)")
                                .font(.custom("Lexend-Regular", size: 10))
                                .foregroundColor(.secondary.opacity(0.5))
                                .monospacedDigit()
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 5) {
                        TextField("Enter habit name", text: $name)
                            .font(.custom("Lexend-Regular", size: 16))
                            .focused(isTextFieldFocused)
                            .textFieldStyle(PlainTextFieldStyle())
                            .foregroundColor(.primary)
                            .padding(.vertical, 2)
                        
                        // Enhanced underline with sophisticated gradient
                        ZStack(alignment: .leading) {
                            // Background line
                            Rectangle()
                                .fill(.quaternary)
                                .frame(height: 1)
                            
                            // Animated gradient line
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: name.isEmpty ? [
                                            Color.clear,
                                            Color.clear
                                        ] : [
                                            selectedColor.opacity(0.8),
                                            selectedColor.opacity(0.4),
                                            selectedColor.opacity(0.1)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: name.isEmpty ? 0 : nil, height: 1.5)
                                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: name)
                                .animation(.easeOut(duration: 0.3), value: selectedColor)
                        }
                    }
                }
                .padding(.horizontal, 4)
                
                // Description field
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text("Description")
                            .font(.custom("Lexend-Medium", size: 11))
                            .foregroundColor(.primary)
                            .opacity(0.7)
                            .textCase(.uppercase)
                            .kerning(0.5)
                        
                        Text("Optional")
                            .font(.custom("Lexend-Regular", size: 10))
                            .foregroundColor(.secondary.opacity(0.4))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(.quaternary.opacity(0.5))
                            )
                        
                        Spacer()
                    }
                    
                    VStack(alignment: .leading, spacing: 5) {
                        TextField("Add a brief description", text: $habitDescription)
                            .font(.custom("Lexend-Regular", size: 15))
                            .focused(isTextFieldFocused)
                            .textFieldStyle(PlainTextFieldStyle())
                            .foregroundColor(.secondary)
                            .padding(.vertical, 2)
                        
                        // Subtle underline for description
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(.quaternary)
                                .frame(height: 0.8)
                            
                            Rectangle()
                                .fill(.tertiary.opacity(habitDescription.isEmpty ? 0 : 0.6))
                                .frame(width: habitDescription.isEmpty ? 0 : nil, height: 1)
                                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: habitDescription)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 15)
            .glassBackground()
            
        }
        .padding(.horizontal, 14)
        .padding(.top, 20)
        
    }
    
    @ViewBuilder
    private func premiumColorButton(_ color: Color) -> some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                selectedColor = color
            }
            triggerHaptic(.impactLight)
        } label: {
            ZStack {
                // Shadow/glow effect
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: selectedColor == color ? 34 : 30, height: selectedColor == color ? 34 : 30)
                    //.blur(radius: selectedColor == color ? 3 : 1)
                
                // Main color circle
                Circle()
                    .fill(color)
                    .frame(width: selectedColor == color ? 28 : 24, height: selectedColor == color ? 28 : 24)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        .white.opacity(selectedColor == color ? 0.4 : 0.2),
                                        .clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: selectedColor == color ? 1.2 : 0.8
                            )
                    )
                    
                
                // Selection indicator
                if selectedColor == color {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 0.5)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: selectedColor)
    }
    
    private func colorButton(_ color: Color) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                selectedColor = color
            }
            triggerHaptic(.impactLight)
        }) {
            Circle()
                .fill(color)
                .frame(width: 26, height: 26)
                .background(
                    Circle()
                        .fill(.white.opacity(selectedColor == color ? 0.3 : 0))
                        .frame(width: 32, height: 32)
                )
                .overlay(
                    Circle()
                        .stroke(.white.opacity(selectedColor == color ? 0.8 : 0), lineWidth: 2)
                )
                .scaleEffect(selectedColor == color ? 1.15 : 1.0)
                .shadow(
                    color: color.opacity(selectedColor == color ? 0.3 : 0),
                    radius: selectedColor == color ? 4 : 0,
                    x: 0, y: 2
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
struct CreateHabitCoreSection_Previews: PreviewProvider {
    @State static var name = "Morning Meditation"
    @State static var habitDescription = "10 minutes of mindful breathing"
    @State static var icon = "leaf.fill"
    @State static var selectedColor = Color.green
    @FocusState static var isTextFieldFocused: Bool
    
    static let colors: [Color] = [
        .blue, .green, .orange, .red, .purple, .pink,
        .cyan, .mint, .indigo, .yellow, .brown, .gray
    ]
    
    static var previews: some View {
        Group {
            VStack {
                CreateHabitCoreSection(
                    name: $name,
                    habitDescription: $habitDescription,
                    icon: $icon,
                    selectedColor: $selectedColor,
                    isTextFieldFocused: $isTextFieldFocused,
                    colors: colors,
                    isBadHabit: false,
                    selectedIntensity: .moderate,
                    showIconPicker: { print("Icon picker tapped") },
                    showWallpaperPicker: { print("Wallpaper picker tapped") },
                    hasWallpaper: false
                )
            }
            .padding()
            .previewDisplayName("Light")
            
            CreateHabitCoreSection(
                name: $name,
                habitDescription: $habitDescription,
                icon: $icon,
                selectedColor: $selectedColor,
                isTextFieldFocused: $isTextFieldFocused,
                colors: colors,
                isBadHabit: false,
                selectedIntensity: .moderate,
                showIconPicker: { },
                showWallpaperPicker: { },
                hasWallpaper: true
            )
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark with Wallpaper")
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    
    }
}
