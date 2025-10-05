//
//  Untitled.swift
//  Habital
//
//  Created by Elias Osarumwense on 08.04.25.
//

import SwiftUI
import CoreData

struct HabitSortView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    // Fetched habits from Core Data
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Habit.order, ascending: true)],
        animation: .default)
    private var habits: FetchedResults<Habit>
    
    // State for tracking selected habits
    @State private var selectedHabits: Set<UUID> = []
    @State private var isEditMode: EditMode = .active // Start in edit mode
    @State private var showDeleteAlert = false
    @State private var showSaveConfirmation = false
    @State private var animateConfirmation = false
    @State private var listRefreshID = UUID()
    @State private var pulseDelete = false
    @State private var showInstructions = false
    
    // Current list directly passed from parent view
    let selectedList: HabitList?
    
    // Color palette selection
    @AppStorage("accentColorIndex") private var accentColorIndex: Int = 0
    
    // Initialize with the selected list
    init(selectedList: HabitList?) {
        self.selectedList = selectedList
    }
    
    // Use the app's accent color or list color
    private var accentColor: Color {
        if let list = selectedList,
           let colorData = list.color,
           let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
            return Color(uiColor)
        }
        return ColorPalette.color(at: accentColorIndex)
    }
    
    // Computed property for ordered habits (all habits sorted)
    private var orderedHabits: [Habit] {
        return habits.filter { !$0.isArchived }.sorted { $0.order < $1.order }
    }
    
    // Check if a habit is part of the currently selected list
    private func isHabitInCurrentList(_ habit: Habit) -> Bool {
        if selectedList == nil {
            return true
        } else {
            return habit.habitList == selectedList
        }
    }
    
    private var instructionsPopup: some View {
        ZStack {
            if showInstructions {
                // Background overlay
                Color.clear
                    .background(.ultraThinMaterial)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            showInstructions = false
                        }
                    }
                
                // Alert-style popup
                VStack(spacing: 0) {
                    // Header section
                    VStack(spacing: 12) {
                        // Icon
                        ZStack {
                            Circle()
                                .fill(accentColor.opacity(0.15))
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: "hand.draw")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(accentColor)
                        }
                        
                        // Title
                        Text("How to Organize")
                            .font(.customFont("Lexend", .bold, 18))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                        
                        // Instructions
                        VStack(spacing: 8) {
                            InstructionRow(icon: "hand.drag", text: "Drag habits to reorder them", accentColor: accentColor)
                            InstructionRow(icon: "hand.tap", text: "Tap habits to select multiple", accentColor: accentColor)
                            InstructionRow(icon: "trash", text: "Swipe left to delete a habit", accentColor: accentColor)
                            InstructionRow(icon: "plus.circle", text: "Tap + to add habits to this list", accentColor: accentColor)
                        }
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 24)
                    
                    // Separator
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 0.5)
                    
                    // Close button
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            showInstructions = false
                        }
                    }) {
                        Text("Got it")
                            .font(.customFont("Lexend", .semiBold, 16))
                            .foregroundColor(accentColor)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
                .frame(maxWidth: 320)
                .shadow(color: Color.black.opacity(0.3), radius: 30, x: 0, y: 15)
                .scaleEffect(showInstructions ? 1 : 0.8)
                .opacity(showInstructions ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: showInstructions)
            }
        }
    }
    
    
    private var habitsInCurrentList: [Habit] {
        return orderedHabits.filter { isHabitInCurrentList($0) }
    }
    
    private var habitsNotInCurrentList: [Habit] {
        return orderedHabits.filter { !isHabitInCurrentList($0) }
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // Modern gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    colorScheme == .dark ? Color(hex: "0F0F0F") : Color(hex: "FAFBFF"),
                    colorScheme == .dark ? Color(hex: "1A1A1A") : Color(hex: "F0F2FF")
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Add spacing at the top to account for the navbar height
                Color.clear.frame(height: 55)
                
                // Content area
                if orderedHabits.isEmpty {
                    modernEmptyState
                } else {
                    modernHabitsList
                }
                
                // Modern bottom action area
                modernBottomActions
            }
            
            // Custom navbar - placed at the top of the ZStack to stay fixed
            UltraThinMaterialNavBar(
                title: "Organize",
                leftIcon: "xmark",
                rightIcon: "info.circle",
                leftAction: {
                    dismiss()
                },
                rightAction: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        showInstructions.toggle()
                    }
                },
                titleColor: .primary,
                leftIconColor: .red,
                rightIconColor: accentColor
            )
            .zIndex(1)
        }
        .alert(isPresented: $showDeleteAlert) {
            Alert(
                title: Text("Delete Selected Habits"),
                message: Text("Are you sure you want to delete \(selectedHabits.count) habit\(selectedHabits.count != 1 ? "s" : "")? This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    deleteSelectedHabits()
                },
                secondaryButton: .cancel()
            )
        }
        .overlay(
            // Modern save confirmation overlay
            modernSaveConfirmation
        )
        .overlay(
            // Instructions popup overlay
            instructionsPopup
        )
    }
    
    // MARK: - Modern UI Components
    
    private var modernEmptyState: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                // Animated background circles
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(accentColor.opacity(0.1 - Double(index) * 0.03))
                        .frame(width: 120 + CGFloat(index * 30), height: 120 + CGFloat(index * 30))
                        .scaleEffect(1.0 + sin(Date().timeIntervalSince1970 + Double(index)) * 0.1)
                        .animation(.easeInOut(duration: 2 + Double(index)).repeatForever(), value: UUID())
                }
                /*
                Image(systemName: selectedList == nil ? "sparkles" : "list.bullet.rectangle.portrait")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [accentColor, accentColor.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                 */
            }
            
            VStack(spacing: 8) {
                Text(selectedList == nil ? "No Habits to Organize" : "No Habits in \(selectedList?.name ?? "List")")
                    .font(.customFont("Lexend", .semiBold, 20))
                    .foregroundColor(.primary)
                
                Text(selectedList == nil ?
                     "Create some habits first to organize them" :
                        "Add habits to this list to organize them")
                .font(.customFont("Lexend", .regular, 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 32)
    }
    
    private var modernHabitsList: some View {
        VStack(spacing: 0) {
            // Modern section header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedList?.name ?? "All Habits")
                        .font(.customFont("Lexend", .bold, 22))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [accentColor, accentColor.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("\(habitsInCurrentList.count) habit\(habitsInCurrentList.count != 1 ? "s" : "")")
                        .font(.customFont("Lexend", .medium, 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Modern select all button
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        if selectedHabits.count == habitsInCurrentList.count {
                            selectedHabits.removeAll()
                        } else {
                            selectedHabits = Set(habitsInCurrentList.compactMap { $0.id })
                        }
                    }
                    
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: selectedHabits.count == habitsInCurrentList.count ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 14, weight: .medium))
                        
                        Text(selectedHabits.count == habitsInCurrentList.count ? "Deselect" : "Select All")
                            .font(.customFont("Lexend", .medium, 13))
                    }
                    .foregroundColor(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.clear)
                            .overlay(
                                Capsule()
                                    .stroke(.primary.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .disabled(habitsInCurrentList.isEmpty)
                .scaleEffect(habitsInCurrentList.isEmpty ? 0.95 : 1.0)
                .opacity(habitsInCurrentList.isEmpty ? 0.6 : 1.0)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            
            // Modern List with native drag and drop using BlurredScrollView
            BlurredScrollView(
                blurHeight: 4
                
            ) {
                VStack(spacing: 0) {
                    List {
                        // Section for habits in the current list
                        Section {
                            ForEach(habitsInCurrentList) { habit in
                                ModernHabitSortRow(
                                    habit: habit,
                                    isSelected: selectedHabits.contains(habit.id ?? UUID()),
                                    accentColor: accentColor,
                                    isDragging: false, // Not used with native List drag
                                    toggleSelection: {
                                        toggleSelection(for: habit)
                                    },
                                    isInCurrentList: true,
                                    currentList: selectedList
                                )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    toggleSelection(for: habit)
                                }
                                .listRowBackground(
                                    selectedHabits.contains(habit.id ?? UUID()) ?
                                    accentColor.opacity(0.05) :
                                        Color.clear
                                )
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 2, leading: 8, bottom: 2, trailing: 8))
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    // Custom delete button
                                    Button(role: .destructive) {
                                        withAnimation {
                                            if let index = habitsInCurrentList.firstIndex(of: habit) {
                                                deleteItems(at: IndexSet([index]))
                                            }
                                        }
                                    } label: {
                                        VStack(spacing: 4) {
                                            Image(systemName: "trash.fill")
                                                .font(.system(size: 16, weight: .semibold))
                                            Text("Delete")
                                                .font(.caption2)
                                        }
                                    }
                                    .tint(.red)
                                }
                            }
                            .onMove(perform: moveItems)
                        }
                        
                        // Other habits section
                        if !habitsNotInCurrentList.isEmpty && selectedList != nil {
                            Section(header:
                                        HStack {
                                Text("Other Habits")
                                    .font(.customFont("Lexend", .medium, 14))
                                    .foregroundColor(.secondary)
                                    .textCase(nil)
                                
                                Spacer()
                                
                                Text("Tap + to add to list")
                                    .font(.customFont("Lexend", .regular, 12))
                                    .foregroundStyle(.tertiary)
                            }
                                .padding(.vertical, 4)
                            ) {
                                ForEach(habitsNotInCurrentList) { habit in
                                    ModernHabitSortRow(
                                        habit: habit,
                                        isSelected: false,
                                        accentColor: accentColor,
                                        isDragging: false,
                                        toggleSelection: { /* can't select */ },
                                        isInCurrentList: false,
                                        currentList: selectedList
                                    )
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 2, leading: 8, bottom: 2, trailing: 8))
                                    .onChange(of: habit.habitList) { _, _ in
                                        listRefreshID = UUID()
                                    }
                                }
                            }
                        }
                    }
                    .id(listRefreshID)
                    .listStyle(.insetGrouped)
                    .environment(\.editMode, $isEditMode)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .frame(minHeight: 600) // Ensure minimum height for proper scrolling
                }
            }
        }
    }
    
    private var modernSeparator: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Other Habits")
                    .font(.customFont("Lexend", .medium, 14))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Tap + to add to list")
                    .font(.customFont("Lexend", .regular, 12))
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.clear, accentColor.opacity(0.3), Color.clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)
            }
        }
        .padding(.vertical, 16)
    }
    
    private var modernBottomActions: some View {
        VStack(spacing: 0) {
            // Glass morphism background
            Rectangle()
                .fill(.ultraThinMaterial)
                .frame(height: 1)
                .opacity(0.5)
            
            VStack(spacing: 12) {
                // Delete button (only shown when items are selected)
                if !selectedHabits.isEmpty {
                    Button(action: {
                        withAnimation(.easeOut(duration: 0.2)) {
                            pulseDelete = true
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            pulseDelete = false
                            showDeleteAlert = true
                        }
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 16, weight: .medium))
                            
                            Text("Delete \(selectedHabits.count) Habit\(selectedHabits.count != 1 ? "s" : "")")
                                .font(.customFont("Lexend", .semiBold, 16))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.red, Color.red.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                )
                                .shadow(
                                    color: Color.red.opacity(0.3),
                                    radius: pulseDelete ? 12 : 8,
                                    x: 0,
                                    y: pulseDelete ? 6 : 4
                                )
                        )
                        .scaleEffect(pulseDelete ? 0.98 : 1.0)
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .bottom).combined(with: .opacity)
                    ))
                }
                
                // Save button
                Button(action: {
                    saveOrder()
                    dismiss()
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16, weight: .medium))
                        
                        Text("Save Organization")
                            .font(.customFont("Lexend", .semiBold, 16))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [accentColor, accentColor.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(accentColor.opacity(0.3), lineWidth: 1)
                            )
                            .shadow(
                                color: accentColor.opacity(0.3),
                                radius: 8,
                                x: 0,
                                y: 4
                            )
                    )
                }
                .disabled(orderedHabits.isEmpty)
                .opacity(orderedHabits.isEmpty ? 0.6 : 1.0)
                .scaleEffect(orderedHabits.isEmpty ? 0.98 : 1.0)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.1), Color.clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
            )
        }
    }
    
    private var modernSaveConfirmation: some View {
        ZStack {
            if showSaveConfirmation {
                VStack {
                    Spacer()
                    
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(accentColor.opacity(0.2))
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(accentColor)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Changes Saved!")
                                .font(.customFont("Lexend", .semiBold, 16))
                                .foregroundColor(.primary)
                            
                            Text("Your habit organization has been updated")
                                .font(.customFont("Lexend", .regular, 12))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(accentColor.opacity(0.3), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
                    )
                    .padding(.horizontal, 20)
                    .scaleEffect(animateConfirmation ? 1 : 0.5)
                    .opacity(animateConfirmation ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: animateConfirmation)
                    
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - Functions
    
    private func toggleSelection(for habit: Habit) {
        if !isHabitInCurrentList(habit) {
            return
        }
        
        if let id = habit.id {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                if selectedHabits.contains(id) {
                    selectedHabits.remove(id)
                } else {
                    selectedHabits.insert(id)
                }
            }
            
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }
    
    private func moveItems(from source: IndexSet, to destination: Int) {
        // Get habits in the current list
        var mutableFilteredHabits = habitsInCurrentList
        
        // Store the original orders before moving
        let originalOrders = mutableFilteredHabits.map { $0.order }
        
        // Perform the move in our local array
        mutableFilteredHabits.move(fromOffsets: source, toOffset: destination)
        
        // Reassign the original orders in the new arrangement
        // This preserves their relative positioning among all habits
        for (index, habit) in mutableFilteredHabits.enumerated() {
            habit.order = originalOrders[index]
        }
        
        // Save the context
        do {
            try viewContext.save()
            
            print("✓ Successfully reordered habits, total list habits: \(habitsInCurrentList.count)")
            for (i, h) in mutableFilteredHabits.enumerated() {
                print("  Habit #\(i): \(h.name ?? "Unnamed") (order: \(h.order))")
            }
        } catch {
            print("❌ Failed to save after reordering: \(error)")
        }
    }
    
    private func deleteItems(at offsets: IndexSet) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            // Filter to only delete habits that are in the current list
            let habitsToDelete = offsets.compactMap { index -> Habit? in
                guard index < habitsInCurrentList.count else { return nil }
                let habit = habitsInCurrentList[index]
                return isHabitInCurrentList(habit) ? habit : nil
            }
            
            // Delete the filtered habits
            for habit in habitsToDelete {
                viewContext.delete(habit)
                // Remove from selection if it was selected
                if let id = habit.id {
                    selectedHabits.remove(id)
                }
            }
            
            saveContext()
            
            // Renumber the remaining habits to maintain consistent ordering
            reorderRemainingHabits()
            
            // Provide delete haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }
    
    private func deleteSelectedHabits() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            let habitsToDelete = selectedHabits.compactMap { id -> Habit? in
                if let habit = orderedHabits.first(where: { $0.id == id }), isHabitInCurrentList(habit) {
                    return habit
                }
                return nil
            }
            
            for habit in habitsToDelete {
                viewContext.delete(habit)
            }
            
            saveContext()
            selectedHabits.removeAll()
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            reorderRemainingHabits()
        }
    }
    
    private func reorderRemainingHabits() {
        if selectedList == nil {
            let remainingHabits = habits.filter { !$0.isArchived }.sorted { $0.order < $1.order }
            for (index, habit) in remainingHabits.enumerated() {
                habit.order = Int16(index)
            }
        } else {
            let remainingHabits = habits.filter {
                !$0.isArchived && $0.habitList == selectedList
            }.sorted { $0.order < $1.order }
            
            for (index, habit) in remainingHabits.enumerated() {
                habit.order = Int16(index)
            }
        }
        
        saveContext()
    }
    
    private func saveOrder() {
        if orderedHabits.isEmpty {
            return
        }
        
        showSaveConfirmation = true
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            animateConfirmation = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeOut(duration: 0.3)) {
                showSaveConfirmation = false
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                animateConfirmation = false
            }
        }
        
        saveContext()
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            print("Error saving context: \(nsError), \(nsError.userInfo)")
        }
    }
}

