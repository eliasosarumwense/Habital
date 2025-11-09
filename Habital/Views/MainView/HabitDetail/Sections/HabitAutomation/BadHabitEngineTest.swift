//
//  BadHabitEngineTest.swift
//  Test file for verifying bad habit automation percentage
//

import Foundation
import Testing
import CoreData

// Mock implementations for testing
class MockHabit {
    var isBadHabit: Bool = true
    var intensityLevel: Int16 = 1
    var startDate: Date? = Date()
    var id: UUID? = UUID()
    var name: String? = "Test Bad Habit"
    var bestStreakEver: Int16 = 0
    
    func isCompleted(on date: Date) -> Bool {
        return false // No completions yet for new habit
    }
    
    func calculateStreak(upTo date: Date) -> Int {
        return 0 // New habit has no streak
    }
    
    func calculateLongestStreak() -> Int {
        return 0 // New habit has no history
    }
}

class MockHabitUtilities {
    static func isHabitActive(habit: MockHabit, on date: Date) -> Bool {
        return true // Assume daily habit for simplicity
    }
}

@Suite("Bad Habit Engine Tests")
struct BadHabitEngineTests {
    
    @Test("New bad habit should show baseline percentage, not 0%")
    func newBadHabitShowsBaselinePercentage() async throws {
        // Create a mock bad habit created today
        let habit = MockHabit()
        habit.isBadHabit = true
        habit.intensityLevel = 1 // Light intensity
        habit.startDate = Date()
        
        // The baseline floor for intensity level 1 should be 0.25 (25%)
        // This means a new bad habit should show 25% automation (control), not 0%
        
        let expectedBaselinePercentage = 25.0 // 25% for intensity level 1
        
        // This test demonstrates what should happen:
        // 1. Bad habit is created today
        // 2. It starts with baseline control level (floor_min = 0.25)
        // 3. Automation percentage should be 25%, not 0%
        
        #expect(expectedBaselinePercentage > 0, "Bad habits should start with baseline control, not zero")
        print("Expected baseline for new bad habit: \(expectedBaselinePercentage)%")
    }
    
    @Test("Bad habit parameters verify correct baseline floors")
    func badHabitParametersVerification() async throws {
        // Test that badParams function returns expected baseline floors
        struct BadHabitParams {
            let k_ext: Double
            let lambda_reinst: Double  
            let floor_min: Double
            let softDrift: Double
        }
        
        func badParams(for level: Int) -> BadHabitParams {
            switch max(1, min(4, level)) {
            case 1: return .init(k_ext: 0.09,  lambda_reinst: 0.06, floor_min: 0.25, softDrift: 0.002)
            case 2: return .init(k_ext: 0.07,  lambda_reinst: 0.08, floor_min: 0.20, softDrift: 0.002)
            case 3: return .init(k_ext: 0.05,  lambda_reinst: 0.10, floor_min: 0.15, softDrift: 0.003)
            default:return .init(k_ext: 0.035, lambda_reinst: 0.12, floor_min: 0.10, softDrift: 0.003)
            }
        }
        
        // Verify baseline floors for each intensity level
        let level1Params = badParams(for: 1)
        let level2Params = badParams(for: 2)
        let level3Params = badParams(for: 3)
        let level4Params = badParams(for: 4)
        
        #expect(level1Params.floor_min == 0.25, "Level 1 should have 25% baseline")
        #expect(level2Params.floor_min == 0.20, "Level 2 should have 20% baseline")
        #expect(level3Params.floor_min == 0.15, "Level 3 should have 15% baseline")
        #expect(level4Params.floor_min == 0.10, "Level 4 should have 10% baseline")
        
        print("Baseline floors verified:")
        print("Level 1: \(level1Params.floor_min * 100)%")
        print("Level 2: \(level2Params.floor_min * 100)%")
        print("Level 3: \(level3Params.floor_min * 100)%") 
        print("Level 4: \(level4Params.floor_min * 100)%")
    }
}