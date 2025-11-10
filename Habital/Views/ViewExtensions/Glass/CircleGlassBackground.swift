//
//  CircleGlassBackground.swift
//  Habital
//
//  Created by Elias Osarumwense on 04.08.25.
//

import SwiftUI

struct GlassCircleBackgroundModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    
    let borderWidth: CGFloat
    let backgroundColor: Color?
    
    init(borderWidth: CGFloat = 1.5, backgroundColor: Color? = nil) {
        self.borderWidth = borderWidth
        self.backgroundColor = backgroundColor
    }
    
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            // iOS 26+ uses native Liquid Glass effect
            content
                .glassEffect(in: .circle)
                .tint(backgroundColor ?? .clear)
        } else {
            // Fallback for iOS < 26 - Your existing vibrant implementation
            content
                .background(
                    ZStack {
                        // Glass morphism background - enhanced with more vibrant colors
                        Circle()
                            .fill(backgroundColor != nil ?
                                  AnyShapeStyle(backgroundColor!.opacity(colorScheme == .dark ? 0.6 : 0.5)) :
                                  AnyShapeStyle(.ultraThinMaterial))
                        
                        // Enhanced inner glow for better light mode visibility with more vibrant colors
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: colorScheme == .dark ? [
                                        backgroundColor?.opacity(0.4) ?? Color.white.opacity(0.15),
                                        backgroundColor?.opacity(0.2) ?? Color.white.opacity(0.08),
                                        Color.clear
                                    ] : [
                                        Color.white.opacity(0.9),
                                        backgroundColor?.opacity(0.6) ?? Color.white.opacity(0.5),
                                        backgroundColor?.opacity(0.3) ?? Color.white.opacity(0.3),
                                        Color.clear
                                    ],
                                    center: .topLeading,
                                    startRadius: 0,
                                    endRadius: 50
                                )
                            )
                        
                        // Enhanced border for better light mode contrast with vibrant colors
                        Circle()
                            .strokeBorder(
                                AngularGradient(
                                    colors: colorScheme == .dark ? [
                                        backgroundColor?.opacity(0.8) ?? Color.white.opacity(0.3),
                                        backgroundColor?.opacity(0.4) ?? Color.white.opacity(0.15),
                                        backgroundColor?.opacity(0.6) ?? Color.primary.opacity(0.2),
                                        backgroundColor?.opacity(0.3) ?? Color.clear,
                                        backgroundColor?.opacity(0.9) ?? Color.white.opacity(0.25)
                                    ] : [
                                        Color.white.opacity(0.95),
                                        backgroundColor?.opacity(0.8) ?? Color.gray.opacity(0.6),
                                        backgroundColor?.opacity(0.6) ?? Color.gray.opacity(0.4),
                                        backgroundColor?.opacity(0.4) ?? Color.black.opacity(0.2),
                                        Color.white.opacity(0.8)
                                    ],
                                    center: .center,
                                    startAngle: .degrees(0),
                                    endAngle: .degrees(360)
                                ),
                                lineWidth: borderWidth
                            )
                        
                        // Additional vibrant inner shadow for depth
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: colorScheme == .dark ? [
                                        Color.clear,
                                        backgroundColor?.opacity(0.3) ?? Color.black.opacity(0.1)
                                    ] : [
                                        Color.clear,
                                        backgroundColor?.opacity(0.2) ?? Color.black.opacity(0.05)
                                    ],
                                    center: .bottomTrailing,
                                    startRadius: 5,
                                    endRadius: 70
                                )
                            )
                        
                        // Enhanced highlight reflection for extra glass effect with vibrant colors
                        Circle()
                            .fill(
                                EllipticalGradient(
                                    colors: colorScheme == .dark ? [
                                        backgroundColor?.opacity(0.5) ?? Color.white.opacity(0.2),
                                        backgroundColor?.opacity(0.2) ?? Color.white.opacity(0.1),
                                        Color.clear
                                    ] : [
                                        Color.white.opacity(0.8),
                                        backgroundColor?.opacity(0.4) ?? Color.white.opacity(0.3),
                                        Color.clear
                                    ],
                                    center: .topLeading,
                                    startRadiusFraction: 0.05,
                                    endRadiusFraction: 0.5
                                )
                            )
                            .blur(radius: 0.8)
                        
                        // Additional vibrant color overlay for more saturation
                        if let bgColor = backgroundColor {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            bgColor.opacity(colorScheme == .dark ? 0.3 : 0.25),
                                            bgColor.opacity(colorScheme == .dark ? 0.15 : 0.1),
                                            Color.clear
                                        ],
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 30
                                    )
                                )
                                .blendMode(.overlay)
                        }
                    }
                )
        }
    }
}

