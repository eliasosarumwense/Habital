import SwiftUI

// MARK: - Modern Smooth Expanding Menu Button with Hero Animation
struct ExpandingGlassMenuButton: View {
    let currentStatsListIcon: String
    let currentStatsListColor: Color
    let habitLists: [HabitListData]
    let currentSelectedIndex: Int
    let onListSelected: (Int) -> Void
    
    @State private var isExpanded = false
    @State private var showSelectedName = false
    @State private var hideTimer: Timer?
    @Namespace private var heroAnimation
    @Environment(\.colorScheme) private var colorScheme
    
    // Animation constants - modern, minimal sizing
    private let collapsedWidth: CGFloat = 80
    private let collapsedHeight: CGFloat = 36
    private let expandedWidth: CGFloat = 260
    private let expandedHeight: CGFloat = 280
    
    var body: some View {
        ZStack {
            // Expanded state - full menu
            if isExpanded {
                expandedMenuView
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8, anchor: .bottomTrailing)
                            .combined(with: .opacity),
                        removal: .scale(scale: 0.8, anchor: .bottomTrailing)
                            .combined(with: .opacity)
                    ))
                    .zIndex(0)
            }
            
            // Collapsed state - minimal button (disappears immediately)
            if !isExpanded {
                collapsedButtonView
                    .transition(.identity) // No transition - instant disappear
                    .zIndex(1)
            }
        }
        .animation(.smooth(duration: 0.2, extraBounce: 0.02), value: isExpanded) // ONLY animate expand/collapse
        .onDisappear {
            // Clean up timer when view disappears
            hideTimer?.invalidate()
            hideTimer = nil
        }
    }
    
    // MARK: - Collapsed Button View (Icon Only in Idle)
    private var collapsedButtonView: some View {
        Button(action: expandMenu) {
            HStack(spacing: 8) {
                Image(systemName: currentStatsListIcon)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(currentStatsListColor)
                    .matchedGeometryEffect(id: "menuIcon", in: heroAnimation)
                    .animation(nil, value: currentStatsListIcon) // Remove icon animation
                    .animation(nil, value: currentStatsListColor) // Remove color animation
                    .animation(nil, value: currentStatsListIcon) // Remove icon animation
                    .animation(nil, value: currentStatsListColor) // Remove color animation
                
                // Only show text when showing selected name, not in normal idle state
                if showSelectedName {
                    Text(getSelectedListName())
                        .font(.customFont("Lexend", .medium, 12))
                        .foregroundColor(currentStatsListColor)
                        .lineLimit(1)
                        .matchedGeometryEffect(id: "menuText", in: heroAnimation)
                        .animation(nil, value: getSelectedListName()) // Remove text animation
                }
            }
            .frame(
                width: showSelectedName ? min(getSelectedListNameWidth(), 160) : 44, // Square icon-only button
                height: 44
            )
            .minimalistGlassBackground(
                backgroundColor: currentStatsListColor.opacity(0.08),
                cornerRadius: 22 // Circular when icon-only
            )
        }
        .buttonStyle(MinimalistButtonStyle())
    }
    
    // MARK: - Expanded Menu View (Clean & Minimal)
    private var expandedMenuView: some View {
        VStack(spacing: 0) {
            // Ultra-minimal header
            HStack {
                Image(systemName: currentStatsListIcon)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(currentStatsListColor)
                    .matchedGeometryEffect(id: "menuIcon", in: heroAnimation)
                
                Text("Select List")
                    .font(.customFont("Lexend", .semiBold, 16))
                    .foregroundColor(.primary)
                    .matchedGeometryEffect(id: "menuText", in: heroAnimation)
                    .animation(nil, value: "Select List") // Remove text animation
                
                Spacer()
                
                Button(action: collapseMenu) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 24, height: 24)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(InstantCollapseButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            // Clean separator
            Divider()
                .opacity(0.3)
                .padding(.horizontal, 16)
            
            // Minimal list items
            ScrollView(showsIndicators: false) {
                VStack(spacing: 2) {
                    // All Habits option
                    MinimalListItem(
                        icon: "tray.full",
                        title: "All Habits",
                        color: .secondary,
                        habitCount: getAllHabitsCount(),
                        isSelected: isAllHabitsSelected(),
                        onTap: { selectList(0) }
                    )
                    
                    // Individual habit lists
                    ForEach(Array(habitLists.enumerated()), id: \.element.id) { index, list in
                        MinimalListItem(
                            icon: list.icon,
                            title: list.name,
                            color: list.color,
                            habitCount: list.habitCount,
                            isSelected: isListSelected(index + 1),
                            onTap: { selectList(index + 1) }
                        )
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
            }
            .frame(maxHeight: 200)
            
            Spacer(minLength: 16)
        }
        .frame(width: expandedWidth, height: expandedHeight)
        .minimalistGlassBackground(cornerRadius: 24)
    }
    
    // MARK: - Actions
    private func expandMenu() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.6)
        
        // Cancel any existing timer when expanding
        hideTimer?.invalidate()
        hideTimer = nil
        
        // Immediate state change - button disappears instantly
        showSelectedName = false
        isExpanded = true
    }
    
    private func collapseMenu() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.4)
        
        // Cancel any existing timer when collapsing
        hideTimer?.invalidate()
        hideTimer = nil
        
        // Instant collapse - no animation delay
        isExpanded = false
    }
    
    private func selectList(_ index: Int) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred(intensity: 0.8)
        
        onListSelected(index)
        
        // Cancel any existing timer
        hideTimer?.invalidate()
        hideTimer = nil
        
        // Instant collapse
        isExpanded = false
        
        // Show selected list name immediately (no animation or delay)
        showSelectedName = true
        
        // Start 5-second timer to hide the name
        hideTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
            showSelectedName = false
            hideTimer = nil
        }
    }
    
    // MARK: - Helper Functions
    private func getSelectedListName() -> String {
        if currentSelectedIndex == 0 {
            return "All Habits"
        } else if currentSelectedIndex <= habitLists.count {
            return habitLists[currentSelectedIndex - 1].name
        }
        return "Lists"
    }
    
    private func getSelectedListNameWidth() -> CGFloat {
        let text = getSelectedListName()
        let font = UIFont.systemFont(ofSize: 12, weight: .medium)
        let attributes = [NSAttributedString.Key.font: font]
        let size = text.size(withAttributes: attributes)
        return size.width + 48 // icon + padding
    }
    
    private func getAllHabitsCount() -> Int {
        return habitLists.reduce(0) { total, list in
            total + list.habitCount
        }
    }
    
    private func isAllHabitsSelected() -> Bool {
        return currentSelectedIndex == 0
    }
    
    private func isListSelected(_ index: Int) -> Bool {
        return currentSelectedIndex == index
    }
}

