//
//  HabitIconStyleTester.swift
//  Habital
//
//  Created on 11.09.25.
//

import SwiftUI

// MARK: - Style 1: Soft Minimal (Enhanced)

/// Clean, minimalist design with sophisticated internal color gradients
struct SoftMinimalIconView: View {
    let iconName: String?
    let isActive: Bool
    let habitColor: Color
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            // Multi-stop radial gradient background for depth
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(stops: [
                            .init(color: habitColor.opacity(isActive ? 0.25 : 0.1), location: 0.0),
                            .init(color: habitColor.opacity(isActive ? 0.18 : 0.07), location: 0.4),
                            .init(color: habitColor.opacity(isActive ? 0.12 : 0.05), location: 0.7),
                            .init(color: habitColor.opacity(isActive ? 0.08 : 0.03), location: 1.0)
                        ]),
                        center: UnitPoint(x: 0.35, y: 0.35),
                        startRadius: 2,
                        endRadius: 25
                    )
                )
                .frame(width: 41, height: 41)
                .overlay(
                    // Subtle highlight on top-left
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(colorScheme == .dark ? 0.12 : 0.25),
                                    Color.clear
                                ]),
                                center: UnitPoint(x: 0.3, y: 0.3),
                                startRadius: 2,
                                endRadius: 18
                            )
                        )
                )
                .overlay(
                    // Darker shading on bottom-right
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.clear,
                                    (colorScheme == .dark ? Color.black : habitColor).opacity(isActive ? 0.15 : 0.08)
                                ]),
                                center: UnitPoint(x: 0.7, y: 0.7),
                                startRadius: 8,
                                endRadius: 22
                            )
                        )
                )
                // Sophisticated gradient border
                .overlay(
                    Circle()
                        .strokeBorder(
                            AngularGradient(
                                gradient: Gradient(stops: [
                                    .init(color: habitColor.opacity(isActive ? 0.6 : 0.25), location: 0.0),
                                    .init(color: habitColor.opacity(isActive ? 0.3 : 0.12), location: 0.25),
                                    .init(color: habitColor.opacity(isActive ? 0.5 : 0.2), location: 0.5),
                                    .init(color: habitColor.opacity(isActive ? 0.4 : 0.15), location: 0.75),
                                    .init(color: habitColor.opacity(isActive ? 0.6 : 0.25), location: 1.0)
                                ]),
                                center: .center,
                                startAngle: .degrees(135),
                                endAngle: .degrees(495)
                            ),
                            lineWidth: isActive ? 2.0 : 1.5
                        )
                )
                // Inner accent ring
                .overlay(
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(colorScheme == .dark ? 0.2 : 0.35),
                                    Color.clear,
                                    Color.clear
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.8
                        )
                        .padding(2)
                )
            
            // Icon with enhanced color treatment
            if let iconName = iconName, !iconName.isEmpty {
                if iconName.count == 1 || (iconName.first?.isEmoji ?? false) {
                    Text(iconName)
                        .font(.system(size: 25))
                        .saturation(isActive ? 1.2 : 0.0)
                        .brightness(isActive ? 0.05 : 0.0)
                        .opacity(isActive ? 1.0 : 0.6)
                } else {
                    Image(systemName: iconName)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    isActive ? habitColor.opacity(0.95) : .gray,
                                    isActive ? habitColor.opacity(0.75) : .gray.opacity(0.7)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .opacity(isActive ? 1.0 : 0.5)
                }
            }
        }
    }
}

// MARK: - Style 2: Bold Glassmorphic (Enhanced)

