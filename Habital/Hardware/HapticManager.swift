//
//  HapticManager.swift
//  Habital
//
//  Created by Elias Osarumwense on 20.08.25.
//

import SwiftUI
import CoreHaptics

final class HapticsManager {
    static let shared = HapticsManager()
    
    private var engine: CHHapticEngine?
    private var supportsHaptics: Bool = false
    
    private init() {
        prepareEngine()
    }
    
    private func prepareEngine() {
        let cap = CHHapticEngine.capabilitiesForHardware()
        supportsHaptics = cap.supportsHaptics
        guard supportsHaptics else { return }
        
        do {
            engine = try CHHapticEngine()
            try engine?.start()
            engine?.stoppedHandler = { _ in
                // Try to restart on interruptions
                try? self.engine?.start()
            }
            engine?.resetHandler = {
                // Rebuild resources if needed
                self.prepareEngine()
            }
        } catch {
            supportsHaptics = false
        }
    }
    
    // MARK: - Public API
    
    /// Crisp, rising triple-tap with a tiny sparkle tail (reward/dopamine)
    func playDopamineSuccess() {
        guard supportsHaptics, let engine = engine else {
            // Fallback
            let g = UINotificationFeedbackGenerator()
            g.notificationOccurred(.success)
            return
        }
        
        do {
            var events: [CHHapticEvent] = []
            
            // Three transients with rising intensity & sharpness
            let taps: [(time: TimeInterval, intensity: Float, sharpness: Float)] = [
                (0.00, 0.45, 0.50),
                (0.08, 0.70, 0.80),
                (0.16, 1.00, 1.00)
            ]
            for t in taps {
                let params = [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: t.intensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: t.sharpness)
                ]
                events.append(CHHapticEvent(eventType: .hapticTransient,
                                            parameters: params,
                                            relativeTime: t.time))
            }
            
            // A very short continuous "sparkle" tail that quickly fades
            // (keeps it feeling premium but still minimal)
            let tailStart: TimeInterval = 0.22
            let tailDuration: TimeInterval = 0.08
            var tailParams = [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.22),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9)
            ]
            let tail = CHHapticEvent(eventType: .hapticContinuous,
                                     parameters: tailParams,
                                     relativeTime: tailStart,
                                     duration: tailDuration)
            events.append(tail)
            
            // Parameter curve: fade the tail intensity to 0
            let curve = CHHapticParameterCurve(
                parameterID: .hapticIntensityControl,
                controlPoints: [
                    .init(relativeTime: tailStart, value: 0.22),
                    .init(relativeTime: tailStart + tailDuration, value: 0.0)
                ],
                relativeTime: 0
            )
            
            let pattern = try CHHapticPattern(events: events, parameterCurves: [curve])
            let player = try engine.makePlayer(with: pattern)
            try engine.start()
            try player.start(atTime: 0)
        } catch {
            // Fallback if something goes wrong mid-flight
            let g = UINotificationFeedbackGenerator()
            g.notificationOccurred(.success)
        }
    }
    
    /// Dull thud + descending fade (regret)
    func playRegretSkip() {
        guard supportsHaptics, let engine = engine else {
            // Fallback for devices without Core Haptics
            let g = UINotificationFeedbackGenerator()
            g.notificationOccurred(.error) // harsher than .warning
            return
        }
        
        do {
            var events: [CHHapticEvent] = []
            
            // 1. Heavy dull thud
            let thud1 = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.9),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: -0.6) // deep, bassy
                ],
                relativeTime: 0.0
            )
            events.append(thud1)
            
            // 2. Weak aftershock (feels like an "echo" of regret)
            let thud2 = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: -0.8)
                ],
                relativeTime: 0.12
            )
            events.append(thud2)
            
            // 3. Short rumble tail that dies away
            let rumbleDuration: TimeInterval = 0.25
            let rumble = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.25),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: -0.7)
                ],
                relativeTime: 0.18,
                duration: rumbleDuration
            )
            events.append(rumble)
            
            // Fade intensity to zero → "emptiness"
            let fade = CHHapticParameterCurve(
                parameterID: .hapticIntensityControl,
                controlPoints: [
                    .init(relativeTime: 0.18, value: 0.25),
                    .init(relativeTime: 0.18 + rumbleDuration, value: 0.0)
                ],
                relativeTime: 0
            )
            
            // Build and play pattern
            let pattern = try CHHapticPattern(events: events, parameterCurves: [fade])
            let player = try engine.makePlayer(with: pattern)
            try engine.start()
            try player.start(atTime: 0)
            
        } catch {
            let g = UINotificationFeedbackGenerator()
            g.notificationOccurred(.error)
        }
    }
}
