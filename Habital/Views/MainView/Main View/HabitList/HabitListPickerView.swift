//
//  HabitListPickerView.swift
//  Habital
//
//  Created by Elias Osarumwense on 09.04.25.
//

import SwiftUI
import CoreData

struct HabitListPickerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var selectedHabitList: HabitList?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var showCreateNewList = false
    
    // Define a primary accent color to match styling
    @State private var accentColor: Color = .blue
    
    // Create a separate FetchRequest like in the HabitListTabView
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \HabitList.name, ascending: true)],
        animation: .default)
    private var habitLists: FetchedResults<HabitList>
    
    // Add a fetch request for all habits to count unassigned habits
    @FetchRequest(
        entity: Habit.entity(),
        sortDescriptors: [],
        predicate: NSPredicate(format: "habitList == nil"),
        animation: .default)
    private var unassignedHabits: FetchedResults<Habit>
    
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
                
                VStack(spacing: 12) {
                    // None option card
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Select a List")
                            .font(.subheadline)
                            .padding(.horizontal)
                            .padding(.top, 8)
                        
                        Button(action: {
                            // Clear selection
                            selectedHabitList = nil
                            dismiss()
                        }) {
                            HStack {
                                // Default icon for "None" option
                                ListIconCircleView(icon: "tray", color: accentColor)
                                
                                Text("None")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                                    .padding(.leading, 4) // Add some padding after the icon
                                
                                Spacer()
                                
                                // Show count of unassigned habits
                                HStack(spacing: 5) {
                                    Text("\(unassignedHabits.count)")
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
                                
                                if selectedHabitList == nil {
                                    Spacer()
                                        .frame(width: 8)
                                    
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(accentColor)
                                        .font(.system(size: 14))
                                }
                            }
                            .padding(12)
                            .background(Color(.systemBackground))
                            .cornerRadius(10)
                            .shadow(color: Color(UIColor { $0.userInterfaceStyle == .dark ?
                                                        UIColor.white.withAlphaComponent(0.04) :
                                                        UIColor.black.withAlphaComponent(0.04) }),
                                   radius: 2, x: 0, y: 0)
                        }
                        .padding(.horizontal)
                    }
                    
                    // List of habit lists
                    if habitLists.count > 0 {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Your Lists")
                                .font(.subheadline)
                                .padding(.horizontal)
                                .padding(.top, 4)
                            
                            ScrollView {
                                VStack(spacing: 8) {
                                    ForEach(Array(habitLists.enumerated()), id: \.element.self) { index, list in
                                        Button(action: {
                                            selectedHabitList = list
                                            dismiss()
                                        }) {
                                            HStack {
                                                // Display list icon in a colored circle
                                                ZStack {
                                                    Circle()
                                                        .fill(getListColor(list).opacity(0.2))
                                                        .frame(width: 28, height: 28)
                                                    
                                                    // Check if icon is an emoji
                                                    if let icon = list.icon, icon.first?.isEmoji ?? false {
                                                        Text(icon)
                                                            .font(.system(size: 14))
                                                    } else {
                                                        Image(systemName: list.icon ?? "list.bullet")
                                                            .foregroundColor(getListColor(list))
                                                            .font(.system(size: 12))
                                                    }
                                                }
                                                
                                                Text(list.name ?? "Unnamed List")
                                                    .font(.system(size: 14, weight: .medium))
                                                    .foregroundColor(.primary)
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
                                                
                                                // Spacing between count and checkmark
                                                if selectedHabitList == list {
                                                    Spacer()
                                                        .frame(width: 8)
                                                    
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .foregroundColor(accentColor)
                                                        .font(.system(size: 14))
                                                }
                                            }
                                            .padding(12)
                                            .background(Color(.systemBackground))
                                            .cornerRadius(10)
                                            .shadow(color: Color(UIColor { $0.userInterfaceStyle == .dark ?
                                                                        UIColor.white.withAlphaComponent(0.04) :
                                                                        UIColor.black.withAlphaComponent(0.04) }),
                                                   radius: 2, x: 0, y: 0)
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Create new list button
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Options")
                            .font(.subheadline)
                            .padding(.horizontal)
                            .padding(.top, 4)
                        
                        Button(action: {
                            showCreateNewList = true
                        }) {
                            HStack {
                                ListIconCircleView(icon: "plus.circle", color: accentColor)
                                
                                Text("Create New List")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                                    .padding(.leading, 4) // Add some padding after the icon
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 10, weight: .medium))
                            }
                            .padding(12)
                            .background(Color(.systemBackground))
                            .cornerRadius(10)
                            .shadow(color: Color(UIColor { $0.userInterfaceStyle == .dark ?
                                                        UIColor.white.withAlphaComponent(0.04) :
                                                        UIColor.black.withAlphaComponent(0.04) }),
                                   radius: 2, x: 0, y: 0)
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                }
                .padding(.top, 12)
            }
            .navigationTitle("Select Habit List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.customFont("Lexend", .semiBold, 16))
                    .foregroundColor(.primary)
                }
            }
            .sheet(isPresented: $showCreateNewList) {
                CreateHabitListView()
                    .environment(\.managedObjectContext, viewContext)
            }
        }
    }
    
    // Helper function to create color circle - matching the approach in HabitListTabView
    private func getListColorCircle(_ list: HabitList) -> some View {
        return Circle()
            .fill(getListColor(list))
    }
    
    // Matching the getListColor function from HabitListTabView
    private func getListColor(_ list: HabitList) -> Color {
        if let colorData = list.color,
           let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
            return Color(uiColor)
        }
        return .blue // Default color
    }
    
    // Function to get the number of habits in a list
    private func getHabitCount(_ list: HabitList) -> Int {
        if let habits = list.habits {
            return habits.count
        }
        return 0
    }
}





