//
//  ManageHabitListsView.swift
//  Habital
//
//  Created by Elias Osarumwense on 10.04.25.
//

import SwiftUI
import CoreData

struct ManageHabitListsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    // Fetch all habit lists sorted by order
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \HabitList.order, ascending: true)],
        animation: .default)
    private var habitLists: FetchedResults<HabitList>
    
    // State for edit mode and selection
    @State private var editMode: EditMode = .inactive
    @State private var selectedLists = Set<UUID>()
    @State private var showDeleteAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient to match other views
                LinearGradient(
                    gradient: Gradient(colors: [
                        colorScheme == .dark ? Color(hex: "1A1A1A") : Color(hex: "F8F8FF"),
                        colorScheme == .dark ? Color(hex: "202020") : Color(hex: "FFFFFF")
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack {
                    // Instructions banner when in edit mode
                    if editMode == .active {
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "arrow.up.arrow.down")
                                Text("Drag to reorder lists")
                                Spacer()
                            }
                            
                            HStack {
                                Image(systemName: "hand.tap")
                                Text("Tap to select multiple lists")
                                Spacer()
                            }
                            
                            HStack {
                                Image(systemName: "trash")
                                Text("Use trash icon to delete selected lists")
                                Spacer()
                            }
                        }
                        .font(.system(size: 14))
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .padding(.top)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    List {
                        ForEach(habitLists) { list in
                            HStack {
                                // Selection indicator when in edit mode
                                if editMode == .active {
                                    Image(systemName: selectedLists.contains(list.id!) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(selectedLists.contains(list.id!) ? .accentColor : .gray)
                                        .animation(.spring(), value: selectedLists)
                                }
                                
                                // Icon in circle with list color
                                ListIconCircleView(icon: list.icon, color: getListColor(list))
                                
                                Text(list.name ?? "Unnamed List")
                                    .font(.system(size: 16, weight: .medium))
                                    .padding(.leading, 4) // Add some padding after the icon
                                
                                Spacer()
                                
                                // Show habit count
                                HStack(spacing: 5) {
                                    let count = getHabitCount(list)
                                    Text("\(count)")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.secondary)
                                    
                                    Image(systemName: "list.bullet")
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(6)
                                
                                // Reorder handle when in edit mode
                                if editMode == .active {
                                    Image(systemName: "line.3.horizontal")
                                        .foregroundColor(.gray)
                                        .padding(.leading, 5)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if editMode == .active {
                                    if let id = list.id {
                                        withAnimation {
                                            if selectedLists.contains(id) {
                                                selectedLists.remove(id)
                                            } else {
                                                selectedLists.insert(id)
                                            }
                                        }
                                    }
                                }
                            }
                            .background(
                                editMode == .active && list.id != nil && selectedLists.contains(list.id!)
                                ? Color.accentColor.opacity(0.15)
                                : Color.clear
                            )
                            .listRowBackground(
                                editMode == .active && list.id != nil && selectedLists.contains(list.id!)
                                ? Color.accentColor.opacity(0.07)
                                : Color(.systemBackground)
                            )
                        }
                        .onDelete(perform: deleteLists)
                        .onMove(perform: moveLists)
                    }
                    .listStyle(InsetGroupedListStyle())
                    .environment(\.editMode, $editMode)
                    
                    // Bulk delete button visible in edit mode at bottom of screen
                    if editMode == .active && !selectedLists.isEmpty {
                        Button(action: {
                            showDeleteAlert = true
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete Selected (\(selectedLists.count))")
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding()
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .animation(.spring(), value: editMode)
            }
            .navigationTitle("Manage Lists")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        
                            dismiss()
                        
                    }
                    .font(.customFont("Lexend", .semiBold, 16))
                    .foregroundColor(.primary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                        .font(.customFont("Lexend", .semiBold, 16))
                        .foregroundColor(.primary)
                        .onChange(of: editMode) { newValue in
                            if newValue == .inactive {
                                // Clear selection when exiting edit mode
                                selectedLists.removeAll()
                            }
                        }
                }
            }
            .alert("Delete Selected Lists", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {
                    // Do nothing
                }
                Button("Delete", role: .destructive) {
                    deleteSelectedLists()
                }
            } message: {
                Text("Are you sure you want to delete \(selectedLists.count) list\(selectedLists.count == 1 ? "" : "s")? Any habits in these lists will remain in your app but won't be assigned to any list.")
            }
        }
    }
    
    // Delete lists by IndexSet (for swipe-to-delete)
    private func deleteLists(at offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let list = habitLists[index]
                removeHabitsFromList(list)
                viewContext.delete(list)
            }
            
            saveContext()
        }
    }
    
    // Move lists (reordering)
    private func moveLists(from source: IndexSet, to destination: Int) {
        // Create a mutable array from fetched results
        var lists = habitLists.map { $0 }
        
        // Perform the move operation
        lists.move(fromOffsets: source, toOffset: destination)
        
        // Update order values
        for (index, list) in lists.enumerated() {
            list.order = Int16(index)
        }
        
        saveContext()
    }
    
    // Delete multiple selected lists
    private func deleteSelectedLists() {
        withAnimation {
            for list in habitLists {
                if let id = list.id, selectedLists.contains(id) {
                    removeHabitsFromList(list)
                    viewContext.delete(list)
                }
            }
            
            selectedLists.removeAll()
            saveContext()
        }
    }
    
    // Helper function to remove habits from a list before deletion
    private func removeHabitsFromList(_ list: HabitList) {
        if let habits = list.habits as? Set<Habit> {
            for habit in habits {
                habit.habitList = nil
            }
        }
    }
    
    // Save context and handle errors
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
    
    // Get list color (same function as in other views)
    private func getListColor(_ list: HabitList) -> Color {
        if let colorData = list.color,
           let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
            return Color(uiColor)
        }
        return .blue // Default color
    }
    
    // Get habit count for a list
    private func getHabitCount(_ list: HabitList) -> Int {
        if let habits = list.habits {
            return habits.count
        }
        return 0
    }
}