/// Premium glass effect with rich internal gradients and luminous depth
struct BoldGlassmorphicIconView: View {
    let iconName: String?
    let isActive: Bool
    let habitColor: Color
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            // Rich multi-layer radial gradient base
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(stops: [
                            .init(color: habitColor.opacity(isActive ? 0.45 : 0.2), location: 0.0),
                            .init(color: habitColor.opacity(isActive ? 0.35 : 0.15), location: 0.3),
                            .init(color: habitColor.opacity(isActive ? 0.25 : 0.1), location: 0.6),
                            .init(color: habitColor.opacity(isActive ? 0.15 : 0.05), location: 1.0)
                        ]),
                        center: .center,
                        startRadius: 5,
                        endRadius: 22
                    )
                )
                .frame(width: 41, height: 41)
                .overlay(
                    // Top-left bright highlight
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(colorScheme == .dark ? 0.25 : 0.4),
                                    Color.white.opacity(colorScheme == .dark ? 0.08 : 0.12),
                                    Color.clear
                                ]),
                                center: UnitPoint(x: 0.25, y: 0.25),
                                startRadius: 3,
                                endRadius: 20
                            )
                        )
                )
                .overlay(
                    // Bottom-right deeper color
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.clear,
                                    habitColor.opacity(isActive ? 0.3 : 0.12),
                                    habitColor.opacity(isActive ? 0.4 : 0.18)
                                ]),
                                center: UnitPoint(x: 0.75, y: 0.75),
                                startRadius: 5,
                                endRadius: 22
                            )
                        )
                )
                // Angular shimmer border
                .overlay(
                    Circle()
                        .strokeBorder(
                            AngularGradient(
                                gradient: Gradient(stops: [
                                    .init(color: Color.white.opacity(colorScheme == .dark ? 0.45 : 0.65), location: 0.0),
                                    .init(color: habitColor.opacity(isActive ? 0.5 : 0.25), location: 0.2),
                                    .init(color: Color.white.opacity(colorScheme == .dark ? 0.25 : 0.4), location: 0.4),
                                    .init(color: habitColor.opacity(isActive ? 0.4 : 0.2), location: 0.6),
                                    .init(color: Color.white.opacity(colorScheme == .dark ? 0.35 : 0.55), location: 0.8),
                                    .init(color: Color.white.opacity(colorScheme == .dark ? 0.45 : 0.65), location: 1.0)
                                ]),
                                center: .center,
                                startAngle: .degrees(0),
                                endAngle: .degrees(360)
                            ),
                            lineWidth: 1.8
                        )
                )
                // Inner luminous ring
                .overlay(
                    Circle()
                        .strokeBorder(
                            AngularGradient(
                                gradient: Gradient(colors: [
                                    habitColor.opacity(isActive ? 0.5 : 0.2),
                                    habitColor.opacity(isActive ? 0.2 : 0.08),
                                    habitColor.opacity(isActive ? 0.4 : 0.15),
                                    habitColor.opacity(isActive ? 0.25 : 0.1)
                                ]),
                                center: .center,
                                startAngle: .degrees(45),
                                endAngle: .degrees(405)
                            ),
                            lineWidth: 1.0
                        )
                        .padding(2)
                )
            
            // Icon with sophisticated color treatment
            if let iconName = iconName, !iconName.isEmpty {
                if iconName.count == 1 || (iconName.first?.isEmoji ?? false) {
                    Text(iconName)
                        .font(.system(size: 25))
                        .saturation(isActive ? 1.3 : 0.0)
                        .brightness(isActive ? 0.1 : 0.0)
                        .opacity(isActive ? 1.0 : 0.6)
                } else {
                    Image(systemName: iconName)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: colorScheme == .dark ? [
                                    Color.white.opacity(0.95),
                                    Color.white.opacity(0.8)
                                ] : [
                                    habitColor.opacity(isActive ? 1.0 : 0.6),
                                    habitColor.opacity(isActive ? 0.75 : 0.45)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .opacity(isActive ? 1.0 : 0.5)
                }
            }
        }
    }
}

// MARK: - Style 3: Vibrant Solid (Enhanced)

