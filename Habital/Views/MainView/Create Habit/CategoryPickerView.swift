//
//  CategoryPickerView.swift
//  Habital
//
//  Created by Elias Osarumwense on 27.08.25.
//

import SwiftUI
import CoreData

// MARK: - Minimal Glass Background Modifier
struct MinimalGlassBackground: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    let isSelected: Bool
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Ultra minimal base - almost transparent
                    Circle()
                        .fill(
                            colorScheme == .dark
                                ? Color.white.opacity(0.05)  // Very subtle in dark mode
                                : Color.black.opacity(0.03)  // Very subtle in light mode
                        )
                    
                    // Extremely subtle material overlay
                    Circle()
                        .fill(.ultraThinMaterial)
                        .opacity(0.15)
                    
                    // Minimal glass shimmer effect
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(colorScheme == .dark ? 0.03 : 0.1),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Very subtle border for definition
                    Circle()
                        .strokeBorder(
                            Color.white.opacity(colorScheme == .dark ? 0.08 : 0.15),
                            lineWidth: 0.5
                        )
                }
            )
            
    }
}

extension View {
    func minimalGlassCircle(isSelected: Bool = false) -> some View {
        modifier(MinimalGlassBackground(isSelected: isSelected))
    }
}

// MARK: - Main Category Picker View
struct CategoryPickerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @Binding var selectedCategory: HabitCategory?
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \HabitCategory.order, ascending: true)],
        animation: .default)
    private var categories: FetchedResults<HabitCategory>
    
    @State private var showCreateNewCategory = false
    @State private var newCategoryName = ""
    @State private var newCategoryIcon = "tag.fill"
    @State private var newCategoryColor = Color.blue
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)
    
    var body: some View {
        VStack(spacing: 0) {
            // Minimal Drag Indicator
            Capsule()
                .fill(Color(.systemGray5))
                .frame(width: 32, height: 4)
                .padding(.top, 6)
                .padding(.bottom, 16)
            
            // Title
            Text("Category")
                .font(.custom("Lexend-SemiBold", size: 16))
                .foregroundColor(.primary)
                .padding(.bottom, 20)
            
            // Categories Grid
            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 14) {
                    // No Category Option
                    MinimalCategoryItem(
                        name: "None",
                        icon: "slash.circle",
                        color: Color(.systemGray3),
                        isSelected: selectedCategory == nil
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedCategory = nil
                        }
                        dismiss()
                    }
                    
                    // Existing Categories
                    ForEach(categories) { category in
                        MinimalCategoryItem(
                            name: category.name ?? "",
                            icon: category.icon ?? "tag.fill",
                            color: category.categoryColor,
                            isSelected: selectedCategory?.id == category.id
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedCategory = category
                            }
                            dismiss()
                        }
                    }
                    
                    // Create New Category
                    MinimalAddCategoryItem {
                        showCreateNewCategory = true
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .background(Color(.systemBackground))
        .sheet(isPresented: $showCreateNewCategory) {
            CompactCreateCategorySheet(
                categoryName: $newCategoryName,
                categoryIcon: $newCategoryIcon,
                categoryColor: $newCategoryColor,
                onSave: createNewCategory
            )
            .presentationDetents([.height(380)])
            .presentationDragIndicator(.hidden)
            .presentationCornerRadius(28)
        }
        .onAppear {
            createMockCategoriesIfNeeded()
        }
    }
    
    private func createNewCategory() {
        let category = HabitCategory(context: viewContext)
        category.id = UUID()
        category.name = newCategoryName.isEmpty ? "New" : newCategoryName
        category.icon = newCategoryIcon
        
        if let colorData = try? NSKeyedArchiver.archivedData(
            withRootObject: UIColor(newCategoryColor),
            requiringSecureCoding: false
        ) {
            category.color = colorData
        }
        
        category.order = Int16(categories.count)
        category.isDefault = false
        category.createdAt = Date()
        
        do {
            try viewContext.save()
            selectedCategory = category
            showCreateNewCategory = false
            dismiss()
        } catch {
            print("Failed to create category: \(error)")
        }
        
        resetFields()
    }
    
    private func resetFields() {
        newCategoryName = ""
        newCategoryIcon = "tag.fill"
        newCategoryColor = .blue
    }
    
    private func createMockCategoriesIfNeeded() {
        guard categories.isEmpty else { return }
        
        let mockCategories = [
            ("Health", "heart.fill", Color.red),
            ("Work", "briefcase.fill", Color.blue),
            ("Learn", "book.fill", Color.orange),
            ("Fitness", "figure.run", Color.green),
            ("Mind", "brain.head.profile", Color.purple),
            ("Social", "person.2.fill", Color.pink),
            ("Create", "sparkles", Color.yellow),
            ("Home", "house.fill", Color.brown)
        ]
        
        for (index, (name, icon, color)) in mockCategories.enumerated() {
            let category = HabitCategory(context: viewContext)
            category.id = UUID()
            category.name = name
            category.icon = icon
            
            if let colorData = try? NSKeyedArchiver.archivedData(
                withRootObject: UIColor(color),
                requiringSecureCoding: false
            ) {
                category.color = colorData
            }
            
            category.order = Int16(index)
            category.isDefault = true
            category.createdAt = Date()
        }
        
        try? viewContext.save()
    }
}

