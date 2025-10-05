//
//  HabitDetailPreferences.swift
//  Habital
//
//  Created by Elias Osarumwense on 01.05.25.
//

import SwiftUI

enum HabitDetailComponent: String, CaseIterable, Identifiable {
    case streaks = "Streaks"
    case xpIndicator = "XP Indicator"
    case consistencyChart = "Consistency Chart"
    case schedule = "Schedule"
    case calendar = "Calendar"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .streaks: return "flame"
        case .xpIndicator: return "star"
        case .consistencyChart: return "chart.line.uptrend.xyaxis"
        case .schedule: return "calendar.badge.clock"
        case .calendar: return "calendar"
        }
    }
}

// User preferences storage for component visibility and order
class HabitDetailPreferences: ObservableObject {
    // Default values with consistency chart visible, XP indicator hidden
    @AppStorage("habitDetailVisibleComponents") private var storedVisibleComponents: String = "streaks,consistencyChart,schedule,calendar"
    @AppStorage("habitDetailComponentOrder") private var storedComponentOrder: String = "streaks,consistencyChart,schedule,calendar,xpIndicator"
    
    @Published var visibleComponents: [HabitDetailComponent] = []
    @Published var componentOrder: [HabitDetailComponent] = []
    
    init() {
        loadPreferences()
    }
    
    func loadPreferences() {
        // Load visible components
        let visibleComponentStrings = storedVisibleComponents.split(separator: ",").map(String.init)
        visibleComponents = visibleComponentStrings.compactMap { componentString in
            HabitDetailComponent.allCases.first { $0.rawValue.lowercased() == componentString.lowercased() }
        }
        
        // Load component order
        let orderComponentStrings = storedComponentOrder.split(separator: ",").map(String.init)
        componentOrder = orderComponentStrings.compactMap { componentString in
            HabitDetailComponent.allCases.first { $0.rawValue.lowercased() == componentString.lowercased() }
        }
        
        // Ensure all components are accounted for in order
        let missingComponents = HabitDetailComponent.allCases.filter { !componentOrder.contains($0) }
        componentOrder.append(contentsOf: missingComponents)
    }
    
    func savePreferences() {
        // Save visible components
        storedVisibleComponents = visibleComponents.map { $0.rawValue.lowercased() }.joined(separator: ",")
        
        // Save component order
        storedComponentOrder = componentOrder.map { $0.rawValue.lowercased() }.joined(separator: ",")
    }
    
    func toggleVisibility(for component: HabitDetailComponent) {
        if visibleComponents.contains(component) {
            visibleComponents.removeAll { $0 == component }
        } else {
            visibleComponents.append(component)
        }
        savePreferences()
    }
    
    func moveComponent(from source: IndexSet, to destination: Int) {
        componentOrder.move(fromOffsets: source, toOffset: destination)
        savePreferences()
    }
    
    func isVisible(_ component: HabitDetailComponent) -> Bool {
        return visibleComponents.contains(component)
    }
    
    func resetToDefaults() {
        // Reset to default visibility - XP indicator is hidden by default
        visibleComponents = [.streaks, .consistencyChart, .schedule, .calendar]
        
        // Reset to default order - streaks, chart, schedule, calendar, xp indicator
        componentOrder = [.streaks, .consistencyChart, .schedule, .calendar, .xpIndicator]
        savePreferences()
    }
}

// Configuration sheet for habit detail view
struct HabitDetailConfigSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var preferences: HabitDetailPreferences
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Visible Components")) {
                    ForEach(HabitDetailComponent.allCases) { component in
                        Toggle(isOn: Binding(
                            get: { preferences.isVisible(component) },
                            set: { _ in preferences.toggleVisibility(for: component) }
                        )) {
                            HStack {
                                Image(systemName: component.icon)
                                    .foregroundColor(.primary)
                                    .frame(width: 24, height: 24)
                                
                                Text(component.rawValue)
                                    .font(.system(size: 16, weight: .medium))
                            }
                        }
                    }
                }
                
                Section(header: Text("Arrangement (Drag to Reorder)")) {
                    ForEach(preferences.componentOrder, id: \.self) { component in
                        HStack {
                            Image(systemName: component.icon)
                                .foregroundColor(.primary)
                                .frame(width: 24, height: 24)
                            
                            Text(component.rawValue)
                                .font(.system(size: 16, weight: .medium))
                            
                            Spacer()
                            
                            // Visual indicator of visibility
                            if !preferences.isVisible(component) {
                                Text("Hidden")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule()
                                            .fill(Color.gray.opacity(0.2))
                                    )
                            }
                            
                            Image(systemName: "line.3.horizontal")
                                .foregroundColor(.gray.opacity(0.7))
                                .font(.system(size: 14))
                        }
                        .padding(.vertical, 4)
                    }
                    .onMove(perform: preferences.moveComponent)
                }
                
                Section {
                    Button(action: preferences.resetToDefaults) {
                        HStack {
                            Spacer()
                            Text("Reset to Defaults")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Customize View")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
