import SwiftUI

// Tracking type enum

struct RingFillCheckmarkButton: View {
    let habitColor: Color
    @Binding var isCompleted: Bool
    var onTap: () -> Void
    var isInPast: Bool?
    
    // Existing properties for repetitions
    var repeatsPerDay: Int = 1
    var completedRepeats: Int = 0
    var onLongPress: (() -> Void)? = nil
    var isSkipped: Bool = false
    
    // New properties for duration and quantity
    var trackingType: TrackingType = .repetitions
    var targetDuration: Int = 30 // in minutes
    var completedDuration: Int = 0 // in minutes
    var targetQuantity: Int = 10
    var completedQuantity: Int = 0
    var quantityUnit: String = "items"
    var hideText: Bool = false
    
    // App storage for appearance settings
    @AppStorage("checkmarkColorType") private var checkmarkColorType = "habit"
    
    // Animation states
    @State private var scale: CGFloat = 1
    @State private var ringFillTrim: CGFloat = 0
    @State private var checkmarkTrim: CGFloat = 0
    @State private var checkmarkOpacity: Double = 0
    @State private var hasInitialized: Bool = false
    
    // State tracking for haptic feedback
    @State private var previousIsCompleted: Bool = false
    @State private var previousIsSkipped: Bool = false
    @State private var previousCompletedRepeats: Int = 0
    @State private var previousCompletedDuration: Int = 0
    @State private var previousCompletedQuantity: Int = 0
    @State private var isUserInitiatedChange: Bool = false
    
    // Enhanced skip animation states
    @State private var skipIconTrim: CGFloat = 0
    @State private var skipIconOpacity: Double = 0
    @State private var skipRingRotation: Double = 0
    @State private var skipPulseScale: CGFloat = 1.0
    
    
    @State private var chevron1Trim: CGFloat = 0
    @State private var chevron1Opacity: Double = 0
    @State private var chevron2Trim: CGFloat = 0
    @State private var chevron2Opacity: Double = 0
    @State private var chevron3Trim: CGFloat = 0
    @State private var chevron3Opacity: Double = 0
    
    // Computed properties
    private var isFullyCompleted: Bool {
        switch trackingType {
        case .repetitions:
            return completedRepeats >= repeatsPerDay
        case .duration:
            return completedDuration >= targetDuration
        case .quantity:
            return completedQuantity >= targetQuantity
        }
    }
    
    private var completionProgress: CGFloat {
        switch trackingType {
        case .repetitions:
            if repeatsPerDay <= 1 {
                return isCompleted ? 1.0 : 0.0
            } else {
                return CGFloat(completedRepeats) / CGFloat(repeatsPerDay)
            }
        case .duration:
            return min(1.0, CGFloat(completedDuration) / CGFloat(targetDuration))
        case .quantity:
            return min(1.0, CGFloat(completedQuantity) / CGFloat(targetQuantity))
        }
    }
    
    private var centerDisplay: String {
        switch trackingType {
        case .repetitions:
            if repeatsPerDay > 1 && completedRepeats < repeatsPerDay {
                return "\(completedRepeats)/\(repeatsPerDay)"
            }
            return ""
        case .duration:
            if completedDuration < targetDuration {
                return formatDuration(completedDuration)
            }
            return ""
        case .quantity:
            if completedQuantity < targetQuantity {
                return "\(completedQuantity)"
            }
            return ""
        }
    }
    
    private var centerDisplayUnit: String? {
        switch trackingType {
        case .quantity:
            if completedQuantity < targetQuantity {
                return quantityUnit
            }
        default:
            return nil
        }
        return nil
    }
    
    private var bottomRightBadge: String? {
        switch trackingType {
        case .repetitions:
            if repeatsPerDay > 1 && checkmarkOpacity > 0.5 {
                return "\(completedRepeats)"
            }
        case .duration:
            if checkmarkOpacity > 0.5 {
                return formatDurationWithUnit(completedDuration)
            }
        case .quantity:
            if checkmarkOpacity > 0.5 {
                return "\(completedQuantity)"
            }
        }
        return nil
    }
    
    private func formatDuration(_ minutes: Int) -> String {
        return "\(minutes)"
    }
    
