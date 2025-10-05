// MARK: - Updated CreateHabitMoreOptionsSection with Category Support

import SwiftUI
import CoreData

struct CreateHabitMoreOptionsSection: View {
    @Binding var showAdvancedOptions: Bool
    @Binding var isBadHabit: Bool
    @Binding var selectedIntensity: HabitIntensity
    @Binding var selectedHabitList: HabitList?
    @Binding var selectedCategory: HabitCategory?  // NEW: Category binding
    @Binding var notificationsEnabled: Bool
    @Binding var notificationTime: Date
    @Binding var notificationNotes: String
    let isTextFieldFocused: FocusState<Bool>.Binding
    
    let selectedColor: Color
    let showHabitListPicker: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var showListPicker = false
    @State private var showCategoryPicker = false  // NEW: Category picker state
    @State private var showNotificationSettings = false
    
    var body: some View {
        VStack(spacing: 0) {
            // More Options Button
            moreOptionsButton
        }
        .sheet(isPresented: $showAdvancedOptions) {
            optionsSheet
        }
    }
    
    // MARK: - Extracted Components
    
    private var moreOptionsButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                showAdvancedOptions = true
            }
            triggerHaptic(.impactLight)
        }) {
            HStack(spacing: 8) {
                Text("More Options")
                    .font(.custom("Lexend-Medium", size: 12))
                    .foregroundColor(.secondary)
                
                Image(systemName: "chevron.up")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.secondary.opacity(0.7))
            }
            .padding(.horizontal, 14)
            .padding(.top, 7)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var optionsSheet: some View {
        NavigationView {
            CompactModernOptionsSheet(
                isBadHabit: $isBadHabit,
                selectedIntensity: $selectedIntensity,
                selectedHabitList: $selectedHabitList,
                selectedCategory: $selectedCategory,  // NEW: Pass category binding
                notificationsEnabled: $notificationsEnabled,
                selectedColor: selectedColor
            )
        }
        .presentationDetents([.height(580)])  // Increased height for category section
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(50)
        .presentationBackground(.clear)
        .background(
            Rectangle().fill(.thickMaterial).ignoresSafeArea()
        )
    }
}

// MARK: - Compact Modern Options Sheet with Category Support
struct CompactModernOptionsSheet: View {
    @Binding var isBadHabit: Bool
    @Binding var selectedIntensity: HabitIntensity
    @Binding var selectedHabitList: HabitList?
    @Binding var selectedCategory: HabitCategory?  // NEW: Category binding
    @Binding var notificationsEnabled: Bool
    
