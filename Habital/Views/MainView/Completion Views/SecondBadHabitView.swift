//
//  SecondBadHabitView.swift
//  Habital
//
//  Created by Elias Osarumwense on 14.04.25.
//

import SwiftUI

struct CrossShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Create an X shape
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        
        path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        
        return path
    }
}

struct BadHabitButton: View {
    let successColor: Color // Color when habit is NOT broken (good)
    let failureColor: Color // Color when habit IS broken (bad)
    @Binding var isBroken: Bool
    var streakCount: Int = 0 // Optional streak counter
    var onTap: () -> Void
    
    // Animation states
    @State private var scale: CGFloat = 1
    @State private var successRingOpacity: Double = 1.0
    @State private var failureRingTrim: CGFloat = 0
    @State private var crossTrim: CGFloat = 0
    @State private var crossOpacity: Double = 0
    @State private var shakeEffect: Bool = false
    @State private var hasInitialized: Bool = false
    @State private var streakScale: CGFloat = 1.0
    @State private var streakPulse: Bool = false
    
    // Computed property for streak size
    private var streakFontSize: CGFloat {
        if streakCount < 10 {
            return 12 // Single digit
        } else if streakCount < 100 {
            return 10 // Double digit
        } else {
            return 8 // Triple digit or more
        }
    }
    
    var body: some View {
        Button(action: {
            // Button press animation
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                scale = 0.92
            }
            
            // Toggle broken state
            let oldValue = isBroken
            isBroken.toggle()
            let newValue = isBroken
            
            if newValue {
                // Animate to broken state (bad) - only shake when CHANGING from good to bad
                if !oldValue && newValue {
                    // Fade out success ring and streak glow
                    withAnimation(Animation.easeOut(duration: 0.3)) {
                        successRingOpacity = 0
                        //streakGlowOpacity = 0
                    }
                    
                    // Fill failure ring with red counter-clockwise
                    withAnimation(Animation.easeInOut(duration: 0.4).delay(0.2)) {
                        failureRingTrim = 1.0
                    }
                    
                    // Draw X mark with animation
                    withAnimation(Animation.easeInOut(duration: 0.4).delay(0.5)) {
                        crossOpacity = 1
                        crossTrim = 1
                    }
                    
                    // Add shake effect for negative feedback ONLY when breaking habit
                    withAnimation(Animation.easeInOut(duration: 0.4).delay(0.6)) {
                        shakeEffect = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
                        withAnimation(.easeOut(duration: 0.2)) {
                            shakeEffect = false
                        }
                    }
                } else {
                    // Already broken state, just update without shaking
                    successRingOpacity = 0
                    //streakGlowOpacity = 0
                    failureRingTrim = 1.0
                    crossOpacity = 1
                    crossTrim = 1
                }
                
            } else {
                // Animate back to default state (good) - NO shaking here
                
                // Quick erase of failure indicators
                withAnimation(.easeOut(duration: 0.3)) {
                    failureRingTrim = 0
                    crossTrim = 0
                    crossOpacity = 0
                }
                
                // Bring back the success ring
                withAnimation(Animation.easeIn(duration: 0.4).delay(0.2)) {
                    successRingOpacity = 1.0
                }
                
                // Streak celebration animation
                if streakCount > 0 {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        streakScale = 1.2
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            streakScale = 1.0
                        }
                    }
                }
            }
            
