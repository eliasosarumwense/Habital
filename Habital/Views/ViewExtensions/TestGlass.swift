import SwiftUI

// MARK: - iOS 26 Liquid Glass Round Button (Authentic Implementation)
struct LiquidGlassRoundButton: View {
    let systemImage: String
    let action: () -> Void
    let size: CGFloat
    let iconSize: CGFloat
    
    @State private var isPressed = false
    @Environment(\.colorScheme) var colorScheme
    
    init(
        systemImage: String,
        size: CGFloat = 50,
        iconSize: CGFloat = 20,
        action: @escaping () -> Void
    ) {
        self.systemImage = systemImage
        self.size = size
        self.iconSize = iconSize
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: iconSize, weight: .medium, design: .rounded))
                .foregroundStyle(.primary)
                .frame(width: size, height: size)
                .background(liquidGlassBackground)
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
    
    // Authentic iOS 26 Liquid Glass implementation
    private var liquidGlassBackground: some View {
        ZStack {
            // Base ultra-thin material (foundation of Liquid Glass)
            Circle()
                .fill(.ultraThinMaterial)
            
            // Primary translucent glass layer that "refracts surroundings"
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            // Top highlight - mimics light reflection
                            Color.white.opacity(colorScheme == .dark ? 0.15 : 0.35),
                            // Middle - clear to show content behind
                            Color.clear,
                            // Bottom shadow - creates depth
                            Color.black.opacity(colorScheme == .dark ? 0.2 : 0.04)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .blendMode(.overlay)
            
            // Sharp glass edge catches (bright, opaque reflections)
            Circle()
                .strokeBorder(
                    AngularGradient(
                        colors: [
                            Color.white.opacity(colorScheme == .dark ? 0.8 : 0.95), // Bright catch
                            Color.clear,
                            Color.white.opacity(colorScheme == .dark ? 0.4 : 0.7),   // Medium catch
                            Color.clear,
                            Color.white.opacity(colorScheme == .dark ? 0.1 : 0.3),   // Subtle catch
                            Color.clear,
                            Color.white.opacity(colorScheme == .dark ? 0.6 : 0.85)   // Another bright catch
                        ],
                        center: .center,
                        startAngle: .degrees(45),
                        endAngle: .degrees(405)
                    ),
                    lineWidth: 1.0
                )
            
            // Secondary sharp edge reflection (different angle)
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(colorScheme == .dark ? 0.5 : 0.8),
                            Color.clear
                        ],
                        startPoint: UnitPoint(x: 0.2, y: 0.1),
                        endPoint: UnitPoint(x: 0.4, y: 0.3)
                    ),
                    lineWidth: 0.8
                )
                .padding(0.5)
        }
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.4 : 0.15),
            radius: isPressed ? 2 : 6,
            x: 0,
            y: isPressed ? 1 : 3
        )
        .shadow(
            color: Color.white.opacity(colorScheme == .dark ? 0.08 : 0.5),
            radius: 1,
            x: 0,
            y: -1
        )
    }
}

// MARK: - Simplified Liquid Glass Button (Clean version)
struct SimpleLiquidGlassButton: View {
    let systemImage: String
    let action: () -> Void
    let size: CGFloat
    
    @State private var isPressed = false
    @Environment(\.colorScheme) var colorScheme
    
    init(
        systemImage: String,
        size: CGFloat = 48,
        action: @escaping () -> Void
    ) {
        self.systemImage = systemImage
        self.size = size
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: size * 0.4, weight: .medium, design: .rounded))
                .foregroundStyle(.primary)
                .frame(width: size, height: size)
                .background(
                    ZStack {
                        // Ultra-thin material base
                        Circle()
                            .fill(.ultraThinMaterial)
                        
                        // Simple translucent overlay
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(colorScheme == .dark ? 0.1 : 0.25),
                                        Color.clear,
                                        Color.black.opacity(colorScheme == .dark ? 0.15 : 0.03)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .blendMode(.overlay)
                        
                        // Sharp glass edge with bright catches
                        Circle()
                            .strokeBorder(
                                AngularGradient(
                                    colors: [
                                        Color.white.opacity(colorScheme == .dark ? 0.7 : 0.9),
                                        Color.clear,
                                        Color.white.opacity(colorScheme == .dark ? 0.3 : 0.6),
                                        Color.clear,
                                        Color.white.opacity(colorScheme == .dark ? 0.5 : 0.8)
                                    ],
                                    center: .center,
                                    startAngle: .degrees(30),
                                    endAngle: .degrees(390)
                                ),
                                lineWidth: 0.7
                            )
                    }
                )
                .scaleEffect(isPressed ? 0.96 : 1.0)
                .shadow(
                    color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1),
                    radius: isPressed ? 1 : 4,
                    x: 0,
                    y: isPressed ? 0.5 : 2
                )
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                        isPressed = false
                    }
                }
        )
    }
}

// MARK: - Liquid Glass Style Enum
enum LiquidGlassButtonStyle {
    case full       // Complete iOS 26 effect
    case simple     // Clean minimal version
    case minimal    // Ultra-minimal
}

// MARK: - Unified Liquid Glass Button
struct iOS26LiquidGlassButton: View {
    let systemImage: String
    let action: () -> Void
    let size: CGFloat
    let style: LiquidGlassButtonStyle
    