    private func formatDurationWithUnit(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            return mins > 0 ? "\(hours)h\(mins)m" : "\(hours)h"
        }
    }
    
    // Checkmark color based on settings
    private var checkmarkColor: Color {
        switch checkmarkColorType {
        case "habit":
            return habitColor
        case "green":
            return .green
        case "primary":
            return .primary
        default:
            return habitColor
        }
    }
    
    private var skipColor: Color {
        return .primary
    }
    
    var body: some View {
        Button(action: {
            isUserInitiatedChange = true
            
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                scale = 0.92
            }
            
            let wasCompleted = isCompleted
            let wasSkipped = isSkipped
            
            isCompleted.toggle()
            onTap()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if !wasCompleted && isCompleted {
                    HapticsManager.shared.playDopamineSuccess()
                } else if wasCompleted && !isCompleted {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isUserInitiatedChange = false
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    scale = 1
                }
            }
        }) {
            ZStack {
                // Empty circle border - always solid
                Circle()
                    .strokeBorder(
                        isSkipped ? skipColor.opacity(0.40) : Color.gray.opacity(0.3),
                        lineWidth: 2
                    )
                    .frame(width: 32, height: 32)
                
                // Progress ring fill that animates clockwise from top
                Circle()
                    .trim(from: 0, to: ringFillTrim)
                    .stroke(
                        checkmarkColor.opacity(0.8),
                        style: StrokeStyle(
                            lineWidth: 3,
                            lineCap: .round,
                            lineJoin: .miter
                        )
                    )
                    .frame(width: 32, height: 32)
                    .rotationEffect(.degrees(-90 + skipRingRotation))
                
                // Skip icon (when skipped)
                if isSkipped {
                    ZStack {
                            // First chevron (rightmost) - low opacity, animates first
                            ChevronShape(position: 0)
                                .trim(from: 0, to: chevron1Trim)
                                .stroke(
                                    skipColor,
                                    style: StrokeStyle(
                                        lineWidth: 2.5,
                                        lineCap: .round,
                                        lineJoin: .round
                                    )
                                )
                                .frame(width: 20, height: 20)
                                .opacity(chevron1Opacity * 0.6) // 30% opacity
                                .scaleEffect(skipPulseScale)
                            
                            // Second chevron (middle) - medium opacity, animates second
                            ChevronShape(position: 1)
                                .trim(from: 0, to: chevron2Trim)
                                .stroke(
                                    skipColor,
                                    style: StrokeStyle(
                                        lineWidth: 2.5,
                                        lineCap: .round,
                                        lineJoin: .round
                                    )
                                )
                                .frame(width: 20, height: 20)
                                .opacity(chevron2Opacity * 0.8) // 60% opacity
                                .scaleEffect(skipPulseScale)
                            
                            // Third chevron (leftmost) - full opacity, animates last
                            ChevronShape(position: 2)
                                .trim(from: 0, to: chevron3Trim)
                                .stroke(
                                    skipColor,
                                    style: StrokeStyle(
                                        lineWidth: 2.5,
                                        lineCap: .round,
                                        lineJoin: .round
                                    )
                                )
                                .frame(width: 20, height: 20)
                                .opacity(chevron3Opacity * 1.0) // Full opacity
                                .scaleEffect(skipPulseScale)
                        }
                } else {
                    // Center display for incomplete states
                    if !hideText && !centerDisplay.isEmpty && checkmarkOpacity < 0.5 {
                        if trackingType == .quantity && completedQuantity < targetQuantity {
                            // For quantity: use clean slash format like multi-repetitions
                            HStack(spacing: 0) {
                                Text("\(completedQuantity)")
                                    .font(.customFont("Lexend", .semibold, 10))
                                    .foregroundColor(checkmarkColor)
                                Text("/")
                                    .font(.customFont("Lexend", .semibold, 8.5))
                                    .foregroundColor(checkmarkColor.opacity(0.7))
                                    .offset(y: 0.5)
                                Text("\(targetQuantity)")
                                    .font(.customFont("Lexend", .semibold, 8.5))
                                    .foregroundColor(checkmarkColor.opacity(0.7))
                                    .offset(y: 0.5)
                            }
                            .opacity(checkmarkOpacity < 0.5 ? 1.0 : 0.0)
                        } else if trackingType == .duration && completedDuration < targetDuration {
                            // For duration: use clean slash format like multi-repetitions
                            HStack(spacing: 0) {
                                Text("\(completedDuration)")
                                    .font(.customFont("Lexend", .semibold, 10))
                                    .foregroundColor(checkmarkColor)
                                Text("/")
                                    .font(.customFont("Lexend", .semibold, 8.5))
                                    .foregroundColor(checkmarkColor.opacity(0.7))
                                    .offset(y: 0.5)
                                Text("\(targetDuration)")
                                    .font(.customFont("Lexend", .semibold, 8.5))
                                    .foregroundColor(checkmarkColor.opacity(0.7))
                                    .offset(y: 0.5)
                            }
                            .opacity(checkmarkOpacity < 0.5 ? 1.0 : 0.0)
                        } else if trackingType == .repetitions && repeatsPerDay > 1 {
                            // For multi-repetitions: styled text with smaller slash and denominator
                            let parts = centerDisplay.split(separator: "/")
                            if parts.count == 2 {
                                HStack(spacing: 0) {
                                    Text(String(parts[0]))
                                        .font(.customFont("Lexend", .semibold, 10))
                                        .foregroundColor(checkmarkColor)
                                    Text("/")
                                        .font(.customFont("Lexend", .semibold, 8.5))
                                        .foregroundColor(checkmarkColor.opacity(0.7))
                                        .offset(y: 0.5)
                                    Text(String(parts[1]))
                                        .font(.customFont("Lexend", .semibold, 8.5))
                                        .foregroundColor(checkmarkColor.opacity(0.7))
                                        .offset(y: 0.5)
                                }
                                .opacity(checkmarkOpacity < 0.5 ? 1.0 : 0.0)
                            } else {
                                Text(centerDisplay)
                                    .font(.customFont("Lexend", .semibold, 10))
                                    .foregroundColor(checkmarkColor)
                                    .opacity(checkmarkOpacity < 0.5 ? 1.0 : 0.0)
                            }
                        } else {
                            // For other types: single line
                            Text(centerDisplay)
                                .font(.customFont("Lexend", .bold, 10))
                                .foregroundColor(checkmarkColor)
                                .opacity(checkmarkOpacity < 0.5 ? 1.0 : 0.0)
                        }
                    }
                    
                    // Drawing checkmark (only when fully completed)
                    CheckmarkShape()
                        .trim(from: 0, to: checkmarkTrim)
                        .stroke(
                            checkmarkColor,
                            style: StrokeStyle(
                                lineWidth: 3,
                                lineCap: .round,
                                lineJoin: .round
                            )
                        )
                        .frame(width: 16, height: 16)
                        .opacity(checkmarkOpacity)
                    
                    if !hideText, let badge = bottomRightBadge {
                        Text(badge)
                            .font(.customFont("Lexend", .bold, trackingType == .duration ? 7 : 9))
                            .foregroundColor(checkmarkColor.opacity(0.95))
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: trackingType == .duration ? 14 : 12, height: trackingType == .duration ? 14 : 12)
                            )
                            .offset(x: 10, y: 10)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .scaleEffect(scale)
            .contentShape(Circle())
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    onLongPress?()
                }
        )
        .onAppear {
            initializeStates()
        }
        .onChange(of: isSkipped) { oldValue, newValue in
            handleSkipChange(from: oldValue, to: newValue)
        }
        .onChange(of: completedRepeats) { oldValue, newValue in
            if trackingType == .repetitions {
                handleRepetitionChange(from: oldValue, to: newValue)
            }
        }
        .onChange(of: completedDuration) { oldValue, newValue in
            if trackingType == .duration {
                handleDurationChange(from: oldValue, to: newValue)
            }
        }
        .onChange(of: completedQuantity) { oldValue, newValue in
            if trackingType == .quantity {
                handleQuantityChange(from: oldValue, to: newValue)
            }
        }
        .onChange(of: isCompleted) { oldValue, newValue in
            handleCompletionChange(from: oldValue, to: newValue)
        }
    }
    
    // MARK: - State Management
    private func animateSkipIcon(entering: Bool) {
        if entering {
            // Ring rotation animation (same as before)
            withAnimation(.easeInOut(duration: 0.4)) {
                skipRingRotation = 25
            }
            
            withAnimation(.easeOut(duration: 0.3).delay(0.4)) {
                skipRingRotation = -10
            }
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.7)) {
                skipRingRotation = 0
            }
            
            // Pulse scale animation (same as before)
            withAnimation(.easeInOut(duration: 0.8).delay(0.2)) {
                skipPulseScale = 1.1
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeOut(duration: 0.4)) {
                    skipPulseScale = 1.0
                }
            }
            
            // Staggered chevron animations
            // First chevron (rightmost, low opacity) - starts first
            withAnimation(.easeOut(duration: 0.3).delay(0.2)) {
                chevron1Opacity = 1.0
            }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.3)) {
                chevron1Trim = 1.0
            }
            
            // Second chevron (middle, medium opacity) - starts after short delay
            withAnimation(.easeOut(duration: 0.3).delay(0.35)) {
                chevron2Opacity = 1.0
            }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.45)) {
                chevron2Trim = 1.0
            }
            
            // Third chevron (leftmost, full opacity) - starts last
            withAnimation(.easeOut(duration: 0.3).delay(0.5)) {
                chevron3Opacity = 1.0
            }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.6)) {
                chevron3Trim = 1.0
            }
            
        } else {
            // Exit animation - all chevrons disappear together
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                chevron1Trim = 0
                chevron1Opacity = 0
                chevron2Trim = 0
                chevron2Opacity = 0
                chevron3Trim = 0
                chevron3Opacity = 0
                skipRingRotation = 0
                skipPulseScale = 1.0
            }
        }
    }

    private func initializeStates() {
        if !hasInitialized {
            if isSkipped {
                // When skipped, show EMPTY ring
                ringFillTrim = 0.0  // Always 0% when skipped
                chevron1Trim = 1.0
                chevron1Opacity = 1.0
                chevron2Trim = 1.0
                chevron2Opacity = 1.0
                chevron3Trim = 1.0
                chevron3Opacity = 1.0
                skipRingRotation = 0
                skipPulseScale = 1.0
            } else {
                ringFillTrim = completionProgress
                checkmarkTrim = isFullyCompleted ? 1.0 : 0.0
                checkmarkOpacity = isFullyCompleted ? 1.0 : 0.0
                // Initialize chevron states to 0 when not skipped
                chevron1Trim = 0
                chevron1Opacity = 0
                chevron2Trim = 0
                chevron2Opacity = 0
                chevron3Trim = 0
                chevron3Opacity = 0
            }
            
            previousIsCompleted = isCompleted
            previousIsSkipped = isSkipped
            previousCompletedRepeats = completedRepeats
            previousCompletedDuration = completedDuration
            previousCompletedQuantity = completedQuantity
            hasInitialized = true
        }
    }

    private func handleSkipChange(from oldValue: Bool, to newValue: Bool) {
        let isRealStateChange = hasInitialized && (oldValue != newValue)
        
        if !oldValue && newValue {
            // Entering skip state
            if isRealStateChange && isUserInitiatedChange {
                HapticsManager.shared.playRegretSkip()
            }
            
            // Hide checkmark immediately
            withAnimation(.easeIn(duration: 0.15)) {
                checkmarkTrim = 0
                checkmarkOpacity = 0
            }
            
            // EMPTY THE RING when skipping
            withAnimation(.easeInOut(duration: 0.4)) {
                ringFillTrim = 0.0
            }
            
            animateSkipIcon(entering: true)
            
        } else if oldValue && !newValue {
            // Exiting skip state
            if isRealStateChange && isUserInitiatedChange {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            }
            
            animateSkipIcon(entering: false)
            
            // Restore actual progress when unskipping
            withAnimation(.easeOut(duration: 0.4).delay(0.1)) {
                ringFillTrim = completionProgress
            }
            
            // If fully completed, show checkmark
            if isFullyCompleted {
                withAnimation(Animation.easeOut(duration: 0.3).delay(0.2)) {
                    checkmarkOpacity = 1
                }
                
                withAnimation(Animation.easeInOut(duration: 0.4).delay(0.25)) {
                    checkmarkTrim = 1
                }
            }
        }
        
        if hasInitialized {
            previousIsSkipped = newValue
        }
    }
    
    
    private func handleRepetitionChange(from oldValue: Int, to newValue: Int) {
        let shouldPlayFullHaptics = hasInitialized && (oldValue != newValue) && isUserInitiatedChange && oldValue < repeatsPerDay && newValue >= repeatsPerDay
        let shouldPlayPartialHaptics = hasInitialized && (oldValue != newValue) && isUserInitiatedChange && newValue < repeatsPerDay
        
        if repeatsPerDay > 1 {
            withAnimation(Animation.easeInOut(duration: 0.3)) {
                ringFillTrim = completionProgress
            }
            
            if newValue >= repeatsPerDay {
                if shouldPlayFullHaptics {
                    HapticsManager.shared.playDopamineSuccess()
                }
                
                withAnimation(Animation.easeOut(duration: 0.3)) {
                    checkmarkOpacity = 1
                }
                
                withAnimation(Animation.easeInOut(duration: 0.4)) {
                    checkmarkTrim = 1
                }
            } else {
                // Play small haptic for individual repetition (not fully completed)
                if shouldPlayPartialHaptics {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                }
                
                withAnimation(.easeIn(duration: 0.2)) {
                    checkmarkTrim = 0
                    checkmarkOpacity = 0
                }
            }
        }
        
        if hasInitialized {
            previousCompletedRepeats = newValue
        }
    }
    
    private func handleDurationChange(from oldValue: Int, to newValue: Int) {
        let shouldPlayHaptics = hasInitialized && (oldValue != newValue) && isUserInitiatedChange && oldValue < targetDuration && newValue >= targetDuration
        
        withAnimation(Animation.easeInOut(duration: 0.3)) {
            ringFillTrim = completionProgress
        }
        
        if newValue >= targetDuration {
            if shouldPlayHaptics {
                HapticsManager.shared.playDopamineSuccess()
            }
            
            withAnimation(Animation.easeOut(duration: 0.3)) {
                checkmarkOpacity = 1
            }
            
            withAnimation(Animation.easeInOut(duration: 0.4)) {
                checkmarkTrim = 1
            }
        } else {
            withAnimation(.easeIn(duration: 0.2)) {
                checkmarkTrim = 0
                checkmarkOpacity = 0
            }
        }
        
        if hasInitialized {
            previousCompletedDuration = newValue
        }
    }
    
    private func handleQuantityChange(from oldValue: Int, to newValue: Int) {
        let shouldPlayFullHaptics = hasInitialized && (oldValue != newValue) && isUserInitiatedChange && oldValue < targetQuantity && newValue >= targetQuantity
        let shouldPlayPartialHaptics = hasInitialized && (oldValue != newValue) && isUserInitiatedChange && newValue < targetQuantity
        
        withAnimation(Animation.easeInOut(duration: 0.3)) {
            ringFillTrim = completionProgress
        }
        
        if newValue >= targetQuantity {
            if shouldPlayFullHaptics {
                HapticsManager.shared.playDopamineSuccess()
            }
            
            withAnimation(Animation.easeOut(duration: 0.3)) {
                checkmarkOpacity = 1
            }
            
            withAnimation(Animation.easeInOut(duration: 0.4)) {
                checkmarkTrim = 1
            }
        } else {
            // Play small haptic for quantity progress (not fully completed)
            if shouldPlayPartialHaptics {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            }
            
            withAnimation(.easeIn(duration: 0.2)) {
                checkmarkTrim = 0
                checkmarkOpacity = 0
            }
        }
        
        if hasInitialized {
            previousCompletedQuantity = newValue
        }
    }
    
    private func handleCompletionChange(from oldValue: Bool, to newValue: Bool) {
        if !isSkipped {
            let shouldPlayHaptics = hasInitialized && (oldValue != newValue) && isUserInitiatedChange
            
            // Handle single-repeat habits or when tracking type uses isCompleted as main trigger
            if (trackingType == .repetitions && repeatsPerDay <= 1) ||
               (trackingType == .duration && targetDuration <= 0) ||
               (trackingType == .quantity && targetQuantity <= 0) {
                
                if !oldValue && newValue {
                    if shouldPlayHaptics {
                        HapticsManager.shared.playDopamineSuccess()
                    }
                    
                    withAnimation(Animation.easeInOut(duration: 0.45)) {
                        ringFillTrim = 1.0
                    }
                    
                    withAnimation(Animation.easeOut(duration: 0.5).delay(0.4)) {
                        checkmarkOpacity = 1
                    }
                    
                    withAnimation(Animation.easeInOut(duration: 0.6).delay(0.45)) {
                        checkmarkTrim = 1
                    }
                } else if oldValue && !newValue {
                    if shouldPlayHaptics {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                    }
                    
                    withAnimation(.easeIn(duration: 0.2)) {
                        ringFillTrim = 0
                        checkmarkTrim = 0
                        checkmarkOpacity = 0
                    }
                }
            }
        }
        
        if hasInitialized {
            previousIsCompleted = newValue
        }
    }
}

