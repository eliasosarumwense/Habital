//
//  BlurredScrollView.swift
//  Habital
//
//  Created by Elias Osarumwense on 21.05.25.
//

import SwiftUI

//
//  BlurredScrollView.swift
//  Habital
//
//  Created by Elias Osarumwense on 21.05.25.
//

import SwiftUI

struct BlurredScrollView<Content: View>: View {
    let content: Content
    let blurHeight: CGFloat
    
    @Environment(\.colorScheme) private var colorScheme
    
    init(
        blurHeight: CGFloat = 20,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.blurHeight = blurHeight
    }
    
    var body: some View {
        ScrollView {
            content
        }
        .overlay(
            // Top blur overlay
            VStack {
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: backgroundColor.opacity(1), location: 0),
                        .init(color: backgroundColor.opacity(0.95), location: 0.15),
                        .init(color: backgroundColor.opacity(0.8), location: 0.4),
                        .init(color: backgroundColor.opacity(0.4), location: 0.7),
                        .init(color: backgroundColor.opacity(0.1), location: 0.9),
                        .init(color: backgroundColor.opacity(0), location: 1)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: blurHeight)
                
                Spacer()
            }
            .allowsHitTesting(false),
            alignment: .top
        )
        .overlay(
            // Bottom blur overlay
            VStack {
                Spacer()
                
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: backgroundColor.opacity(0), location: 0),
                        .init(color: backgroundColor.opacity(0.1), location: 0.1),
                        .init(color: backgroundColor.opacity(0.4), location: 0.3),
                        .init(color: backgroundColor.opacity(0.8), location: 0.6),
                        .init(color: backgroundColor.opacity(0.95), location: 0.85),
                        .init(color: backgroundColor.opacity(1), location: 1)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: blurHeight)
            }
            .allowsHitTesting(false),
            alignment: .bottom
        )
    }
    
    private var backgroundColor: Color {
        Color(UIColor.systemBackground)
    }
}

// Extension to make it easy to apply to any View
extension View {
    func blurredScrollView(blurHeight: CGFloat = 20) -> some View {
        BlurredScrollView(blurHeight: blurHeight) {
            self
        }
    }
}

