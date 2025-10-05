//
//  EditHabitListView.swift
//  Habital
//
//  Created by Elias Osarumwense on 09.04.25.
//

import SwiftUI

struct EditHabitListView: View {
    let list: HabitList
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var listName: String
    @State private var selectedColor: Color
    @State private var selectedIcon: String
    @State private var showColorPicker = false
    @State private var showIconPicker = false
    
    private let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]
    
    init(list: HabitList) {
        self.list = list
        
        // Initialize state properties
        _listName = State(initialValue: list.name ?? "")
        _selectedIcon = State(initialValue: list.icon ?? "list.bullet")
        
        // Extract the color
        if let colorData = list.color,
           let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
            _selectedColor = State(initialValue: Color(uiColor))
        } else {
            _selectedColor = State(initialValue: .blue)
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        colorScheme == .dark ? Color(hex: "1A1A1A") : Color(hex: "F8F8FF"),
                        colorScheme == .dark ? Color(hex: "202020") : Color(hex: "FFFFFF")
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        // List preview
                        VStack {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(selectedColor.opacity(0.15))
                                    .frame(height: 110)
                                
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(listName.isEmpty ? "Edit List" : listName)
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(selectedColor)
                                        
                                        Text("List Preview")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.leading, 20)
                                    
                                    Spacer()
                                    
                                    // Display icon in circle
                                    ListIconCircleView(icon: selectedIcon, color: selectedColor, size: 40)
                                        .padding(.trailing, 20)
                                }
                            }
                            .padding(.horizontal)
                            .shadow(color: selectedColor.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .padding(.top, 20)
                        
                        // Color picker section
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Select Color")
                                .font(.headline)
                                .padding(.leading)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    ForEach(colors, id: \.self) { color in
                                        Circle()
                                            .fill(color)
                                            .frame(width: 40, height: 40)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.white, lineWidth: 2)
                                                    .opacity(selectedColor == color ? 1 : 0)
                                            )
                                            .shadow(color: color.opacity(0.5), radius: 3, x: 0, y: 2)
                                            .onTapGesture {
                                                withAnimation(.spring()) {
                                                    selectedColor = color
                                                }
                                            }
                                    }
                                    
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [.pink, .purple, .blue]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Image(systemName: "plus")
                                                .foregroundColor(.white)
                                        )
                                        .onTapGesture {
                                            showColorPicker.toggle()
                                        }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // Icon picker section
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Select Icon")
                                .font(.headline)
                                .padding(.leading)
                            
                            Button(action: {
                                showIconPicker = true
                            }) {
                                HStack {
                                    // Display current selected icon in a circle
                                    ListIconCircleView(icon: selectedIcon, color: selectedColor, size: 40)
                                    
                                    Text("Tap to change icon")
                                        .font(.system(size: 16))
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                }
                                .padding(12)
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                                .padding(.horizontal)
                            }
                        }
                        
                        // List name input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("List Details")
                                .font(.headline)
                                .padding(.leading)
                            
                            HStack {
                                Image(systemName: "pencil")
                                    .foregroundColor(selectedColor)
                                    .frame(width: 30)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Name")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    
                                    TextField("Enter list name", text: $listName)
                                        .font(.system(size: 16, weight: .medium))
                                }
                            }
                            .padding(15)
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                            .padding(.horizontal)
                        }
                        
                        Spacer(minLength: 30)
                        
                        // Save button
                        Button(action: {
                            updateList()
                            dismiss()
                        }) {
                            Text("Save Changes")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    listName.isEmpty ?
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.7)]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ) :
                                        LinearGradient(
                                            gradient: Gradient(colors: [selectedColor.opacity(0.8), selectedColor]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                )
                                .cornerRadius(16)
                                .shadow(color: listName.isEmpty ? Color.gray.opacity(0.3) : selectedColor.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .disabled(listName.isEmpty)
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle("Edit List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showColorPicker) {
                ColorPicker("Choose a color", selection: $selectedColor)
                    .padding()
            }
            .sheet(isPresented: $showIconPicker) {
                IconPickerView(selectedIcon: $selectedIcon, selectedColor: selectedColor)
            }
        }
    }
    
    private func updateList() {
        list.name = listName
        list.icon = selectedIcon // Save the updated icon
        
        // Store color as data
        if let colorData = try? NSKeyedArchiver.archivedData(withRootObject: UIColor(selectedColor), requiringSecureCoding: false) {
            list.color = colorData
        }
        
        do {
            try viewContext.save()
            print("Habit list updated successfully")
        } catch {
            print("Error updating habit list: \(error)")
        }
    }
}
