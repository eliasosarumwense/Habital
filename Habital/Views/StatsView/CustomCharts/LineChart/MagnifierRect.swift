//
//  MagnifierRect.swift
//
//
//  Created by Samu András on 2020. 03. 04..
//

import SwiftUI

public struct MagnifierRect: View {
    @Binding var currentNumber: Double
    var valueSpecifier: String
    var contextLabel: String? // Optional label to display date/day/week information
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    
    public var body: some View {
        // The entire component in a single ZStack with animation disabled for the content
        ZStack {
            // Modern glass morphism background
            modernGlassBackground
            
            // Fixed-position value text that doesn't animate
            Text("\(self.currentNumber, specifier: valueSpecifier)%")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .offset(x: 0, y: -90)
                .foregroundStyle(.primary)
                .fixedSize()
                .animation(nil, value: currentNumber) // Explicitly disable animation for value changes
            
            // Context label display with animation disabled
            if let label = contextLabel {
                Text(label)
                    .customFont("Lexend", .medium, 13)
                    .offset(x: 0, y: -70)
                    .foregroundStyle(.secondary)
                    .fixedSize()
                    .animation(nil, value: label) // Explicitly disable animation for label changes
            }
        }
        .offset(x: 0, y: -15)
    }
    
    // MARK: - Modern Glass Background (Chart-Transparent)
    
    @ViewBuilder
    private var modernGlassBackground: some View {
        ZStack {
            // Minimal translucent background - chart shows through clearly
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    colorScheme == .dark
                        ? Color.black.opacity(0.15)  // Very subtle dark overlay
                        : Color.white.opacity(0.25)  // Very subtle white overlay
                )
                .frame(width: 60, height: 250)
                .background(
                    // Ultra-light material for subtle depth
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .opacity(0.3)  // Much more transparent
                        .frame(width: 60, height: 250)
                )
            
            // Subtle glass reflection only at the edges
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            // Very light top highlight
                            Color.white.opacity(colorScheme == .dark ? 0.08 : 0.15),
                            // Completely clear middle - chart is fully visible
                            Color.clear,
                            Color.clear,
                            Color.clear,
                            Color.clear,
                            // Very subtle bottom reflection
                            Color.black.opacity(colorScheme == .dark ? 0.05 : 0.02)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 60, height: 250)
                .blendMode(.overlay)
            
            // Clean glass edge with sharp definition but transparency
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(colorScheme == .dark ? 0.4 : 0.6),
                            Color.white.opacity(colorScheme == .dark ? 0.2 : 0.4),
                            Color.clear,
                            Color.white.opacity(colorScheme == .dark ? 0.15 : 0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.2
                )
                .frame(width: 60, height: 250)
            
            // Minimal inner highlight for glass definition
            RoundedRectangle(cornerRadius: 15)
                .strokeBorder(
                    Color.white.opacity(colorScheme == .dark ? 0.15 : 0.25),
                    lineWidth: 0.5
                )
                .frame(width: 58, height: 248)
        }
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.25 : 0.08),
            radius: 8,
            x: 0,
            y: 4
        )
        .shadow(
            color: Color.white.opacity(colorScheme == .dark ? 0.03 : 0.2),
            radius: 1,
            x: 0,
            y: -1
        )
    }
}

// MARK: - Alternative Minimal Glass Style (Chart-Transparent)

