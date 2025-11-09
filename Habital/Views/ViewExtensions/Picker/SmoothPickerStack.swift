//
//  SmoothPickerStack.swift
//  Habital
//
//  Created by Elias Osarumwense on 08.11.25.
//

import SwiftUI

/// A custom picker that displays items in a smooth animated stack
struct SmoothPickerStack<Item: Identifiable & Hashable>: View {
    let items: [Item]
    @Binding var selectedItem: Item
    let label: (Item) -> String
    
    @State private var isExpanded = false
    @Namespace private var animation
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            if isExpanded {
                // Fade overlay - ignores safe area completely
                Color.black.opacity(colorScheme == .dark ? 0.5 : 0.3)
                    .ignoresSafeArea(.all, edges: .all)
                    .transition(.opacity)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isExpanded = false
                        }
                    }
            }
            
            VStack(spacing: 4) {
                if isExpanded {
                    // Display all items stacked upwards (reversed order to appear above)
                    let filteredItems = items.filter { $0.id != selectedItem.id }
                    ForEach(Array(filteredItems.enumerated().reversed()), id: \.element.id) { index, item in
                        pickerItemView(item: item, isSelected: false)
                            .matchedGeometryEffect(
                                id: item.id,
                                in: animation,
                                isSource: true
                            )
                            .transition(.asymmetric(
                                insertion: .offset(y: 50).combined(with: .opacity),
                                removal: .offset(y: 50).combined(with: .opacity)
                            ))
                            .animation(
                                .spring(response: 0.35, dampingFraction: 0.75)
                                    .delay(Double(filteredItems.count - 1 - index) * 0.05),
                                value: isExpanded
                            )
                            .onTapGesture {
                                selectItem(item)
                            }
                    }
                }
                
                // The button - always at the bottom of the VStack
                pickerItemView(item: selectedItem, isSelected: true)
                    .matchedGeometryEffect(
                        id: selectedItem.id,
                        in: animation,
                        isSource: true
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isExpanded.toggle()
                        }
                    }
            }
        }
    }
    
    @ViewBuilder
    private func pickerItemView(item: Item, isSelected: Bool) -> some View {
        Text(label(item))
            .font(.caption)
            .fontWeight(isSelected ? .semibold : .regular)
            .foregroundStyle(colorScheme == .dark ? .white : .black)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .frame(width: 70)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
            )
    }
    
    private func selectItem(_ item: Item) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            selectedItem = item
            isExpanded = false
        }
    }
}

// MARK: - Preview

#Preview {
    struct PreviewItem: Identifiable, Hashable {
        let id = UUID()
        let name: String
    }
    
    struct PreviewWrapper: View {
        let items = [
            PreviewItem(name: "Running"),
            PreviewItem(name: "Gym"),
            PreviewItem(name: "Reading"),
            PreviewItem(name: "Coding")
        ]
        
        @State private var selected: PreviewItem
        
        init() {
            let items = [
                PreviewItem(name: "Running"),
                PreviewItem(name: "Gym"),
                PreviewItem(name: "Reading"),
                PreviewItem(name: "Coding")
            ]
            _selected = State(initialValue: items[0])
        }
        
        var body: some View {
            ZStack {
                // Background content to show fade effect
                VStack(spacing: 20) {
                    Text("Habital")
                        .font(.largeTitle)
                        .bold()
                    
                    Text("Your Daily Habit Tracker")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text("Selected: \(selected.name)")
                        .font(.title3)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                    
                    Spacer()
                }
                .padding()
                
                // Picker overlay
                SmoothPickerStack(
                    items: items,
                    selectedItem: $selected,
                    label: { $0.name }
                )
            }
        }
    }
    
    return PreviewWrapper()
}
