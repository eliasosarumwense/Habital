//
//  HabitListSelectorButton.swift
//  Habital
//
//  Created by Elias Osarumwense on 26.07.25.
//

import SwiftUI
import CoreData

struct HabitListSelectorButton: View {
    @State var showMenu = false
    
    // Bindings for MainHabitsView
    @Binding var selectedListIndex: Int
    @Binding var showArchivedHabits: Bool
    
    // Core Data
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \HabitList.order, ascending: true)],
        animation: .easeInOut
    ) private var habitLists: FetchedResults<HabitList>
    
    // Settings
    @AppStorage("showListColors") private var showListColors = true
    @AppStorage("accentColorIndex") private var accentColorIndex: Int = 0
    
    private var accentColor: Color {
        return ColorPalette.color(at: accentColorIndex)
    }
    
    var body: some View {
        ZStack {
            if showMenu {
                let layout = showMenu ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12)) :
                                        AnyLayout(ZStackLayout(alignment: .bottomLeading))
                
                layout {
                    // All Habits option
                    ListOptionView(
                        icon: "tray.full",
                        title: "All Habits",
                        habitCount: getAllHabitsCount(),
                        isSelected: selectedListIndex == 0 && !showArchivedHabits,
                        color: showListColors ? accentColor : .secondary
                    ) {
                        withAnimation(.spring(duration: 0.4)) {
                            selectedListIndex = 0
                            showArchivedHabits = false
                        }
                        showMenu = false
                    }
                    
                    // Individual habit lists
                    ForEach(Array(habitLists.enumerated()), id: \.element.id) { index, list in
                        ListOptionView(
                            icon: list.icon ?? "list.bullet",
                            title: list.name ?? "Unnamed List",
                            habitCount: getHabitCount(list),
                            isSelected: selectedListIndex == index + 1 && !showArchivedHabits,
                            color: showListColors ? getListColor(list) : .secondary
                        ) {
                            withAnimation(.spring(duration: 0.4)) {
                                selectedListIndex = index + 1
                                showArchivedHabits = false
                            }
                            showMenu = false
                        }
                    }
                    
                    // Divider
                    Divider()
                        .padding(.vertical, 4)
                    
                    // Archived Habits option
                    ListOptionView(
                        icon: "archivebox",
                        title: "Archived",
                        habitCount: getArchivedHabitsCount(),
                        isSelected: showArchivedHabits,
                        color: showListColors ? .orange : .secondary
                    ) {
                        withAnimation(.spring(duration: 0.4)) {
                            showArchivedHabits = true
                            selectedListIndex = 0
                        }
                        showMenu = false
                    }
                }
                .blur(radius: showMenu ? 0 : 10)
                .opacity(showMenu ? 1 : 0)
                .padding(.horizontal, showMenu ? 47 : 25)
                .padding(.bottom, showMenu ? 90 : 25)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                .background(
                    .ultraThinMaterial
                        .opacity(showMenu ? 1 : 0)
                )
                .onTapGesture {
                    showMenu = false
                }
                .animation(.spring(duration: 0.2), value: showMenu)
            }
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Image(systemName: "line.3.horizontal.decrease")
                        .foregroundColor(getCurrentListColor())
                        .padding(10)
                        .background(.gray.opacity(0.3), in: .rect(cornerRadius: 42))
                        .onTapGesture {
                            withAnimation {
                                showMenu = true
                            }
                        }
                        //.animation(.easeInOut(duration: 0.3), value: getCurrentListColor())
                }
            }
        }
        .ignoresSafeArea(.all)
    }
    
    // MARK: - Helper Functions
    
    private func getCurrentListColor() -> Color {
        if showArchivedHabits {
            return .orange
        } else if selectedListIndex == 0 {
            return accentColor
        } else if selectedListIndex <= habitLists.count {
            let list = habitLists[selectedListIndex - 1]
            return getListColor(list)
        }
        return accentColor
    }
    
    private func getListColor(_ list: HabitList) -> Color {
        if let colorData = list.color,
           let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
            return Color(uiColor)
        }
        return accentColor
    }
    
    private func getHabitCount(_ list: HabitList) -> Int {
        guard let habits = list.habits as? Set<Habit> else { return 0 }
        return habits.filter { !$0.isArchived }.count
    }
    
    private func getAllHabitsCount() -> Int {
        let request: NSFetchRequest<Habit> = Habit.fetchRequest()
        request.predicate = NSPredicate(format: "isArchived == %@", NSNumber(value: false))
        return (try? viewContext.count(for: request)) ?? 0
    }
    
    private func getArchivedHabitsCount() -> Int {
        let request: NSFetchRequest<Habit> = Habit.fetchRequest()
        request.predicate = NSPredicate(format: "isArchived == %@", NSNumber(value: true))
        return (try? viewContext.count(for: request)) ?? 0
    }
}

struct ListOptionView: View {
    let icon: String
    let title: String
    let habitCount: Int
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(color.opacity(isSelected ? 0.2 : 0.1))
                        .frame(width: 36, height: 36)
                    
                    if icon.count == 1 && icon.first?.isEmoji == true {
                        Text(icon)
                            .font(.system(size: 16))
                    } else {
                        Image(systemName: icon)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(color)
                    }
                }
                
                // Title and count
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.custom("Lexend-SemiBold", size: 15))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text("\(habitCount) habit\(habitCount != 1 ? "s" : "")")
                        .font(.custom("Lexend-Medium", size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(color)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? color.opacity(0.1) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                isSelected ? color.opacity(0.3) : Color.clear,
                                lineWidth: 1.5
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    HabitListSelectorButton(
        selectedListIndex: .constant(0),
        showArchivedHabits: .constant(false)
    )
}


