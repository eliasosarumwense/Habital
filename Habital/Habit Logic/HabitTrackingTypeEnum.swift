//
//  HabitTrackingTypeEnum.swift
//  Habital
//
//  Created by Elias Osarumwense on 24.08.25.
//

import Foundation

enum HabitTrackingType: String, CaseIterable {
    case repetitions = "repetitions"
    case duration = "duration"
    case quantity = "quantity"
    
    var title: String {
        switch self {
        case .repetitions:
            return "Times"
        case .duration:
            return "Duration"
        case .quantity:
            return "Amount"
        }
    }
    
    var icon: String {
        switch self {
        case .repetitions:
            return "repeat"
        case .duration:
            return "clock"
        case .quantity:
            return "number"
        }
    }
    
    var description: String {
        switch self {
        case .repetitions:
            return "Complete a certain number of times"
        case .duration:
            return "Track time spent on habit"
        case .quantity:
            return "Track specific amount or quantity"
        }
    }
}

// Common quantity units
enum QuantityUnit: String, CaseIterable {
    case pages = "pages"
    case minutes = "minutes"
    case hours = "hours"
    case glasses = "glasses"
    case steps = "steps"
    case words = "words"
    case items = "items"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .pages: return "Pages"
        case .minutes: return "Minutes"
        case .hours: return "Hours"
        case .glasses: return "Glasses"
        case .steps: return "Steps"
        case .words: return "Words"
        case .items: return "Items"
        case .custom: return "Custom"
        }
    }
}

typealias TrackingType = HabitTrackingType