// MARK: - Modern Habit Row Component

struct ModernHabitSortRow: View {
    let habit: Habit
    let isSelected: Bool
    let accentColor: Color
    let isDragging: Bool
    let toggleSelection: () -> Void
    let isInCurrentList: Bool
    let currentList: HabitList?
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var showAddToListAlert = false
    @State private var isPressed = false
    
    private var habitColor: Color {
        if let colorData = habit.color,
           let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
            return Color(uiColor)
        }
        return accentColor
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Use HabitIconView instead of custom icon implementation
            HabitIconView(
                iconName: habit.icon,
                isActive: isInCurrentList,
                habitColor: habitColor,
                streak: 0, // No streak in sort view
                showStreaks: false,
                useModernBadges: false,
                isFutureDate: false,
                isBadHabit: habit.isBadHabit,
                intensityLevel: habit.intensityLevel
            )
            .scaleEffect(0.9) // Slightly smaller for sort view
            
            // Habit info
            VStack(alignment: .leading, spacing: 6) {
                Text(habit.name ?? "Unnamed Habit")
                    .font(.customFont("Lexend", .semiBold, 16))
                    .foregroundColor(isInCurrentList ? .primary : .secondary)
                    .lineLimit(1)
                
                if !isInCurrentList {
                    HStack(spacing: 6) {
                        if let habitList = habit.habitList, let listName = habitList.name {
                            let listIcon = habitList.icon ?? "list.bullet"
                            
                            if isEmoji(listIcon) {
                                Text(listIcon)
                                    .font(.caption2)
                            } else {
                                Image(systemName: listIcon)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text("In: \(listName)")
                                .font(.customFont("Lexend", .medium, 12))
                                .foregroundColor(.secondary)
                        } else {
                            HStack(spacing: 4) {
                                Image(systemName: "minus.circle")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                                
                                Text("No list assigned")
                                    .font(.customFont("Lexend", .medium, 12))
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
            }
            
            Spacer()
            
            // Selection indicator overlay (positioned above the action area)
            ZStack {
                // Action area
                if isInCurrentList {
                    
                } else if currentList != nil {
                    // Add to list button
                    Button(action: {
                        showAddToListAlert = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(accentColor.opacity(0.15))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle()
                                        .stroke(accentColor.opacity(0.3), lineWidth: 1)
                                )
                            
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(accentColor)
                        }
                    }
                    .scaleEffect(isPressed ? 0.95 : 1.0)
                    .animation(.spring(response: 0.3), value: isPressed)
                    .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                        isPressed = pressing
                    }, perform: {})
                    .alert(isPresented: $showAddToListAlert) {
                        Alert(
                            title: Text("Add to \(currentList?.name ?? "List")"),
                            message: Text("Move '\(habit.name ?? "this habit")' to \(currentList?.name ?? "this list")?"),
                            primaryButton: .default(Text("Add")) {
                                addHabitToCurrentList()
                            },
                            secondaryButton: .cancel()
                        )
                    }
                }
                
                // Selection indicator (only for habits in current list)
                if isSelected && isInCurrentList {
                    ZStack {
                        Circle()
                            .fill(accentColor)
                            .frame(width: 20, height: 20)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                            )
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .offset(x: 10, y: -10)
                    .scaleEffect(isSelected ? 1.0 : 0.1)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    isSelected ?
                    LinearGradient(
                        colors: [
                            accentColor.opacity(0.15),
                            accentColor.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ) :
                    LinearGradient(
                        colors: [
                            colorScheme == .dark ? Color(UIColor.systemGray6) : Color.white,
                            colorScheme == .dark ? Color(UIColor.systemGray6).opacity(0.8) : Color.white.opacity(0.9)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            isSelected ?
                            LinearGradient(
                                colors: [accentColor.opacity(0.4), accentColor.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [Color.white.opacity(0.3), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: isSelected ? accentColor.opacity(0.2) : Color.black.opacity(colorScheme == .dark ? 0.3 : 0.05),
                    radius: isSelected ? 8 : 4,
                    x: 0,
                    y: isSelected ? 4 : 2
                )
                .opacity(isInCurrentList ? 1.0 : 0.7)
        )
        .scaleEffect(isDragging ? 1.02 : (isPressed ? 0.98 : 1.0))
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDragging)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .contentShape(Rectangle())
        .onTapGesture {
            if isInCurrentList {
                toggleSelection()
            }
        }
    }
    
    // Function to add habit to current list
    private func addHabitToCurrentList() {
        guard let list = currentList else { return }
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            habit.habitList = list
        }
        
        do {
            try viewContext.save()
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        } catch {
            print("Error adding habit to list: \(error)")
        }
    }
    
    // Helper to check if string is emoji
    private func isEmoji(_ text: String) -> Bool {
        if text.isEmpty { return false }
        
        if text.count == 1, let firstChar = text.first {
            return firstChar.isEmoji
        }
        
        for scalar in text.unicodeScalars {
            if scalar.properties.isEmoji {
                return true
            }
        }
        
        return false
    }
}

// MARK: - Helper Views

// Helper view for instruction rows
struct InstructionRow: View {
    let icon: String
    let text: String
    let accentColor: Color
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.1))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(accentColor)
            }
            
            Text(text)
                .font(.customFont("Lexend", .medium, 14))
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
    }
}