/// Bold, rich color design with sophisticated internal gradients and dimension
struct VibrantSolidIconView: View {
    let iconName: String?
    let isActive: Bool
    let habitColor: Color
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            // Rich angular gradient background
            Circle()
                .fill(
                    AngularGradient(
                        gradient: Gradient(stops: [
                            .init(color: habitColor.opacity(isActive ? 1.0 : 0.4), location: 0.0),
                            .init(color: habitColor.opacity(isActive ? 0.85 : 0.35), location: 0.15),
                            .init(color: habitColor.opacity(isActive ? 1.0 : 0.4), location: 0.35),
                            .init(color: habitColor.opacity(isActive ? 0.9 : 0.37), location: 0.5),
                            .init(color: habitColor.opacity(isActive ? 1.0 : 0.4), location: 0.65),
                            .init(color: habitColor.opacity(isActive ? 0.88 : 0.36), location: 0.85),
                            .init(color: habitColor.opacity(isActive ? 1.0 : 0.4), location: 1.0)
                        ]),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    )
                )
                .frame(width: 41, height: 41)
                .overlay(
                    // Luminous top-left highlight
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(stops: [
                                    .init(color: Color.white.opacity(isActive ? 0.35 : 0.2), location: 0.0),
                                    .init(color: Color.white.opacity(isActive ? 0.15 : 0.08), location: 0.4),
                                    .init(color: Color.clear, location: 0.7)
                                ]),
                                center: UnitPoint(x: 0.28, y: 0.28),
                                startRadius: 2,
                                endRadius: 18
                            )
                        )
                )
                .overlay(
                    // Deeper shading on bottom-right
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(stops: [
                                    .init(color: Color.clear, location: 0.3),
                                    .init(color: Color.black.opacity(isActive ? 0.15 : 0.08), location: 0.7),
                                    .init(color: Color.black.opacity(isActive ? 0.2 : 0.12), location: 1.0)
                                ]),
                                center: UnitPoint(x: 0.72, y: 0.72),
                                startRadius: 5,
                                endRadius: 22
                            )
                        )
                )
                // Angular shimmer border
                .overlay(
                    Circle()
                        .strokeBorder(
                            AngularGradient(
                                gradient: Gradient(stops: [
                                    .init(color: Color.white.opacity(0.7), location: 0.0),
                                    .init(color: Color.white.opacity(0.25), location: 0.15),
                                    .init(color: Color.white.opacity(0.5), location: 0.3),
                                    .init(color: Color.white.opacity(0.15), location: 0.5),
                                    .init(color: Color.white.opacity(0.6), location: 0.65),
                                    .init(color: Color.white.opacity(0.2), location: 0.85),
                                    .init(color: Color.white.opacity(0.7), location: 1.0)
                                ]),
                                center: .center,
                                startAngle: .degrees(135),
                                endAngle: .degrees(495)
                            ),
                            lineWidth: 1.2
                        )
                )
                // Inner bright accent ring
                .overlay(
                    Circle()
                        .strokeBorder(
                            AngularGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.4),
                                    Color.white.opacity(0.1),
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.05),
                                    Color.white.opacity(0.35)
                                ]),
                                center: .center,
                                startAngle: .degrees(90),
                                endAngle: .degrees(450)
                            ),
                            lineWidth: 0.8
                        )
                        .padding(2.5)
                )
            
            // Premium white icon with gradient
            if let iconName = iconName, !iconName.isEmpty {
                if iconName.count == 1 || (iconName.first?.isEmoji ?? false) {
                    Text(iconName)
                        .font(.system(size: 25))
                        .saturation(isActive ? 1.25 : 0.0)
                        .brightness(isActive ? 0.15 : 0.0)
                        .opacity(isActive ? 1.0 : 0.6)
                } else {
                    Image(systemName: iconName)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.98),
                                    Color.white.opacity(0.85)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .opacity(isActive ? 1.0 : 0.7)
                }
            }
        }
    }
}

// MARK: - Preview Comparison