// MARK: - Lightweight Glass Circle Background
struct LightGlassCircleBackgroundModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    
    let borderWidth: CGFloat
    let backgroundColor: Color?
    
    init(borderWidth: CGFloat = 1, backgroundColor: Color? = nil) {
        self.borderWidth = borderWidth
        self.backgroundColor = backgroundColor
    }
    
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            // iOS 26+ uses native Liquid Glass effect
            content
                .glassEffect(in: .circle)
                .tint(backgroundColor ?? .clear)
        } else {
            // Fallback for iOS < 26 - Simplified version
            content
                .background(
                    ZStack {
                        // Simplified glass background
                        Circle()
                            .fill(.thinMaterial)
                        
                        // Optional color tint overlay
                        if let backgroundColor = backgroundColor {
                            Circle()
                                .fill(
                                    backgroundColor.opacity(colorScheme == .dark ? 0.12 : 0.06)
                                )
                        }
                        
                        // Simple top highlight
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.white.opacity(colorScheme == .dark ? 0.03 : 0.4),
                                        Color.clear
                                    ],
                                    center: .topLeading,
                                    startRadius: 0,
                                    endRadius: 40
                                )
                            )
                        
                        // Simplified border
                        Circle()
                            .strokeBorder(
                                Color.primary.opacity(colorScheme == .dark ? 0.1 : 0.15),
                                lineWidth: borderWidth
                            )
                    }
                )
        }
    }
}

// MARK: - Modern Glass Circle Background
struct ModernGlassCircleBackgroundModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    
    let borderWidth: CGFloat
    let backgroundColor: Color?
    
    init(borderWidth: CGFloat = 0.5, backgroundColor: Color? = nil) {
        self.borderWidth = borderWidth
        self.backgroundColor = backgroundColor
    }
    
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            // iOS 26+ uses native Liquid Glass effect with interactive style
            content
                .glassEffect(
                    .regular.interactive(),
                    in: .circle
                )
                .tint(backgroundColor ?? .clear)
        } else {
            // Fallback for iOS < 26 - Modern implementation
            content
                .background(
                    ZStack {
                        // Base ultra-thin material
                        Circle()
                            .fill(.ultraThinMaterial)
                        
                        // Optional color tint overlay
                        if let backgroundColor = backgroundColor {
                            Circle()
                                .fill(
                                    backgroundColor.opacity(colorScheme == .dark ? 0.08 : 0.15)
                                )
                        }
                        
                        // Primary glass effect layer
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.white.opacity(colorScheme == .dark ? 0.15 : 0.35),
                                        Color.clear,
                                        Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05)
                                    ],
                                    center: .topLeading,
                                    startRadius: 0,
                                    endRadius: 50
                                )
                            )
                            .blendMode(.overlay)
                        
                        // Subtle border with glass catches
                        Circle()
                            .strokeBorder(
                                AngularGradient(
                                    colors: [
                                        Color.white.opacity(colorScheme == .dark ? 0.4 : 0.6),
                                        Color.white.opacity(colorScheme == .dark ? 0.1 : 0.2),
                                        Color.clear,
                                        Color.white.opacity(colorScheme == .dark ? 0.2 : 0.3)
                                    ],
                                    center: .center
                                ),
                                lineWidth: borderWidth
                            )
                    }
                    .shadow(
                        color: Color.black.opacity(colorScheme == .dark ? 0.25 : 0.08),
                        radius: 8,
                        x: 0,
                        y: 3
                    )
                )
        }
    }
}

// MARK: - View Extension
extension View {
    /// Applies a custom glass circle background effect with glassmorphism styling and vibrant colors
    /// - Parameters:
    ///   - borderWidth: The width of the gradient border (default: 1.5)
    ///   - backgroundColor: Optional background color tint (default: nil for material only)
    /// - Returns: A view with the vibrant glass circle background applied
    func glassCircleBackground(borderWidth: CGFloat = 1.5, backgroundColor: Color? = nil) -> some View {
        modifier(GlassCircleBackgroundModifier(borderWidth: borderWidth, backgroundColor: backgroundColor))
    }
    
