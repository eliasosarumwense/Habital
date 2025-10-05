//
//  HabitListTabView.swift
//  Habital
//
//  Created by Elias Osarumwense on 09.04.25.
//

import SwiftUI

extension UserDefaults {
    // Keys
    private enum Keys {
        static let selectedListIndex = "selectedListIndex"
    }
    
    // Save the selected list index
    static func saveSelectedListIndex(_ index: Int) {
        UserDefaults.standard.set(index, forKey: Keys.selectedListIndex)
    }
    
    // Load the selected list index (default to 0 - "All Habits")
    static func loadSelectedListIndex() -> Int {
        return UserDefaults.standard.integer(forKey: Keys.selectedListIndex)
    }
}

struct HabitListTabView: View {
    let habitLists: FetchedResults<HabitList>
    @Binding var selectedListIndex: Int
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    
    // Add reference to the shared state
    @EnvironmentObject var tabReference: HabitListTabReference
    
    @State private var showCreateList = false
    @State private var showEditList = false
    @State private var showDeleteAlert = false
    @State private var listToEdit: HabitList? = nil
    @State private var listToDelete: HabitList? = nil
    @State private var showHabitSortView = false
    
    @Binding var showArchivedhabits: Bool
    
    @State private var showManageLists = false
    
    @AppStorage("showListColors") private var showListColors = true
    
    // For creating a TabView with a fixed set of options including "All Habits" and "Archived"
    private var allOptions: [TabItem] {
        var items = [TabItem(id: "all", title: "All Habits", color: showListColors ? .primary : .secondary, icon: "tray.full")]
        
        // Create a sorted array of habit lists based on the order property
        let sortedLists = habitLists.sorted {
            $0.order < $1.order
        }
        
        // Add the sorted lists to the items array
        sortedLists.enumerated().forEach { index, list in
            items.append(
                TabItem(
                    id: list.id?.uuidString ?? "list-\(index)",
                    title: list.name ?? "Unnamed List",
                    color: showListColors ? getListColor(list) : .secondary,
                    icon: list.icon ?? "list.bullet",
                    list: list
                )
            )
        }
        
        // Add an archive option at the end
        items.append(
            TabItem(
                id: "archived",
                title: "Archived",
                color: showListColors ? .gray : .secondary,
                icon: "archivebox",
                isArchived: true
            )
        )
        
        return items
    }
    
