//
//  HealthPermissionView.swift
//  Habital
//
//  Created by Elias Osarumwense on 20.08.25.
//

//
//  HealthPermissionView.swift
//  Habital
//
//  Created by AI Assistant on 20.08.25.
//

import SwiftUI
import HealthKit

struct HealthPermissionView: View {
    let metric: HealthKitManager.Metric
    let onResult: (Bool) -> Void
    
    @State private var isRequesting = false
    
    private let healthManager = HealthKitManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            permissionIcon
            permissionText
            allowButton
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    private var permissionIcon: some View {
        ZStack {
            Circle()
                .fill(Color.blue.opacity(0.1))
                .frame(width: 64, height: 64)
            
            Image(systemName: "heart.text.square")
                .font(.system(size: 28))
                .foregroundColor(.blue)
        }
    }
    
    private var permissionText: some View {
        VStack(spacing: 8) {
            Text("Allow \(metric.displayName) Access")
                .font(.headline)
                .multilineTextAlignment(.center)
            
            Text(permissionDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var allowButton: some View {
        Button {
            requestPermission()
        } label: {
            HStack {
                if isRequesting {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "heart.fill")
                }
                
                Text(isRequesting ? "Requesting..." : "Allow in Apple Health")
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .disabled(isRequesting)
    }
    
    private var permissionDescription: String {
        switch metric {
        case .sleep:
            return "Allow access to your sleep data to track your nightly rest and link it to your habits."
        case .steps:
            return "Allow access to your step count to track your daily activity and movement goals."
        case .walkingHeartRateAvg:
            return "Allow access to your walking heart rate to monitor your cardiovascular activity during exercise."
        case .restingHeartRate:
            return "Allow access to your resting heart rate to track your overall cardiovascular health."
        case .mindfulMinutes:
            return "Allow access to your mindfulness sessions to track your meditation and relaxation time."
        case .activeEnergy:
            return "Allow access to your active energy data to monitor calories burned during activities."
        case .workouts:
            return "Allow access to your workout data to track your exercise sessions and fitness activities."
        }
    }
    
    private func requestPermission() {
        guard !isRequesting else { return }
        
        isRequesting = true
        
        Task {
            do {
                // Request authorization
                try await healthManager.requestAuthorization(for: metric)
                
                // IMPORTANT: Add a small delay to allow the system to update authorization status
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                
                // Check the actual authorization status after the request
                let status = healthManager.authorizationStatus(for: metric)
                print("🔐 Raw authorization status for \(metric.displayName): \(status.rawValue)")
                
                // For read permissions, we need to test if we can actually fetch data
                // rather than relying solely on authorization status
                let canReadData = await testDataAccess()
                
                print("📊 Can read \(metric.displayName) data: \(canReadData)")
                
                await MainActor.run {
                    isRequesting = false
                    onResult(canReadData)
                }
            } catch {
                print("❌ Authorization error for \(metric.displayName): \(error)")
                await MainActor.run {
                    isRequesting = false
                    onResult(false)
                }
            }
        }
    }
    
    // Test if we can actually read data from HealthKit
    private func testDataAccess() async -> Bool {
        do {
            // Try to fetch a small sample of recent data
            let endDate = Date()
            let startDate = Calendar.current.date(byAdding: .day, value: -1, to: endDate) ?? endDate
            
            let samples = try await healthManager.fetchSamples(
                for: metric,
                start: startDate,
                end: endDate
            )
            
            // If we can fetch without error, we have access (even if no data)
            print("✅ Successfully fetched \(samples.count) samples for \(metric.displayName)")
            return true
        } catch {
            print("❌ Cannot fetch data for \(metric.displayName): \(error)")
            return false
        }
    }
}
