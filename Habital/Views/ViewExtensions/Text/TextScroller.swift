//
//  TextScroller.swift
//  Habital
//
//  Created by Elias Osarumwense on 07.11.25.
//

import SwiftUI

/// A modern marquee text component that automatically scrolls text horizontally with smooth fade effects on both edges.
struct ScrollingText: View {
    let text: String
    let font: Font
    let speed: Double
    let fadeWidth: CGFloat
    
    @State private var offset: CGFloat = 0
    @State private var textWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    @State private var shouldAnimate: Bool = false
    @State private var animationTask: Task<Void, Never>?
    
    /// Creates a marquee text view with customizable parameters
    /// - Parameters:
    ///   - text: The text to display and scroll
    ///   - font: The font to use for the text (default: .body)
    ///   - speed: Scrolling speed in points per second (default: 30)
    ///   - fadeWidth: Width of the fade effect on each edge (default: 20)
    init(
        _ text: String,
        font: Font = .body,
        speed: Double = 30,
        fadeWidth: CGFloat = 20
    ) {
        self.text = text
        self.font = font
        self.speed = speed
        self.fadeWidth = fadeWidth
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                // Scrolling text content
                if shouldAnimate {
                    // Single instance that scrolls back and forth
                    Text(text)
                        .font(font)
                        .fixedSize()
                        .offset(x: offset)
                        .background(
                            GeometryReader { textGeometry in
                                Color.clear
                                    .onAppear {
                                        containerWidth = geometry.size.width
                                        textWidth = textGeometry.size.width
                                        checkIfAnimationNeeded()
                                    }
                                    .onChange(of: geometry.size.width) { _, newWidth in
                                        containerWidth = newWidth
                                        checkIfAnimationNeeded()
                                    }
                                    .onChange(of: textGeometry.size.width) { _, newWidth in
                                        textWidth = newWidth
                                        checkIfAnimationNeeded()
                                    }
                            }
                        )
                } else {
                    // Static text when it fits
                    Text(text)
                        .font(font)
                        .fixedSize()
                        .background(
                            GeometryReader { textGeometry in
                                Color.clear
                                    .onAppear {
                                        containerWidth = geometry.size.width
                                        textWidth = textGeometry.size.width
                                        checkIfAnimationNeeded()
                                    }
                                    .onChange(of: geometry.size.width) { _, newWidth in
                                        containerWidth = newWidth
                                        checkIfAnimationNeeded()
                                    }
                                    .onChange(of: textGeometry.size.width) { _, newWidth in
                                        textWidth = newWidth
                                        checkIfAnimationNeeded()
                                    }
                            }
                        )
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
            .clipped()
            .mask {
                if shouldAnimate {
                    // Create a rectangle with gradient mask for fading edges on BOTH sides
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .black, location: fadeWidth / max(geometry.size.width, 1)),
                            .init(color: .black, location: 1 - (fadeWidth / max(geometry.size.width, 1))),
                            .init(color: .clear, location: 1)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                } else {
                    // Full visibility when not animating
                    Rectangle()
                }
            }
        }
        .onAppear {
            startAnimation()
        }
        .onChange(of: text) { _, _ in
            resetAnimation()
        }
        .onDisappear {
            animationTask?.cancel()
        }
    }
    
    private func checkIfAnimationNeeded() {
        let wasAnimating = shouldAnimate
        shouldAnimate = textWidth > containerWidth
        
        print("Check animation - textWidth: \(textWidth), containerWidth: \(containerWidth), shouldAnimate: \(shouldAnimate)")
        
        if !shouldAnimate {
            offset = 0
            animationTask?.cancel()
        } else {
            // Start with text positioned at fadeWidth from the left
            offset = fadeWidth
            
            // Start animation if it wasn't already animating
            if !wasAnimating {
                startAnimation()
            }
        }
    }
    
    private func startAnimation() {
        guard shouldAnimate else { return }
        
        // Cancel any existing animation
        animationTask?.cancel()
        
        // Make sure we have valid measurements
        guard textWidth > 0, containerWidth > 0 else { return }
        
        // Calculate the maximum offset (how far left the text can scroll)
        // We need to scroll until the END of the text is visible within the container
        // Start position: text begins at fadeWidth (left edge of visible area)
        // End position: text ends at containerWidth - fadeWidth (right edge of visible area)
        let startOffset = fadeWidth
        let endOffset = -(textWidth - containerWidth + fadeWidth)
        let distance = abs(endOffset - startOffset)
        let duration = distance / speed
        
        print("Animation starting - textWidth: \(textWidth), containerWidth: \(containerWidth)")
        print("Start offset: \(startOffset), End offset: \(endOffset), Duration: \(duration)")
        
        // Start the back-and-forth animation loop
        animationTask = Task {
            // Initial delay before first animation - 5 seconds
            try? await Task.sleep(for: .seconds(1.5))
            
            while !Task.isCancelled {
                print("Animating to left - offset will be: \(endOffset)")
                
                // Scroll to the left (show end of text)
                await MainActor.run {
                    withAnimation(.linear(duration: duration)) {
                        offset = endOffset
                    }
                }
                
                // Wait for animation to complete plus a pause
                try? await Task.sleep(for: .seconds(duration + 1.0))
                
                guard !Task.isCancelled else { break }
                
                print("Animating to right - offset will be: \(startOffset)")
                
                // Scroll back to the right (show beginning of text)
                await MainActor.run {
                    withAnimation(.linear(duration: duration)) {
                        offset = startOffset
                    }
                }
                
                // Wait for animation to complete plus a pause
                try? await Task.sleep(for: .seconds(duration + 1.0))
                
                guard !Task.isCancelled else { break }
            }
        }
    }
    
    private func resetAnimation() {
        // Cancel existing animation
        animationTask?.cancel()
        
        // Reset offset to starting position
        offset = fadeWidth
        
        // Restart after a brief delay
        Task {
            try? await Task.sleep(for: .milliseconds(100))
            await MainActor.run {
                checkIfAnimationNeeded()
                startAnimation()
            }
        }
    }
}