    /// Applies a lightweight glass circle background effect optimized for performance
    /// - Parameters:
    ///   - borderWidth: The width of the border (default: 1)
    ///   - backgroundColor: Optional background color tint
    /// - Returns: A view with the lightweight glass circle background applied
    func lightGlassCircleBackground(borderWidth: CGFloat = 1, backgroundColor: Color? = nil) -> some View {
        modifier(LightGlassCircleBackgroundModifier(borderWidth: borderWidth, backgroundColor: backgroundColor))
    }
    
    /// Applies a modern glass circle background effect with advanced glassmorphism styling
    /// - Parameters:
    ///   - borderWidth: The width of the subtle border (default: 0.5)
    ///   - backgroundColor: Optional background color tint
    /// - Returns: A view with the modern glass circle background applied
    func modernGlassCircleBackground(borderWidth: CGFloat = 0.5, backgroundColor: Color? = nil) -> some View {
        modifier(ModernGlassCircleBackgroundModifier(borderWidth: borderWidth, backgroundColor: backgroundColor))
    }
}

// MARK: - Preview
struct GlassCircleBackgroundPreview: View {
    var body: some View {
        VStack(spacing: 30) {
            HStack(spacing: 20) {
                // Example usage with default values
                Text("📱")
                    .font(.title)
                    .frame(width: 60, height: 60)
                    .glassCircleBackground()
                
                // Example with vibrant blue tint
                Text("💎")
                    .font(.title)
                    .frame(width: 60, height: 60)
                    .glassCircleBackground(backgroundColor: .blue)
                
                // Example with vibrant green tint
                Text("🌿")
                    .font(.title)
                    .frame(width: 60, height: 60)
                    .glassCircleBackground(backgroundColor: .green)
            }
            
            HStack(spacing: 20) {
                // Example with vibrant purple tint and thick border
                Text("🔮")
                    .font(.title)
                    .frame(width: 60, height: 60)
                    .glassCircleBackground(borderWidth: 3, backgroundColor: .purple)
                
                // Example with vibrant red tint
                Text("❤️")
                    .font(.title)
                    .frame(width: 60, height: 60)
                    .glassCircleBackground(backgroundColor: .red)
                
                // Example with vibrant orange tint and thin border
                Text("🔥")
                    .font(.title)
                    .frame(width: 60, height: 60)
                    .glassCircleBackground(borderWidth: 0.8, backgroundColor: .orange)
            }
            
            HStack(spacing: 20) {
                // Example with vibrant pink tint
                Text("🌸")
                    .font(.title)
                    .frame(width: 60, height: 60)
                    .glassCircleBackground(backgroundColor: .pink)
                
                // Example with vibrant cyan tint
                Text("💧")
                    .font(.title)
                    .frame(width: 60, height: 60)
                    .glassCircleBackground(backgroundColor: .cyan)
                
                // Example with vibrant mint tint
                Text("🍃")
                    .font(.title)
                    .frame(width: 60, height: 60)
                    .glassCircleBackground(backgroundColor: .mint)
            }
            
            // Larger example with vibrant yellow
            VStack {
                Image(systemName: "star.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.yellow)
                Text("Vibrant Glass")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 100, height: 100)
            .glassCircleBackground(borderWidth: 2, backgroundColor: .yellow)
            
            Divider()
                .padding(.vertical)
            
            // Lightweight versions
            HStack(spacing: 20) {
                Text("🎯")
                    .font(.title)
                    .frame(width: 60, height: 60)
                    .lightGlassCircleBackground()
                
                Text("🎨")
                    .font(.title)
                    .frame(width: 60, height: 60)
                    .lightGlassCircleBackground(backgroundColor: .indigo)
            }
            
            // Modern versions
            HStack(spacing: 20) {
                Text("✨")
                    .font(.title)
                    .frame(width: 60, height: 60)
                    .modernGlassCircleBackground()
                
                Text("🌟")
                    .font(.title)
                    .frame(width: 60, height: 60)
                    .modernGlassCircleBackground(backgroundColor: .orange)
            }
        }
        .padding(40)
        .background(
            LinearGradient(
                colors: [.indigo, .purple, .pink, .orange],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

#Preview {
    GlassCircleBackgroundPreview()
}

extension View {
    @ViewBuilder
    func glassButton() -> some View {
        if #available(iOS 26.0, *) {
            self
                .buttonStyle(.glassProminent)
                .tint(.clear)
                
        } else {
            // Fallback style for iOS < 17
            self
                .buttonStyle(.borderedProminent)
                .tint(.clear)
                
        }
    }
}
