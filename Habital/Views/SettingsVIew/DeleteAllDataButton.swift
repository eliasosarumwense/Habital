//
//  DeleteAllDataButton.swift
//  Habital
//
//  Created by Elias Osarumwense on 14.04.25.
//

import SwiftUI
import CoreData

struct DeleteAllDataButton: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var showingAlert = false
    
    var body: some View {
        Button(role: .destructive) {
            showingAlert = true
        } label: {
            Label("Delete All Data", systemImage: "trash")
        }
        .alert("Delete All Data", isPresented: $showingAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteAllData()
            }
        } message: {
            Text("This will permanently delete all your habits, lists, and completions. This action cannot be undone.")
        }
    }
    
    private func deleteAllData() {
        let entities = [
            "Completion",
            "DailyGoal",
            "Habit",
            "HabitList",
            "MonthlyGoal",
            "RepeatPattern",
            "WeeklyGoal"
        ]
        
        for entity in entities {
            deleteAllObjects(entityName: entity)
        }
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            print("Unresolved error \(nsError), \(nsError.userInfo)")
            // Handle the error appropriately in your app
        }
    }
    
    private func deleteAllObjects(entityName: String) {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entityName)
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try viewContext.execute(batchDeleteRequest)
        } catch {
            let nsError = error as NSError
            print("Error deleting \(entityName): \(nsError), \(nsError.userInfo)")
        }
    }
}