    var body: some View {
        // Use a VStack with zero spacing to position elements
        ZStack {
            HStack {
                VStack(spacing: 0) {
                    // Main TabView for swiping with enhanced styling
                    TabView(selection: Binding(
                        get: { selectedListIndex },
                        set: { newIndex in
                            // Enhanced smooth spring animation with modern iOS feel
                            withAnimation(.interpolatingSpring(stiffness: 300, damping: 30)) {
                                // Update the selection index
                                selectedListIndex = newIndex
                                
                                // Update archived status immediately for better UI response
                                if newIndex == allOptions.count - 1 {
                                    showArchivedhabits = true
                                } else {
                                    showArchivedhabits = false
                                }
                            }
                            triggerHaptic(.impactSoft)
                        }
                    )) {
                        ForEach(0..<allOptions.count, id: \.self) { index in
                            HStack(spacing: 4) {
                                // Enhanced text with better styling and smoother animation
                                Text("\(allOptions[index].title)")
                                    .customFont("Lexend", .semiBold, 14)
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [
                                                selectedListIndex == index ? .primary : .secondary,
                                                selectedListIndex == index ? .primary.opacity(0.8) : .secondary.opacity(0.6)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                            .tag(index)
                            .scaleEffect(selectedListIndex == index ? 1.02 : 0.98)
                            // Enhanced animation with more natural feel
                            .animation(.interpolatingSpring(stiffness: 350, damping: 25), value: selectedListIndex)
                        }
                    }
                    .offset(y: -9.5)
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(width: min(CGFloat(130 + (10 * allOptions.count)), 160), height: 45)
                    .background(Color.clear)
                    .overlay(
                        // Enhanced bottom overlay with icons instead of dots
                        HStack {
                            // Custom centered page indicator icons with enhanced styling
                            HStack(spacing: 8) {
                                ForEach(0..<allOptions.count, id: \.self) { index in
                                    ZStack {
                                        // Icon container with subtle background for selected state
                                        ZStack {
                                            // Main icon with shadow applied directly to the icon
                                            Group {
                                                if let icon = allOptions[index].icon {
                                                    if icon.first?.isEmoji ?? false {
                                                        Text(icon)
                                                            .font(.system(size: selectedListIndex == index ? 11 : 9))
                                                            .shadow(
                                                                color: selectedListIndex == index ?
                                                                Color.black.opacity(0.2) :
                                                                Color.clear,
                                                                radius: 1,
                                                                x: 0,
                                                                y: 0.5
                                                            )
                                                    } else {
                                                        Image(systemName: selectedListIndex == index && allOptions[index].isArchived ? "archivebox.fill" : icon)
                                                            .font(.system(size: selectedListIndex == index ? 11 : 9, weight: .medium))
                                                            .foregroundColor(
                                                                selectedListIndex == index ?
                                                                (showListColors ? allOptions[index].color : .primary) :
                                                                Color.gray.opacity(0.4)
                                                            )
                                                            .shadow(
                                                                color: selectedListIndex == index ?
                                                                (showListColors ? allOptions[index].color : .primary).opacity(0.4) :
                                                                Color.clear,
                                                                radius: 1,
                                                                x: 0,
                                                                y: 0.5
                                                            )
                                                    }
                                                } else {
                                                    // Fallback icon
                                                    Image(systemName: "list.bullet")
                                                        .font(.system(size: selectedListIndex == index ? 11 : 9, weight: .medium))
                                                        .foregroundColor(
                                                            selectedListIndex == index ?
                                                            (showListColors ? allOptions[index].color : .primary) :
                                                            Color.gray.opacity(0.4)
                                                        )
                                                        .shadow(
                                                            color: selectedListIndex == index ?
                                                            (showListColors ? allOptions[index].color : .primary).opacity(0.4) :
                                                            Color.clear,
                                                            radius: 1,
                                                            x: 0,
                                                            y: 0.5
                                                        )
                                                }
                                            }
                                        }
                                    }
                                    // Enhanced icon scaling with more fluid animation
                                    .scaleEffect(selectedListIndex == index ? 1.45 : 1.0)
                                    .animation(.interpolatingSpring(stiffness: 280, damping: 20), value: selectedListIndex)
                                }
                            }
                            .padding(.horizontal, 8)
                        }
                        .offset(y: -2)
                        .padding(.bottom, 4),
                        alignment: .bottom
                    )
                    .onAppear {
                        // Update the tab reference with current state
                        tabReference.totalTabs = allOptions.count
                    }
                    .onChange(of: selectedListIndex) { _, newValue in
                        // Keep the reference in sync
                        tabReference.selectedIndex = newValue
                        
                        // Toggle showArchivedhabits based on tab selection
                        if newValue == allOptions.count - 1 {
                            // User selected the "Archived" tab (last tab)
                            showArchivedhabits = true
                        } else {
                            // User selected any other tab
                            showArchivedhabits = false
                        }
                    }
                    .onChange(of: allOptions.count) { _, newValue in
                        // Update total tabs when options change
                        tabReference.totalTabs = newValue
                    }
                }
            }
            .frame(width: 245, height: 48)
            .background(liquidGlassTabBackground)
            .sheet(isPresented: $showCreateList) {
                CreateHabitListView()
                    .environment(\.managedObjectContext, viewContext)
            }
            .sheet(isPresented: $showEditList) {
                if let list = listToEdit {
                    EditHabitListView(list: list)
                        .environment(\.managedObjectContext, viewContext)
                }
            }
            .sheet(isPresented: $showHabitSortView) {
                HabitSortView(selectedList: getCurrentList())
                    .environment(\.managedObjectContext, viewContext)
                    .presentationCornerRadius(20)
            }
            .alert("Delete List", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {
                    listToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let list = listToDelete {
                        deleteList(list)
                    }
                    listToDelete = nil
                }
            } message: {
                if let list = listToDelete {
                    Text("Are you sure you want to delete \"\(list.name ?? "this list")\"? Any habits in this list will remain in your app but won't be assigned to any list.")
                } else {
                    Text("Are you sure you want to delete this list?")
                }
            }
            
            // Position buttons on left and right sides of the tab view with enhanced styling
            HStack(spacing: 0) {
                EnhancedHabitSortButton()
                    .padding(.horizontal, 6)
                
                Spacer()
                
                EnhancedHabitListOptionsButton(
                    onSelectList: { index in
                        // Enhanced smooth animation for button-triggered list selection
                        withAnimation(.interpolatingSpring(stiffness: 300, damping: 30)) {
                            selectedListIndex = index
                        }
                    },
                    allLists: allOptions,
                    selectedListIndex: selectedListIndex,
                    showListColors: showListColors,
                    onCreateList: {
                        showCreateList = true
                    },
                    onEditList: {
                        if let currentList = getCurrentList() {
                            listToEdit = currentList
                            showEditList = true
                        }
                    },
                    onDeleteList: {
                        if let currentList = getCurrentList() {
                            listToDelete = currentList
                            showDeleteAlert = true
                        }
                    },
                    onManageLists: {
                        showManageLists = true
                    },
                    currentList: getCurrentList()
                )
                .padding(.horizontal, 6)
            }
            .frame(width: 245)
            .sheet(isPresented: $showManageLists) {
                ManageHabitListsView()
                    .environment(\.managedObjectContext, viewContext)
            }
        }
        // Enhanced animation for list color changes
        .animation(.interpolatingSpring(stiffness: 300, damping: 30), value: showListColors)
    }
    
    // Authentic iOS 26 Liquid Glass background for main tab container (matching SimpleLiquidGlassButton)
    private var liquidGlassTabBackground: some View {
        ZStack {
            // Base ultra-thin material
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
            
            // Simple translucent overlay (same as SimpleLiquidGlassButton)
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(colorScheme == .dark ? 0.1 : 0.25),
                            Color.clear,
                            Color.black.opacity(colorScheme == .dark ? 0.15 : 0.03)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .blendMode(.overlay)
            
        }
    }
    
    // Get the current list for edit/delete operations
    private func getCurrentList() -> HabitList? {
        if selectedListIndex > 0 && selectedListIndex < allOptions.count - 1 { // Exclude "All Habits" and "Archived"
            return habitLists[selectedListIndex - 1]
        }
        return nil
    }
    
    // Delete the specified list
    private func deleteList(_ list: HabitList) {
        // Enhanced animation for list deletion
        withAnimation(.interpolatingSpring(stiffness: 280, damping: 30)) {
            // First, reassign any habits in this list to no list
            if let habits = list.habits as? Set<Habit> {
                for habit in habits {
                    habit.habitList = nil
                }
            }
            
            // Delete the list
            viewContext.delete(list)
            
            // Save changes
            do {
                try viewContext.save()
                
                // Reset selection to "All Habits" if we deleted the current list
                selectedListIndex = 0
            } catch {
                print("Error deleting list: \(error)")
            }
        }
    }
    
    private func getListColor(_ list: HabitList) -> Color {
        if let colorData = list.color,
           let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
            return Color(uiColor)
        }
        return .blue // Default color
    }
    
    // Enhanced Sort button with Liquid Glass effect
    @ViewBuilder
    private func EnhancedHabitSortButton() -> some View {
        @State var isPressed = false
        
        Button(action: {
            showHabitSortView = true
        }) {
            ZStack {
                // Liquid Glass button background (matching SimpleLiquidGlassButton)
                Circle()
                    .fill(.ultraThinMaterial)
                
                // Simple translucent overlay
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.1 : 0.25),
                                Color.clear,
                                Color.black.opacity(colorScheme == .dark ? 0.15 : 0.03)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blendMode(.overlay)
                
                // Real glass edge with bright catches (matching SimpleLiquidGlassButton exactly)
                Circle()
                    .strokeBorder(
                        AngularGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.7 : 0.9),
                                Color.clear,
                                Color.white.opacity(colorScheme == .dark ? 0.3 : 0.6),
                                Color.clear,
                                Color.white.opacity(colorScheme == .dark ? 0.5 : 0.8)
                            ],
                            center: .center,
                            startAngle: .degrees(30),
                            endAngle: .degrees(390)
                        ),
                        lineWidth: 0.7
                    )
                