// MARK: - Minimal List Item Component
struct MinimalListItem: View {
    let icon: String
    let title: String
    let color: Color
    let habitCount: Int
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Clean icon
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(color)
                    .frame(width: 20, height: 20)
                
                // Clean text - no animations
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.customFont("Lexend", .medium, 14))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text("\(habitCount) habit\(habitCount != 1 ? "s" : "")")
                        .font(.customFont("Lexend", .regular, 11))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Minimal selection indicator
                if isSelected {
                    Circle()
                        .fill(color)
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? color.opacity(0.08) : Color.clear)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
        )
    }
}

// MARK: - Button Styles
struct MinimalistButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Instant Collapse Button Style
struct InstantCollapseButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .opacity(configuration.isPressed ? 0.6 : 1.0)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}

// MARK: - Minimalist Glass Background Modifier
extension View {
    func minimalistGlassBackground(backgroundColor: Color? = nil, cornerRadius: CGFloat = 20) -> some View {
        self.background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(backgroundColor ?? .clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(.white.opacity(0.15), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Data Structure (unchanged)
struct HabitListData: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let color: Color
    let habitCount: Int
}

// MARK: - Preview
struct ExpandingGlassMenuPreview: View {
    @State private var selectedListIndex = 0
    
    private let sampleHabitLists: [HabitListData] = [
        HabitListData(name: "Health & Fitness", icon: "heart.fill", color: .red, habitCount: 5),
        HabitListData(name: "Work & Productivity", icon: "briefcase.fill", color: .blue, habitCount: 3),
        HabitListData(name: "Learning", icon: "book.fill", color: .green, habitCount: 4),
        HabitListData(name: "Personal Care", icon: "sparkles", color: .purple, habitCount: 2),
        HabitListData(name: "Social", icon: "person.2.fill", color: .orange, habitCount: 3)
    ]
    
    var body: some View {
        ZStack {
            // Clean background
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.05),
                    Color.purple.opacity(0.03),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                HStack {
                    Spacer()
                    
                    ExpandingGlassMenuButton(
                        currentStatsListIcon: currentIcon,
                        currentStatsListColor: currentColor,
                        habitLists: sampleHabitLists,
                        currentSelectedIndex: selectedListIndex,
                        onListSelected: { index in
                            selectedListIndex = index
                        }
                    )
                    .padding(.trailing, 24)
                    .padding(.bottom, 120)
                }
            }
            
            // Clean info overlay
            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Statistics")
                            .font(.largeTitle.bold())
                            .foregroundColor(.primary)
                        
                        Text("Currently viewing: \(currentListName)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .animation(nil, value: currentListName) // Remove text animation
                    }
                    Spacer()
                }
                .padding(.top, 80)
                .padding(.horizontal, 24)
                
                Spacer()
            }
        }
    }
    
    private var currentIcon: String {
        if selectedListIndex == 0 {
            return "tray.full"
        } else if selectedListIndex <= sampleHabitLists.count {
            return sampleHabitLists[selectedListIndex - 1].icon
        }
        return "list.bullet"
    }
    
    private var currentColor: Color {
        if selectedListIndex == 0 {
            return .secondary
        } else if selectedListIndex <= sampleHabitLists.count {
            return sampleHabitLists[selectedListIndex - 1].color
        }
        return .secondary
    }
    
    private var currentListName: String {
        if selectedListIndex == 0 {
            return "All Habits"
        } else if selectedListIndex <= sampleHabitLists.count {
            return sampleHabitLists[selectedListIndex - 1].name
        }
        return "Unknown"
    }
}

#Preview {
    ExpandingGlassMenuPreview()
}

// MARK: - Extension for MainHabitsView (unchanged)
extension MainHabitsView {
    var menuHabitLists: [HabitListData] {
        return effectiveHabitLists.map { list in
            HabitListData(
                name: list.name ?? "Unnamed List",
                icon: list.icon ?? "list.bullet",
                color: getListColor(from: list) ?? .secondary,
                habitCount: getHabitCount(for: list)
            )
        }
    }
    
    func getHabitCount(for list: HabitList) -> Int {
        return effectiveHabits.filter { $0.habitList == list && !$0.isArchived }.count
    }
    
   var currentListIcon: String {
        if selectedListIndex == 0 {
            return "tray.full"
        } else if selectedListIndex <= effectiveHabitLists.count {
            return effectiveHabitLists[selectedListIndex - 1].icon ?? "list.bullet"
        }
        return "list.bullet"
    }
    
    var currentListColor: Color {
        if selectedListIndex == 0 {
            return .secondary
        } else if selectedListIndex <= effectiveHabitLists.count {
            return getListColor(from: effectiveHabitLists[selectedListIndex - 1]) ?? .secondary
        }
        return .secondary
    }
}
