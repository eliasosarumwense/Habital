//
//  HabitListSelectionPopover.swift
//  Habital
//
//  Created by Elias Osarumwense on 04.08.25.
//

import SwiftUI
import CoreData

struct HabitListSelectionPopover: View {
    let availableHabitLists: [HabitListItem]
    let globalState: GlobalTabState
    @Binding var selectedHabitList: HabitListItem?
    @Binding var isExpanded: Bool
    let selectedCoreDataList: HabitList?
    let viewContext: NSManagedObjectContext
    
    @Environment(\.colorScheme) private var colorScheme
    
    // Sheet states managed within the popover
    @State private var showCreateList = false
    @State private var showManageLists = false
    @State private var listToEdit: HabitList?
    
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
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ZStack {
                // Left button - Create List (direct action)
                Button(action: {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    showCreateList = true
                    
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        isExpanded = false
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 48, height: 48)
                        .background(Color.blue)
                        .clipShape(Circle())
                }
                .offset(x: isExpanded ? -80 : 0, y: isExpanded ? -80 : 0)
                .opacity(isExpanded ? 1 : 0)
                .scaleEffect(isExpanded ? 1 : 0.5)
                
                // Middle button - iOS Menu
                Menu {
                    // Available habit lists
                    ForEach(availableHabitLists, id: \.id) { habitList in
                        Button(action: {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                            
                            globalState.selectHabitList(habitList, habitLists: availableHabitLists)
                            selectedHabitList = habitList
                            
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                isExpanded = false
                            }
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
                            selectedHabitList = nil
                            
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                isExpanded = false
                            }
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
                        
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            isExpanded = false
                        }
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
                            
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                isExpanded = false
                            }
                        }) {
                            Label("Edit List", systemImage: "pencil")
                        }
                    }
                    
                    // Manage Lists
                    Button(action: {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        showManageLists = true
                        
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            isExpanded = false
                        }
                    }) {
                        Label("Manage Lists", systemImage: "gear")
                    }
                    
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: selectedHabitList?.icon ?? "tray.full")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                        
                        Text(displayName)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(buttonColor)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                }
                .offset(x: 0, y: isExpanded ? -80 : 0)
                .opacity(isExpanded ? 1 : 0)
                .scaleEffect(isExpanded ? 1 : 0.5)
                
                // Right button - Manage Lists (direct action)
                Button(action: {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    showManageLists = true
                    
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        isExpanded = false
                    }
                }) {
                    Image(systemName: "gear.circle.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 48, height: 48)
                        .background(Color.gray)
                        .clipShape(Circle())
                }
                .offset(x: isExpanded ? 80 : 0, y: isExpanded ? -80 : 0)
                .opacity(isExpanded ? 1 : 0)
                .scaleEffect(isExpanded ? 1 : 0.5)
            }
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isExpanded)
            
            Spacer()
        }
        .padding()
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
/*
// MARK: - Habit List Selection Popover
struct HabitListSelectionPopover: View {
    let availableHabitLists: [HabitListItem]
    let globalState: GlobalTabState
    @Binding var selectedHabitList: HabitListItem?
    @Binding var isExpanded: Bool
    let selectedCoreDataList: HabitList?
    let viewContext: NSManagedObjectContext
    
    @Environment(\.colorScheme) private var colorScheme
    
    // Sheet states managed within the popover
    @State private var showCreateList = false
    @State private var showManageLists = false
    @State private var listToEdit: HabitList?
    
    var body: some View {
        VStack(spacing: 0) {
            // Clean iOS-style header
            popoverHeader
            
            // List content
            popoverListContent
        }
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
    
    @ViewBuilder
    private var popoverHeader: some View {
        VStack(spacing: 0) {
            // Title row with close button
            HStack {
                Text("Lists")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                // iOS-style close button
                Button(action: {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    
                    withAnimation(.smooth(duration: 0.3)) {
                        isExpanded = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.secondary)
                        .symbolRenderingMode(.hierarchical)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            // Action buttons in iOS style
            HStack(spacing: 12) {
                // Create button
                IOSActionButton(
                    title: "Create List",
                    icon: "plus",
                    color: .blue,
                    action: {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        showCreateList = true
                    }
                )
                
                // Edit button (conditionally shown)
                if let selectedList = selectedCoreDataList,
                   globalState.selectedHabitList?.name != "All Habits" &&
                   globalState.selectedHabitList?.name != "Archived" {
                    IOSActionButton(
                        title: "Edit",
                        icon: "pencil",
                        color: .orange,
                        action: {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                            listToEdit = selectedList
                        }
                    )
                }
                
                // Manage button
                IOSActionButton(
                    title: "Manage",
                    icon: "list.bullet",
                    color: .gray,
                    action: {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        showManageLists = true
                    }
                )
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            
            // iOS-style divider
            Divider()
        }
    }
    
    @ViewBuilder
    private var popoverListContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(availableHabitLists, id: \.id) { habitList in
                    IOSHabitListRow(
                        habitList: habitList,
                        isSelected: globalState.selectedHabitList?.id == habitList.id,
                        onTap: {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                            
                            globalState.selectHabitList(habitList, habitLists: availableHabitLists)
                            selectedHabitList = habitList
                            
                            withAnimation(.smooth(duration: 0.4)) {
                                isExpanded = false
                            }
                        }
                    )
                }
                
                // Clear selection
                if globalState.selectedHabitList != nil {
                    IOSClearSelectionRow(
                        onTap: {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                            
                            globalState.clearSelection()
                            selectedHabitList = nil
                            
                            withAnimation(.smooth(duration: 0.4)) {
                                isExpanded = false
                            }
                        }
                    )
                }
            }
            .padding(.vertical, 8)
        }
        .frame(maxHeight: 280)
    }
}

// MARK: - iOS Action Button
struct IOSActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(color)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(color.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - iOS Habit List Row
struct IOSHabitListRow: View {
    let habitList: HabitListItem
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon with background
                ZStack {
                    Circle()
                        .fill(habitList.color.opacity(0.15))
                        .frame(width: 28, height: 28)
                    
                    Image(systemName: habitList.icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(habitList.color)
                }
                
                // List details
                VStack(alignment: .leading, spacing: 1) {
                    Text(habitList.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text("\(habitList.habitCount) habit\(habitList.habitCount == 1 ? "" : "s")")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Selection checkmark
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(habitList.color)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Rectangle()
                    .fill(isSelected ? habitList.color.opacity(0.05) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - iOS Clear Selection Row
struct IOSClearSelectionRow: View {
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Clear icon
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.15))
                        .frame(width: 28, height: 28)
                    
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.red)
                }
                
                Text("Clear Selection")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
*/
