//
//  HabitOverviewView.swift
//  Habital
//
//  Created by Assistant on 14.08.25.
//  Overview screen with overall habit score section
//

import SwiftUI
import CoreData

struct HabitOverviewView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    
    // Fetch all active habits
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Habit.order, ascending: true)],
        predicate: NSPredicate(format: "isArchived == false"),
        animation: .default
    ) private var habits: FetchedResults<Habit>
    
    private let evaluationDate = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                colorScheme == .dark ? Color.secondary.opacity(0.20) : Color.secondary.opacity(0.24), // More visible top
                colorScheme == .dark ? Color.secondary.opacity(0.12) : Color.secondary.opacity(0.16), // Visible middle
                colorScheme == .dark ? Color.secondary.opacity(0.08) : Color.secondary.opacity(0.10), // Fade
                colorScheme == .dark ? Color(hex: "0A0A0A") : Color(hex: "E8E8FF")
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundGradient
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Overall Habit Score Section
                        OverallHabitScoreSection(habits: Array(habits), date: evaluationDate)
                            .padding(.horizontal, 10)
                        
                        // Habit Insights Section
                        HabitInsightsSection(habits: Array(habits))
                            .padding(.horizontal, 10)
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Overview")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