#Preview("Marquee Text Showcase") {
    struct PreviewContent: View {
        @State private var customText = "This is your custom scrolling text!"
        
        var body: some View {
            ScrollView {
                VStack(spacing: 40) {
                    // Header
                    VStack(spacing: 8) {
                        Text("ScrollingText")
                            .font(.largeTitle.bold())
                        Text("Modern scrolling text with fade effects")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 40)
                    
                    Divider()
                    
                    // Examples
                    VStack(alignment: .leading, spacing: 30) {
                        // Example 1: Long text
                        ExampleCard(
                            title: "Long Text",
                            description: "Automatically scrolls when text overflows"
                        ) {
                            ScrollingText(
                                "This is a really long text that will scroll smoothly across the screen with beautiful fade effects on both sides",
                                font: .headline,
                                speed: 40
                            )
                            .frame(height: 30)
                        }
                        
                        // Example 2: Short text (no scrolling)
                        ExampleCard(
                            title: "Short Text",
                            description: "Static when text fits"
                        ) {
                            ScrollingText(
                                "Short text",
                                font: .headline,
                                speed: 40
                            )
                            .frame(height: 30)
                        }
                        
                        // Example 3: Custom styling
                        ExampleCard(
                            title: "Custom Styling",
                            description: "Large font with slower speed"
                        ) {
                            ScrollingText(
                                "Breaking News: SwiftUI makes beautiful animations easy!",
                                font: .title2.bold(),
                                speed: 25,
                                fadeWidth: 30
                            )
                            .frame(height: 40)
                            .foregroundStyle(.blue)
                        }
                        
                        // Example 4: Notification style
                        ExampleCard(
                            title: "Notification Style",
                            description: "Perfect for banners"
                        ) {
                            HStack(spacing: 12) {
                                Image(systemName: "bell.fill")
                                    .foregroundStyle(.orange)
                                
                                ScrollingText(
                                    "You have 5 new messages waiting for your attention",
                                    font: .subheadline,
                                    speed: 35
                                )
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(.orange.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        // Example 5: Song title style
                        ExampleCard(
                            title: "Music Player Style",
                            description: "Like a now playing indicator"
                        ) {
                            HStack(spacing: 12) {
                                Image(systemName: "music.note")
                                    .foregroundStyle(.pink)
                                    .font(.title2)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    ScrollingText(
                                        "Midnight City by M83 from the album Hurry Up, We're Dreaming",
                                        font: .body.weight(.semibold),
                                        speed: 30,
                                        fadeWidth: 25
                                    )
                                    .frame(height: 20)
                                    
                                    Text("Electronic • 2011")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.pink.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        // Example 6: Interactive
                        ExampleCard(
                            title: "Interactive",
                            description: "Try editing the text"
                        ) {
                            VStack(spacing: 12) {
                                TextField("Enter your text", text: $customText)
                                    .textFieldStyle(.roundedBorder)
                                
                                ScrollingText(
                                    customText,
                                    font: .body,
                                    speed: 35
                                )
                                .frame(height: 25)
                                .padding()
                                .background(.gray.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 40)
                }
            }
            .background(Color(.systemGroupedBackground))
        }
    }
    
    return PreviewContent()
}

// Helper view for consistent example cards
private struct ExampleCard<Content: View>: View {
    let title: String
    let description: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            content
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

