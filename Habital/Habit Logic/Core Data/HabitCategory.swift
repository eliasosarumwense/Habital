//
//  HabitCategory.swift
//  Habital
//
//  Created by Elias Osarumwense on 27.08.25.
//

import SwiftUI
import CoreData

extension HabitCategory {
    
    // Preset categories that will be created on first launch
    static let defaultCategories: [(String, String, UIColor)] = [
        ("Health", "heart.fill", UIColor.systemRed),
        ("Fitness", "figure.run", UIColor.systemTeal),
        ("Productivity", "checkmark.circle.fill", UIColor.systemBlue),
        ("Learning", "book.fill", UIColor.systemPurple),
        ("Mindfulness", "brain.head.profile", UIColor.systemYellow),
        ("Social", "person.2.fill", UIColor.systemPink),
        ("Finance", "dollarsign.circle.fill", UIColor.systemGreen),
        ("Creativity", "paintbrush.fill", UIColor.systemIndigo),
        ("Nutrition", "fork.knife", UIColor.systemOrange),
        ("Sleep", "moon.fill", UIColor.systemIndigo),
        ("Work", "briefcase.fill", UIColor.systemMint),
        ("Personal", "star.fill", UIColor.systemPink)
    ]
    
    // Create default categories if they don't exist
    static func createDefaultCategories(in context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<HabitCategory> = HabitCategory.fetchRequest()
        
        do {
            let existingCategories = try context.fetch(fetchRequest)
            
            // Only create if no categories exist
            if existingCategories.isEmpty {
                for (index, categoryInfo) in defaultCategories.enumerated() {
                    let category = HabitCategory(context: context)
                    category.id = UUID()
                    category.name = categoryInfo.0
                    category.icon = categoryInfo.1
                    
                    // Store color as Data, same as HabitList
                    if let colorData = try? NSKeyedArchiver.archivedData(withRootObject: categoryInfo.2, requiringSecureCoding: false) {
                        category.color = colorData
                    }
                    
                    category.order = Int16(index)
                    category.isDefault = true
                    category.createdAt = Date()
                }
                
                try context.save()
                print("✅ Created \(defaultCategories.count) default categories")
            }
        } catch {
            print("❌ Failed to create default categories: \(error)")
        }
    }
    
    // Helper computed property to get SwiftUI Color from stored Data
    var categoryColor: Color {
        if let colorData = color,
           let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
            return Color(uiColor)
        }
        return .blue // Default color
    }
    
    // Helper method to set color from SwiftUI Color
    func setColor(_ swiftUIColor: Color) {
        if let colorData = try? NSKeyedArchiver.archivedData(withRootObject: UIColor(swiftUIColor), requiringSecureCoding: false) {
            self.color = colorData
        }
    }
}