struct HabitIconStyleTester_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 5) {
                    Text("HabitIconView Style Comparison")
                        .font(.title2.bold())
                    Text("Compare three different styling approaches")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // Current Style
                VStack(spacing: 15) {
                    Text("Current Style")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    HStack(spacing: 20) {
                        VStack {
                            HabitIconView(
                                iconName: "book.fill",
                                isActive: true,
                                habitColor: .blue,
                                streak: 0,
                                showStreaks: false,
                                useModernBadges: true,
                                isFutureDate: false
                            )
                            Text("Active")
                                .font(.caption)
                        }
                        
                        VStack {
                            HabitIconView(
                                iconName: "dumbbell.fill",
                                isActive: false,
                                habitColor: .red,
                                streak: 0,
                                showStreaks: false,
                                useModernBadges: true,
                                isFutureDate: false
                            )
                            Text("Inactive")
                                .font(.caption)
                        }
                        
                        VStack {
                            HabitIconView(
                                iconName: "🏃",
                                isActive: true,
                                habitColor: .green,
                                streak: 0,
                                showStreaks: false,
                                useModernBadges: true,
                                isFutureDate: false
                            )
                            Text("Emoji")
                                .font(.caption)
                        }
                        
                        VStack {
                            HabitIconView(
                                iconName: "leaf.fill",
                                isActive: true,
                                habitColor: .purple,
                                streak: 0,
                                showStreaks: false,
                                useModernBadges: true,
                                isFutureDate: false
                            )
                            Text("Purple")
                                .font(.caption)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(15)
                .padding(.horizontal)
                
                Divider()
                
                // Style 1: Soft Minimal
                VStack(spacing: 15) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Style 1: Soft Minimal (Enhanced)")
                            .font(.headline)
                        Text("Sophisticated internal gradients with natural depth")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    HStack(spacing: 20) {
                        VStack {
                            SoftMinimalIconView(
                                iconName: "book.fill",
                                isActive: true,
                                habitColor: .blue
                            )
                            Text("Active")
                                .font(.caption)
                        }
                        
                        VStack {
                            SoftMinimalIconView(
                                iconName: "dumbbell.fill",
                                isActive: false,
                                habitColor: .red
                            )
                            Text("Inactive")
                                .font(.caption)
                        }
                        
                        VStack {
                            SoftMinimalIconView(
                                iconName: "🏃",
                                isActive: true,
                                habitColor: .green
                            )
                            Text("Emoji")
                                .font(.caption)
                        }
                        
                        VStack {
                            SoftMinimalIconView(
                                iconName: "leaf.fill",
                                isActive: true,
                                habitColor: .purple
                            )
                            Text("Purple")
                                .font(.caption)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(15)
                .padding(.horizontal)
                
                // Style 2: Bold Glassmorphic
                VStack(spacing: 15) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Style 2: Bold Glassmorphic (Enhanced)")
                            .font(.headline)
                        Text("Rich layered gradients with angular shimmer")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    HStack(spacing: 20) {
                        VStack {
                            BoldGlassmorphicIconView(
                                iconName: "book.fill",
                                isActive: true,
                                habitColor: .blue
                            )
                            Text("Active")
                                .font(.caption)
                        }
                        
                        VStack {
                            BoldGlassmorphicIconView(
                                iconName: "dumbbell.fill",
                                isActive: false,
                                habitColor: .red
                            )
                            Text("Inactive")
                                .font(.caption)
                        }
                        
                        VStack {
                            BoldGlassmorphicIconView(
                                iconName: "🏃",
                                isActive: true,
                                habitColor: .green
                            )
                            Text("Emoji")
                                .font(.caption)
                        }
                        
                        VStack {
                            BoldGlassmorphicIconView(
                                iconName: "leaf.fill",
                                isActive: true,
                                habitColor: .purple
                            )
                            Text("Purple")
                                .font(.caption)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(15)
                .padding(.horizontal)
                
                // Style 3: Vibrant Solid
                VStack(spacing: 15) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Style 3: Vibrant Solid (Enhanced)")
                            .font(.headline)
                        Text("Bold angular gradients with dimensional shading")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    HStack(spacing: 20) {
                        VStack {
                            VibrantSolidIconView(
                                iconName: "book.fill",
                                isActive: true,
                                habitColor: .blue
                            )
                            Text("Active")
                                .font(.caption)
                        }
                        
                        VStack {
                            VibrantSolidIconView(
                                iconName: "dumbbell.fill",
                                isActive: false,
                                habitColor: .red
                            )
                            Text("Inactive")
                                .font(.caption)
                        }
                        
                        VStack {
                            VibrantSolidIconView(
                                iconName: "🏃",
                                isActive: true,
                                habitColor: .green
                            )
                            Text("Emoji")
                                .font(.caption)
                        }
                        
                        VStack {
                            VibrantSolidIconView(
                                iconName: "leaf.fill",
                                isActive: true,
                                habitColor: .purple
                            )
                            Text("Purple")
                                .font(.caption)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(15)
                .padding(.horizontal)
                
                // Color variety test
                Divider()
                    .padding(.top)
                
                VStack(spacing: 15) {
                    Text("Color Variety Test")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    // Current Style
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current")
                            .font(.subheadline.bold())
                        HStack(spacing: 12) {
                            ForEach([Color.red, .orange, .yellow, .green, .cyan, .blue, .purple, .pink], id: \.self) { color in
                                HabitIconView(
                                    iconName: "star.fill",
                                    isActive: true,
                                    habitColor: color,
                                    streak: 0,
                                    showStreaks: false,
                                    useModernBadges: true,
                                    isFutureDate: false
                                )
                            }
                        }
                    }
                    
                    // Style 1
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Style 1")
                            .font(.subheadline.bold())
                        HStack(spacing: 12) {
                            ForEach([Color.red, .orange, .yellow, .green, .cyan, .blue, .purple, .pink], id: \.self) { color in
                                SoftMinimalIconView(
                                    iconName: "star.fill",
                                    isActive: true,
                                    habitColor: color
                                )
                            }
                        }
                    }
                    
                    // Style 2
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Style 2")
                            .font(.subheadline.bold())
                        HStack(spacing: 12) {
                            ForEach([Color.red, .orange, .yellow, .green, .cyan, .blue, .purple, .pink], id: \.self) { color in
                                BoldGlassmorphicIconView(
                                    iconName: "star.fill",
                                    isActive: true,
                                    habitColor: color
                                )
                            }
                        }
                    }
                    
                    // Style 3
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Style 3")
                            .font(.subheadline.bold())
                        HStack(spacing: 12) {
                            ForEach([Color.red, .orange, .yellow, .green, .cyan, .blue, .purple, .pink], id: \.self) { color in
                                VibrantSolidIconView(
                                    iconName: "star.fill",
                                    isActive: true,
                                    habitColor: color
                                )
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(15)
                .padding(.horizontal)
                
                Spacer(minLength: 20)
            }
        }
        .previewDisplayName("Light Mode")
        
        ScrollView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 5) {
                    Text("HabitIconView Style Comparison")
                        .font(.title2.bold())
                    Text("Compare three different styling approaches")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // Current Style
                VStack(spacing: 15) {
                    Text("Current Style")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    HStack(spacing: 20) {
                        VStack {
                            HabitIconView(
                                iconName: "book.fill",
                                isActive: true,
                                habitColor: .blue,
                                streak: 0,
                                showStreaks: false,
                                useModernBadges: true,
                                isFutureDate: false
                            )
                            Text("Active")
                                .font(.caption)
                        }
                        
                        VStack {
                            HabitIconView(
                                iconName: "dumbbell.fill",
                                isActive: false,
                                habitColor: .red,
                                streak: 0,
                                showStreaks: false,
                                useModernBadges: true,
                                isFutureDate: false
                            )
                            Text("Inactive")
                                .font(.caption)
                        }
                        
                        VStack {
                            HabitIconView(
                                iconName: "🏃",
                                isActive: true,
                                habitColor: .green,
                                streak: 0,
                                showStreaks: false,
                                useModernBadges: true,
                                isFutureDate: false
                            )
                            Text("Emoji")
                                .font(.caption)
                        }
                        
                        VStack {
                            HabitIconView(
                                iconName: "leaf.fill",
                                isActive: true,
                                habitColor: .purple,
                                streak: 0,
                                showStreaks: false,
                                useModernBadges: true,
                                isFutureDate: false
                            )
                            Text("Purple")
                                .font(.caption)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray5))
                .cornerRadius(15)
                .padding(.horizontal)
                
                Divider()
                
                // Style 1: Soft Minimal
                VStack(spacing: 15) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Style 1: Soft Minimal (Enhanced)")
                            .font(.headline)
                        Text("Luminous accents with sophisticated color infusion")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    HStack(spacing: 20) {
                        VStack {
                            SoftMinimalIconView(
                                iconName: "book.fill",
                                isActive: true,
                                habitColor: .blue
                            )
                            Text("Active")
                                .font(.caption)
                        }
                        
                        VStack {
                            SoftMinimalIconView(
                                iconName: "dumbbell.fill",
                                isActive: false,
                                habitColor: .red
                            )
                            Text("Inactive")
                                .font(.caption)
                        }
                        
                        VStack {
                            SoftMinimalIconView(
                                iconName: "🏃",
                                isActive: true,
                                habitColor: .green
                            )
                            Text("Emoji")
                                .font(.caption)
                        }
                        
                        VStack {
                            SoftMinimalIconView(
                                iconName: "leaf.fill",
                                isActive: true,
                                habitColor: .purple
                            )
                            Text("Purple")
                                .font(.caption)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray5))
                .cornerRadius(15)
                .padding(.horizontal)
                
                // Style 2: Bold Glassmorphic
                VStack(spacing: 15) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Style 2: Bold Glassmorphic (Enhanced)")
                            .font(.headline)
                        Text("Premium glass with angular shimmer and radiance")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    HStack(spacing: 20) {
                        VStack {
                            BoldGlassmorphicIconView(
                                iconName: "book.fill",
                                isActive: true,
                                habitColor: .blue
                            )
                            Text("Active")
                                .font(.caption)
                        }
                        
                        VStack {
                            BoldGlassmorphicIconView(
                                iconName: "dumbbell.fill",
                                isActive: false,
                                habitColor: .red
                            )
                            Text("Inactive")
                                .font(.caption)
                        }
                        
                        VStack {
                            BoldGlassmorphicIconView(
                                iconName: "🏃",
                                isActive: true,
                                habitColor: .green
                            )
                            Text("Emoji")
                                .font(.caption)
                        }
                        
                        VStack {
                            BoldGlassmorphicIconView(
                                iconName: "leaf.fill",
                                isActive: true,
                                habitColor: .purple
                            )
                            Text("Purple")
                                .font(.caption)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray5))
                .cornerRadius(15)
                .padding(.horizontal)
                
                // Style 3: Vibrant Solid
                VStack(spacing: 15) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Style 3: Vibrant Solid (Enhanced)")
                            .font(.headline)
                        Text("Rich angular gradients with multi-layer depth")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    HStack(spacing: 20) {
                        VStack {
                            VibrantSolidIconView(
                                iconName: "book.fill",
                                isActive: true,
                                habitColor: .blue
                            )
                            Text("Active")
                                .font(.caption)
                        }
                        
                        VStack {
                            VibrantSolidIconView(
                                iconName: "dumbbell.fill",
                                isActive: false,
                                habitColor: .red
                            )
                            Text("Inactive")
                                .font(.caption)
                        }
                        
                        VStack {
                            VibrantSolidIconView(
                                iconName: "🏃",
                                isActive: true,
                                habitColor: .green
                            )
                            Text("Emoji")
                                .font(.caption)
                        }
                        
                        VStack {
                            VibrantSolidIconView(
                                iconName: "leaf.fill",
                                isActive: true,
                                habitColor: .purple
                            )
                            Text("Purple")
                                .font(.caption)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray5))
                .cornerRadius(15)
                .padding(.horizontal)
                
                // Color variety test
                Divider()
                    .padding(.top)
                
                VStack(spacing: 15) {
                    Text("Color Variety Test")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    // Current Style
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current")
                            .font(.subheadline.bold())
                        HStack(spacing: 12) {
                            ForEach([Color.red, .orange, .yellow, .green, .cyan, .blue, .purple, .pink], id: \.self) { color in
                                HabitIconView(
                                    iconName: "star.fill",
                                    isActive: true,
                                    habitColor: color,
                                    streak: 0,
                                    showStreaks: false,
                                    useModernBadges: true,
                                    isFutureDate: false
                                )
                            }
                        }
                    }
                    
                    // Style 1
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Style 1")
                            .font(.subheadline.bold())
                        HStack(spacing: 12) {
                            ForEach([Color.red, .orange, .yellow, .green, .cyan, .blue, .purple, .pink], id: \.self) { color in
                                SoftMinimalIconView(
                                    iconName: "star.fill",
                                    isActive: true,
                                    habitColor: color
                                )
                            }
                        }
                    }
                    
                    // Style 2
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Style 2")
                            .font(.subheadline.bold())
                        HStack(spacing: 12) {
                            ForEach([Color.red, .orange, .yellow, .green, .cyan, .blue, .purple, .pink], id: \.self) { color in
                                BoldGlassmorphicIconView(
                                    iconName: "star.fill",
                                    isActive: true,
                                    habitColor: color
                                )
                            }
                        }
                    }
                    
                    // Style 3
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Style 3")
                            .font(.subheadline.bold())
                        HStack(spacing: 12) {
                            ForEach([Color.red, .orange, .yellow, .green, .cyan, .blue, .purple, .pink], id: \.self) { color in
                                VibrantSolidIconView(
                                    iconName: "star.fill",
                                    isActive: true,
                                    habitColor: color
                                )
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray5))
                .cornerRadius(15)
                .padding(.horizontal)
                
                Spacer(minLength: 20)
            }
        }
        .preferredColorScheme(.dark)
        .previewDisplayName("Dark Mode")
    }
}
