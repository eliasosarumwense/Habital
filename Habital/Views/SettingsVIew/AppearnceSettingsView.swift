//
//  AppearnceSettingsView.swift
//  Habital
//
//  Created by Elias Osarumwense on 12.04.25.
//

import SwiftUI

struct MockEnhancedTrackIndicator: View {
    let isOnTrack: Bool
    let condensed: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(isOnTrack ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                    .frame(width: condensed ? 16 : 20, height: condensed ? 16 : 20)
                
                Image(systemName: isOnTrack ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(isOnTrack ? .green : .red)
                    .font(.system(size: condensed ? 8 : 10))
            }
            
            Text(isOnTrack ? "On track" : "Missed")
                .font(.system(size: condensed ? 10 : 11, weight: .medium))
                .foregroundColor(isOnTrack ? Color.green.opacity(0.9) : Color.red.opacity(0.9))
        }
        .padding(.vertical, condensed ? 3 : 4)
        .padding(.horizontal, condensed ? 8 : 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isOnTrack ? Color.green.opacity(0.08) : Color.red.opacity(0.08))
        )
    }
}

struct AppearanceView: View {
    // App Theme Settings
    @AppStorage("accentColorIndex") private var accentColorIndex: Int = 0
    @AppStorage("showListColors") private var showListColors = true
    
    // Habit List Display Settings
    @AppStorage("showInactiveHabits") private var showInactiveHabits = true
    @AppStorage("groupCompletedHabits") private var groupCompletedHabits = false
    @AppStorage("showProgressBars") private var showProgressBars = true
    
    // Habit Row Visual Indicators
    @AppStorage("highlightOverdueHabits") private var highlightOverdueHabits = true
    @AppStorage("showCompletionDates") private var showCompletionDates = true
    @AppStorage("showChartTrackIndicator") private var showChartTrackIndicator = true
    
    // Calendar View Settings
    @AppStorage("showEllipse") private var showEllipse = true
    @AppStorage("useSegmentedRings") private var useSegmentedRings = false
    