    let selectedColor: Color
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    @State private var showListPicker = false
    @State private var showCategoryPicker = false  // NEW: Category picker state
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 12) {
                        habitTypeSection
                        
                        if !isBadHabit {
                            intensitySection
                        }
                        
                        categorySection  // NEW: Category section
                        listSection
                        notificationsSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    .padding(.bottom, 80)
                }
                
                Spacer()
                
                bottomDoneButton
            }
        }
        
        .sheet(isPresented: $showCategoryPicker) {  // NEW: Category picker sheet
            CategoryPickerView(selectedCategory: $selectedCategory)
                .presentationDetents([.height(480)])
        }
         
        .sheet(isPresented: $showListPicker) {
            HabitListPickerView(selectedHabitList: $selectedHabitList)
        }
    }
    
    // MARK: - NEW Category Section
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CATEGORY")
                .font(.custom("Lexend-Medium", size: 10))
                .foregroundColor(.secondary)
                .kerning(0.5)
            
            Button(action: {
                showCategoryPicker = true
                triggerHaptic(.impactLight)
            }) {
                HStack(spacing: 12) {
                    // Category icon or placeholder
                    Circle()
                        .fill(categoryColor.opacity(0.1))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image(systemName: selectedCategory?.icon ?? "tag.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(categoryColor)
                        )
                    
                    // Category name
                    VStack(alignment: .leading, spacing: 2) {
                        Text(selectedCategory?.name ?? "No Category")
                            .font(.custom("Lexend-Medium", size: 14))
                            .foregroundColor(.primary)
                        
                        Text("Organize your habits")
                            .font(.custom("Lexend-Regular", size: 11))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary.opacity(0.6))
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.tertiarySystemGroupedBackground))
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // Helper computed property for category color
    private var categoryColor: Color {
        selectedCategory?.categoryColor ?? .gray
    }
    
    // MARK: - Sheet Components (existing code)
    
    private var bottomDoneButton: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.secondary.opacity(0.2))
                .frame(height: 0.5)
            
            Button("Done") {
                dismiss()
            }
            .font(.custom("Lexend-Medium", size: 15))
            .foregroundColor(colorScheme == .dark ? .black : .white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? .white : .black)
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGroupedBackground))
        }
    }
    
    // MARK: - Compact Habit Type Toggle
    private var habitTypeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("HABIT TYPE")
                .font(.custom("Lexend-Medium", size: 10))
                .foregroundColor(.secondary)
                .kerning(0.5)
            
            HStack(spacing: 8) {
                CompactHabitTypeCard(
                    title: "Good",
                    subtitle: "Build positive",
                    icon: "checkmark.circle.fill",
                    color: .green,
                    isSelected: !isBadHabit
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isBadHabit = false
                    }
                    triggerHaptic(.impactLight)
                }
                
                CompactHabitTypeCard(
                    title: "Bad",
                    subtitle: "Break negative",
                    icon: "xmark.circle.fill",
                    color: .red,
                    isSelected: isBadHabit
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isBadHabit = true
                    }
                    triggerHaptic(.impactLight)
                }
            }
        }
    }
    
    // MARK: - Intensity Section
    private var intensitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("INTENSITY")
                .font(.custom("Lexend-Medium", size: 10))
                .foregroundColor(.secondary)
                .kerning(0.5)
            
            HStack(spacing: 6) {
                ForEach(HabitIntensity.allCases, id: \.self) { intensity in
                    CompactIntensityButton(
                        intensity: intensity,
                        isSelected: selectedIntensity == intensity,
                        selectedColor: selectedColor
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedIntensity = intensity
                        }
                        triggerHaptic(.impactLight)
                    }
                }
            }
        }
    }
    
    // MARK: - List Section
    private var listSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("HABIT LIST")
                .font(.custom("Lexend-Medium", size: 10))
                .foregroundColor(.secondary)
                .kerning(0.5)
            
            Button(action: {
                showListPicker = true
                triggerHaptic(.impactLight)
            }) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(listColor.opacity(0.1))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image(systemName: selectedHabitList?.icon ?? "tray.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(listColor)
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(selectedHabitList?.name ?? "No List")
                            .font(.custom("Lexend-Medium", size: 14))
                            .foregroundColor(.primary)
                        
                        Text("Group related habits")
                            .font(.custom("Lexend-Regular", size: 11))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary.opacity(0.6))
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.tertiarySystemGroupedBackground))
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private var listColor: Color {
        if let colorData = selectedHabitList?.color,
           let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
            return Color(uiColor)
        }
        return .gray
    }
    
    // MARK: - Notifications Section
    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("NOTIFICATIONS")
                .font(.custom("Lexend-Medium", size: 10))
                .foregroundColor(.secondary)
                .kerning(0.5)
            
            HStack {
                Toggle("", isOn: $notificationsEnabled)
                    .labelsHidden()
                    .tint(selectedColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(notificationsEnabled ? "Enabled" : "Disabled")
                        .font(.custom("Lexend-Medium", size: 14))
                        .foregroundColor(.primary)
                    
                    Text("Get reminders for this habit")
                        .font(.custom("Lexend-Regular", size: 11))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.tertiarySystemGroupedBackground))
            )
        }
    }
}

// MARK: - Supporting Components
struct CompactHabitTypeCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Circle()
                    .fill(isSelected ? color.opacity(0.15) : Color(.tertiarySystemGroupedBackground))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(isSelected ? color : .secondary)
                    )
                
                VStack(spacing: 2) {
                    Text(title)
                        .font(.custom("Lexend-Medium", size: 13))
                        .foregroundColor(isSelected ? .primary : .secondary)
                    
                    Text(subtitle)
                        .font(.custom("Lexend-Regular", size: 10))
                        .foregroundColor(.secondary.opacity(0.8))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? color.opacity(0.06) : Color(.tertiarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(isSelected ? color.opacity(0.2) : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CompactIntensityButton: View {
    let intensity: HabitIntensity
    let isSelected: Bool
    let selectedColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                
                Text(intensity.title)
                    .font(.custom("Lexend-Medium", size: 9))
                    .foregroundColor(isSelected ? .primary : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? intensity.color.opacity(0.06) : Color(.tertiarySystemGroupedBackground))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

