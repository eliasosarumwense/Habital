//
//  HealthKitManager.swift
//  Habital
//
//  Created by Elias Osarumwense on 20.08.25.
//

//
//  HealthKitManager.swift
//  Habital
//
//  Created by AI Assistant on 20.08.25.
//

import HealthKit
import SwiftUI

@MainActor
final class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    private let store = HKHealthStore()
    private init() {}

    // Check availability
    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    // Map friendly IDs to HKSampleType / HKQuantityType
    enum Metric: String, CaseIterable, Identifiable {
        case sleep, steps, walkingHeartRateAvg, restingHeartRate, mindfulMinutes, activeEnergy, workouts
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .sleep: return "Sleep"
            case .steps: return "Steps"
            case .walkingHeartRateAvg: return "Walking HR"
            case .restingHeartRate: return "Resting HR"
            case .mindfulMinutes: return "Mindful"
            case .activeEnergy: return "Active Energy"
            case .workouts: return "Workouts"
            }
        }
        
        var icon: String {
            switch self {
            case .sleep: return "bed.double.fill"
            case .steps: return "figure.walk"
            case .walkingHeartRateAvg, .restingHeartRate: return "heart.fill"
            case .mindfulMinutes: return "sparkles"
            case .activeEnergy: return "flame.fill"
            case .workouts: return "figure.run"
            }
        }
        
        var unit: String {
            switch self {
            case .sleep: return "h"
            case .steps: return "steps"
            case .walkingHeartRateAvg, .restingHeartRate: return "bpm"
            case .mindfulMinutes: return "min"
            case .activeEnergy: return "kcal"
            case .workouts: return "workouts"
            }
        }
        
        var defaultThreshold: Double {
            switch self {
            case .sleep: return 7.0
            case .steps: return 8000
            case .walkingHeartRateAvg: return 120
            case .restingHeartRate: return 65
            case .mindfulMinutes: return 10
            case .activeEnergy: return 300
            case .workouts: return 1
            }
        }
        
        var defaultComparison: String {
            switch self {
            case .sleep, .steps, .mindfulMinutes, .activeEnergy, .workouts: return ">="
            case .walkingHeartRateAvg, .restingHeartRate: return "<="
            }
        }
    }

    func hkType(for metric: Metric) -> HKSampleType? {
        switch metric {
        case .sleep: return HKObjectType.categoryType(forIdentifier: .sleepAnalysis)
        case .steps: return HKObjectType.quantityType(forIdentifier: .stepCount)
        case .walkingHeartRateAvg: return HKObjectType.quantityType(forIdentifier: .walkingHeartRateAverage)
        case .restingHeartRate: return HKObjectType.quantityType(forIdentifier: .restingHeartRate)
        case .mindfulMinutes: return HKObjectType.categoryType(forIdentifier: .mindfulSession)
        case .activeEnergy: return HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)
        case .workouts: return HKObjectType.workoutType()
        }
    }

    // Request read permission for a single metric
    func requestAuthorization(for metric: Metric) async throws {
        guard isAvailable, let type = hkType(for: metric) else {
            throw HealthKitError.typeNotAvailable
        }
        try await store.requestAuthorization(toShare: [], read: [type])
    }
    
    // Check if we have authorization for a specific metric
    func authorizationStatus(for metric: Metric) -> HKAuthorizationStatus {
        guard let type = hkType(for: metric) else { return .notDetermined }
        return store.authorizationStatus(for: type)
    }

    // Fetch samples for a metric within a date range
    func fetchSamples(for metric: Metric, start: Date, end: Date) async throws -> [HKSample] {
        guard let type = hkType(for: metric) else { return [] }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: samples ?? [])
                }
            }
            store.execute(query)
        }
    }
    
    // Convert samples to daily entries
    func convertToDailyEntries(samples: [HKSample], metric: Metric) -> [DailyEntry] {
        let calendar = Calendar.current
        var dayBuckets: [Date: Double] = [:]
        
        for sample in samples {
            let day = calendar.startOfDay(for: sample.startDate)
            
            switch metric {
            case .sleep:
                if let categorySample = sample as? HKCategorySample,
                   categorySample.value == HKCategoryValueSleepAnalysis.asleep.rawValue {
                    let duration = sample.endDate.timeIntervalSince(sample.startDate) / 3600 // hours
                    dayBuckets[day, default: 0] += duration
                }
                
            case .steps, .activeEnergy:
                if let quantitySample = sample as? HKQuantitySample {
                    let value = quantitySample.quantity.doubleValue(for: hkUnit(for: metric))
                    dayBuckets[day, default: 0] += value
                }
                
            case .walkingHeartRateAvg, .restingHeartRate:
                if let quantitySample = sample as? HKQuantitySample {
                    let value = quantitySample.quantity.doubleValue(for: hkUnit(for: metric))
                    // For heart rate, we want the average, so we'll collect all values and average them
                    dayBuckets[day, default: 0] = (dayBuckets[day, default: 0] + value) / 2
                }
                
            case .mindfulMinutes:
                if let categorySample = sample as? HKCategorySample {
                    let duration = sample.endDate.timeIntervalSince(sample.startDate) / 60 // minutes
                    dayBuckets[day, default: 0] += duration
                }
                
            case .workouts:
                dayBuckets[day, default: 0] += 1
            }
        }
        
        return dayBuckets.map { date, value in
            DailyEntry(date: date, value: value, unit: metric.unit)
        }.sorted { $0.date < $1.date }
    }
    
    private func hkUnit(for metric: Metric) -> HKUnit {
        switch metric {
        case .sleep: return .hour()
        case .steps: return .count()
        case .walkingHeartRateAvg, .restingHeartRate: return HKUnit.count().unitDivided(by: .minute())
        case .mindfulMinutes: return .minute()
        case .activeEnergy: return .kilocalorie()
        case .workouts: return .count()
        }
    }
}

// MARK: - Data Models
struct DailyEntry {
    let date: Date
    let value: Double
    let unit: String
}

// MARK: - Error Types
enum HealthKitError: Error, LocalizedError {
    case typeNotAvailable
    case authorizationDenied
    case dataNotAvailable
    
    var errorDescription: String? {
        switch self {
        case .typeNotAvailable:
            return "Health data type not available"
        case .authorizationDenied:
            return "Health data access denied"
        case .dataNotAvailable:
            return "Health data not available"
        }
    }
}
