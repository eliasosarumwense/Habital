//
//  HabitIconStyleTester.swift
//  Habital
//
//  Created on 11.09.25.
//

import SwiftUI

// MARK: - Style 1: Soft Minimal

/// Clean, minimalist design with subtle gradients and soft shadows
struct SoftMinimalIconView: View {
    let iconName: String?
    let isActive: Bool
    let habitColor: Color
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            // Soft background with subtle elevation
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(.systemBackground),
                            Color(.systemBackground).opacity(0.95)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 41, height: 41)
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 4, x: 0, y: 2)
                .overlay(
                    Circle()
                        .strokeBorder(
                            habitColor.opacity(isActive ? 0.3 : 0.15),
                            lineWidth: 2
                        )
                )
            
            // Icon
            if let iconName = iconName, !iconName.isEmpty {
                if iconName.count == 1 || (iconName.first?.isEmoji ?? false) {
                    Text(iconName)
                        .font(.system(size: 25))
                        .saturation(isActive ? 1.0 : 0.0)
                        .opacity(isActive ? 1.0 : 0.6)
                } else {
                    Image(systemName: iconName)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                        .foregroundColor(isActive ? habitColor : .gray)
                }
            }
        }
    }
}

// MARK: - Style 2: Bold Glassmorphic

/// Modern glass effect with vibrant colors and depth
struct BoldGlassmorphicIconView: View {
    let iconName: String?
    let isActive: Bool
    let habitColor: Color
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            // Glass background with color tint
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 41, height: 41)
                .background(
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    habitColor.opacity(isActive ? 0.4 : 0.15),
                                    habitColor.opacity(isActive ? 0.2 : 0.05)
                                ]),
                                center: .center,
                                startRadius: 10,
                                endRadius: 25
                            )
                        )
                        .frame(width: 41, height: 41)
                )
                .overlay(
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(colorScheme == .dark ? 0.3 : 0.5),
                                    Color.white.opacity(colorScheme == .dark ? 0.1 : 0.2)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: habitColor.opacity(isActive ? 0.2 : 0.05), radius: 8, x: 0, y: 4)
            
            // Icon with white/light appearance
            if let iconName = iconName, !iconName.isEmpty {
                if iconName.count == 1 || (iconName.first?.isEmoji ?? false) {
                    Text(iconName)
                        .font(.system(size: 25))
                        .saturation(isActive ? 1.0 : 0.0)
                        .opacity(isActive ? 1.0 : 0.6)
                } else {
                    Image(systemName: iconName)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                        .foregroundColor(colorScheme == .dark ? .white : habitColor)
                        .opacity(isActive ? 1.0 : 0.5)
                }
            }
        }
    }
}

// MARK: - Style 3: Vibrant Solid

/// Bold, colorful solid design with high contrast
struct VibrantSolidIconView: View {
    let iconName: String?
    let isActive: Bool
    let habitColor: Color
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            // Solid colored background with gradient
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            habitColor.opacity(isActive ? 1.0 : 0.3),
                            habitColor.opacity(isActive ? 0.85 : 0.25)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 41, height: 41)
                .shadow(color: habitColor.opacity(isActive ? 0.3 : 0.1), radius: 6, x: 0, y: 3)
                .overlay(
                    // Inner glow effect
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.4),
                                    Color.white.opacity(0.0)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                        .padding(2)
                )
            
            // White icon for maximum contrast
            if let iconName = iconName, !iconName.isEmpty {
                if iconName.count == 1 || (iconName.first?.isEmoji ?? false) {
                    Text(iconName)
                        .font(.system(size: 25))
                        .saturation(isActive ? 1.0 : 0.0)
                        .opacity(isActive ? 1.0 : 0.6)
                } else {
                    Image(systemName: iconName)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                        .foregroundColor(.white)
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
                        Text("Style 1: Soft Minimal")
                            .font(.headline)
                        Text("Clean background with colored border")
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
                        Text("Style 2: Bold Glassmorphic")
                            .font(.headline)
                        Text("Glass material with radial color glow")
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
                        Text("Style 3: Vibrant Solid")
                            .font(.headline)
                        Text("Bold solid color with white icons")
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
                        Text("Style 1: Soft Minimal")
                            .font(.headline)
                        Text("Clean background with colored border")
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
                        Text("Style 2: Bold Glassmorphic")
                            .font(.headline)
                        Text("Glass material with radial color glow")
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
                        Text("Style 3: Vibrant Solid")
                            .font(.headline)
                        Text("Bold solid color with white icons")
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
