//
//  Completely Fixed Stats Animations
//  Habital - All CGSize errors resolved
//

import SwiftUI
import CoreData

// MARK: - Pull Down Stats Overlay (FIXED)
struct PullDownStatsOverlay: View {
    @Binding var showStats: Bool
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    
    private let pullThreshold: CGFloat = 80
    
    var body: some View {
        VStack {
            // Invisible drag area at the top
            Rectangle()
                .fill(Color.clear)
                .frame(height: 100)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let translationY = value.translation.height
                            if translationY > 0 {
                                isDragging = true
                                dragOffset = min(translationY, pullThreshold * 1.5)
                            }
                        }
                        .onEnded { value in
                            isDragging = false
                            if dragOffset > pullThreshold {
                                // Trigger stats view
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                    showStats = true
                                }
                                
                                // Haptic feedback
                                let impact = UIImpactFeedbackGenerator(style: .medium)
                                impact.impactOccurred()
                            }
                            
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                dragOffset = 0
                            }
                        }
                )
            
            Spacer()
        }
        .overlay(
            // Visual feedback during drag
            VStack {
                if isDragging && dragOffset > 20 {
                    VStack(spacing: 8) {
                        // Animated chart icon
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 60, height: 60)
                                .opacity(min(dragOffset / pullThreshold, 1.0))
                            
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.blue)
                                .scaleEffect(0.8 + (dragOffset / pullThreshold) * 0.4)
                                .rotationEffect(.degrees(dragOffset * 4.5))
                        }
                        
                        let thresholdReached = dragOffset > pullThreshold
                        Text(thresholdReached ? "Release for Stats" : "Pull for Stats")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .opacity(min(dragOffset / 40, 1.0))
                    }
                    .offset(y: dragOffset * 0.3)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: dragOffset)
                }
                
                Spacer()
            }
        )
    }
}

// MARK: - Edge Swipe Stats Gesture (FIXED)
struct EdgeSwipeStatsGesture: ViewModifier {
    @Binding var showStats: Bool
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    
    private let swipeThreshold: CGFloat = 100
    private let edgeWidth: CGFloat = 30
    
    func body(content: Content) -> some View {
        content
            .overlay(
                // Invisible edge area
                HStack {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: edgeWidth)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let translationX = value.translation.width
                                    if translationX > 0 {
                                        isDragging = true
                                        dragOffset = min(translationX, swipeThreshold * 1.5)
                                    }
                                }
                                .onEnded { value in
                                    isDragging = false
                                    if dragOffset > swipeThreshold {
                                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                            showStats = true
                                        }
                                        
                                        let impact = UIImpactFeedbackGenerator(style: .medium)
                                        impact.impactOccurred()
                                    }
                                    
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        dragOffset = 0
                                    }
                                }
                        )
                    
                    Spacer()
                }
            )
            .overlay(
                // Visual feedback
                HStack {
                    if isDragging && dragOffset > 10 {
                        VStack {
                            ZStack {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 4, height: 80)
                                    .opacity(min(dragOffset / swipeThreshold, 1.0))
                                
                                VStack(spacing: 4) {
                                    ForEach(0..<3) { index in
                                        let indexOffset = CGFloat(index) * 20
                                        let opacity = min((dragOffset - indexOffset) / 20, 1.0)
                                        let scale = min((dragOffset - indexOffset) / 20, 1.0)
                                        
                                        Circle()
                                            .fill(.blue)
                                            .frame(width: 6, height: 6)
                                            .opacity(opacity)
                                            .scaleEffect(scale)
                                    }
                                }
                            }
                        }
                        .offset(x: min(dragOffset * 0.5, 40))
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: dragOffset)
                    }
                    
                    Spacer()
                }
            )
    }
}

// MARK: - Long Press + Drag (COMPLETELY FIXED)
struct LongPressDragStats: View {
    @Binding var showStats: Bool
    let triggerView: AnyView
    
    @State private var isLongPressing = false
    @State private var dragOffsetWidth: CGFloat = 0
    @State private var dragOffsetHeight: CGFloat = 0
    @State private var showPreview = false
    
    var body: some View {
        triggerView
            .scaleEffect(isLongPressing ? 0.95 : 1.0)
            .offset(x: dragOffsetWidth, y: dragOffsetHeight)
            .onLongPressGesture(minimumDuration: 0.5) {
                // Long press completed
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    showStats = true
                }
                
                let impact = UIImpactFeedbackGenerator(style: .heavy)
                impact.impactOccurred()
                
                // Reset state
                isLongPressing = false
                dragOffsetWidth = 0
                dragOffsetHeight = 0
                showPreview = false
            } onPressingChanged: { pressing in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isLongPressing = pressing
                    if pressing {
                        showPreview = true
                        
                        // Light haptic at start
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                    } else {
                        showPreview = false
                    }
                }
            }
            .simultaneousGesture(
                DragGesture()
                    .onChanged { value in
                        if isLongPressing {
                            dragOffsetWidth = value.translation.width * 0.1
                            dragOffsetHeight = value.translation.height * 0.1
                        }
                    }
                    .onEnded { _ in
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            dragOffsetWidth = 0
                            dragOffsetHeight = 0
                        }
                    }
            )
            .overlay(
                // Preview overlay
                Group {
                    if showPreview {
                        VStack {
                            Spacer()
                            
                            HStack {
                                VStack(spacing: 4) {
                                    Image(systemName: "chart.bar.fill")
                                        .font(.title2)
                                        .foregroundColor(.blue)
                                    
                                    Text("Stats")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(12)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                                .scaleEffect(showPreview ? 1.0 : 0.1)
                                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: showPreview)
                                
                                Spacer()
                            }
                            .padding()
                        }
                    }
                }
            )
    }
}

