//
//  Untitled.swift
//  Habital
//
//  Created by Elias Osarumwense on 21.05.25.
//

import SwiftUI

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGPoint = .zero
    
    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {
        value = nextValue()
    }
}

struct HabitTabContainerView: View {
    // HabitListTabView parameters
    let habitLists: FetchedResults<HabitList>
    @Binding var selectedListIndex: Int
    @Binding var showArchivedhabits: Bool
    
    // Left button parameters
    var leftButtonIcon: String
    var leftButtonAction: () -> Void
    
    // Right button parameters
    var rightButtonIcon: String
    var rightButtonAction: () -> Void
    
    // Optional environment object for tab reference
    @EnvironmentObject var habitListTabView: HabitListTabReference
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var leftButtonPressed = false
    @State private var rightButtonPressed = false
    
    var body: some View {
        ZStack {
            // Clean background - matches navbar
            Rectangle()
                .fill(.clear)
                .edgesIgnoringSafeArea(.bottom)
            
            HStack(spacing: 8) {
                // Enhanced Left button with modern design
                LiquidGlassRoundButton(
                    systemImage: leftButtonIcon,
                    size: 50,
                    iconSize: 20
                ) {
                    leftButtonAction()
                }
                
                // Habit List Tab View in the middle
                HabitListTabView(
                    habitLists: habitLists,
                    selectedListIndex: $selectedListIndex,
                    showArchivedhabits: $showArchivedhabits
                )
                .environmentObject(habitListTabView)
                
                // Enhanced Right button with modern design
                Button(action: rightButtonAction) {
                    Image(systemName: rightButtonIcon)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    colorScheme == .dark ? .white : .black,
                                    colorScheme == .dark ? .white.opacity(0.8) : .black.opacity(0.7)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                        .background(
                            ZStack {
                                // Main background with blur effect
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(
                                                colorScheme == .dark
                                                ? Color.white.opacity(0.08)
                                                : Color.black.opacity(0.04)
                                            )
                                    )
                                
                                // Floating border with gradient
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [
                                                colorScheme == .dark
                                                ? Color.white.opacity(0.3)
                                                : Color.white.opacity(0.8),
                                                colorScheme == .dark
                                                ? Color.white.opacity(0.05)
                                                : Color.black.opacity(0.1)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.5
                                    )
                                
                                // Inner glow for depth
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(
                                        colorScheme == .dark
                                        ? Color.white.opacity(0.15)
                                        : Color.white.opacity(0.6),
                                        lineWidth: 0.8
                                    )
                                    .padding(1.5)
                                
                                // Subtle highlight
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(
                                        RadialGradient(
                                            colors: [
                                                colorScheme == .dark
                                                ? Color.white.opacity(0.12)
                                                : Color.white.opacity(0.25),
                                                Color.clear
                                            ],
                                            center: .topLeading,
                                            startRadius: 4,
                                            endRadius: 24
                                        )
                                    )
                            }
                        )
                        .scaleEffect(rightButtonPressed ? 0.94 : 1.0)
                        
                }
                .buttonStyle(PlainButtonStyle())
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            withAnimation(.spring(response: 0.15, dampingFraction: 0.8)) {
                                rightButtonPressed = true
                            }
                        }
                        .onEnded { _ in
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                                rightButtonPressed = false
                            }
                        }
                )
            }
            .padding(.horizontal, 25) // Same padding as navbar
        }
        .frame(height: 60) // Same height as navbar
    }
}

// MARK: - Alternative Minimal Version with Enhanced Glossy Effect

struct MinimalHabitTabContainer: View {
    let habitLists: FetchedResults<HabitList>
    @Binding var selectedListIndex: Int
    @Binding var showArchivedhabits: Bool
    
    var leftButtonIcon: String
    var leftButtonAction: () -> Void
    var rightButtonIcon: String
    var rightButtonAction: () -> Void
    
    // Add these new parameters
    var showStatsView: Bool = false
    var showAnalyticsAction: (() -> Void)? = nil
    
    @EnvironmentObject var habitListTabView: HabitListTabReference
    @Environment(\.colorScheme) private var colorScheme
    @State private var leftButtonPressed = false
    @State private var rightButtonPressed = false
    
    var body: some View {
        HStack(spacing: 10) {
            // Enhanced minimal left button with modern glass effect
            SimpleLiquidGlassButton(
                systemImage: leftButtonIcon,
                size: 50
            ) {
                leftButtonAction()
            }
            
            // Conditional middle content
            if showStatsView {
                /*
                // Show Analytics Button when in stats view
                if let analyticsAction = showAnalyticsAction {
                    AnalyticsButton(action: analyticsAction)
                        .transition(.opacity)
                } else {
                    // Fallback empty space
                    Spacer()
                }
                 */
            } else {
                // Show Habit List Tab View when in habits view
                HabitListTabView(
                    habitLists: habitLists,
                    selectedListIndex: $selectedListIndex,
                    showArchivedhabits: $showArchivedhabits
                )
                .environmentObject(habitListTabView)
                .transition(.opacity)
            }
            
            SimpleLiquidGlassButton(
                systemImage: rightButtonIcon,
                size: 50
            ) {
                rightButtonAction()
            }
        }
        .padding(.horizontal, 20)
        .frame(height: 60)
        .background(.clear)
        .animation(.easeInOut(duration: 0.3), value: showStatsView)
    }
}

// MARK: - Usage Extension (Updated)

extension View {
    func modernHabitTabContainer(
        habitLists: FetchedResults<HabitList>,
        selectedListIndex: Binding<Int>,
        showArchivedhabits: Binding<Bool>,
        leftButtonIcon: String,
        leftButtonAction: @escaping () -> Void,
        rightButtonIcon: String,
        rightButtonAction: @escaping () -> Void,
        habitListTabView: HabitListTabReference,
        style: ModernTabContainerStyle = .standard
    ) -> some View {
        self.overlay(
            Group {
                switch style {
                case .standard:
                    HabitTabContainerView(
                        habitLists: habitLists,
                        selectedListIndex: selectedListIndex,
                        showArchivedhabits: showArchivedhabits,
                        leftButtonIcon: leftButtonIcon,
                        leftButtonAction: leftButtonAction,
                        rightButtonIcon: rightButtonIcon,
                        rightButtonAction: rightButtonAction
                    )
                    .environmentObject(habitListTabView)
                case .minimal:
                    MinimalHabitTabContainer(
                        habitLists: habitLists,
                        selectedListIndex: selectedListIndex,
                        showArchivedhabits: showArchivedhabits,
                        leftButtonIcon: leftButtonIcon,
                        leftButtonAction: leftButtonAction,
                        rightButtonIcon: rightButtonIcon,
                        rightButtonAction: rightButtonAction
                    )
                    .environmentObject(habitListTabView)
                }
            },
            alignment: .bottom
        )
    }
}

enum ModernTabContainerStyle {
    case standard
    case minimal
}
