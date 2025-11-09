//
//  ShimmerEffect.swift
//  Habital
//
//  Created by Elias Osarumwense on 20.08.25.
//

import SwiftUI

// MARK: - Shimmer Effect Modifier
struct ShimmerEffectGitGrid: ViewModifier {
    @State private var isShimmering = false
    
    let gradient = LinearGradient(
        colors: [
            Color.clear,
            Color.white.opacity(0.3),
            Color.clear
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    func body(content: Content) -> some View {
        content
            .mask(
                Rectangle()
                    .fill(gradient)
                    .scaleEffect(x: 3, y: 1)
                    .offset(x: isShimmering ? 200 : -200)
                    .animation(
                        Animation
                            .linear(duration: 1.5)
                            .repeatForever(autoreverses: false),
                        value: isShimmering
                    )
            )
            .onAppear {
                isShimmering = true
            }
    }
}

// MARK: - Convenience Extension
extension View {
    func shimmer() -> some View {
        self.modifier(ShimmerEffectGitGrid())
    }
}
