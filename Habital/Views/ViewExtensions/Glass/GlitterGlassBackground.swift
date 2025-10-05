//
//  GlitterGlassBackground.swift
//  Habital
//
//  Created by Elias Osarumwense on 13.08.25.
//

//
//  GlitterGlassBackground.swift
//  Habital
//
//  Created by Elias Osarumwense on 12.08.25.
//

import SwiftUI

// MARK: - Glitter Glass Background for Outstanding Habit Score View
struct GlitterGlassBackgroundModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    @State private var animateGlitter = false
    @State private var phase: Double = 0
    
    let cornerRadius: CGFloat
    let borderWidth: CGFloat
    let tintColor: Color?
    let glitterIntensity: Double
    
    init(cornerRadius: CGFloat = 20, borderWidth: CGFloat = 1.5, tintColor: Color? = nil, glitterIntensity: Double = 0.6) {
        self.cornerRadius = cornerRadius
        self.borderWidth = borderWidth
        self.tintColor = tintColor
        self.glitterIntensity = glitterIntensity
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Base glass background (same as your original)
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                    
                    // Optional color tint overlay
                    if let tintColor = tintColor {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                tintColor.opacity(colorScheme == .dark ? 0.08 : 0.15)
                            )
                    }
                    
                    // Enhanced inner glow (same as original)
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: colorScheme == .dark ? [
                                    Color.white.opacity(0.05),
                                    Color.clear,
                                    Color.clear
                                ] : [
                                    Color.white.opacity(0.6),
                                    Color.white.opacity(0.2),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    
                    // Subtle animated glitter border
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            AngularGradient(
                                gradient: Gradient(stops: [
                                    .init(color: glitterColor1, location: 0.0),
                                    .init(color: glitterColor2, location: 0.2),
                                    .init(color: glitterColor3, location: 0.4),
                                    .init(color: glitterColor1, location: 0.6),
                                    .init(color: glitterColor2, location: 0.8),
                                    .init(color: glitterColor1, location: 1.0)
                                ]),
                                center: .center,
                                startAngle: .degrees(phase),
                                endAngle: .degrees(phase + 360)
                            ),
                            lineWidth: borderWidth
                        )
                        .animation(
                            .linear(duration: 4.0)
                            .repeatForever(autoreverses: false),
                            value: phase
                        )
                    
                    // Shimmer overlay for extra sparkle
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    shimmerColor.opacity(animateGlitter ? 0.3 : 0.0),
                                    Color.clear,
                                    Color.clear,
                                    shimmerColor.opacity(animateGlitter ? 0.2 : 0.0),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: borderWidth * 0.8
                        )
                        .animation(
                            .easeInOut(duration: 2.5)
                            .repeatForever(autoreverses: true),
                            value: animateGlitter
                        )
                    
                    // Additional subtle shadow for light mode depth (same as original)
                    if colorScheme == .light {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.clear,
                                        Color.black.opacity(0.03)
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 100
                                )
                            )
                    }
                }
            )
            .onAppear {
                startGlitterAnimation()
            }
    }
    
    // MARK: - Glitter Colors
    
    private var glitterColor1: Color {
        if let tintColor = tintColor {
            return colorScheme == .dark ?
                tintColor.opacity(0.4 * glitterIntensity) :
                tintColor.opacity(0.6 * glitterIntensity)
        }
        return colorScheme == .dark ?
            Color.white.opacity(0.15 * glitterIntensity) :
            Color.gray.opacity(0.3 * glitterIntensity)
    }
    
    private var glitterColor2: Color {
        if let tintColor = tintColor {
            return colorScheme == .dark ?
                tintColor.opacity(0.2 * glitterIntensity) :
                tintColor.opacity(0.4 * glitterIntensity)
        }
        return colorScheme == .dark ?
            Color.white.opacity(0.08 * glitterIntensity) :
            Color.black.opacity(0.15 * glitterIntensity)
    }
    
    private var glitterColor3: Color {
        if let tintColor = tintColor {
            return colorScheme == .dark ?
                tintColor.opacity(0.1 * glitterIntensity) :
                tintColor.opacity(0.2 * glitterIntensity)
        }
        return Color.clear
    }
    
    private var shimmerColor: Color {
        if let tintColor = tintColor {
            return tintColor
        }
        return colorScheme == .dark ? Color.white : Color.gray
    }
    
    // MARK: - Animation Control
    
    private func startGlitterAnimation() {
        // Start the rotating gradient
        withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
            phase = 360
        }
        
        // Start the shimmer effect
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
            animateGlitter = true
        }
    }
}

