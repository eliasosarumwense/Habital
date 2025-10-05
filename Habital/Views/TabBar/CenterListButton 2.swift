//
//  CenterListButton.swift
//  Habital
//
//  Created by Elias Osarumwense on 04.08.25.
//

import SwiftUI
import CoreData

// MARK: - Center List Button Component with Menu
struct CenterListButton: View {
    @Binding var isExpanded: Bool
    let selectedHabitList: HabitListItem?
    let availableHabitLists: [HabitListItem]
    let globalState: GlobalTabState
    let selectedCoreDataList: HabitList?
    let viewContext: NSManagedObjectContext
    let onTap: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    // Sheet states
    @State private var showCreateList = false
    @State private var showManageLists = false
    @State private var listToEdit: HabitList?
    @State private var isRotated = false
    
    // Helper to get display name for selected list
    private var displayName: String {
        selectedHabitList?.name ?? "All Habits"
    }
    
    // Helper to get the correct color based on selected list
    private var buttonColor: Color {
        if let selectedList = selectedHabitList {
            if selectedList.name == "All Habits" {
                return .secondary
            } else if selectedList.name == "Archived" {
                return .gray
            } else {
                return selectedList.color
            }
        } else {
            return .secondary
        }
    }
    
    // Helper to get the correct icon
    private var buttonIcon: String {
        if let selectedList = selectedHabitList {
            return selectedList.icon
        } else {
            return "tray.full" // Default icon for "All Habits"
        }
    }
    
    var body: some View {
        ZStack {
            // Background Menu button (invisible but functional)
            Menu {
                // Available habit lists
                ForEach(availableHabitLists, id: \.id) { habitList in
                    Button(action: {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        
                        globalState.selectHabitList(habitList, habitLists: availableHabitLists)
                    }) {
                        Label(habitList.name, systemImage: habitList.icon)
                    }
                }
                
                // Clear selection option
                if globalState.selectedHabitList != nil {
                    Divider()
                    
                    Button(action: {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        
                        globalState.clearSelection()
                    }) {
                        Label("Clear Selection", systemImage: "xmark.circle")
                    }
                }
                
                Divider()
                
                // Create List
                Button(action: {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    showCreateList = true
                }) {
                    Label("Create List", systemImage: "plus")
                }
                
                // Edit List (for editable lists)
                if let selectedList = selectedCoreDataList,
                   globalState.selectedHabitList?.name != "All Habits" &&
                   globalState.selectedHabitList?.name != "Archived" {
                    
                    Button(action: {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        listToEdit = selectedList
                    }) {
                        Label("Edit List", systemImage: "pencil")
                    }
                }
                
                // Manage Lists
                Button(action: {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    showManageLists = true
                }) {
                    Label("Manage Lists", systemImage: "gear")
                }
                
            } label: {
                // Invisible button with same size
                Color.clear
                    .frame(width: 56, height: 56)
            }
            
            // Foreground dummy button (visible with animation)
            Button(action: {
                // This button doesn't do anything, just provides visual feedback
            }) {
                Image(systemName: isRotated ? "xmark" : buttonIcon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(colorScheme == .dark ? .black : .white)
                    .frame(width: 56, height: 56)
                    .glassCircleBackground(
                        borderWidth: 1.2,
                        backgroundColor: buttonColor
                    )
                    .rotationEffect(.degrees(isRotated ? 90 : 0))
            }
            .allowsHitTesting(false) // This makes touches pass through to the Menu button
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    isRotated = pressing
                }
            }, perform: {})
        }
        .animation(.smooth(duration: 0.3), value: selectedHabitList?.id)
        .frame(width: 80)
        .sheet(isPresented: $showCreateList) {
            NavigationView {
                CreateHabitListView()
                    .environment(\.managedObjectContext, viewContext)
            }
            .presentationCornerRadius(24)
        }
        .sheet(isPresented: $showManageLists) {
            NavigationView {
                ManageHabitListsView()
                    .environment(\.managedObjectContext, viewContext)
            }
            .presentationCornerRadius(24)
        }
        .sheet(item: $listToEdit) { list in
            NavigationView {
                EditHabitListView(list: list)
                    .environment(\.managedObjectContext, viewContext)
            }
            .presentationCornerRadius(24)
        }
    }
}
