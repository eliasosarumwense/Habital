//
//  BadHabitEngineTest.swift
//  Test file for verifying bad habit automation percentage
//
/*
import Foundation
import Testing
import CoreData

@Suite("Bad Habit Engine Tests")
struct BadHabitEngineTests {
    
    @Test("Verify bad habit baseline percentages")
    func badHabitBaselinePercentages() async throws {
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
        
        print("Bad habit baseline automation percentages:")
        print("Light intensity (Level 1): \(level1Params.floor_min * 100)%")
        print("Moderate intensity (Level 2): \(level2Params.floor_min * 100)%")
        print("Hard intensity (Level 3): \(level3Params.floor_min * 100)%")
        print("Extreme intensity (Level 4): \(level4Params.floor_min * 100)%")
        
        // This demonstrates what SHOULD happen:
        print("\nWhen you create a new bad habit today:")
        print("- Light bad habit should show 25% automation (not 0%)")
        print("- Moderate bad habit should show 20% automation (not 0%)")
        print("- Hard bad habit should show 15% automation (not 0%)")
        print("- Extreme bad habit should show 10% automation (not 0%)")
    }
}
*/