// MARK: - Supporting Shapes

struct CheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        
        var path = Path()
        
        path.move(to: CGPoint(x: width * 0.2, y: height * 0.55))
        path.addQuadCurve(
            to: CGPoint(x: width * 0.4, y: height * 0.75),
            control: CGPoint(x: width * 0.3, y: height * 0.7)
        )
        path.addQuadCurve(
            to: CGPoint(x: width * 0.85, y: height * 0.2),
            control: CGPoint(x: width * 0.6, y: height * 0.5)
        )
        
        return path
    }
}
/*
struct SkipIconShape: Shape {
    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        
        var path = Path()
        
        let chevronWidth = width * 0.10
        let chevronHeight = height * 0.4
        let spacing = width * 0.10
        
        let centerY = height * 0.5
        let totalWidth = (chevronWidth * 3) + (spacing * 2)
        let startX = (width - totalWidth) / 2
        
        // First chevron (rightmost - full opacity)
        let x1 = startX
        path.move(to: CGPoint(x: x1, y: centerY - chevronHeight/2))
        path.addLine(to: CGPoint(x: x1 + chevronWidth, y: centerY))
        path.addLine(to: CGPoint(x: x1, y: centerY + chevronHeight/2))
        
        // Second chevron (middle - medium opacity)
        let x2 = x1 + chevronWidth + spacing
        path.move(to: CGPoint(x: x2, y: centerY - chevronHeight/2))
        path.addLine(to: CGPoint(x: x2 + chevronWidth, y: centerY))
        path.addLine(to: CGPoint(x: x2, y: centerY + chevronHeight/2))
        
        // Third chevron (leftmost - low opacity)
        let x3 = x2 + chevronWidth + spacing
        path.move(to: CGPoint(x: x3, y: centerY - chevronHeight/2))
        path.addLine(to: CGPoint(x: x3 + chevronWidth, y: centerY))
        path.addLine(to: CGPoint(x: x3, y: centerY + chevronHeight/2))
        
        return path
    }
}
*/
struct ChevronShape: Shape {
    let position: Int // 0 = first (right), 1 = middle, 2 = last (left)
    
    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        
        var path = Path()
        
