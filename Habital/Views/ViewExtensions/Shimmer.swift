//
//  Shimmer.swift
//  Habital
//
//  Created by Elias Osarumwense on 11.06.25.
//

import SwiftUI

// MARK: - Modern Shimmer Implementation
struct Shimmer: ViewModifier {
    @State private var isInitialState = true
    @Environment(\.layoutDirection) private var layoutDirection
    
    private let animation: Animation
    private let gradient: Gradient
    private let min, max: CGFloat
    
    init(
        animation: Animation = Self.defaultAnimation,
        gradient: Gradient = Self.defaultGradient,
        bandSize: CGFloat = 0.3
    ) {
        self.animation = animation
        self.gradient = gradient
        // Calculate unit point dimensions beyond the gradient's edges by the band size
        self.min = 0 - bandSize
        self.max = 1 + bandSize
    }
    
    /// The default animation effect
    static let defaultAnimation = Animation.linear(duration: 1.5)
        .delay(0.25)
        .repeatForever(autoreverses: false)
    
    /// A default gradient for the animated mask
    static let defaultGradient = Gradient(colors: [
        .black.opacity(0.3),
        .black,
        .black.opacity(0.3)
    ])
    
    /// Alternative brighter gradient
    static let brightGradient = Gradient(colors: [
        .clear,
        .white.opacity(0.8),
        .clear
    ])
    
    func body(content: Content) -> some View {
        content
            .mask(
                LinearGradient(
                    gradient: gradient,
                    startPoint: startPoint,
                    endPoint: endPoint
                )
            )
            .animation(animation, value: isInitialState)
            .onAppear {
                isInitialState = false
            }
    }
    
    /// Determines the shimmer direction based on layout direction
    private var startPoint: UnitPoint {
        if layoutDirection == .rightToLeft {
            return isInitialState ? UnitPoint(x: max, y: min) : UnitPoint(x: 0, y: 1)
        } else {
            return isInitialState ? UnitPoint(x: min, y: min) : UnitPoint(x: max, y: max)
        }
    }
    
    private var endPoint: UnitPoint {
        if layoutDirection == .rightToLeft {
            return isInitialState ? UnitPoint(x: 1, y: 0) : UnitPoint(x: min, y: max)
        } else {
            return isInitialState ? UnitPoint(x: 0, y: 0) : UnitPoint(x: 1, y: 1)
        }
    }
}

// MARK: - Alternative High-Performance Shimmer
struct PerformantShimmer: ViewModifier {
    @State private var phase: CGFloat = 0
    
    private let animation: Animation
    private let gradient: Gradient
    private let bandSize: CGFloat
    
    init(
        animation: Animation = .linear(duration: 1.2).repeatForever(autoreverses: false),
        gradient: Gradient = Gradient(colors: [.clear, .white.opacity(0.6), .clear]),
        bandSize: CGFloat = 0.2
    ) {
        self.animation = animation
        self.gradient = gradient
        self.bandSize = bandSize
    }
    
    func body(content: Content) -> some View {
        content
            .mask(
                LinearGradient(
                    gradient: gradient,
                    startPoint: UnitPoint(x: phase - bandSize, y: 0.5),
                    endPoint: UnitPoint(x: phase + bandSize, y: 0.5)
                )
            )
            .onAppear {
                withAnimation(animation) {
                    phase = 1 + bandSize
                }
            }
    }
}

// MARK: - Overlay Mode Shimmer (Alternative approach)
struct OverlayShimmer: ViewModifier {
    @State private var startPoint = UnitPoint(x: -1.8, y: -1.2)
    @State private var endPoint = UnitPoint(x: 0, y: -0.2)
    
    private let colors: [Color]
    private let animation: Animation
    
    init(
        colors: [Color] = [.clear, .white.opacity(0.4), .clear],
        animation: Animation = .easeInOut(duration: 1.5).repeatForever(autoreverses: false)
    ) {
        self.colors = colors
        self.animation = animation
    }
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: colors,
                    startPoint: startPoint,
                    endPoint: endPoint
                )
                .blendMode(.overlay)
            )
            .onAppear {
                withAnimation(animation) {
                    startPoint = UnitPoint(x: 1, y: 1)
                    endPoint = UnitPoint(x: 2.2, y: 2.2)
                }
            }
    }
}

// MARK: - View Extensions
extension View {
    /// Adds a shimmer effect to the view
    @ViewBuilder
    func shimmering(
        active: Bool = true,
        animation: Animation = Shimmer.defaultAnimation,
        gradient: Gradient = Shimmer.defaultGradient,
        bandSize: CGFloat = 0.3
    ) -> some View {
        if active {
            self.modifier(Shimmer(animation: animation, gradient: gradient, bandSize: bandSize))
        } else {
            self
        }
    }
    
    /// Adds a high-performance shimmer effect
    @ViewBuilder
    func performantShimmer(
        active: Bool = true,
        duration: Double = 1,
        gradient: Gradient = Gradient(colors: [.clear, .white.opacity(0.6), .clear])
    ) -> some View {
        if active {
            self.modifier(
                PerformantShimmer(
                    animation: .linear(duration: duration).repeatForever(autoreverses: false),
                    gradient: gradient
                )
            )
        } else {
            self
        }
    }
    
    /// Adds an overlay-based shimmer effect
    @ViewBuilder
    func overlayShimmer(
        active: Bool = true,
        colors: [Color] = [.clear, .white.opacity(0.4), .clear],
        duration: Double = 1.5
    ) -> some View {
        if active {
            self.modifier(
                OverlayShimmer(
                    colors: colors,
                    animation: .easeInOut(duration: duration).repeatForever(autoreverses: false)
                )
            )
        } else {
            self
        }
    }
}


// MARK: - Usage Examples
struct ShimmerDemoView: View {
    @State private var isLoading = true
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Modern Shimmer")
                .font(.title)
                .padding()
                .background(Color.gray.opacity(0.3))
                .cornerRadius(10)
                .shimmering(active: isLoading, gradient: Shimmer.brightGradient)
            
            Text("Performant Shimmer")
                .font(.title)
                .padding()
                .background(Color.blue.opacity(0.3))
                .cornerRadius(10)
                .performantShimmer(active: isLoading)
            
            Text("Overlay Shimmer")
                .font(.title)
                .padding()
                .background(Color.green.opacity(0.3))
                .cornerRadius(10)
                .overlayShimmer(active: isLoading)
            
            Button("Toggle Shimmer") {
                isLoading.toggle()
            }
            .padding()
            .background(Color.orange)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
    }
}

#Preview {
    ShimmerDemoView()
}
