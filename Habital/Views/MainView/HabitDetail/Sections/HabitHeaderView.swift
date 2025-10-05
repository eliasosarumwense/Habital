//
//  HabitHeaderView.swift
//  Habital
//
//  Created by Elias Osarumwense on 20.04.25.
//

import SwiftUI

struct HabitHeaderView: View {
    let habit: Habit
    let showStreaks: Bool
    
    @State private var showEditSheet = false
    @State private var showArchiveAlert = false
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    
    // Calculate streak
    private var streak: Int {
        return habit.calculateStreak(upTo: Date())
    }
    
    // Extract the habit color
    private var habitColor: Color {
        if let colorData = habit.color,
           let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
            return Color(uiColor)
        }
        return .blue // Default color if not set
    }
    
    // Format date with specific style
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "Not set" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(spacing: 2) {
            // Main header row with icon, name and date in top-right
            ZStack(alignment: .topLeading) {
                // Main content area
                HabitHeaderMainContent(
                    habit: habit,
                    streak: streak,
                    habitColor: habitColor,
                    showStreaks: showStreaks
                )
                
            }
            /*
            HStack(spacing: 12) {
                Spacer()
                // Edit button with subtle hover effect
                Button {
                    showEditSheet = true
                } label: {
                    Circle()
                        .fill(Color.secondary.opacity(0.1))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "pencil")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                        )
                        .contentShape(Circle())
                }
                .buttonStyle(ScaleButtonStyle())
                
                // Archive button with subtle hover effect
                Button {
                    showArchiveAlert = true
                } label: {
                    Circle()
                        .fill(Color.secondary.opacity(0.1))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: habit.isArchived ? "tray.and.arrow.up" : "archivebox")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                        )
                        .contentShape(Circle())
                }
                .buttonStyle(ScaleButtonStyle())
            }
             
            .padding(.trailing, 4)
            .padding(.top, -20)
             */
            
            //.padding(.trailing, 4)
            //.padding(.top, -30)
            //.offset(y: 13)
            // Description section
            HabitDescriptionView(
                description: habit.habitDescription,
                colorScheme: colorScheme
            )
            //.padding(.top, -20)
            
            
        }
        .padding()
        .glassBackground()
        /*
        .glitterGlassBackground(
            cornerRadius: 30,
            tintColor: habitColor.opacity(0.7),
            glitterIntensity: 0.9 // Subtle but noticeable
        )
         */
        .alert(isPresented: $showArchiveAlert) {
            Alert(
                title: Text(habit.isArchived ? "Unarchive Habit" : "Archive Habit"),
                message: Text(habit.isArchived ?
                              "This habit will be restored and available in your active habits." :
                                "This habit will be archived and removed from your active habits."),
                primaryButton: .destructive(Text(habit.isArchived ? "Unarchive" : "Archive")) {
                    toggleArchiveHabit(habit: habit, context: viewContext)
                },
                secondaryButton: .cancel()
            )
        }
        .sheet(isPresented: $showEditSheet) {
            EditHabitView(habit: habit)
                .environment(\.managedObjectContext, viewContext)
        }

    }
}

struct HabitHeaderMainContent: View {
    @Environment(\.colorScheme) private var colorScheme
    let habit: Habit
    let streak: Int
    let habitColor: Color
    let showStreaks: Bool
    
    @State private var showEditSheet = false
    @State private var showArchiveAlert = false
    @State private var editButtonPressed = false
    @State private var archiveButtonPressed = false
    
    @Environment(\.managedObjectContext) private var viewContext
    
    private var habitIntensity: HabitIntensity {
        return HabitIntensity(rawValue: habit.intensityLevel) ?? .light
    }
    
