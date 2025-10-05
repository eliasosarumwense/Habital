//
//  Persistence.swift
//  Habital
//
//  Created by Elias Osarumwense on 29.03.25.
//

import CoreData
import SwiftUI

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Create the habit
            let habit = Habit(context: viewContext)
            
            // Set basic properties
            habit.name = "Daily Meditation"
            habit.habitDescription = "15 minutes of mindfulness practice"
            habit.icon = "brain.head.profile"
            habit.isBadHabit = false
            
            // Set the color (orange)
            let colorData = try? NSKeyedArchiver.archivedData(withRootObject: UIColor.systemOrange, requiringSecureCoding: false)
            habit.color = colorData
            
            // Set dates (start date in the past)
            let calendar = Calendar.current
            habit.startDate = calendar.date(byAdding: .day, value: -30, to: Date())
            
            // Create follow-up repeat pattern
            let repeatPattern = RepeatPattern(context: viewContext)
            repeatPattern.followUp = true
            repeatPattern.effectiveFrom = habit.startDate
            repeatPattern.repeatsPerDay = 1
            
            // Set up daily pattern
            let dailyGoal = DailyGoal(context: viewContext)
            dailyGoal.everyDay = false
            dailyGoal.daysInterval = 2 // Every 2 days
            repeatPattern.dailyGoal = dailyGoal
            
            // Connect habit and pattern
            habit.addToRepeatPattern(repeatPattern)
            
            // Add some completions for streak history
            for day in [-2, -4, -6, -8, -10] {
                if let date = calendar.date(byAdding: .day, value: day, to: Date()) {
                    let completion = Completion(context: viewContext)
                    completion.date = date
                    completion.completed = true
                    habit.addToCompletion(completion)
                }
            }
         
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
            container = NSPersistentCloudKitContainer(name: "Habital")
            
            if inMemory {
                container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
            }
            
            // WICHTIG: Füge diese Zeilen für automatische Migration hinzu
            container.persistentStoreDescriptions.forEach { storeDescription in
                storeDescription.setOption(true as NSNumber,
                                         forKey: NSMigratePersistentStoresAutomaticallyOption)
                storeDescription.setOption(true as NSNumber,
                                         forKey: NSInferMappingModelAutomaticallyOption)
            }
            
            container.loadPersistentStores(completionHandler: { (storeDescription, error) in
                if let error = error as NSError? {
                    /*
                     Typical reasons for an error here include:
                     * The parent directory does not exist, cannot be created, or disallows writing.
                     * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                     * The device is out of space.
                     * The store could not be migrated to the current model version.
                     Check the error message to determine what the actual problem was.
                     */
                    fatalError("Unresolved error \(error), \(error.userInfo)")
                }
            })
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            container.viewContext.automaticallyMergesChangesFromParent = true
        }
}
enum PreviewPersistence {
    static let container: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Habital") // <-- must match your .xcdatamodeld name
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        description.shouldAddStoreAsynchronously = false
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load in-memory store: \(error)")
            }
        }
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return container
    }()
}