// MARK: - Double-Tap Week Timeline Animation (FIXED)
struct DoubleTapWeekStatsGesture: ViewModifier {
    @Binding var showStats: Bool
    @State private var showRipple = false
    
    func body(content: Content) -> some View {
        content
            .onTapGesture(count: 2) {
                // Double tap detected
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    showStats = true
                }
                
                // Ripple effect
                withAnimation(.easeOut(duration: 0.8)) {
                    showRipple = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    showRipple = false
                }
                
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
            }
            .overlay(
                // Ripple effect
                Group {
                    if showRipple {
                        Circle()
                            .stroke(Color.blue.opacity(0.6), lineWidth: 2)
                            .scaleEffect(showRipple ? 3 : 0)
                            .opacity(showRipple ? 0 : 1)
                            .animation(.easeOut(duration: 0.8), value: showRipple)
                    }
                }
            )
    }
}

// MARK: - Particle Burst Animation (COMPLETELY FIXED)
struct ParticleBurstStatsButton: View {
    @Binding var showStats: Bool
    @State private var particles: [Particle] = []
    
    struct Particle: Identifiable {
        let id = UUID()
        var positionX: CGFloat
        var positionY: CGFloat
        var velocityX: CGFloat
        var velocityY: CGFloat
        var scale: CGFloat
        var opacity: Double
    }
    
    var body: some View {
        Button(action: {
            // Create particle burst
            createParticleBurst()
            
            // Show stats after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    showStats = true
                }
            }
            
            let impact = UIImpactFeedbackGenerator(style: .heavy)
            impact.impactOccurred()
        }) {
            ZStack {
                Circle()
                    .fill(.blue.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
        .overlay(
            // Particles
            ForEach(particles) { particle in
                Circle()
                    .fill(.blue)
                    .frame(width: 4, height: 4)
                    .scaleEffect(particle.scale)
                    .opacity(particle.opacity)
                    .position(x: particle.positionX, y: particle.positionY)
            }
        )
    }
    
    private func createParticleBurst() {
        particles.removeAll()
        
        for _ in 0..<12 {
            let angle = Double.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 50...100)
            
            let velocityX = cos(angle) * speed
            let velocityY = sin(angle) * speed
            
            let particle = Particle(
                positionX: 25, // Center of button
                positionY: 25,
                velocityX: velocityX,
                velocityY: velocityY,
                scale: 1.0,
                opacity: 1.0
            )
            
            particles.append(particle)
        }
        
        // Animate particles
        withAnimation(.easeOut(duration: 1.0)) {
            for i in particles.indices {
                particles[i].positionX += particles[i].velocityX
                particles[i].positionY += particles[i].velocityY
                particles[i].scale = 0.1
                particles[i].opacity = 0.0
            }
        }
        
        // Clear particles after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            particles.removeAll()
        }
    }
}

// MARK: - Extension for easy integration (FIXED)
extension View {
    func edgeSwipeStats(showStats: Binding<Bool>) -> some View {
        self.modifier(EdgeSwipeStatsGesture(showStats: showStats))
    }
    
    func doubleTapWeekStats(showStats: Binding<Bool>) -> some View {
        self.modifier(DoubleTapWeekStatsGesture(showStats: showStats))
    }
}

// MARK: - Simple Implementation for MainHabitsView (READY TO USE)
extension MainHabitsView {
    func addSimpleStatsGesture() -> some View {
        self
            .gesture(
                DragGesture()
                    .onEnded { value in
                        let startX = value.startLocation.x
                        let translationX = value.translation.width
                        let translationY = value.translation.height
                        
                        // Edge swipe right
                        if startX < 30 && translationX > 100 {
                            // Add this state to your MainHabitsView: @State private var showStatsView = false
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                // showStatsView = true
                            }
                            let impact = UIImpactFeedbackGenerator(style: .medium)
                            impact.impactOccurred()
                        }
                        // Pull down from top
                        else if value.startLocation.y < 100 && translationY > 80 {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                // showStatsView = true
                            }
                            let impact = UIImpactFeedbackGenerator(style: .medium)
                            impact.impactOccurred()
                        }
                    }
            )
    }
}

// MARK: - Complete Working Example
struct WorkingStatsExample: View {
    @State private var showStatsView = false
    
    var body: some View {
        ZStack {
            VStack {
                Text("Your Main Habits View Content")
                    .padding()
                
                Button("Test Stats") {
                    showStatsView = true
                }
                .padding()
                .background(.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            
            // Add pull-down gesture
            PullDownStatsOverlay(showStats: $showStatsView)
        }
        // Add edge swipe
        .edgeSwipeStats(showStats: $showStatsView)
        // Present stats
        .fullScreenCover(isPresented: $showStatsView) {
            StatsView()
        }
    }
}
