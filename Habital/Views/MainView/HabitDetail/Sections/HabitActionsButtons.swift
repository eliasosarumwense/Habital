//
//  HabitActionsButtons.swift
//  Habital
//
//  Created by Elias Osarumwense on 16.05.25.
//

import SwiftUI
import CoreData

struct HabitActionButtons: View {
    let habit: Habit
    @Binding var isPresented: Bool
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    @State private var showDeleteAlert = false
    @State private var showEditSheet = false
    
    // Extract habit color for consistent UI
    private var habitColor: Color {
        if let colorData = habit.color,
           let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
            return Color(uiColor)
        }
        return .blue // Default color
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Edit button
            Button(action: {
                showEditSheet = true
            }) {
                Text("Edit")
                    .customFont("Lexend", .semiBold, 15)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(habitColor.opacity(0.3))
                    )
            }
            
            HStack(spacing: 8) {
                // Archive button
                Button(action: {
                    toggleArchiveHabit(habit: habit, context: viewContext)
                }) {
                    Text(habit.isArchived ? "Unarchive" : "Archive")
                        .customFont("Lexend", .semiBold, 15)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(colorScheme == .dark ? Color(UIColor.systemGray6) : Color.white)
                                )
                        )
                }
                
                // Delete button
                Button(action: {
                    showDeleteAlert = true
                }) {
                    Text("Delete")
                        .customFont("Lexend", .semiBold, 15)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(colorScheme == .dark ? Color(UIColor.systemGray6) : Color.white)
                                )
                        )
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            (colorScheme == .dark ? Color(hex: "121212") : Color(UIColor.systemBackground))
                .edgesIgnoringSafeArea(.bottom)
        )
        .alert(isPresented: $showDeleteAlert) {
            Alert(
                title: Text("Delete Habit"),
                message: Text("Are you sure you want to delete \"\(habit.name ?? "this habit")\"?"),
                primaryButton: .destructive(Text("Delete")) {
                    deleteHabit(habit: habit)
                    isPresented = false
                },
                secondaryButton: .cancel()
            )
        }
        .sheet(isPresented: $showEditSheet) {
            HabitUtilities.clearHabitActivityCache()
        } content: {
            EditHabitView(habit: habit)
                .environment(\.managedObjectContext, viewContext)
        }
    }
    
    private func toggleArchiveHabit(habit: Habit, context: NSManagedObjectContext) {
        habit.isArchived.toggle()
        do {
            try context.save()
            HabitUtilities.clearHabitActivityCache()
        } catch {
            print("Error toggling archive status: \(error)")
        }
    }
    
    private func deleteHabit(habit: Habit) {
        viewContext.delete(habit)
        do {
            try viewContext.save()
        } catch {
            print("Error deleting habit: \(error)")
        }
    }
}
