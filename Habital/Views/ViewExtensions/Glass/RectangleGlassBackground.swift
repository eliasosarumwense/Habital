//
//  Glassbackground.swift
//  Habital
//
//  Created by Elias Osarumwense on 04.08.25.
//

import SwiftUI

struct GlassBackgroundModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    
    let cornerRadius: CGFloat
    let borderWidth: CGFloat
    let tintColor: Color?
    let interactiveGlass: Bool
    
    init(cornerRadius: CGFloat = 30, borderWidth: CGFloat = 1.5, tintColor: Color? = nil, interactiveGlass: Bool = false) {
        self.cornerRadius = cornerRadius
        self.borderWidth = borderWidth
        self.tintColor = tintColor
        self.interactiveGlass = interactiveGlass
    }
    
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            // iOS 26+ uses native Liquid Glass effect
            let glassStyle = interactiveGlass ? Glass.regular.interactive() : Glass.regular
            
            if let tintColor = tintColor {
                content
                    .glassEffect(
                        glassStyle.tint(tintColor),
                        in: .rect(cornerRadius: cornerRadius, style: .continuous)
                    )
            } else {
                content
                    .glassEffect(
                        glassStyle,
                        in: .rect(cornerRadius: cornerRadius, style: .continuous)
                    )
            }
        } else {
            // Fallback for iOS < 26 - Your existing implementation
            content
                .background(
                    ZStack {
                        // Glass morphism background with optional color tint
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(.ultraThinMaterial)
                        
                        // Optional color tint overlay
                        if let tintColor = tintColor {
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .fill(
                                    tintColor.opacity(colorScheme == .dark ? 0.08 : 0.15)
                                )
                        }
                        
                        // Enhanced inner glow for better light mode visibility
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
                        
                        // Enhanced border for better light mode contrast
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: colorScheme == .dark ? [
                                        Color.white.opacity(0.15),
                                        Color.primary.opacity(0.08),
                                        Color.clear
                                    ] : [
                                        Color.white.opacity(0.8),
                                        Color.gray.opacity(0.3),
                                        Color.black.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: borderWidth
                            )
                        
                        // Additional subtle shadow for light mode depth
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
        }
    }
}

// MARK: - Lightweight Glass Background for HabitRowView
struct LightGlassBackgroundModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    
    let cornerRadius: CGFloat
    let borderWidth: CGFloat
    let tintColor: Color?
    let style: GlassStyle
    
    enum GlassStyle {
        case regular
        case clear
        case interactive
    }
    
    init(cornerRadius: CGFloat = 16, borderWidth: CGFloat = 1, tintColor: Color? = nil, style: GlassStyle = .regular) {
        self.cornerRadius = cornerRadius
        self.borderWidth = borderWidth
        self.tintColor = tintColor
        self.style = style
    }
    
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            // iOS 26+ uses native Liquid Glass effect
            let glassEffect: Glass = {
                switch style {
                case .regular:
                    return Glass.regular
                case .clear:
                    return Glass.clear
                case .interactive:
                    return Glass.regular.interactive()
                }
            }()
            
            if let tintColor = tintColor {
                content
                    .glassEffect(
                        glassEffect.tint(tintColor),
                        in: .rect(cornerRadius: cornerRadius, style: .continuous)
                    )
            } else {
                content
                    .glassEffect(
                        glassEffect,
                        in: .rect(cornerRadius: cornerRadius, style: .continuous)
                    )
            }
        } else {
            // Fallback for iOS < 26 - Your existing implementation
            content
                .background(
                    ZStack {
                        // Simplified glass background
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(.thinMaterial)
                        
                        // Optional color tint overlay
                        if let tintColor = tintColor {
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .fill(
                                    tintColor.opacity(colorScheme == .dark ? 0.12 : 0.06)
                                )
                        }
                        
                        // Simple top highlight
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(colorScheme == .dark ? 0.03 : 0.4),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .center
                                )
                            )
                        
                        // Simplified border
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(
                                Color.primary.opacity(colorScheme == .dark ? 0.1 : 0.15),
                                lineWidth: borderWidth
                            )
                    }
                )
        }
    }
}