        let chevronWidth = width * 0.10
        let chevronHeight = height * 0.4
        let spacing = width * 0.10
        
        let centerY = height * 0.5
        let totalWidth = (chevronWidth * 3) + (spacing * 2)
        let startX = (width - totalWidth) / 2
        
        let xPosition = startX + CGFloat(position) * (chevronWidth + spacing)
        
        path.move(to: CGPoint(x: xPosition, y: centerY - chevronHeight/2))
        path.addLine(to: CGPoint(x: xPosition + chevronWidth, y: centerY))
        path.addLine(to: CGPoint(x: xPosition, y: centerY + chevronHeight/2))
        
        return path
    }
}


// MARK: - Comprehensive Preview
/*
struct RingFillCheckmarkButton_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 30) {
                // MARK: Repetitions Examples
                Group {
                    Text("REPETITIONS")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 30) {
                        VStack(spacing: 8) {
                            RingFillCheckmarkButton(
                                habitColor: .blue,
                                isCompleted: .constant(false),
                                onTap: {},
                                repeatsPerDay: 1,
                                completedRepeats: 0,
                                trackingType: .repetitions
                            )
                            Text("0/1")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(spacing: 8) {
                            RingFillCheckmarkButton(
                                habitColor: .blue,
                                isCompleted: .constant(true),
                                onTap: {},
                                repeatsPerDay: 1,
                                completedRepeats: 1,
                                trackingType: .repetitions
                            )
                            Text("Complete")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(spacing: 8) {
                            RingFillCheckmarkButton(
                                habitColor: .purple,
                                isCompleted: .constant(false),
                                onTap: {},
                                repeatsPerDay: 3,
                                completedRepeats: 1,
                                trackingType: .repetitions
                            )
                            Text("1/3")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(spacing: 8) {
                            RingFillCheckmarkButton(
                                habitColor: .purple,
                                isCompleted: .constant(true),
                                onTap: {},
                                repeatsPerDay: 3,
                                completedRepeats: 3,
                                trackingType: .repetitions
                            )
                            Text("3/3")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Divider()
                
                // MARK: Duration Examples
                Group {
                    Text("DURATION")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 30) {
                        VStack(spacing: 8) {
                            RingFillCheckmarkButton(
                                habitColor: .orange,
                                isCompleted: .constant(false),
                                onTap: {},
                                trackingType: .duration,
                                targetDuration: 30,
                                completedDuration: 0
                            )
                            Text("0/30m")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(spacing: 8) {
                            RingFillCheckmarkButton(
                                habitColor: .orange,
                                isCompleted: .constant(false),
                                onTap: {},
                                trackingType: .duration,
                                targetDuration: 60,
                                completedDuration: 15
                            )
                            Text("15/60m")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(spacing: 8) {
                            RingFillCheckmarkButton(
                                habitColor: .orange,
                                isCompleted: .constant(false),
                                onTap: {},
                                trackingType: .duration,
                                targetDuration: 90,
                                completedDuration: 75
                            )
                            Text("1h15m/1h30m")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(spacing: 8) {
                            RingFillCheckmarkButton(
                                habitColor: .orange,
                                isCompleted: .constant(true),
                                onTap: {},
                                trackingType: .duration,
                                targetDuration: 30,
                                completedDuration: 30
                            )
                            Text("Complete")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Divider()
                
                // MARK: Quantity Examples
                Group {
                    Text("QUANTITY")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 30) {
                        VStack(spacing: 8) {
                            RingFillCheckmarkButton(
                                habitColor: .green,
                                isCompleted: .constant(false),
                                onTap: {},
                                trackingType: .quantity,
                                targetQuantity: 50,
                                completedQuantity: 0,
                                quantityUnit: "pages"
                            )
                            Text("0/50 pages")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(spacing: 8) {
                            RingFillCheckmarkButton(
                                habitColor: .green,
                                isCompleted: .constant(false),
                                onTap: {},
                                trackingType: .quantity,
                                targetQuantity: 8,
                                completedQuantity: 3,
                                quantityUnit: "glasses"
                            )
                            Text("3/8 glasses")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(spacing: 8) {
                            RingFillCheckmarkButton(
                                habitColor: .green,
                                isCompleted: .constant(false),
                                onTap: {},
                                trackingType: .quantity,
                                targetQuantity: 100,
                                completedQuantity: 85,
                                quantityUnit: "words"
                            )
                            Text("85/100 words")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(spacing: 8) {
                            RingFillCheckmarkButton(
                                habitColor: .green,
                                isCompleted: .constant(true),
                                onTap: {},
                                trackingType: .quantity,
                                targetQuantity: 10,
                                completedQuantity: 10,
                                quantityUnit: "items"
                            )
                            Text("Complete")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Divider()
                
                // MARK: Skipped State Examples
                Group {
                    Text("SKIPPED STATES")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 30) {
                        VStack(spacing: 8) {
                            RingFillCheckmarkButton(
                                habitColor: .indigo,
                                isCompleted: .constant(false),
                                onTap: {},
                                isSkipped: true,
                                trackingType: .repetitions
                            )
                            Text("Skipped")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(spacing: 8) {
                            RingFillCheckmarkButton(
                                habitColor: .indigo,
                                isCompleted: .constant(false),
                                onTap: {},
                                isSkipped: true,
                                trackingType: .duration,
                                targetDuration: 30
                            )
                            Text("Skipped")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(spacing: 8) {
                            RingFillCheckmarkButton(
                                habitColor: .indigo,
                                isCompleted: .constant(false),
                                onTap: {},
                                isSkipped: true,
                                trackingType: .quantity,
                                targetQuantity: 20
                            )
                            Text("Skipped")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
            }
            .padding()
        }
    }
}
*/

