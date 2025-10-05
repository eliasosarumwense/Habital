//
//  HapticFeedback.swift
//  Habital
//
//  Created by Elias Osarumwense on 15.04.25.
//

import UIKit

enum HapticFeedbackType {
    case impactLight
    case impactMedium
    case impactHeavy
    case impactSoft
    case impactRigid
    case notificationSuccess
    case notificationWarning
    case notificationError
    case selection
}

func triggerHaptic(_ type: HapticFeedbackType) {
    switch type {
    case .impactLight:
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
        
    case .impactMedium:
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
        
    case .impactHeavy:
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()
        generator.impactOccurred()
        
    case .impactSoft:
        if #available(iOS 13.0, *) {
            let generator = UIImpactFeedbackGenerator(style: .soft)
            generator.prepare()
            generator.impactOccurred()
        }
        
    case .impactRigid:
        if #available(iOS 13.0, *) {
            let generator = UIImpactFeedbackGenerator(style: .rigid)
            generator.prepare()
            generator.impactOccurred()
        }
        
    case .notificationSuccess:
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
        
    case .notificationWarning:
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)
        
    case .notificationError:
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.error)
        
    case .selection:
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
}
