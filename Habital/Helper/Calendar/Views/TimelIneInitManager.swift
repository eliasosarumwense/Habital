//
//  TimelIneInitManager.swift
//  Habital
//
//  Created by Elias Osarumwense on 31.07.25.
//

import SwiftUI
import CoreData

class TimelineStartDateManager: ObservableObject {
    @Published var earliestStartDate: Date = Date()
    
    private let userDefaults = UserDefaults.standard
    private let earliestDateKey = "timeline_earliest_start_date"
    
    init() {
        loadEarliestDate()
    }
    
    /// Load the stored earliest date from UserDefaults
    private func loadEarliestDate() {
        if let storedDate = userDefaults.object(forKey: earliestDateKey) as? Date {
            earliestStartDate = storedDate
        } else {
            // If no stored date, use current date as fallback
            earliestStartDate = Date()
        }
    }
    
    /// Save the earliest date to UserDefaults
    private func saveEarliestDate() {
        userDefaults.set(earliestStartDate, forKey: earliestDateKey)
    }
    
    /// Update the earliest start date by checking all habits
    func refreshEarliestDate(context: NSManagedObjectContext) {
        let request: NSFetchRequest<Habit> = Habit.fetchRequest()
        request.predicate = NSPredicate(format: "isArchived == NO AND startDate != nil")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Habit.startDate, ascending: true)]
        request.fetchLimit = 1
        
        do {
            let habits = try context.fetch(request)
            if let earliestHabit = habits.first, let startDate = earliestHabit.startDate {
                updateEarliestDate(startDate)
            } else {
                // No habits found, use current date
                updateEarliestDate(Date())
            }
        } catch {
            print("Error fetching earliest habit: \(error)")
        }
    }
    
    /// Update the earliest date if the new date is earlier
    func updateEarliestDate(_ newDate: Date) {
        let calendar = Calendar.current
        let newDateStart = calendar.startOfDay(for: newDate)
        let currentEarliestStart = calendar.startOfDay(for: earliestStartDate)
        
        if newDateStart < currentEarliestStart {
            earliestStartDate = newDateStart
            saveEarliestDate()
            print("📅 Updated earliest start date to: \(newDateStart)")
        }
    }
    
    /// Check if a new habit requires updating the earliest date
    func checkNewHabit(startDate: Date) {
        updateEarliestDate(startDate)
    }
    
    /// Get the start of the month for the earliest date
    var earliestMonth: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: earliestStartDate)
        return calendar.date(from: components) ?? earliestStartDate
    }
    
    /// Check if a given date is before the earliest allowed date
    func isDateBeforeEarliest(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let dateMonth = calendar.startOfMonth(for: date)
        return dateMonth < earliestMonth
    }
}

// MARK: - Calendar Extension
extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? date
    }
}