            // Reset scale after button press
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    scale = 1
                }
            }
            
            // Execute callback
            onTap()
            /*
            // Haptic feedback - double rigid vibration when breaking bad habits (only when changing from good to bad)
            if newValue && !oldValue {
                // First rigid vibration
                let generator = UIImpactFeedbackGenerator(style: .rigid)
                generator.prepare() // Prepare for better performance
                generator.impactOccurred(intensity: 1.0)
                
                // Second vibration after a short delay - with full intensity
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    let secondGenerator = UIImpactFeedbackGenerator(style: .rigid)
                    secondGenerator.prepare()
                    secondGenerator.impactOccurred(intensity: 1.0)
                }
            } else {
                // Normal light feedback for other state changes
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            }
             */
        }) {
            ZStack {
                // Success circle - shown when habit is NOT broken (good state)
                Circle()
                    .stroke(
                        successColor,
                        style: StrokeStyle(
                            lineWidth: 3,
                            lineCap: .round
                        )
                    )
                    .frame(width: 32, height: 32)
                    .opacity(successRingOpacity)
                
                // Background for broken state
                Circle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 32, height: 32)
                    .opacity(1 - successRingOpacity)
                
                // Failure ring that animates counter-clockwise (appears when broken)
                Circle()
                    .trim(from: 0, to: failureRingTrim)
                    .stroke(
                        failureColor,
                        style: StrokeStyle(
                            lineWidth: 3,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                    .frame(width: 32, height: 32)
                    .rotationEffect(.degrees(90)) // Start from bottom (6 o'clock)
                
                // Drawing X mark
                CrossShape()
                    .trim(from: 0, to: crossTrim)
                    .stroke(
                        failureColor,
                        style: StrokeStyle(
                            lineWidth: 3,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                    .frame(width: 16, height: 16)
                    .opacity(crossOpacity)
                
                // Enhanced streak counter (only show when streak > 0 AND not broken)
                if streakCount > 0 && !isBroken {
                    ZStack {
                        // Add subtle background highlight for the streak number
                        Circle()
                            .fill(successColor.opacity(0.15))
                            .frame(width: 28, height: 28)
                        
                        // Add a subtle inner circle for depth
                        Circle()
                            .stroke(successColor.opacity(0.3), lineWidth: 1)
                            .frame(width: 22, height: 22)
                        
                        // The streak number itself
                        Text("\(streakCount)")
                            .font(.system(size: streakFontSize, weight: .bold))
                            .foregroundColor(successColor)
                            .minimumScaleFactor(0.5)
                            .scaleEffect(streakScale)
                    }
                    .opacity(successRingOpacity)
                    
                    // Add subtle glow effect around the circle for higher streaks
                    if streakCount >= 5 {
                        Circle()
                            .fill(successColor.opacity(0.2))
                            .frame(width: streakCount >= 10 ? 40 : 36, height: streakCount >= 10 ? 40 : 36)
                            //.blur(radius: 4)
                            .opacity(successRingOpacity)
                            .scaleEffect(streakPulse ? 1.05 : 1.0)
                            .animation(
                                Animation.easeInOut(duration: 1.5)
                                    .repeatForever(autoreverses: true),
                                value: streakPulse
                            )
                            .onAppear {
                                streakPulse = true
                            }
                    }
                }
            }
            .scaleEffect(scale)
            .modifier(ShakeEffect(animatableData: shakeEffect ? 1 : 0))
            .contentShape(Circle()) // Ensure tap area is the full circle
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            // Initialize states based on current broken state without animation
            if !hasInitialized {
                // Set initial states based on isBroken value
                successRingOpacity = isBroken ? 0.0 : 1.0
                failureRingTrim = isBroken ? 1.0 : 0.0
                crossTrim = isBroken ? 1.0 : 0.0
                crossOpacity = isBroken ? 1.0 : 0.0
                hasInitialized = true
                
                // Start gentle pulsing for higher streaks
                if streakCount >= 5 && !isBroken {
                    streakPulse = true
                }
            }
        }
        .onChange(of: isBroken) { oldValue, newValue in
            // This handles external changes to isBroken (not from button press)
            if !oldValue && newValue {
                // Changed to broken externally - animate and shake ONLY when transitioning from good to bad
                withAnimation(Animation.easeOut(duration: 0.3)) {
                    successRingOpacity = 0
                }
                
                withAnimation(Animation.easeInOut(duration: 0.4).delay(0.2)) {
                    failureRingTrim = 1.0
                }
                
                withAnimation(Animation.easeInOut(duration: 0.4).delay(0.5)) {
                    crossOpacity = 1
                    crossTrim = 1
                }
                
                // Add shake when broken externally too (only when CHANGING from good to bad)
                withAnimation(Animation.easeInOut(duration: 0.4).delay(0.6)) {
                    shakeEffect = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
                    withAnimation(.easeOut(duration: 0.2)) {
                        shakeEffect = false
                    }
                }
                

                
            } else if oldValue && !newValue {
                // Changed to unbroken externally - NO shaking
                withAnimation(.easeOut(duration: 0.3)) {
                    failureRingTrim = 0
                    crossTrim = 0
                    crossOpacity = 0
                }
                
                withAnimation(Animation.easeIn(duration: 0.4).delay(0.2)) {
                    successRingOpacity = 1.0
                }
                
                // Celebrate streak restore with subtle animation
                if streakCount > 0 {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        streakScale = 1.2
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            streakScale = 1.0
                        }
                    }
                }
            }
        }
        // Update pulsing effect when streak changes
        .onChange(of: streakCount) { oldValue, newValue in
            if newValue >= 5 && !isBroken && !streakPulse {
                streakPulse = true
            }
        }
    }
}