    // Statistics Settings
    @AppStorage("includeBadHabitsInStats") private var includeBadHabitsInStats = true
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.presentationMode) var presentationMode
    
    // Computed property to get the current selected color
    private var selectedColor: Color {
        return ColorPalette.color(at: accentColorIndex)
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // Background
            (colorScheme == .dark ? Color(hex: "0D0D0D") : Color(UIColor.systemGroupedBackground))
                .ignoresSafeArea()
            
            ScrollView {
                LazyVStack(spacing: 24) {
                    // Add top spacing for navbar
                    Color.clear.frame(height: 70)
                    
                    VStack(spacing: 20) {
                        themeSection
                        habitListSection
                        habitRowSection
                        calendarSection
                        statusIndicatorsSection
                        statisticsSection
                    }
                    .padding(.horizontal, 20)
                    
                    // Bottom spacing
                    Color.clear.frame(height: 30)
                }
            }
            
            // Ultra Thin Material Navbar
            UltraThinMaterialNavBar(
                title: "Appearance",
                leftIcon: "xmark",
                leftAction: {
                    presentationMode.wrappedValue.dismiss()
                },
                titleColor: .primary,
                leftIconColor: .red
            )
            .zIndex(1)
        }
    }
    
    // MARK: - Theme Section
    private var themeSection: some View {
        ModernAppearanceSection(title: "Theme", icon: "paintpalette.fill", iconColor: selectedColor) {
            VStack(spacing: 20) {
                // Color Palette
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Accent Color")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 6), spacing: 12) {
                        ForEach(ColorPalette.accentColors.indices, id: \.self) { index in
                            let color = ColorPalette.accentColors[index]
                            
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    accentColorIndex = index
                                }
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(color)
                                        .frame(width: 40, height: 40)
                                        .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)
                                    
                                    if accentColorIndex == index {
                                        Circle()
                                            .stroke(colorScheme == .dark ? Color.white : Color.black, lineWidth: 3)
                                            .frame(width: 48, height: 48)
                                        
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                                .scaleEffect(accentColorIndex == index ? 1.1 : 1.0)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                Divider()
                    .padding(.horizontal, 20)
                
                // List Colors Toggle
                ModernAppearanceToggle(
                    icon: "list.bullet.rectangle.fill",
                    title: "List Colors",
                    subtitle: "Show habit list colors",
                    isOn: $showListColors,
                    accentColor: selectedColor
                )
            }
        }
    }
    
    // MARK: - Habit List Section
    private var habitListSection: some View {
        ModernAppearanceSection(title: "Habit List", icon: "list.dash", iconColor: .blue) {
            VStack(spacing: 0) {
                ModernAppearanceToggle(
                    icon: "eye.fill",
                    title: "Show Inactive Habits",
                    subtitle: "Display habits not due today",
                    isOn: $showInactiveHabits,
                    accentColor: selectedColor
                )
                
                Divider()
                    .padding(.leading, 52)
                
                ModernAppearanceToggle(
                    icon: "checkmark.circle.fill",
                    title: "Group Completed Habits",
                    subtitle: "Separate completed from pending",
                    isOn: $groupCompletedHabits,
                    accentColor: selectedColor
                )
                
                Divider()
                    .padding(.leading, 52)
                
                ModernAppearanceToggle(
                    icon: "chart.bar.fill",
                    title: "Progress Bars",
                    subtitle: "Show completion progress",
                    isOn: $showProgressBars,
                    accentColor: selectedColor
                )
            }
        }
    }
    
    // MARK: - Habit Row Section
    private var habitRowSection: some View {
        ModernAppearanceSection(title: "Habit Rows", icon: "rectangle.3.group.fill", iconColor: .green) {
            VStack(spacing: 0) {
                NavigationLink(destination: HabitRowSettingView()) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.purple.opacity(0.15))
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.purple)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Customize Appearance")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                            
                            Text("Colors, backgrounds, and indicators")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 20)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // MARK: - Calendar Section
    private var calendarSection: some View {
        ModernAppearanceSection(title: "Calendar", icon: "calendar", iconColor: .orange) {
            VStack(spacing: 0) {
                ModernAppearanceToggle(
                    icon: "circle.dotted",
                    title: "Completion Rings",
                    subtitle: "Show progress rings on calendar",
                    isOn: $showEllipse,
                    accentColor: selectedColor
                )
                
                if showEllipse {
                    Divider()
                        .padding(.leading, 52)
                    
                    ModernAppearanceToggle(
                        icon: "chart.pie.fill",
                        title: "Segmented Rings",
                        subtitle: "Use color-coded ring segments",
                        isOn: $useSegmentedRings,
                        accentColor: selectedColor
                    )
                }
            }
        }
    }
    
    // MARK: - Status Indicators Section
    private var statusIndicatorsSection: some View {
        ModernAppearanceSection(title: "Status Indicators", icon: "info.circle.fill", iconColor: .cyan) {
            VStack(spacing: 16) {
                ModernAppearanceToggle(
                    icon: "target",
                    title: "Track Indicators",
                    subtitle: "Show if you're on track with habits",
                    isOn: $showChartTrackIndicator,
                    accentColor: selectedColor
                )
                
                if showChartTrackIndicator {
                    VStack(spacing: 16) {
                        Divider()
                            .padding(.horizontal, 20)
                        
                        // Info Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "info.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.blue)
                                
                                Text("About Track Indicators")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                            }
                            
                            Text("Shows whether you completed or missed your habit the last time it was active.")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .lineLimit(nil)
                        }
                        .padding(.horizontal, 20)
                        
                        // Preview Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Preview")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                                .padding(.horizontal, 20)
                            
                            VStack(spacing: 8) {
                                HStack {
                                    Text("Completed:")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.secondary)
                                        .frame(width: 90, alignment: .leading)
                                    
                                    MockEnhancedTrackIndicator(
                                        isOnTrack: true,
                                        condensed: true
                                    )
                                    
                                    Spacer()
                                }
                                
                                HStack {
                                    Text("Missed:")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.secondary)
                                        .frame(width: 90, alignment: .leading)
                                    
                                    MockEnhancedTrackIndicator(
                                        isOnTrack: false,
                                        condensed: true
                                    )
                                    
                                    Spacer()
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Statistics Section
    private var statisticsSection: some View {
        ModernAppearanceSection(title: "Statistics", icon: "chart.bar.xaxis", iconColor: .purple) {
            VStack(spacing: 16) {
                ModernAppearanceToggle(
                    icon: "x.circle.fill",
                    title: "Include Bad Habits",
                    subtitle: "Count bad habits in statistics",
                    isOn: $includeBadHabitsInStats,
                    accentColor: selectedColor
                )
                
                if includeBadHabitsInStats {
                    VStack(spacing: 12) {
                        Divider()
                            .padding(.horizontal, 20)
                        
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.blue)
                            
                            Text("Bad habits count as completed when NOT performed")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .lineLimit(nil)
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
        }
    }
}

// MARK: - Modern Appearance Components

struct ModernAppearanceSection<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    let content: Content
    
    @Environment(\.colorScheme) private var colorScheme
    
    init(title: String, icon: String, iconColor: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(iconColor)
                }
                
                Text(title)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 20)
            
            // Section Content
            VStack(spacing: 0) {
                content
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color(UIColor.secondarySystemGroupedBackground) : Color.white)
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.05), radius: 8, x: 0, y: 2)
            )
        }
    }
}

struct ModernAppearanceToggle: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    let accentColor: Color
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isOn ? accentColor.opacity(0.15) : Color.gray.opacity(0.15))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isOn ? accentColor : .secondary)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: accentColor))
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
    }
}

struct AppearanceView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AppearanceView()
        }
    }
}