    // Modern action buttons
    private var actionButtons: some View {
        VStack(spacing: 10) {
            // Edit button
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    editButtonPressed = true
                }
                
                // Haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        editButtonPressed = false
                    }
                    showEditSheet = true
                }
            }) {
                ZStack {
                    // Glass morphism background
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(colorScheme == .dark ? 0.1 : 0.3),
                                            Color.clear
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        //.shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                    
                    Image(systemName: "pencil")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .symbolEffect(.bounce, value: editButtonPressed)
                }
                .scaleEffect(editButtonPressed ? 0.95 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: editButtonPressed)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Archive/Unarchive button
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    archiveButtonPressed = true
                }
                
                // Haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        archiveButtonPressed = false
                    }
                    showArchiveAlert = true
                }
            }) {
                ZStack {
                    // Glass morphism background with different tint for archive
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            (habit.isArchived ? Color.green : .secondary).opacity(0.3),
                                            Color.clear
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        /*.shadow(color: (habit.isArchived ? Color.green : Color.orange).opacity(0.2), radius: 8, x: 0, y: 4)
                    */
                    Image(systemName: habit.isArchived ? "tray.and.arrow.up" : "archivebox")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(habit.isArchived ? .green : .secondary)
                        .symbolEffect(.bounce, value: archiveButtonPressed)
                }
                .scaleEffect(archiveButtonPressed ? 0.95 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: archiveButtonPressed)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Icon using HabitIconView
            VStack(alignment: .leading, spacing: 2) {
                HabitIconView(
                    iconName: habit.icon,
                    isActive: true, // Always active in detail sheet
                    habitColor: habitColor,
                    streak: streak,
                    showStreaks: false,
                    useModernBadges: true, // You can customize this
                    isFutureDate: false, // Since this is for current habit detail
                    isBadHabit: habit.isBadHabit,
                    intensityLevel: habit.intensityLevel // Add this if your Habit model has duration
                )
                .scaleEffect(1.85) // Scale up for the detail sheet header
                .frame(width: 80, height: 80) // Maintain consistent sizing
            }
            .frame(width: 80) // Fixed width for icon column
            
            // Center column with habit name and badges
            VStack(alignment: .leading, spacing: 0) {
                // Habit name
                VStack(spacing: 6) {
                    Text(habit.name ?? "Unnamed Habit")
                        .font(.customFont("Lexend", .bold, 23))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.trailing, 4)
                        .padding(.top, 3)
                        .shadow(color: colorScheme == .dark ? .white.opacity(0.33) : .black.opacity(0.33), radius: 0.5)
                    
                    HStack {
                        if let habitList = habit.habitList {
                            HabitListBadge(habitList: habitList)
                            //MinimalHabitListBadge(habitList: habitList)
                            //GlassHabitListBadge(habitList: habitList)
                        } else {
                            
                        }
                        //UltraMinimalRepeatPatternView(habit: habit, date: Date())
                        Spacer()
                    }
                    Spacer()
                }
                .frame(height: 80)
                
                // Only show archived badge if needed
                if habit.isArchived {
                    ArchivedBadge()
                }
            }
            .frame(maxWidth: .infinity)
            //.padding(.top, 2)
            .padding(.trailing, 0) // Make space for the date in top-right
            
            // Modern action buttons
            actionButtons
        }
        .sheet(isPresented: $showEditSheet) {
            EditHabitView(habit: habit)
                .environment(\.managedObjectContext, viewContext)
        }
        .alert("Archive Habit", isPresented: $showArchiveAlert) {
            Button("Cancel", role: .cancel) { }
            Button(habit.isArchived ? "Unarchive" : "Archive", role: habit.isArchived ? .none : .destructive) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    toggleArchiveHabit()
                }
            }
        } message: {
            Text(habit.isArchived ?
                "This will unarchive the habit and make it active again." :
                "This will archive the habit and hide it from your main list.")
        }
    }
    
    // Helper function to toggle archive status
    func toggleArchiveHabit() {
        habit.isArchived.toggle()
        
        do {
            try viewContext.save()
            
            // Success haptic feedback
            let successFeedback = UINotificationFeedbackGenerator()
            successFeedback.notificationOccurred(.success)
        } catch {
            // Error haptic feedback
            let errorFeedback = UINotificationFeedbackGenerator()
            errorFeedback.notificationOccurred(.error)
            print("Failed to toggle archive status: \(error)")
        }
    }
}


// Subview for description
struct HabitDescriptionView: View {
    let description: String?
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Description")
                .font(.customFont("Lexend", .semiBold, 13))
                .foregroundColor(.primary)
                .padding(.leading, 4)
            
            Group {
                if let description = description, !description.isEmpty {
                    Text(description)
                        .font(.customFont("Lexend", .regular, 12))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("No description yet")
                        .font(.customFont("Lexend", .regular, 12))
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(colorScheme == .dark ? Color.black.opacity(0.2) : Color.gray.opacity(0.05))
            )
        }
        .padding(.top, 2)
    }
}

// Subview for habit list badge
struct HabitListBadge: View {
    let habitList: HabitList
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var listColor: Color {
        habitList.color != nil ? (Color(data: habitList.color!) ?? .secondary) : .secondary
    }
    
    var body: some View {
        HStack(spacing: 8) {
            // Minimal colored indicator
            Circle()
                .fill(listColor)
                .frame(width: 8, height: 8)
            
            // List name with modern typography
            Text(habitList.name ?? "Unnamed List")
                .font(.customFont("Lexend", .medium, 12))
                .foregroundColor(.primary.opacity(0.7))
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(colorScheme == .dark ?
                    Color.white.opacity(0.08) :
                    Color.black.opacity(0.04))
                .overlay(
                    Capsule()
                        .strokeBorder(
                            listColor.opacity(0.15),
                            lineWidth: 1
                        )
                )
        )
    }
}

// Alternative even more minimal version
struct MinimalHabitListBadge: View {
    let habitList: HabitList
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var listColor: Color {
        habitList.color != nil ? (Color(data: habitList.color!) ?? .secondary) : .secondary
    }
    
