//
//  NabBarStatsView.swift
//  Habital
//
//  Created by Elias Osarumwense on 24.10.25.
//

import SwiftUI


struct NavBarStatsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var dataManager: StatsDataManager
    
    @State private var showStatsSettings = false
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \HabitList.order, ascending: true)],
        animation: .default
    )
    private var habitLists: FetchedResults<HabitList>
    
    var body: some View {
        EmptyView()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    customTitleView
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        listMenuContent
                    } label: {
                        Image(systemName: currentListIcon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(currentListColor)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        // Placeholder action
                        showStatsSettings.toggle()
                    }) {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(currentListColor)
                    }
                }
            }
    }
    
    private var titleTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity).combined(with: .scale(scale: 0.98)),
            removal: .move(edge: .top).combined(with: .opacity)
        )
    }
    
    private var customTitleView: some View {
        let anim = Animation.easeInOut(duration: 0.25)
        let subtitleText = getCurrentListName()
        let subtitleID = "\(dataManager.selectedListIndex)-\(subtitleText)"
        
        return VStack(spacing: 2) {
            ZStack {
                Text("Statistics")
                    .id("stats-title")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .transition(titleTransition)
            }
            
            ZStack {
                HStack(spacing: 4) {
                    // Only show dot if we're not in "All Habits" (selectedListIndex > 0)
                    if dataManager.selectedListIndex > 0 {
                        Circle()
                            .fill(currentListColor)
                            .frame(width: 6, height: 6)
                    }
                    
                    Text(subtitleText)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }
                .id(subtitleID)
                .transition(titleTransition)
            }
            .animation(anim, value: subtitleID)
        }
    }
    
    private func getCurrentListName() -> String {
        if dataManager.selectedListIndex == 0 {
            return "All Habits"
        } else if dataManager.selectedListIndex > 0 && dataManager.selectedListIndex <= habitLists.count {
            let list = Array(habitLists)[dataManager.selectedListIndex - 1]
            return list.name ?? "Unnamed List"
        }
        return "All Habits"
    }
    
    // Computed property for menu tint color (used for items inside the menu)
    private var allHabitsTintColor: Color {
        return colorScheme == .dark ? Color(hex: "C9D4FF") : Color(hex: "4050B5")
    }
    
    @ViewBuilder
    private var listMenuContent: some View {
        Button(action: {
            selectList(index: 0)
        }) {
            HStack {
                Label {
                    Text("All Habits")
                        .customFont("Lexend", .medium, 16)
                } icon: {
                    Image(systemName: "tray.full")
                        .foregroundColor(allHabitsTintColor)
                }
                if dataManager.selectedListIndex == 0 {
                    Image(systemName: "checkmark")
                }
            }
        }
        
        ForEach(Array(habitLists.enumerated()), id: \.element.id) { listIndex, list in
            Button(action: {
                selectList(index: listIndex + 1)
            }) {
                HStack {
                    Label {
                        Text(list.name ?? "Unnamed List")
                            .customFont("Lexend", .medium, 16)
                    } icon: {
                        Image(systemName: list.icon ?? "list.bullet")
                    }
                    if dataManager.selectedListIndex == listIndex + 1 {
                        Image(systemName: "checkmark")
                    }
                }
            }
            .tint(allHabitsTintColor)
        }
    }
    

    
    private func selectList(index: Int) {
        withAnimation {
            dataManager.updateSelectedList(index)
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.7)
    }
    
    private var currentListIcon: String {
        if dataManager.selectedListIndex == 0 {
            return "tray.full"
        } else if dataManager.selectedListIndex > 0 && dataManager.selectedListIndex <= habitLists.count {
            let list = Array(habitLists)[dataManager.selectedListIndex - 1]
            return list.icon ?? "list.bullet"
        }
        return "list.bullet"
    }
    
    private var currentListColor: Color {
        if dataManager.selectedListIndex == 0 {
            return colorScheme == .dark ? Color(hex: "C9D4FF") : Color(hex: "4050B5")
        } else if dataManager.selectedListIndex > 0 && dataManager.selectedListIndex <= habitLists.count {
            let list = Array(habitLists)[dataManager.selectedListIndex - 1]
            if let colorData = list.color,
               let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
                return Color(uiColor).opacity(0.7)
            }
            return colorScheme == .dark ? Color(hex: "C9D4FF") : Color(hex: "4050B5")
        }
        return colorScheme == .dark ? Color(hex: "C9D4FF") : Color(hex: "4050B5")
    }

}

