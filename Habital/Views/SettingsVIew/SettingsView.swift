//
//  SettingsView.swift
//  Habital
//
//  Created by Elias Osarumwense on 29.03.25.
//

import SwiftUI
struct SettingsView: View {
    // Calendar behavior settings
    @AppStorage("showMonthView") private var showMonthView = true
    @AppStorage("enableCalendarDragGesture") private var enableCalendarDragGesture = true
    @AppStorage("changeSelectionOnWeekSwipe") private var changeSelectionOnWeekSwipe = true
    
    // Access the accent color for UI elements
    @AppStorage("accentColorIndex") private var accentColorIndex: Int = 0
    
    // Computed property to get the current selected color
    private var accentColor: Color {
        return ColorPalette.color(at: accentColorIndex)
    }
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) private var colorScheme
    
    // State for navigation
    @State private var showDataManagement = false
    @State private var showAppearanceView = false
    @State private var showAboutView = false
    
    var body: some View {
        ZStack(alignment: .top) {
            // Background
            (colorScheme == .dark ? Color(hex: "0D0D0D") : Color(UIColor.systemGroupedBackground))
                .ignoresSafeArea()
            
            ScrollView {
                LazyVStack(spacing: 24) {
                    // Add top spacing for navbar
                    Color.clear.frame(height: 70)
                    
                    // Header Section with Profile-like Card
                    headerSection
                    
                    // Main Settings Sections
                    VStack(spacing: 20) {
                        generalSection
                        calendarSection
                        dataSection
                        dangerZoneSection
                        aboutSection
                    }
                    .padding(.horizontal, 20)
                    
                    // Bottom spacing
                    Color.clear.frame(height: 50)
                }
            }
            
            // Ultra Thin Material Navbar
            UltraThinMaterialNavBar(
                title: "Settings",
                leftIcon: "xmark",
                leftAction: {
                    presentationMode.wrappedValue.dismiss()
                },
                titleColor: .primary,
                leftIconColor: .red
            )
            .zIndex(1)
        }
        .sheet(isPresented: $showDataManagement) {
            NavigationView {
                DataExportImportView()
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showDataManagement = false
                            }
                            .foregroundColor(accentColor)
                            .fontWeight(.semibold)
                        }
                    }
            }
        }
        .sheet(isPresented: $showAppearanceView) {
            NavigationView {
                AppearanceView()
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showAppearanceView = false
                            }
                            .foregroundColor(accentColor)
                            .fontWeight(.semibold)
                        }
                    }
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // App Icon and Title
            HStack(spacing: 16) {
                // App Icon Placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [accentColor, accentColor.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.white)
                }
                .shadow(color: accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Habital")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("Habit Tracker")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(colorScheme == .dark ? Color(UIColor.secondarySystemGroupedBackground) : Color.white)
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.05), radius: 10, x: 0, y: 2)
        )
        .padding(.horizontal, 20)
    }
    
    // MARK: - General Section
    private var generalSection: some View {
        ModernSettingsSection(title: "General", icon: "gearshape.fill", iconColor: accentColor) {
            VStack(spacing: 0) {
                ModernSettingsRow(
                    icon: "paintbrush.fill",
                    title: "Appearance",
                    subtitle: "Customize colors and themes",
                    action: { showAppearanceView = true }
                )
                
                Divider()
                    .padding(.leading, 50)
                
                ModernSettingsRow(
                    icon: "bell.fill",
                    title: "Notifications",
                    subtitle: "Manage habit reminders",
                    action: { /* TODO: Add notifications settings */ }
                )
            }
        }
    }
    
    // MARK: - Calendar Section
    private var calendarSection: some View {
        ModernSettingsSection(title: "Calendar", icon: "calendar", iconColor: .blue) {
            VStack(spacing: 16) {
                ModernToggleRow(
                    icon: "calendar.badge.plus",
                    title: "Month View",
                    subtitle: "Show full month calendar",
                    isOn: $showMonthView,
                    accentColor: accentColor
                )
                
                if showMonthView {
                    VStack(spacing: 16) {
                        Divider()
                            .padding(.leading, 50)
                        
                        ModernToggleRow(
                            icon: "hand.draw.fill",
                            title: "Drag Gestures",
                            subtitle: "Navigate with swipe gestures",
                            isOn: $enableCalendarDragGesture,
                            accentColor: accentColor
                        )
                        
                        Divider()
                            .padding(.leading, 50)
                        
                        ModernToggleRow(
                            icon: "arrow.left.arrow.right",
                            title: "Week Swipe Selection",
                            subtitle: "Change date on week swipe",
                            isOn: $changeSelectionOnWeekSwipe,
                            accentColor: accentColor
                        )
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }
    
    // MARK: - Data Section
    private var dataSection: some View {
        ModernSettingsSection(title: "Data", icon: "externaldrive.fill", iconColor: .orange) {
            VStack(spacing: 0) {
                ModernSettingsRow(
                    icon: "arrow.up.arrow.down.square.fill",
                    title: "Import & Export",
                    subtitle: "Backup and restore your data",
                    action: { showDataManagement = true }
                )
            }
        }
    }
    
    // MARK: - Danger Zone Section
    private var dangerZoneSection: some View {
        ModernSettingsSection(title: "Danger Zone", icon: "exclamationmark.triangle.fill", iconColor: .red) {
            VStack(spacing: 0) {
                DeleteAllDataButton()
                    .padding(.vertical, 16)
                    .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - About Section
    private var aboutSection: some View {
        ModernSettingsSection(title: "About", icon: "info.circle.fill", iconColor: .purple) {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.15))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "app.badge.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Version")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Text("App version number")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("1.0.0")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 20)
            }
        }
    }
}

// MARK: - Modern Components

struct ModernSettingsSection<Content: View>: View {
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
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 28, height: 28)
                    
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(iconColor)
                }
                
                Text(title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
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

struct ModernSettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
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

struct ModernToggleRow: View {
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
        .animation(.easeInOut(duration: 0.2), value: isOn)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