    var body: some View {
        HStack(spacing: 6) {
            // Small colored dot
            Circle()
                .fill(listColor)
                .frame(width: 6, height: 6)
            
            // List name
            Text(habitList.name ?? "Unnamed List")
                .font(.customFont("Lexend", .regular, 11))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
    }
}

// Glass morphism version for premium feel
struct GlassHabitListBadge: View {
    let habitList: HabitList
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var listColor: Color {
        habitList.color != nil ? (Color(data: habitList.color!) ?? .secondary) : .secondary
    }
    
    var body: some View {
        HStack(spacing: 8) {
            // Glass circle with colored border
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .strokeBorder(listColor, lineWidth: 1.5)
                )
            
            // List name
            Text(habitList.name ?? "Unnamed List")
                .font(.customFont("Lexend", .medium, 11))
                .foregroundColor(.primary.opacity(0.8))
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(colorScheme == .dark ? 0.1 : 0.3),
                                    listColor.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
}

// Subview for habit type badge
struct HabitTypeBadge: View {
    let isBadHabit: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: isBadHabit ? "xmark.circle.fill" : "checkmark.circle.fill")
                .foregroundColor(isBadHabit ? .red : .green)
                .font(.system(size: 10))
            
            Text(isBadHabit ? "Bad Habit" : "Good Habit")
                .font(.system(size: 10, weight: .semibold))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(isBadHabit ? Color.red.opacity(0.15) : Color.green.opacity(0.15))
                .overlay(
                    Capsule()
                        .strokeBorder(isBadHabit ? Color.red.opacity(0.2) : Color.green.opacity(0.2), lineWidth: 1)
                )
        )
        .foregroundColor(isBadHabit ? .red : .green)
    }
}

// Subview for archived badge
struct ArchivedBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "archivebox.fill")
                .foregroundColor(.gray)
                .font(.system(size: 10))
            
            Text("Archived")
                .font(.system(size: 10, weight: .semibold))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.gray.opacity(0.15))
                .overlay(
                    Capsule()
                        .strokeBorder(Color.gray.opacity(0.2), lineWidth: 1)
                )
        )
        .foregroundColor(.gray)
    }
}








// Extension to handle Color initialization from Data
extension Color {
    init?(data: Data) {
        guard let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data) else {
            return nil
        }
        self.init(uiColor)
    }
}

// Preview for the HabitHeaderView
struct HabitHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Create a sample habit for preview
            HabitHeaderView(habit: createSampleHabit(), showStreaks: true)
                .padding()
                .previewDisplayName("Light Mode")
            
            HabitHeaderView(habit: createSampleHabit(), showStreaks: true)
                .padding()
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
            
            // Bad habit example
            HabitHeaderView(habit: createBadHabit(), showStreaks: true)
                .padding()
                .previewDisplayName("Bad Habit")
        }
    }
    
    // Helper to create a sample habit for preview
    static func createSampleHabit() -> Habit {
        let context = PersistenceController.preview.container.viewContext
        
        let habit = Habit(context: context)
        habit.id = UUID()
        habit.name = "Morning medsfsddsd"
        habit.habitDescription = "Start each day with 10 minutes of mindfulness meditation to improve focus and reduce stress."
        habit.startDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())
        habit.icon = "brain.head.profile"
        habit.isBadHabit = false
        //habit.energyImpact = 3
        //habit.healthImpact = 4
        habit.intensityLevel = 1
        // Create a color
        if let colorData = try? NSKeyedArchiver.archivedData(withRootObject: UIColor.blue, requiringSecureCoding: false) {
            habit.color = colorData
        }
        
        // Create a list for the habit
        let list = HabitList(context: context)
        list.id = UUID()
        list.name = "Wellness"
        list.icon = "heart.fill"
        if let colorData = try? NSKeyedArchiver.archivedData(withRootObject: UIColor.green, requiringSecureCoding: false) {
            list.color = colorData
        }
        habit.habitList = list
        
        return habit
    }
    
    // Helper to create a sample bad habit for preview
    static func createBadHabit() -> Habit {
        let context = PersistenceController.preview.container.viewContext
        
        let habit = Habit(context: context)
        habit.id = UUID()
        habit.name = "Late Night Snacking"
        habit.habitDescription = "Avoiding food after 8pm to improve sleep quality and digestion."
        habit.startDate = Calendar.current.date(byAdding: .day, value: -15, to: Date())
        habit.icon = "moon.zzz.fill"
        habit.isBadHabit = true
        //habit.energyImpact = -2
        //habit.healthImpact = -3
        
        // Create a color
        if let colorData = try? NSKeyedArchiver.archivedData(withRootObject: UIColor.red, requiringSecureCoding: false) {
            habit.color = colorData
        }
        
        return habit
    }
}

struct HabitStartDateView: View {
    let startDate: Date?
    let formatDate: (Date?) -> String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "calendar")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                
            Text(formatDate(startDate))
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.primary.opacity(0.8))
        }
        //.padding(8)
    }
}
