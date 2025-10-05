//
//  CompletionHelper.swift
//  Habital
//
//  Created by Elias Osarumwense on 22.08.25.
//
import Foundation
import CoreData

struct CompletionRepo {
    let ctx: NSManagedObjectContext

    func completedCount(habit: Habit, dayKey: String) -> Int {
        let r = NSFetchRequest<NSNumber>(entityName: "Completion")
        r.resultType = .countResultType
        r.predicate = NSPredicate(
            format: "habit == %@ AND dayKey == %@ AND completed == YES",
            habit, dayKey
        )
        return (try? ctx.count(for: r)) ?? 0
    }

    func existsCompleted(habit: Habit, dayKey: String) -> Bool {
        let r = NSFetchRequest<NSNumber>(entityName: "Completion")
        r.resultType = .countResultType
        r.fetchLimit = 1
        r.predicate = NSPredicate(
            format: "habit == %@ AND dayKey == %@ AND completed == YES",
            habit, dayKey
        )
        return ((try? ctx.count(for: r)) ?? 0) > 0
    }
}