// MARK: - Enhanced Glitter Version for Special Occasions
struct EnhancedGlitterGlassBackgroundModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    @State private var rotationAngle: Double = 0
    @State private var shimmerOffset: CGFloat = -200
    @State private var sparkleOpacity: Double = 0
    
    let cornerRadius: CGFloat
    let borderWidth: CGFloat
    let tintColor: Color?
    
    init(cornerRadius: CGFloat = 20, borderWidth: CGFloat = 2.0, tintColor: Color? = nil) {
        self.cornerRadius = cornerRadius
        self.borderWidth = borderWidth
        self.tintColor = tintColor
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Base glass background
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                    
                    // Enhanced color tint
                    if let tintColor = tintColor {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                tintColor.opacity(colorScheme == .dark ? 0.12 : 0.18)
                            )
                    }
                    
                    // Multiple rotating glitter borders
                    ForEach(0..<3, id: \.self) { index in
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(
                                AngularGradient(
                                    gradient: Gradient(colors: glitterColors),
                                    center: .center,
                                    startAngle: .degrees(rotationAngle + Double(index * 120)),
                                    endAngle: .degrees(rotationAngle + Double(index * 120) + 360)
                                ),
                                lineWidth: borderWidth / 3
                            )
                            .opacity(0.7 - Double(index) * 0.2)
                    }
                    
                    // Traveling shimmer effect
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    Color.clear,
                                    shimmerColor.opacity(0.8),
                                    shimmerColor.opacity(0.4),
                                    Color.clear,
                                    Color.clear
                                ],
                                startPoint: UnitPoint(x: (shimmerOffset + 200) / 400, y: 0),
                                endPoint: UnitPoint(x: (shimmerOffset + 280) / 400, y: 1)
                            ),
                            lineWidth: borderWidth * 0.6
                        )
                    
                    // Sparkle overlay
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            RadialGradient(
                                colors: [
                                    shimmerColor.opacity(sparkleOpacity * 0.1),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 50
                            )
                        )
                }
            )
            .onAppear {
                startEnhancedAnimation()
            }
    }
    
    private var glitterColors: [Color] {
        if let tintColor = tintColor {
            return [
                Color.clear,
                tintColor.opacity(0.3),
                tintColor.opacity(0.8),
                tintColor.opacity(0.5),
                Color.white.opacity(0.4),
                tintColor.opacity(0.3),
                Color.clear
            ]
        }
        
        return [
            Color.clear,
            Color.white.opacity(0.2),
            Color.white.opacity(0.6),
            Color.white.opacity(0.3),
            Color.clear
        ]
    }
    
    private var shimmerColor: Color {
        tintColor ?? (colorScheme == .dark ? Color.white : Color.gray)
    }
    
    private func startEnhancedAnimation() {
        // Rotating gradient
        withAnimation(.linear(duration: 6.0).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
        
        // Traveling shimmer
        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: false)) {
            shimmerOffset = 200
        }
        
        // Sparkle pulse
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            sparkleOpacity = 1.0
        }
    }
}

// MARK: - View Extensions
extension View {
    /// Applies a subtle glitter glass background effect for outstanding habit scores
    /// - Parameters:
    ///   - cornerRadius: The corner radius for the glass effect (default: 20)
    ///   - borderWidth: The width of the glitter border (default: 1.5)
    ///   - tintColor: Optional color tint for the glass and glitter effect
    ///   - glitterIntensity: Intensity of the glitter effect (0.0 to 1.0, default: 0.6)
    /// - Returns: A view with the glitter glass background applied
    func glitterGlassBackground(
        cornerRadius: CGFloat = 20,
        borderWidth: CGFloat = 1.5,
        tintColor: Color? = nil,
        glitterIntensity: Double = 0.6
    ) -> some View {
        modifier(GlitterGlassBackgroundModifier(
            cornerRadius: cornerRadius,
            borderWidth: borderWidth,
            tintColor: tintColor,
            glitterIntensity: glitterIntensity
        ))
    }
    
    /// Applies an enhanced glitter glass background for exceptional scores
    /// - Parameters:
    ///   - cornerRadius: The corner radius for the glass effect (default: 20)
    ///   - borderWidth: The width of the enhanced glitter border (default: 2.0)
    ///   - tintColor: Optional color tint for the glass and glitter effect
    /// - Returns: A view with the enhanced glitter glass background applied
    func enhancedGlitterGlassBackground(
        cornerRadius: CGFloat = 20,
        borderWidth: CGFloat = 2.0,
        tintColor: Color? = nil
    ) -> some View {
        modifier(EnhancedGlitterGlassBackgroundModifier(
            cornerRadius: cornerRadius,
            borderWidth: borderWidth,
            tintColor: tintColor
        ))
    }
}

// MARK: - Preview
struct GlitterGlassBackgroundPreview: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Subtle glitter version
                VStack(spacing: 16) {
                    Text("Habit Score")
                        .font(.headline)
                    
                    HStack {
                        Text("92")
                            .font(.largeTitle.bold())
                            .foregroundColor(.green)
                        Text("/100")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("Excellent Performance!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(20)
                .glitterGlassBackground(tintColor: .green)
                
                // Enhanced version for perfect scores
                VStack(spacing: 16) {
                    Text("Perfect Streak!")
                        .font(.headline)
                    
                    HStack {
                        Text("100")
                            .font(.largeTitle.bold())
                            .foregroundColor(.yellow)
                        Text("/100")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("Outstanding Achievement! 🏆")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(20)
                .enhancedGlitterGlassBackground(tintColor: .yellow)
                
                // Different intensities
                HStack(spacing: 16) {
                    VStack {
                        Text("Subtle")
                        Text("75/100")
                            .font(.title2.bold())
                    }
                    .padding()
                    .glitterGlassBackground(
                        tintColor: .blue,
                        glitterIntensity: 0.3
                    )
                    
                    VStack {
                        Text("Normal")
                        Text("85/100")
                            .font(.title2.bold())
                    }
                    .padding()
                    .glitterGlassBackground(
                        tintColor: .purple,
                        glitterIntensity: 0.6
                    )
                    
                    VStack {
                        Text("Intense")
                        Text("95/100")
                            .font(.title2.bold())
                    }
                    .padding()
                    .glitterGlassBackground(
                        tintColor: .orange,
                        glitterIntensity: 1.0
                    )
                }
            }
            .padding()
        }
        .background(
            LinearGradient(
                colors: [
                    Color(hex: "1A1A1A"),
                    Color(hex: "2D2D2D")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}


#Preview {
    GlitterGlassBackgroundPreview()
}
