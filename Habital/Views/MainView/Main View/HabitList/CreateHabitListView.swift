//
//  CreateHabitListView.swift
//  Habital
//
//  Created by Elias Osarumwense on 09.04.25.
//

import SwiftUI
import CoreData

struct CreateHabitListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var listName = ""
    @State private var selectedColor = Color.blue
    @State private var selectedIcon = "list.bullet" // Default icon
    @State private var showColorPicker = false
    @State private var showIconPicker = false
    @State private var animateSave = false
    
    // Add more color options to match other views
    private let colors: [Color] = [ .yellow, .orange, .red, .pink, .purple, .blue, .green, .primary ]
    
    // Callback to refresh parent view after creating a list
    var onSave: (() -> Void)?
    
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
                    VStack(spacing: 15) { // Reduced spacing from 25 to 15
                        // List preview
                        VStack {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12) // Reduced from 16
                                    .fill(selectedColor.opacity(0.15))
                                    .frame(height: 80) // Reduced from 110
                                
                                HStack {
                                    VStack(alignment: .leading, spacing: 3) { // Reduced spacing from 4 to 3
                                        Text(listName.isEmpty ? "New List" : listName)
                                            .font(.headline) // Changed from title2
                                            .fontWeight(.semibold) // Changed from bold
                                            .foregroundColor(selectedColor)
                                        
                                        Text("List Preview")
                                            .font(.caption2) // Changed from subheadline
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.leading, 16) // Reduced from 20
                                    
                                    Spacer()
                                    
                                    // Display icon in circle
                                    ListIconCircleView(icon: selectedIcon, color: selectedColor, size: 32)
                                        .padding(.trailing, 16) // Reduced from 20
                                }
                            }
                            .padding(.horizontal)
                            .shadow(color: selectedColor.opacity(0.3), radius: 4, x: 0, y: 2) // Reduced shadow
                        }
                        .padding(.top, 10) // Reduced from 20
                        
                        // Color picker section
                        VStack(alignment: .leading, spacing: 6) { // Reduced spacing from 10 to 6
                            Text("Select Color")
                                .font(.subheadline) // Changed from headline
                                .padding(.leading, 5)
                            
                            HStack(spacing: 8) { // Non-scrollable HStack with reduced spacing
                                ForEach(colors, id: \.self) { color in
                                    Circle()
                                        .fill(color)
                                        .frame(width: 25, height: 25) // Reduced from 40
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: 2)
                                                .opacity(selectedColor == color ? 1 : 0)
                                        )
                                        .shadow(color: color.opacity(0.4), radius: 2, x: 0, y: 1) // Reduced shadow
                                        .onTapGesture {
                                            withAnimation(.spring()) {
                                                selectedColor = color
                                            }
                                        }
                                }
                                
                                // Custom color picker button - replaced with simpler button
                                ColorPicker("", selection: $selectedColor)
                                    .labelsHidden()
                                    .frame(width: 25, height: 25)
                            }
                            .padding(.horizontal, 5)
                            .padding(.vertical, 5)
                        }
                        
                        // Icon picker section
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Select Icon")
                                .font(.subheadline)
                                .padding(.leading, 5)
                            
                            Button(action: {
                                showIconPicker = true
                            }) {
                                HStack {
                                    // Display current selected icon in a circle
                                    ListIconCircleView(icon: selectedIcon, color: selectedColor, size: 36)
                                    
                                    Text("Tap to change icon")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                }
                                .padding(10)
                                .background(Color(.systemBackground))
                                .cornerRadius(10)
                                .shadow(color: Color(UIColor { $0.userInterfaceStyle == .dark ?
                                                            UIColor.white.withAlphaComponent(0.04) :
                                                            UIColor.black.withAlphaComponent(0.04) }),
                                       radius: 2, x: 0, y: 0)
                            }
                            .padding(.horizontal)
                        }
                        
                        // List name input
                        VStack(alignment: .leading, spacing: 5) { // Reduced spacing from 8 to 5
                            Text("List Details")
                                .font(.subheadline) // Changed from headline
                                .padding(.horizontal)
                            
                            HStack {
                                Image(systemName: "pencil")
                                    .foregroundColor(selectedColor)
                                    .frame(width: 25) // Reduced from 30
                                    .font(.system(size: 12)) // Smaller icon
                                
                                VStack(alignment: .leading, spacing: 2) { // Reduced spacing from 4 to 2
                                    Text("Name")
                                        .font(.caption2) // Smaller font
                                        .foregroundColor(.gray)
                                    
                                    TextField("Enter list name", text: $listName)
                                        .font(.system(size: 14, weight: .medium)) // Reduced from 16
                                }
                            }
                            .padding(12) // Reduced from 15
                            .background(Color(.systemBackground))
                            .cornerRadius(10) // Reduced from 12
                            .shadow(color: Color(UIColor { $0.userInterfaceStyle == .dark ?
                                                        UIColor.white.withAlphaComponent(0.04) :
                                                        UIColor.black.withAlphaComponent(0.04) }),
                                   radius: 2, x: 0, y: 0)
                            .padding(.horizontal)
                        }
                        
                        Spacer(minLength: 20) // Add a minimum length
                        
                        // Create button
                        Button(action: {
                            animateSave = true
                            
                            // Create the list after a short animation delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                createList()
                                animateSave = false
                                onSave?()
                                dismiss()
                            }
                        }) {
                            HStack {
                                Text("Create List")
                                    .font(.subheadline) // Changed from headline
                                    .foregroundColor(Color(UIColor { $0.userInterfaceStyle == .dark ? .black : .white }))
                                
                                if animateSave {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: Color(UIColor { $0.userInterfaceStyle == .dark ? .black : .white })))
                                        .padding(.leading, 5)
                                }
                            }
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
                            .cornerRadius(12) // Reduced from 16
                            .shadow(color: listName.isEmpty ? Color.gray.opacity(0.3) : selectedColor.opacity(0.3), radius: 8, x: 0, y: 4) // Reduced shadow
                        }
                        .disabled(listName.isEmpty || animateSave)
                        .padding(.horizontal)
                        .padding(.top, 5) // Reduced from default
                        .padding(.bottom, 20) // Reduced from 30
                    }
                }
            }
            .navigationTitle("Create List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.customFont("Lexend", .semiBold, 16)) // Custom font styling
                    .foregroundColor(.primary)
                }
            }
            .sheet(isPresented: $showIconPicker) {
                IconPickerView(selectedIcon: $selectedIcon, selectedColor: selectedColor)
            }
        }
    }
    
    private func createList() {
        withAnimation {
            let newList = HabitList(context: viewContext)
            newList.name = listName
            newList.id = UUID() // Ensure we set an ID to avoid duplicate issues
            newList.icon = selectedIcon // Save the icon
            
            // Set order to be the next available order number
            let fetchRequest: NSFetchRequest<HabitList> = HabitList.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \HabitList.order, ascending: false)]
            fetchRequest.fetchLimit = 1
            
            do {
                let result = try viewContext.fetch(fetchRequest)
                if let highestOrder = result.first?.order {
                    newList.order = highestOrder + 1
                } else {
                    newList.order = 0 // First list
                }
            } catch {
                print("Error determining list order: \(error)")
                newList.order = 0 // Fallback
            }
            
            // Store color as data
            if let colorData = try? NSKeyedArchiver.archivedData(withRootObject: UIColor(selectedColor), requiringSecureCoding: false) {
                newList.color = colorData
            }
            
            do {
                try viewContext.save()
                print("Habit list saved successfully with order: \(newList.order)")
            } catch {
                print("Error saving habit list: \(error)")
            }
        }
    }
}


// Preview provider
struct CreateHabitListView_Previews: PreviewProvider {
    static var previews: some View {
        CreateHabitListView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
