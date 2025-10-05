import SwiftUI

// MARK: - Models
struct League: Identifiable {
    let id = UUID()
    let name: String
    let abbreviation: String
    let icon: String
    let color: Color
}

// MARK: - Main View
struct AppleSportsMenuView: View {
    @State private var isExpanded = false
    @State private var selectedView: ViewOption = .myLeagues
    @Namespace private var animation
    
    enum ViewOption: String, CaseIterable {
        case myTeams = "My Teams"
        case myLeagues = "My Leagues"
        
        // Individual leagues
        case nfl = "NFL"
        case nba = "NBA"
        case mlb = "MLB"
        case nhl = "NHL"
        case premierLeague = "Premier League"
        case laLiga = "La Liga"
        case serieA = "Serie A"
        case bundesliga = "Bundesliga"
        case mls = "MLS"
    }
    
    let leagues: [ViewOption: League] = [
        .nfl: League(name: "NFL", abbreviation: "NFL", icon: "football.fill", color: .red),
        .nba: League(name: "NBA", abbreviation: "NBA", icon: "basketball.fill", color: .orange),
        .mlb: League(name: "MLB", abbreviation: "MLB", icon: "baseball.fill", color: .blue),
        .nhl: League(name: "NHL", abbreviation: "NHL", icon: "hockey.puck.fill", color: .black),
        .premierLeague: League(name: "Premier League", abbreviation: "PL", icon: "soccerball", color: .purple),
        .laLiga: League(name: "La Liga", abbreviation: "LIGA", icon: "soccerball", color: .red),
        .serieA: League(name: "Serie A", abbreviation: "SA", icon: "soccerball", color: .blue),
        .bundesliga: League(name: "Bundesliga", abbreviation: "BL", icon: "soccerball", color: .red),
        .mls: League(name: "MLS", abbreviation: "MLS", icon: "soccerball", color: .red)
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Content
                    ScrollView {
                        VStack(spacing: 20) {
                            Text(selectedView.rawValue)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                                .padding(.top)
                            
                            // Placeholder game cards
                            ForEach(0..<3) { _ in
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(UIColor.secondarySystemFill))
                                    .frame(height: 100)
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    // Expanding Button
                    ExpandingMenuButton(
                        isExpanded: $isExpanded,
                        selectedView: $selectedView,
                        leagues: leagues,
                        animation: animation
                    )
                }
            }
        }
    }
}

// MARK: - Expanding Menu Button
struct ExpandingMenuButton: View {
    @Binding var isExpanded: Bool
    @Binding var selectedView: AppleSportsMenuView.ViewOption
    let leagues: [AppleSportsMenuView.ViewOption: League]
    let animation: Namespace.ID
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            // Button/Container
            VStack(spacing: 0) {
                // Header Button
                Button(action: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0)) {
                        isExpanded.toggle()
                    }
                }) {
                    HStack(spacing: 8) {
                        if !isExpanded {
                            Image(systemName: "line.3.horizontal")
                                .font(.system(size: 16, weight: .medium))
                                .transition(.scale.combined(with: .opacity))
                        } else {
                            Text(selectedView.rawValue)
                                .font(.system(size: 16, weight: .semibold))
                                .transition(.scale.combined(with: .opacity))
                            
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12, weight: .medium))
                                .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        }
                    }
                    .foregroundColor(.primary)
                    .padding(.horizontal, isExpanded ? 16 : 12)
                    .padding(.vertical, 8)
                    .frame(minWidth: isExpanded ? 200 : 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                
                // Expanded Content
                if isExpanded {
                    VStack(spacing: 0) {
                        Divider()
                            .padding(.horizontal, 12)
                        
                        // Menu Items
                        ScrollView {
                            VStack(spacing: 0) {
                                // Main views
                                Group {
                                    MenuItemView(
                                        title: AppleSportsMenuView.ViewOption.myTeams.rawValue,
                                        isSelected: selectedView == .myTeams
                                    ) {
                                        selectItem(.myTeams)
                                    }
                                    
                                    MenuItemView(
                                        title: AppleSportsMenuView.ViewOption.myLeagues.rawValue,
                                        isSelected: selectedView == .myLeagues
                                    ) {
                                        selectItem(.myLeagues)
                                    }
                                }
                                
                                Divider()
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 4)
                                
                                // League items
                                ForEach(Array(leagues.keys.sorted(by: { $0.rawValue < $1.rawValue })), id: \.self) { viewOption in
                                    if let league = leagues[viewOption] {
                                        MenuItemView(
                                            title: league.name,
                                            isSelected: selectedView == viewOption,
                                            icon: league.icon,
                                            iconColor: league.color
                                        ) {
                                            selectItem(viewOption)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .frame(maxHeight: 300)
                    }
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity
                    ))
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(UIColor.separator), lineWidth: 0.5)
            )
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isExpanded)
        }
    }
    
    private func selectItem(_ item: AppleSportsMenuView.ViewOption) {
        selectedView = item
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            isExpanded = false
        }
    }
}

// MARK: - Menu Item View
struct MenuItemView: View {
    let title: String
    let isSelected: Bool
    var icon: String? = nil
    var iconColor: Color = .primary
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(iconColor)
                        .frame(width: 20)
                }
                
                Text(title)
                    .font(.system(size: 15, weight: isSelected ? .medium : .regular))
                    .foregroundColor(.primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSelected ? Color.blue.opacity(0.08) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
struct AppleSportsMenuView_Previews: PreviewProvider {
    static var previews: some View {
        AppleSportsMenuView()
            .preferredColorScheme(.light)
        
        AppleSportsMenuView()
            .preferredColorScheme(.dark)
    }
}
