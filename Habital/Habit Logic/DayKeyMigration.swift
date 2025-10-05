//
//  DayKeyMigration.swift
//  Habital
//
//  Created by Elias Osarumwense on 22.08.25.
//

import CoreData

struct DayKeyMigration {
    
    /// One-time migration to backfill dayKey for existing completions
    static func backfillDayKeys(in context: NSManagedObjectContext) async throws {
        let request = NSFetchRequest<Completion>(entityName: "Completion")
        request.predicate = NSPredicate(format: "dayKey == nil")
        request.fetchBatchSize = 50  // Process in batches for memory efficiency
        
        let completions = try context.fetch(request)
        var migrationCount = 0
        
        for completion in completions {
            if let date = completion.date {
                completion.dayKey = DayKeyFormatter.localKey(from: date)
                migrationCount += 1
                
                // Save every 50 records to avoid memory issues
                if migrationCount % 50 == 0 {
                    try context.save()
                    print("Migrated \(migrationCount) completions...")
                }
            }
        }
        
        if context.hasChanges {
            try context.save()
        }
        
        print("✅ Migration complete: \(migrationCount) completions updated with dayKey")
    }
    
    /// Check if migration is needed
    static func isMigrationNeeded(in context: NSManagedObjectContext) -> Bool {
        let request = NSFetchRequest<Completion>(entityName: "Completion")
        request.predicate = NSPredicate(format: "dayKey == nil")
        request.fetchLimit = 1
        
        do {
            let count = try context.count(for: request)
            return count > 0
        } catch {
            print("Error checking migration status: \(error)")
            return false
        }
    }
}

// MARK: - Step 6: Optimized Fetch Requests
// Add these helper methods to your data fetching utilities:

extension Completion {
    
    /// Fetch completions for a specific day using dayKey
    static func fetchForDay(_ dayKey: String, habit: Habit? = nil, context: NSManagedObjectContext) -> [Completion] {
        let request = NSFetchRequest<Completion>(entityName: "Completion")
        
        if let habit = habit {
            request.predicate = NSPredicate(format: "dayKey == %@ AND habit == %@", dayKey, habit)
        } else {
            request.predicate = NSPredicate(format: "dayKey == %@", dayKey)
        }
        
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Completion.loggedAt, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching completions for day \(dayKey): \(error)")
            return []
        }
    }
    
    /// Fetch completions for multiple days
    static func fetchForDays(_ dayKeys: [String], habit: Habit? = nil, context: NSManagedObjectContext) -> [Completion] {
        let request = NSFetchRequest<Completion>(entityName: "Completion")
        
        if let habit = habit {
            request.predicate = NSPredicate(format: "dayKey IN %@ AND habit == %@", dayKeys, habit)
        } else {
            request.predicate = NSPredicate(format: "dayKey IN %@", dayKeys)
        }
        
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Completion.dayKey, ascending: false),
            NSSortDescriptor(keyPath: \Completion.loggedAt, ascending: false)
        ]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching completions for days: \(error)")
            return []
        }
    }
    
    /// Count completions for a specific day
    static func countForDay(_ dayKey: String, habit: Habit? = nil, context: NSManagedObjectContext) -> Int {
        let request = NSFetchRequest<Completion>(entityName: "Completion")
        
        if let habit = habit {
            request.predicate = NSPredicate(format: "dayKey == %@ AND habit == %@ AND completed == YES", dayKey, habit)
        } else {
            request.predicate = NSPredicate(format: "dayKey == %@ AND completed == YES", dayKey)
        }
        
        do {
            return try context.count(for: request)
        } catch {
            print("Error counting completions for day \(dayKey): \(error)")
            return 0
        }
    }
}