public struct MinimalMagnifierRect: View {
    @Binding var currentNumber: Double
    var valueSpecifier: String
    var contextLabel: String?
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    
    public var body: some View {
        ZStack {
            // Highly transparent glass background for charts
            ZStack {
                // Extremely subtle base material
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .opacity(0.2)  // Very transparent
                    .frame(width: 60, height: 250)
                
                // Minimal glass overlay - chart visibility priority
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.05 : 0.1),
                                Color.clear,
                                Color.clear,
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 60, height: 250)
                    .blendMode(.overlay)
                
                // Clean edge highlight - defines shape without blocking view
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        Color.white.opacity(colorScheme == .dark ? 0.25 : 0.4),
                        lineWidth: 1.0
                    )
                    .frame(width: 60, height: 250)
            }
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0.15 : 0.05),
                radius: 4,
                x: 0,
                y: 2
            )
            
            // Value text with subtle background for readability
            ZStack {
                // Text background for better readability over chart
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        colorScheme == .dark
                            ? Color.black.opacity(0.4)
                            : Color.white.opacity(0.7)
                    )
                    .frame(width: 45, height: 20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(
                                Color.white.opacity(colorScheme == .dark ? 0.2 : 0.3),
                                lineWidth: 0.5
                            )
                    )
                
                Text("\(self.currentNumber, specifier: valueSpecifier)%")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .fixedSize()
            }
            .offset(x: 0, y: -90)
            .animation(nil, value: currentNumber)
            
            // Context label with subtle background
            if let label = contextLabel {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            colorScheme == .dark
                                ? Color.black.opacity(0.3)
                                : Color.white.opacity(0.6)
                        )
                        .frame(width: 50, height: 16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(
                                    Color.white.opacity(colorScheme == .dark ? 0.15 : 0.25),
                                    lineWidth: 0.5
                                )
                        )
                    
                    Text(label)
                        .customFont("Lexend", .medium, 13)
                        .foregroundStyle(.secondary)
                        .fixedSize()
                }
                .offset(x: 0, y: -70)
                .animation(nil, value: label)
            }
        }
        .offset(x: 0, y: -15)
    }
}

// MARK: - Usage Extension

public extension View {
    /// Apply modern glass magnifier style
    func modernGlassMagnifier(
        currentNumber: Binding<Double>,
        valueSpecifier: String = "%.1f",
        contextLabel: String? = nil,
        style: MagnifierStyle = .full
    ) -> some View {
        self.overlay(
            Group {
                switch style {
                case .full:
                    MagnifierRect(
                        currentNumber: currentNumber,
                        valueSpecifier: valueSpecifier,
                        contextLabel: contextLabel
                    )
                case .minimal:
                    MinimalMagnifierRect(
                        currentNumber: currentNumber,
                        valueSpecifier: valueSpecifier,
                        contextLabel: contextLabel
                    )
                }
            }
        )
    }
}

public enum MagnifierStyle {
    case full       // Complete glass effect
    case minimal    // Clean minimal glass
}

// Preview provider for SwiftUI canvas
struct MagnifierRect_Previews: PreviewProvider {
    @State static var animatePreview = false
    @State static var currentValue: Double = 42.5
    
    static var previews: some View {
        Group {
            // Light mode preview with both styles
            VStack(spacing: 40) {
                Text("Modern Glass Magnifiers")
                    .font(.title2.weight(.bold))
                    .padding(.bottom, 20)
                
                HStack(spacing: 30) {
                    VStack {
                        Text("Full Glass")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                        
                        MagnifierRect(
                            currentNumber: .constant(animatePreview ? 99.9 : 42.5),
                            valueSpecifier: "%.1f",
                            contextLabel: "Monday"
                        )
                    }
                    
                    VStack {
                        Text("Minimal Glass")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                        
                        MinimalMagnifierRect(
                            currentNumber: .constant(animatePreview ? 87.3 : 67.8),
                            valueSpecifier: "%.1f",
                            contextLabel: "Tuesday"
                        )
                    }
                }
                .offset(x: animatePreview ? 50 : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: animatePreview)
                
                Button("Animate") {
                    animatePreview.toggle()
                }
                .buttonStyle(.borderedProminent)
            }
            .preferredColorScheme(.light)
            .previewDisplayName("Light Mode")
            
            // Dark mode preview
            HStack(spacing: 30) {
                MagnifierRect(
                    currentNumber: .constant(75.2),
                    valueSpecifier: "%.1f",
                    contextLabel: "Wednesday"
                )
                
                MinimalMagnifierRect(
                    currentNumber: .constant(91.7),
                    valueSpecifier: "%.1f",
                    contextLabel: "Thursday"
                )
            }
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
        }
        .padding(50)
        .background(Color(.systemBackground))
        .previewLayout(.sizeThatFits)
    }
}