// MARK: - Minimal Category Item
struct MinimalCategoryItem: View {
    let name: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    // Minimal glass background
                    Circle()
                        .frame(width: 48, height: 48)
                        .minimalGlassCircle(isSelected: isSelected)
                        .scaleEffect(isPressed ? 0.9 : 1.0)
                    
                    // Icon with better visibility
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: isSelected ? .semibold : .medium))
                        .foregroundColor(isSelected ? color : color.opacity(0.8))
                        .scaleEffect(isSelected ? 1.1 : 1.0)
                    
                    // Selection ring
                    if isSelected {
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        color,
                                        color.opacity(0.6)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                            .frame(width: 52, height: 52)
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
                
                Text(name)
                    .font(.custom("Lexend-Regular", size: 11))
                    .foregroundColor(isSelected ? color : .secondary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity,
                           pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Minimal Add Category Item
struct MinimalAddCategoryItem: View {
    let action: () -> Void
    @State private var isPressed = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .frame(width: 48, height: 48)
                        .minimalGlassCircle()
                        .scaleEffect(isPressed ? 0.9 : 1.0)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
                
                Text("New")
                    .font(.custom("Lexend-Regular", size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity,
                           pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Compact Create Category Sheet
struct CompactCreateCategorySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @Binding var categoryName: String
    @Binding var categoryIcon: String
    @Binding var categoryColor: Color
    
    let onSave: () -> Void
    
    @FocusState private var isNameFieldFocused: Bool
    
    private let colorOptions: [Color] = [
        .red, .orange, .yellow, .green, .teal, .blue,
        .indigo, .purple, .pink, .brown, .mint, .cyan
    ]
    
    private let iconGroups = [
        [
            "heart.fill", "star.fill", "bolt.fill", "flame.fill"
        ],
        [
            "book.fill", "brain.head.profile", "lightbulb.fill", "sparkles"
        ],
        [
            "figure.run", "dumbbell.fill", "sportscourt.fill", "bicycle"
        ],
        [
            "briefcase.fill", "chart.line.uptrend.xyaxis", "laptopcomputer", "doc.fill"
        ],
        [
            "house.fill", "bed.double.fill", "sofa.fill", "fork.knife"
        ],
        [
            "person.2.fill", "message.fill", "phone.fill", "envelope.fill"
        ]
    ]
    
    @State private var selectedIconRow = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Minimal Drag Indicator
            Capsule()
                .fill(Color(.systemGray5))
                .frame(width: 32, height: 4)
                .padding(.top, 6)
                .padding(.bottom, 16)
            
            // Title
            Text("New Category")
                .font(.custom("Lexend-SemiBold", size: 16))
                .foregroundColor(.primary)
                .padding(.bottom, 20)
            
            VStack(spacing: 20) {
                // Name Field with Icon Preview
                HStack(spacing: 12) {
                    // Icon Preview with minimal glass
                    ZStack {
                        Circle()
                            .frame(width: 42, height: 42)
                            .minimalGlassCircle()
                        
                        Image(systemName: categoryIcon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(categoryColor)
                    }
                    
                    // Name Field
                    TextField("Name", text: $categoryName)
                        .font(.custom("Lexend-Regular", size: 15))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.systemGray6))
                        )
                        .focused($isNameFieldFocused)
                }
                .padding(.horizontal, 20)
                
                // Icon Selection - Horizontal Scroll
                VStack(alignment: .leading, spacing: 8) {
                    Text("ICON")
                        .font(.custom("Lexend-Medium", size: 10))
                        .foregroundColor(.secondary)
                        .kerning(0.5)
                        .padding(.horizontal, 20)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(iconGroups[selectedIconRow], id: \.self) { icon in
                                MinimalIconButton(
                                    icon: icon,
                                    color: categoryColor,
                                    isSelected: categoryIcon == icon
                                ) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        categoryIcon = icon
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Icon Row Indicator
                    HStack(spacing: 4) {
                        ForEach(0..<iconGroups.count, id: \.self) { index in
                            Circle()
                                .fill(index == selectedIconRow ? categoryColor : Color(.systemGray5))
                                .frame(width: 4, height: 4)
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedIconRow = index
                                        categoryIcon = iconGroups[index][0]
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                // Color Grid
                VStack(alignment: .leading, spacing: 8) {
                    Text("COLOR")
                        .font(.custom("Lexend-Medium", size: 10))
                        .foregroundColor(.secondary)
                        .kerning(0.5)
                        .padding(.horizontal, 20)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 6), spacing: 10) {
                        ForEach(colorOptions, id: \.self) { color in
                            CompactColorButton(
                                color: color,
                                isSelected: categoryColor == color
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    categoryColor = color
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            
            Spacer()
            
            // Action Buttons
            HStack(spacing: 12) {
                Button(action: { dismiss() }) {
                    Text("Cancel")
                        .font(.custom("Lexend-Medium", size: 14))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                }
                
                Button(action: onSave) {
                    Text("Create")
                        .font(.custom("Lexend-Medium", size: 14))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(categoryName.isEmpty ? Color(.systemGray4) : categoryColor)
                        )
                }
                .disabled(categoryName.isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .background(Color(.systemBackground))
        .onAppear {
            isNameFieldFocused = true
            categoryIcon = iconGroups[0][0]
        }
    }
}

// MARK: - Minimal Icon Button
struct MinimalIconButton: View {
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .frame(width: 38, height: 38)
                    .minimalGlassCircle(isSelected: isSelected)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? color : color.opacity(0.7))
                
                if isSelected {
                    Circle()
                        .strokeBorder(
                            color.opacity(0.8),
                            lineWidth: 1.5
                        )
                        .frame(width: 40, height: 40)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Compact Color Button
struct CompactColorButton: View {
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Circle()
                .fill(color)
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .opacity(isSelected ? 1 : 0)
                )
                .scaleEffect(isSelected ? 1.1 : 1.0)
                
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Category Badge for HabitHeaderView
struct CategoryBadge: View {
    let category: HabitCategory
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: category.icon ?? "tag.fill")
                .font(.system(size: 10, weight: .medium))
            
            Text(category.name ?? "")
                .font(.custom("Lexend-Medium", size: 11))
        }
        .foregroundColor(category.categoryColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(category.categoryColor.opacity(0.12))
                .overlay(
                    Capsule()
                        .strokeBorder(category.categoryColor.opacity(0.2), lineWidth: 1)
                )
        )
    }
}
