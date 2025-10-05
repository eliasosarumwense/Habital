//
//  HealthMetricSheet.swift
//  Habital
//
//  Created by Elias Osarumwense on 20.08.25.
//

//
//  HealthMetricSheet.swift
//  Habital
//
//  Created by AI Assistant on 20.08.25.
//

import SwiftUI
import HealthKit

struct HealthMetricSheet: View {
    let metric: HealthKitManager.Metric
    @Environment(\.dismiss) private var dismiss
    
    @State private var days = 14
    @State private var isAuthorized = false
    @State private var isLoading = false
    @State private var entries: [DailyEntry] = []
    @State private var errorMessage: String?
    @State private var showLinkSheet = false
    
    private let healthManager = HealthKitManager.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                headerSection
                
                if !isAuthorized {
                    HealthPermissionView(metric: metric) { didAuthorize in
                        print("🔄 Permission callback received: \(didAuthorize)")
                        
                        // Update state immediately
                        isAuthorized = didAuthorize
                        
                        if didAuthorize {
                            print("✅ Permission granted, loading data...")
                            Task {
                                await loadData()
                            }
                        } else {
                            print("❌ Permission denied or failed")
                            // Optionally show an error message
                            errorMessage = "Health access is required to track this metric"
                        }
                    }
                } else {
                    if isLoading {
                        ProgressView("Loading health data...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let errorMessage = errorMessage {
                        ErrorView(message: errorMessage) {
                            Task { await loadData() }
                        }
                    } else {
                        dataSection
                    }
                }
                
                Spacer()
                
                if isAuthorized && !entries.isEmpty {
                    linkToHabitButton
                }
            }
            .padding()
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .task {
            await checkAuthorizationAndLoad()
        }
        .sheet(isPresented: $showLinkSheet) {
            MetricRuleSheet(metric: metric)
                
                .presentationCornerRadius(20)
        }
    }

    // MARK: - Updated Helper Methods
    private func checkAuthorizationAndLoad() async {
        print("🔍 Checking authorization for \(metric.displayName)...")
        
        let status = healthManager.authorizationStatus(for: metric)
        print("📊 Current status: \(status.rawValue)")
        
        // For read permissions, test if we can actually read data
        let canReadData = await testDataAccess()
        print("📖 Can read data: \(canReadData)")
        
        await MainActor.run {
            isAuthorized = canReadData
        }
        
        if canReadData {
            print("✅ Can read data, loading...")
            await loadData()
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
            return true
        } catch {
            print("❌ Cannot fetch data: \(error)")
            return false
        }
    }

    private func loadData() async {
        print("📥 Starting to load data for \(metric.displayName)...")
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        defer {
            Task { @MainActor in
                isLoading = false
            }
        }
        
        do {
            let endDate = Date()
            let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate) ?? endDate
            
            print("📅 Fetching samples from \(startDate) to \(endDate)")
            
            let samples = try await healthManager.fetchSamples(
                for: metric,
                start: startDate,
                end: endDate
            )
            
            print("📊 Received \(samples.count) samples")
            
            let dailyEntries = healthManager.convertToDailyEntries(samples: samples, metric: metric)
            
            print("📈 Converted to \(dailyEntries.count) daily entries")
            
            await MainActor.run {
                entries = dailyEntries
            }
            
        } catch {
            print("❌ Failed to load health data: \(error)")
            await MainActor.run {
                errorMessage = "Failed to load health data: \(error.localizedDescription)"
            }
        }
    }
    private var headerSection: some View {
        HStack {
            Label(metric.displayName, systemImage: metric.icon)
                .font(.title2)
                .fontWeight(.semibold)
            
            Spacer()
            
            if isAuthorized {
                Picker("Period", selection: $days) {
                    Text("7d").tag(7)
                    Text("14d").tag(14)
                    Text("30d").tag(30)
                }
                .pickerStyle(.segmented)
                .frame(width: 160)
                .onChange(of: days) { _, _ in
                    Task { await loadData() }
                }
            }
        }
    }
    
    private var dataSection: some View {
        VStack(spacing: 16) {
            if !entries.isEmpty {
                chartSection
                summarySection
                recentDataList
            } else {
                noDataView
            }
        }
    }
    
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Last \(days) Days")
                .font(.headline)
            
            MinimalSparkline(entries: entries, metric: metric)
                .frame(height: 100)
                .background(.ultraThinMaterial)
                .cornerRadius(12)
        }
    }
    
    private var summarySection: some View {
        HStack(spacing: 20) {
            summaryCard(title: "Average", value: averageValue, unit: metric.unit)
            summaryCard(title: "Best", value: maxValue, unit: metric.unit)
            summaryCard(title: "Recent", value: mostRecentValue, unit: metric.unit)
        }
    }
    
    private func summaryCard(title: String, value: Double, unit: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(formattedValue(value, unit: unit))
                .font(.title3)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .cornerRadius(10)
    }
    
    private var recentDataList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Data")
                .font(.headline)
            
            LazyVStack(spacing: 4) {
                ForEach(entries.suffix(7).reversed(), id: \.date) { entry in
                    HStack {
                        Text(formatDate(entry.date))
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text(formattedValue(entry.value, unit: entry.unit))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(12)
        }
    }
    
    private var noDataView: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            
            Text("No Data Available")
                .font(.headline)
            
            Text("No \(metric.displayName.lowercased()) data found for the selected period.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var linkToHabitButton: some View {
        Button {
            showLinkSheet = true
        } label: {
            Label("Link to Habit Rule", systemImage: "link")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }
    
    // MARK: - Computed Properties
    private var averageValue: Double {
        guard !entries.isEmpty else { return 0 }
        return entries.map(\.value).reduce(0, +) / Double(entries.count)
    }
    
    private var maxValue: Double {
        entries.map(\.value).max() ?? 0
    }
    
    private var mostRecentValue: Double {
        entries.last?.value ?? 0
    }
    
    
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    private func formattedValue(_ value: Double, unit: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = unit == "h" ? 1 : 0
        
        let numberString = formatter.string(from: NSNumber(value: value)) ?? "\(value)"
        return "\(numberString) \(unit)"
    }
}

// MARK: - Error View
struct ErrorView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.red)
            
            Text("Error")
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Try Again") {
                onRetry()
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