    init(
        systemImage: String,
        size: CGFloat = 50,
        style: LiquidGlassButtonStyle = .full,
        action: @escaping () -> Void
    ) {
        self.systemImage = systemImage
        self.size = size
        self.style = style
        self.action = action
    }
    
    var body: some View {
        switch style {
        case .full:
            LiquidGlassRoundButton(
                systemImage: systemImage,
                size: size,
                iconSize: size * 0.4,
                action: action
            )
        case .simple:
            SimpleLiquidGlassButton(
                systemImage: systemImage,
                size: size,
                action: action
            )
        case .minimal:
            MinimalGlassButton(
                systemImage: systemImage,
                size: size,
                action: action
            )
        }
    }
}

// MARK: - Minimal Glass Button
struct MinimalGlassButton: View {
    let systemImage: String
    let action: () -> Void
    let size: CGFloat
    
    @State private var isPressed = false
    @Environment(\.colorScheme) var colorScheme
    
    init(systemImage: String, size: CGFloat, action: @escaping () -> Void) {
        self.systemImage = systemImage
        self.size = size
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: size * 0.4, weight: .medium))
                .foregroundStyle(.primary)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Circle()
                                .fill(Color.white.opacity(colorScheme == .dark ? 0.06 : 0.15))
                                .blendMode(.overlay)
                        )
                        .overlay(
                        // Real glass edge with bright catches
                        Circle()
                            .strokeBorder(
                                AngularGradient(
                                    colors: [
                                        Color.white.opacity(colorScheme == .dark ? 0.6 : 0.85),
                                        Color.clear,
                                        Color.white.opacity(colorScheme == .dark ? 0.2 : 0.5),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startAngle: .degrees(20),
                                    endAngle: .degrees(380)
                                ),
                                lineWidth: 0.6
                            )
                        )
                )
                .scaleEffect(isPressed ? 0.97 : 1.0)
                .shadow(
                    color: Color.black.opacity(colorScheme == .dark ? 0.25 : 0.08),
                    radius: isPressed ? 1 : 3,
                    x: 0,
                    y: isPressed ? 0.5 : 2
                )
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.spring(response: 0.15, dampingFraction: 0.8)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.15, dampingFraction: 0.6)) {
                        isPressed = false
                    }
                }
        )
    }
}

// MARK: - Usage Integration for Your NavBar
extension View {
    /// Replace your existing nav button with iOS 26 Liquid Glass
    func liquidGlassNavButton(
        systemImage: String,
        size: CGFloat = 50,
        style: LiquidGlassButtonStyle = .simple,
        action: @escaping () -> Void
    ) -> some View {
        iOS26LiquidGlassButton(
            systemImage: systemImage,
            size: size,
            style: style,
            action: action
        )
    }
}

// MARK: - Demo and Preview
struct LiquidGlassButtonDemo: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                Text("iOS 26 Liquid Glass Buttons")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Based on Apple's actual WWDC 2025 design")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                VStack(spacing: 25) {
                    Text("Full Liquid Glass")
                        .font(.headline)
                    
                    HStack(spacing: 20) {
                        iOS26LiquidGlassButton(
                            systemImage: "plus",
                            size: 50,
                            style: .full
                        ) { print("Plus") }
                        
                        iOS26LiquidGlassButton(
                            systemImage: "heart.fill",
                            size: 50,
                            style: .full
                        ) { print("Heart") }
                        
                        iOS26LiquidGlassButton(
                            systemImage: "star.fill",
                            size: 50,
                            style: .full
                        ) { print("Star") }
                    }
                }
                
                VStack(spacing: 25) {
                    Text("Simple Style (Recommended)")
                        .font(.headline)
                    
                    HStack(spacing: 15) {
                        iOS26LiquidGlassButton(
                            systemImage: "gear",
                            size: 48,
                            style: .simple
                        ) { print("Settings") }
                        
                        iOS26LiquidGlassButton(
                            systemImage: "magnifyingglass",
                            size: 48,
                            style: .simple
                        ) { print("Search") }
                        
                        iOS26LiquidGlassButton(
                            systemImage: "ellipsis",
                            size: 48,
                            style: .simple
                        ) { print("More") }
                    }
                }
                
                VStack(spacing: 25) {
                    Text("Minimal Style")
                        .font(.headline)
                    
                    HStack(spacing: 15) {
                        iOS26LiquidGlassButton(
                            systemImage: "chevron.left",
                            size: 44,
                            style: .minimal
                        ) { print("Back") }
                        
                        iOS26LiquidGlassButton(
                            systemImage: "house.fill",
                            size: 56,
                            style: .minimal
                        ) { print("Home") }
                        
                        iOS26LiquidGlassButton(
                            systemImage: "chevron.right",
                            size: 44,
                            style: .minimal
                        ) { print("Forward") }
                    }
                }
                
                VStack(spacing: 15) {
                    Text("Perfect for Your Nav Bar!")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("Just replace your existing buttons with:")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    Text("iOS26LiquidGlassButton(systemImage: \"xmark\", style: .simple) { }")
                        .font(.caption2)
                        .fontDesign(.monospaced)
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            .padding()
        }
        .background(
            LinearGradient(
                colors: [Color(.systemBackground), Color(.systemBackground).opacity(0.95)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }
}

#Preview("Light Mode") {
    LiquidGlassButtonDemo()
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    LiquidGlassButtonDemo()
        .preferredColorScheme(.dark)
}