// Preview for testing
struct BlurredScrollView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            Text("Blurred Scroll View")
                .font(.headline)
            
            BlurredScrollView(blurHeight: 30) {
                VStack {
                    ForEach(0..<50) { index in
                        Text("Item \(index)")
                            .frame(height: 50)
                            .frame(maxWidth: .infinity)
                            .background(Color.blue.opacity(0.1))
                    }
                }
            }
            .frame(height: 400)
        }
    }
}
/*
struct BlurredScrollView<Content: View>: View {
    let content: Content
    let blurHeight: CGFloat
    
    @State private var scrollOffset: CGFloat = 0
    @State private var contentHeight: CGFloat = 0
    @State private var viewHeight: CGFloat = 0
    @State private var initialOffset: CGFloat = 0
    @State private var hasSetInitialOffset = false
    
    @Environment(\.colorScheme) private var colorScheme
    
    init(
        blurHeight: CGFloat = 5,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.blurHeight = blurHeight
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                content
                    .background(
                        GeometryReader { contentGeometry -> Color in
                            DispatchQueue.main.async {
                                self.contentHeight = contentGeometry.size.height
                                self.viewHeight = geometry.size.height
                            }
                            return Color.clear
                        }
                    )
                    .background(
                        GeometryReader { scrollGeometry -> Color in
                            let offset = scrollGeometry.frame(in: .global).minY
                            DispatchQueue.main.async {
                                // Capture the initial offset when the view first appears
                                if !self.hasSetInitialOffset {
                                    self.initialOffset = offset
                                    self.hasSetInitialOffset = true
                                }
                                
                                self.scrollOffset = offset
                            }
                            return Color.clear
                        }
                    )
            }
            .overlay(
                // Top blur with dynamic opacity and height based on scroll
                VStack {
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: backgroundColor.opacity(1), location: 0),
                            .init(color: backgroundColor.opacity(0.95), location: 0.15),
                            .init(color: backgroundColor.opacity(0.85), location: 0.35),
                            .init(color: backgroundColor.opacity(0.6), location: 0.55),
                            .init(color: backgroundColor.opacity(0.3), location: 0.75),
                            .init(color: backgroundColor.opacity(0.1), location: 0.9),
                            .init(color: backgroundColor.opacity(0), location: 1)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: calculateTopBlurHeight())
                    .opacity(topBlurOpacity)
                    
                    Spacer()
                }
                .allowsHitTesting(false),
                alignment: .top
            )
            .overlay(
                // Bottom blur with smoother fade
                VStack {
                    Spacer()
                    
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: backgroundColor.opacity(0), location: 0),
                            .init(color: backgroundColor.opacity(0.1), location: 0.1),
                            .init(color: backgroundColor.opacity(0.3), location: 0.25),
                            .init(color: backgroundColor.opacity(0.6), location: 0.45),
                            .init(color: backgroundColor.opacity(0.85), location: 0.65),
                            .init(color: backgroundColor.opacity(0.95), location: 0.85),
                            .init(color: backgroundColor.opacity(1), location: 1)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: calculateBottomBlurHeight())
                    .opacity(bottomBlurOpacity)
                }
                .allowsHitTesting(false),
                alignment: .bottom
            )
        }
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ?
            Color(UIColor.systemBackground) :
            Color(UIColor.systemBackground)
    }
    
    // Calculate dynamic blur height for top based on scroll position
    private func calculateTopBlurHeight() -> CGFloat {
        guard hasSetInitialOffset else { return blurHeight }
        
        // Calculate how much we've scrolled down from the initial position
        let scrollDistance = initialOffset - scrollOffset
        
        // Only show blur when scrolled down (scrollDistance > 0)
        guard scrollDistance > 0 else { return blurHeight }
        
        let maxHeight = blurHeight * 4 // Maximum blur height
        let minHeight = blurHeight
        
        // Increase blur height based on scroll distance
        let dynamicHeight = minHeight + min(scrollDistance / 50, maxHeight - minHeight)
        return max(minHeight, dynamicHeight)
    }
    
    // Calculate dynamic blur height for bottom
    private func calculateBottomBlurHeight() -> CGFloat {
        guard contentHeight > viewHeight else { return blurHeight }
        
        let scrollDistance = initialOffset - scrollOffset
        let maxScroll = contentHeight - viewHeight
        let remainingScroll = max(0, maxScroll - scrollDistance)
        
        let maxHeight = blurHeight * 4
        let minHeight = blurHeight
        
        // Increase blur height when there's more content below
        let dynamicHeight = minHeight + min(remainingScroll / 50, maxHeight - minHeight)
        return max(minHeight, dynamicHeight)
    }
    
    private var topBlurOpacity: Double {
        guard hasSetInitialOffset else { return 0 }
        
        // Calculate how much we've scrolled down from the initial position
        let scrollDistance = initialOffset - scrollOffset
        
        // Only show blur when scrolled down
        guard scrollDistance > 0 else { return 0 }
        
        let threshold: CGFloat = 10 // Minimum scroll distance to start showing blur
        
        if scrollDistance <= 0 {
            return 0
        }
        
        let rawOpacity = min(scrollDistance / threshold, 1.0)
        let easedOpacity = easeInOutQuad(rawOpacity)
        return Double(easedOpacity)
    }
    
    private var bottomBlurOpacity: Double {
        // Show when there's more content below
        guard contentHeight > viewHeight else { return 0 }
        
        let scrollDistance = initialOffset - scrollOffset
        let maxScroll = contentHeight - viewHeight
        let remainingScroll = max(0, maxScroll - scrollDistance)
        
        let threshold: CGFloat = 10 // Reduced threshold
        
        if remainingScroll <= 0 {
            return 0
        }
        
        let rawOpacity = min(remainingScroll / threshold, 1.0)
        let easedOpacity = easeInOutQuad(rawOpacity)
        return Double(easedOpacity)
    }
    
    // Easing function for smoother transitions
    private func easeInOutQuad(_ t: CGFloat) -> CGFloat {
        return t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t
    }
}

// Extension to make it easy to apply to any View
extension View {
    func blurredScrollView(blurHeight: CGFloat = 50) -> some View {
        BlurredScrollView(blurHeight: blurHeight) {
            self
        }
    }
}

// Preview for testing
struct BlurredScrollView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            Text("Blurred Scroll View")
                .font(.headline)
            
            BlurredScrollView(blurHeight: 50) {
                VStack {
                    ForEach(0..<50) { index in
                        Text("Item \(index)")
                            .frame(height: 50)
                            .frame(maxWidth: .infinity)
                            .background(Color.blue.opacity(0.1))
                    }
                }
            }
            .frame(height: 400)
        }
    }
}
*/