                // Sort icon
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.primary)
            }
            .frame(width: 36, height: 36)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    // Smoother button press animation
                    withAnimation(.interpolatingSpring(stiffness: 400, damping: 25)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    // Smoother button release animation
                    withAnimation(.interpolatingSpring(stiffness: 400, damping: 25)) {
                        isPressed = false
                    }
                }
        )
    }
}

// Helper for tab items
struct TabItem: Identifiable {
    var id: String
    var title: String
    var color: Color
    var icon: String? // New property to store the list icon
    var list: HabitList? = nil
    var isArchived: Bool = false
}

// Enhanced Options button with Liquid Glass effect
struct EnhancedHabitListOptionsButton: View {
    var onSelectList: (Int) -> Void
    var allLists: [TabItem]
    var selectedListIndex: Int
    var showListColors: Bool
    var onCreateList: () -> Void
    var onEditList: () -> Void
    var onDeleteList: () -> Void
    var onManageLists: () -> Void
    var currentList: HabitList?
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false
    @State private var inputScale: CGFloat = 1.0
    @State private var inputOpacity: Double = 1.0
    
    var body: some View {
        Menu {
            // List selection section (moved from left button)
            ForEach(0..<allLists.count, id: \.self) { index in
                if index != allLists.count - 1 { // Skip the "Archived" option
                    Button(action: {
                        // Enhanced input animation with modern spring
                        withAnimation(.interpolatingSpring(stiffness: 350, damping: 20)) {
                            inputScale = 0.8
                            inputOpacity = 0.5
                        }
                        
                        // Enhanced list selection animation
                        withAnimation(.interpolatingSpring(stiffness: 300, damping: 30).delay(0.1)) {
                            // Call onSelectList with the new index
                            onSelectList(index)
                            
                            // Reset input animation
                            inputScale = 1.0
                            inputOpacity = 1.0
                        }
                    }) {
                        HStack(spacing: 12) {
                            if index == 0 {
                                // "All Habits" tab uses tray.full icon
                                HStack(spacing: 8) {
                                    Image(systemName: "tray.full")
                                        .foregroundColor(showListColors ? allLists[index].color : .secondary)
                                        .font(.system(size: 14, weight: .medium))
                                    
                                    Text(allLists[index].title)
                                        .foregroundColor(showListColors ? allLists[index].color : .primary)
                                        .font(.system(size: 15, weight: .medium))
                                }
                            } else if let icon = allLists[index].icon {
                                // Check if it's an emoji
                                HStack(spacing: 8) {
                                    if icon.first?.isEmoji ?? false {
                                        Text(icon)
                                            .font(.system(size: 14))
                                    } else {
                                        Image(systemName: icon)
                                            .foregroundColor(showListColors ? allLists[index].color : .secondary)
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                    
                                    Text(allLists[index].title)
                                        .foregroundColor(showListColors ? allLists[index].color : .primary)
                                        .font(.system(size: 15, weight: .medium))
                                }
                            } else {
                                // Fallback for any other case
                                Text(allLists[index].title)
                                    .foregroundColor(showListColors ? allLists[index].color : .primary)
                                    .font(.system(size: 15, weight: .medium))
                            }
                            
                            // Show checkmark for the selected list
                            if selectedListIndex == index {
                                Spacer()
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 12, weight: .bold))
                            }
                        }
                    }
                    .disabled(selectedListIndex == index) // Disable the currently selected list
                }
            }
            
            // Divider to separate list selection from management options
            Divider()
            
            // Management options section (original content)
            if currentList != nil {
                Button(action: {
                    onEditList()
                }) {
                    Label("Edit this List", systemImage: "pencil")
                }
                
                Button(role: .destructive, action: {
                    onDeleteList()
                }) {
                    Label("Delete this List", systemImage: "trash")
                }
                
                Divider()
            }
            
            Button(action: {
                onCreateList()
            }) {
                Label("Create List", systemImage: "plus.circle")
            }
            
            Button(action: {
                onManageLists()
            }) {
                Label("Manage Lists", systemImage: "list.bullet.indent")
            }
            
        } label: {
            ZStack {
                // Liquid Glass button background (matching SimpleLiquidGlassButton)
                Circle()
                    .fill(.ultraThinMaterial)
                
                // Simple translucent overlay
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.1 : 0.25),
                                Color.clear,
                                Color.black.opacity(colorScheme == .dark ? 0.15 : 0.03)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blendMode(.overlay)
                
                // Real glass edge with bright catches (matching SimpleLiquidGlassButton exactly)
                Circle()
                    .strokeBorder(
                        AngularGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.7 : 0.9),
                                Color.clear,
                                Color.white.opacity(colorScheme == .dark ? 0.3 : 0.6),
                                Color.clear,
                                Color.white.opacity(colorScheme == .dark ? 0.5 : 0.8)
                            ],
                            center: .center,
                            startAngle: .degrees(30),
                            endAngle: .degrees(390)
                        ),
                        lineWidth: 0.7
                    )
                
                // Enhanced ellipsis icon with input animation
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.primary)
                    .scaleEffect(inputScale)
                    .opacity(inputOpacity)
                    // Enhanced animation timing for input feedback
                    .animation(.interpolatingSpring(stiffness: 350, damping: 20), value: inputScale)
                    .animation(.interpolatingSpring(stiffness: 350, damping: 20), value: inputOpacity)
            }
            .frame(width: 36, height: 36)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    // Smoother button press animation
                    withAnimation(.interpolatingSpring(stiffness: 400, damping: 25)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    // Smoother button release animation
                    withAnimation(.interpolatingSpring(stiffness: 400, damping: 25)) {
                        isPressed = false
                    }
                }
        )
    }
}