// MARK: - Modern Glass Background
struct ModernGlassBackgroundModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    
    let cornerRadius: CGFloat
    let borderWidth: CGFloat
    let tintColor: Color?
    let glassStyle: GlassVariant
    
    enum GlassVariant {
        case regular
        case clear
        case interactive
        case clearInteractive
    }
    
    init(cornerRadius: CGFloat = 20, borderWidth: CGFloat = 0.5, tintColor: Color? = nil, glassStyle: GlassVariant = .interactive) {
        self.cornerRadius = cornerRadius
        self.borderWidth = borderWidth
        self.tintColor = tintColor
        self.glassStyle = glassStyle
    }
    
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            // iOS 26+ uses native Liquid Glass effect with selected style
            let glass: Glass = {
                switch glassStyle {
                case .regular:
                    return Glass.regular
                case .clear:
                    return Glass.clear
                case .interactive:
                    return Glass.regular.interactive()
                case .clearInteractive:
                    return Glass.clear.interactive()
                }
            }()
            
            if let tintColor = tintColor {
                content
                    .glassEffect(
                        glass.tint(tintColor),
                        in: .rect(cornerRadius: cornerRadius, style: .continuous)
                    )
            } else {
                content
                    .glassEffect(
                        glass,
                        in: .rect(cornerRadius: cornerRadius, style: .continuous)
                    )
            }
        } else {
            // Fallback for iOS < 26 - Your existing implementation
            content
                .background(
                    ZStack {
                        // Base ultra-thin material
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(.ultraThinMaterial)
                        
                        // Optional color tint overlay
                        if let tintColor = tintColor {
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .fill(
                                    tintColor.opacity(colorScheme == .dark ? 0.08 : 0.15)
                                )
                        }
                        
                        // Primary glass effect layer
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(colorScheme == .dark ? 0.15 : 0.35),
                                        Color.clear,
                                        Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .blendMode(.overlay)
                        
                        // Subtle border with glass catches
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(colorScheme == .dark ? 0.4 : 0.6),
                                        Color.white.opacity(colorScheme == .dark ? 0.1 : 0.2),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
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

// MARK: - Glass Container for Multiple Elements
@available(iOS 26.0, *)
struct GlassContainerView<Content: View>: View {
    let spacing: CGFloat
    let content: Content
    
    init(spacing: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }
    
    var body: some View {
        GlassEffectContainer(spacing: spacing) {
            content
        }
    }
}

// MARK: - View Extensions
extension View {
    /// Applies a custom glass background effect with glassmorphism styling
    /// - Parameters:
    ///   - cornerRadius: The corner radius for the glass effect (default: 30)
    ///   - borderWidth: The width of the gradient border (default: 1.5)
    ///   - tintColor: Optional color tint for the glass effect
    ///   - interactiveGlass: Enable interactive glass effect on iOS 26+ (default: false)
    /// - Returns: A view with the glass background applied
    func glassBackground(
        cornerRadius: CGFloat = 30,
        borderWidth: CGFloat = 1.5,
        tintColor: Color? = nil,
        interactiveGlass: Bool = false
    ) -> some View {
        modifier(GlassBackgroundModifier(
            cornerRadius: cornerRadius,
            borderWidth: borderWidth,
            tintColor: tintColor,
            interactiveGlass: interactiveGlass
        ))
    }
    
    /// Applies a lightweight glass background effect optimized for performance
    /// - Parameters:
    ///   - cornerRadius: The corner radius for the glass effect (default: 16)
    ///   - borderWidth: The width of the border (default: 1)
    ///   - tintColor: Optional color tint for the glass effect
    ///   - style: Glass style for iOS 26+ (default: .regular)
    /// - Returns: A view with the lightweight glass background applied
    func lightGlassBackground(
        cornerRadius: CGFloat = 16,
        borderWidth: CGFloat = 1,
        tintColor: Color? = nil,
        style: LightGlassBackgroundModifier.GlassStyle = .regular
    ) -> some View {
        modifier(LightGlassBackgroundModifier(
            cornerRadius: cornerRadius,
            borderWidth: borderWidth,
            tintColor: tintColor,
            style: style
        ))
    }
    
    /// Applies a modern glass background effect with advanced glassmorphism styling
    /// - Parameters:
    ///   - cornerRadius: The corner radius for the glass effect (default: 20)
    ///   - borderWidth: The width of the subtle border (default: 0.5)
    ///   - tintColor: Optional color tint for the glass effect
    ///   - glassStyle: Glass variant for iOS 26+ (default: .interactive)
    /// - Returns: A view with the modern glass background applied
    func modernGlassBackground(
        cornerRadius: CGFloat = 20,
        borderWidth: CGFloat = 0.5,
        tintColor: Color? = nil,
        glassStyle: ModernGlassBackgroundModifier.GlassVariant = .interactive
    ) -> some View {
        modifier(ModernGlassBackgroundModifier(
            cornerRadius: cornerRadius,
            borderWidth: borderWidth,
            tintColor: tintColor,
            glassStyle: glassStyle
        ))
    }
    
    /// Wraps multiple views in a GlassEffectContainer for iOS 26+
    /// This ensures proper blending and performance when multiple glass elements are close together
    @available(iOS 26.0, *)
    func inGlassContainer(spacing: CGFloat = 16) -> some View {
        GlassEffectContainer(spacing: spacing) {
            self
        }
    }
}

// MARK: - Preview
struct GlassBackgroundPreview: View {
    @State private var selectedStyle = 0
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Style selector for iOS 26+
                if #available(iOS 26.0, *) {
                    Picker("Glass Style", selection: $selectedStyle) {
                        Text("Regular").tag(0)
                        Text("Clear").tag(1)
                        Text("Interactive").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    .glassBackground(cornerRadius: 16)
                }
                
                Group {
                    // Example usage with default values
                    Text("Default Glass Effect")
                        .padding()
                        .glassBackground()
                    
                    // Example with interactive glass (iOS 26+)
                    Text("Interactive Glass")
                        .padding()
                        .glassBackground(interactiveGlass: true)
                    
                    // Example with color tint
                    Text("Blue Tinted Glass")
                        .padding()
                        .glassBackground(tintColor: .blue)
                    
                    // Example with green tint
                    Text("Green Tinted Glass")
                        .padding()
                        .glassBackground(tintColor: .green)
                    
                    // Example with custom corner radius and color
                    Text("Custom with Purple Tint")
                        .padding()
                        .glassBackground(cornerRadius: 15, tintColor: .purple)
                }
                
                Divider()
                    .padding(.vertical)
                
                Group {
                    // Modern glass background examples
                    Text("Modern Glass Effect")
                        .padding()
                        .modernGlassBackground()
                    
                    Text("Modern Glass with Blue Tint")
                        .padding()
                        .modernGlassBackground(tintColor: .blue)
                    
                    Text("Modern Clear Interactive Glass")
                        .padding()
                        .modernGlassBackground(
                            tintColor: .orange,
                            glassStyle: .clearInteractive
                        )
                    
                    // Card-style modern glass
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Modern Glass Card")
                            .font(.headline)
                        Text("This is an example of the modern glass background effect with enhanced glassmorphism styling.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .modernGlassBackground(cornerRadius: 16, tintColor: .purple)
                }
                
                Divider()
                    .padding(.vertical)
                
                // Using GlassContainer for multiple elements (iOS 26+)
                if #available(iOS 26.0, *) {
                    Text("Glass Container Group")
                        .font(.headline)
                        .padding(.bottom, 8)
                    
                    GlassContainerView(spacing: 12) {
                        ForEach(0..<3) { index in
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                Text("Item \(index + 1)")
                                Spacer()
                            }
                            .padding()
                            .glassEffect(
                                Glass.regular.tint(.blue.opacity(0.2)),
                                in: .rect(cornerRadius: 12, style: .continuous)
                            )
                        }
                    }
                }
                
                Divider()
                    .padding(.vertical)
                
                Group {
                    // Lightweight versions for habit rows
                    HStack {
                        Image(systemName: "checkmark.circle")
                            .foregroundColor(.green)
                        Text("Drink Water")
                        Spacer()
                        Text("3/8")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .lightGlassBackground()
                    
                    // Lightweight with clear style
                    HStack {
                        Image(systemName: "book.fill")
                            .foregroundColor(.blue)
                        Text("Read 30 minutes")
                        Spacer()
                        Text("✓")
                            .foregroundColor(.green)
                    }
                    .padding()
                    .lightGlassBackground(
                        tintColor: .blue,
                        style: .clear
                    )
                    
                    // Interactive lightweight glass
                    HStack {
                        Image(systemName: "figure.run")
                            .foregroundColor(.orange)
                        Text("Morning Run")
                        Spacer()
                        Text("5km")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .lightGlassBackground(
                        tintColor: .orange,
                        style: .interactive
                    )
                }
            }
            .padding()
        }
        .background(
            LinearGradient(
                colors: [.blue, .purple, .pink],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

#Preview {
    GlassBackgroundPreview()
}