// Shake effect for negative feedback
struct ShakeEffect: GeometryEffect {
    var animatableData: CGFloat
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: sin(animatableData * .pi * 6) * 3, y: 0))
    }
}

// Usage example with demo
struct BadHabitDemo: View {
    @State private var isBroken = false
    @State private var successColor: Color = .green
    @State private var failureColor: Color = .red
    @State private var streakCount: Int = 7 // Demo streak count
    
    let successColorOptions: [Color] = [.green, .blue, .teal, .mint, .cyan]
    let failureColorOptions: [Color] = [.red, .orange, .pink, .purple, .indigo]
    
    var body: some View {
        VStack(spacing: 25) {
            Text("Bad Habit Tracker")
                .font(.headline)
            
            VStack(spacing: 10) {
                BadHabitButton(
                    successColor: successColor,
                    failureColor: failureColor,
                    isBroken: $isBroken,
                    streakCount: streakCount
                ) {
                    print("Toggled bad habit: \(isBroken)")
                }
                .padding(.bottom, 5)
                
                Text(isBroken ? "Bad habit broken today!" : "Streak active: \(streakCount) days")
                    .foregroundColor(isBroken ? failureColor : successColor)
                    .font(.system(size: 16, weight: .medium))
                    .animation(.easeInOut, value: isBroken)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(.systemBackground))
                /*
                    .shadow(color: isBroken ? failureColor.opacity(0.2) : successColor.opacity(0.2),
                            radius: 8, x: 0, y: 2)
                 */
            )
            
            // Example description
            Text(isBroken ? "You need to get back on track!" : "Your current streak is glowing! Keep it up!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .padding(.top, 5)
            
            // Streak controls for demo
            if !isBroken {
                HStack(spacing: 20) {
                    Button(action: {
                        if streakCount > 0 {
                            streakCount -= 1
                        }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    
                    Text("Adjust Streak")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        streakCount += 1
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 5)
            }
            
            // Color selection for demo
            VStack(spacing: 10) {
                Text("Success Color (when streak is active)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 15) {
                    ForEach(successColorOptions, id: \.self) { color in
                        Circle()
                            .fill(color)
                            .frame(width: 25, height: 25)
                            .overlay(
                                Circle()
                                    .strokeBorder(Color.white, lineWidth: 2)
                                    .opacity(color == successColor ? 1 : 0)
                            )
                            //.shadow(color: color.opacity(0.5), radius: 2, x: 0, y: 0)
                            .scaleEffect(color == successColor ? 1.1 : 1.0)
                            .animation(.spring(response: 0.3), value: successColor)
                            .onTapGesture {
                                successColor = color
                            }
                    }
                }
                
                Text("Failure Color (when habit is broken)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 5)
                
                HStack(spacing: 15) {
                    ForEach(failureColorOptions, id: \.self) { color in
                        Circle()
                            .fill(color)
                            .frame(width: 25, height: 25)
                            .overlay(
                                Circle()
                                    .strokeBorder(Color.white, lineWidth: 2)
                                    .opacity(color == failureColor ? 1 : 0)
                            )
                            //.shadow(color: color.opacity(0.5), radius: 2, x: 0, y: 0)
                            .scaleEffect(color == failureColor ? 1.1 : 1.0)
                            .animation(.spring(response: 0.3), value: failureColor)
                            .onTapGesture {
                                failureColor = color
                            }
                    }
                }
            }
            .padding(.bottom, 15)
            .padding(.top, 5)
            
            // Demo controls
            Button(isBroken ? "Reset (didn't break habit)" : "Mark as Broken") {
                withAnimation {
                    isBroken.toggle()
                    // Reset streak when resetting a broken habit
                    if !isBroken && streakCount == 0 {
                        streakCount = 1
                    }
                }
            }
            .buttonStyle(.bordered)
            .tint(isBroken ? successColor : failureColor)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        //.shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 2)
        .padding()
    }
}

#Preview {
    BadHabitDemo()
}
