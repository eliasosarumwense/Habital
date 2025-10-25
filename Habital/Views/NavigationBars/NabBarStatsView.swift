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
                    HStack {
                        Text("Statistic")
                            .font(.customFont("Lexend", .bold, 22))
                            .foregroundColor(.primary)
                        Spacer()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        listMenuContent
                    } label: {
                        Image(systemName: currentListIcon)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(currentListColor)
                    }
                }
            }
    }
    
    @ViewBuilder
    private var listMenuContent: some View {
        Button(action: {
            selectList(index: 0)
        }) {
            HStack {
                Label("All Habits", systemImage: "tray.full")
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
                    Label(list.name ?? "Unnamed List", systemImage: list.icon ?? "list.bullet")
                    if dataManager.selectedListIndex == listIndex + 1 {
                        Image(systemName: "checkmark")
                    }
                }
            }
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
            return .primary
        } else if dataManager.selectedListIndex > 0 && dataManager.selectedListIndex <= habitLists.count {
            let list = Array(habitLists)[dataManager.selectedListIndex - 1]
            if let colorData = list.color,
               let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
                return Color(uiColor)
            }
            return .accentColor
        }
        return .accentColor
    }

}
