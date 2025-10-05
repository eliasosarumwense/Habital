import SwiftUI

import SwiftUI

// MARK: - Reusable Gradient Styles

/// A collection of reusable gradient styles for text and other views
struct GradientStyles {
    
    /// Primary gradient from full opacity to 50% opacity
    static let primary = LinearGradient(
        colors: [Color.primary, Color.primary.opacity(0.5)],
        startPoint: .top,
        endPoint: .bottom
    )
    
    /// Accent color gradient
    static let accent = LinearGradient(
        colors: [Color.accentColor, Color.accentColor.opacity(0.5)],
        startPoint: .top,
        endPoint: .bottom
    )
    
    /// Blue gradient
    static let blue = LinearGradient(
        colors: [Color.blue, Color.blue.opacity(0.5)],
        startPoint: .top,
        endPoint: .bottom
    )
    
    /// Green gradient
    static let green = LinearGradient(
        colors: [Color.green, Color.green.opacity(0.5)],
        startPoint: .top,
        endPoint: .bottom
    )
    
    /// Purple gradient
    static let purple = LinearGradient(
        colors: [Color.purple, Color.purple.opacity(0.5)],
        startPoint: .top,
        endPoint: .bottom
    )
    
    /// Orange gradient
    static let orange = LinearGradient(
        colors: [Color.orange, Color.orange.opacity(0.5)],
        startPoint: .top,
        endPoint: .bottom
    )
    
    /// Red gradient
    static let red = LinearGradient(
        colors: [Color.red, Color.red.opacity(0.5)],
        startPoint: .top,
        endPoint: .bottom
    )
    
    // MARK: - Custom Color Gradients
    /// Create a top-to-bottom gradient with any color
    static func topToBottom(color: Color, endOpacity: Double = 0.5) -> LinearGradient {
        CustomGradient.topToBottom(color: color, endOpacity: endOpacity)
    }
    
    /// Create a leading-to-trailing gradient with any color
    static func leadingToTrailing(color: Color, endOpacity: Double = 0.5) -> LinearGradient {
        CustomGradient.leadingToTrailing(color: color, endOpacity: endOpacity)
    }
    
    /// Create a diagonal gradient with any color
    static func diagonal(color: Color, endOpacity: Double = 0.5) -> LinearGradient {
        CustomGradient.diagonal(color: color, endOpacity: endOpacity)
    }
}

// MARK: - Custom Gradient Builder

/// Create custom gradients with any color
struct CustomGradient {
    
    /// Creates a top-to-bottom gradient with specified color and opacity
    static func topToBottom(color: Color, endOpacity: Double = 0.5) -> LinearGradient {
        LinearGradient(
            colors: [color, color.opacity(endOpacity)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    /// Creates a leading-to-trailing gradient with specified color and opacity
    static func leadingToTrailing(color: Color, endOpacity: Double = 0.5) -> LinearGradient {
        LinearGradient(
            colors: [color, color.opacity(endOpacity)],
            startPoint: .leading,
            endPoint: .trailing
            )
    }
    
    /// Creates a diagonal gradient (top-leading to bottom-trailing)
    static func diagonal(color: Color, endOpacity: Double = 0.5) -> LinearGradient {
        LinearGradient(
            colors: [color, color.opacity(endOpacity)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Preview with All Gradients

struct GradientStylesPreview: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    
                    // MARK: - Predefined Gradients Section
                    VStack(spacing: 15) {
                        Text("Predefined Gradients")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
                            
                            GradientCard(title: "Primary", gradient: GradientStyles.primary)
                            GradientCard(title: "Accent", gradient: GradientStyles.accent)
                            GradientCard(title: "Blue", gradient: GradientStyles.blue)
                            GradientCard(title: "Green", gradient: GradientStyles.green)
                            GradientCard(title: "Purple", gradient: GradientStyles.purple)
                            GradientCard(title: "Orange", gradient: GradientStyles.orange)
                            GradientCard(title: "Red", gradient: GradientStyles.red)
                        }
                    }
                    
                    Divider()
                        .padding(.vertical)
                    
                    // MARK: - Custom Gradients Section
                    VStack(spacing: 15) {
                        Text("Custom Gradients")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                        
                        VStack(spacing: 20) {
                            
                            // Top to Bottom variations
                            Text("Top to Bottom")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
                                GradientCard(title: "Mint", gradient: CustomGradient.topToBottom(color: .mint))
                                GradientCard(title: "Pink", gradient: CustomGradient.topToBottom(color: .pink))
                                GradientCard(title: "Cyan", gradient: CustomGradient.topToBottom(color: .cyan))
                                GradientCard(title: "Yellow", gradient: CustomGradient.topToBottom(color: .yellow))
                            }
                            
                            // Leading to Trailing variations
                            Text("Leading to Trailing")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .padding(.top)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
                                GradientCard(title: "Indigo →", gradient: CustomGradient.leadingToTrailing(color: .indigo))
                                GradientCard(title: "Teal →", gradient: CustomGradient.leadingToTrailing(color: .teal))
                                GradientCard(title: "Brown →", gradient: CustomGradient.leadingToTrailing(color: .brown))
                                GradientCard(title: "Gray →", gradient: CustomGradient.leadingToTrailing(color: .gray))
                            }
                            
                            // Diagonal variations
                            Text("Diagonal")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .padding(.top)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
                                GradientCard(title: "Purple ↘", gradient: CustomGradient.diagonal(color: .purple))
                                GradientCard(title: "Orange ↘", gradient: CustomGradient.diagonal(color: .orange))
                                GradientCard(title: "Green ↘", gradient: CustomGradient.diagonal(color: .green, endOpacity: 0.3))
                                GradientCard(title: "Red ↘", gradient: CustomGradient.diagonal(color: .red, endOpacity: 0.7))
                            }
                        }
                    }
                    
                    Divider()
                        .padding(.vertical)
                    
                    // MARK: - View Extensions Demo
                    VStack(spacing: 15) {
                        Text("View Extensions Demo")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                        
                        VStack(spacing: 10) {
                            Text("Using .primaryGradient()")
                                .font(.title3)
                                .primaryGradient()
                            
                            Text("Using .accentGradient()")
                                .font(.title3)
                                .accentGradient()
                            
                            Text("Using .customGradient()")
                                .font(.title3)
                                .customGradient(color: .mint, endOpacity: 0.4)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Gradient Styles")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Helper Card View
struct GradientCard: View {
    let title: String
    let gradient: LinearGradient
    
    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 12)
                .fill(gradient)
                .frame(height: 80)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }
}

// MARK: - Preview Provider
#Preview {
    GradientStylesPreview()
}

// MARK: - View Extension for Easy Access

extension View {
    /// Apply primary gradient style
    func primaryGradient() -> some View {
        self.foregroundStyle(GradientStyles.primary)
    }
    
    /// Apply accent gradient style
    func accentGradient() -> some View {
        self.foregroundStyle(GradientStyles.accent)
    }
    
    /// Apply custom gradient style
    func customGradient(color: Color, endOpacity: Double = 0.5) -> some View {
        self.foregroundStyle(CustomGradient.topToBottom(color: color, endOpacity: endOpacity))
    }
}
