//
//  Archive Functions.swift
//  Habital
//
//  Created by Elias Osarumwense on 10.04.25.
//

import SwiftUI
import CoreData

func toggleArchiveHabit(habit: Habit, context: NSManagedObjectContext) {
    // Toggle the isArchived property
    habit.isArchived.toggle()
    habit.habitList = nil
    
    // Save changes to Core Data
    do {
        try context.save()
        print("Successfully \(habit.isArchived ? "archived" : "unarchived") habit: \(habit.name ?? "Unknown")")
    } catch {
        // Handle any errors during save
        print("Failed to save context after toggling archive status: \(error.localizedDescription)")
        
        // Optionally revert the change if saving fails
        context.rollback()
    }
}

func archiveAllHabits(context: NSManagedObjectContext) {
    let fetchRequest: NSFetchRequest<Habit> = Habit.fetchRequest()

    do {
        let habits = try context.fetch(fetchRequest)
        
        for habit in habits {
            if !habit.isArchived {
                habit.isArchived = true
            }
        }

        try context.save()
        print("Successfully archived all habits")

    } catch {
        print("Failed to fetch or archive habits: \(error.localizedDescription)")
        context.rollback()
    }
}

func unarchiveAllHabits(context: NSManagedObjectContext) {
    let fetchRequest: NSFetchRequest<Habit> = Habit.fetchRequest()

    do {
        let habits = try context.fetch(fetchRequest)
        
        for habit in habits {
            
                habit.isArchived = false
            
        }

        try context.save()
        print("Successfully archived all habits")

    } catch {
        print("Failed to fetch or archive habits: \(error.localizedDescription)")
        context.rollback()
    }
}

func countArchivedHabits(context: NSManagedObjectContext) -> Int {
    let fetchRequest: NSFetchRequest<NSNumber> = NSFetchRequest(entityName: "Habit")
    fetchRequest.resultType = .countResultType
    fetchRequest.predicate = NSPredicate(format: "isArchived == %@", NSNumber(value: true))

    do {
        let countResult = try context.fetch(fetchRequest)
        return countResult.first?.intValue ?? 0
    } catch {
        print("Failed to count archived habits: \(error.localizedDescription)")
        return 0
    }
}
