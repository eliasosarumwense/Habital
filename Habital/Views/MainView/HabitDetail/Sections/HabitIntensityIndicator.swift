//
//  HabitIntensityIndicator.swift
//  Habital
//
//  Created by Elias Osarumwense on 30.04.25.
//

import SwiftUI

import SwiftUI

struct HabitIntensityIndicator: View {
    
    let habitIntensity: HabitIntensity?
    var condensed: Bool = false
    var offset: CGPoint = CGPoint(x: -15, y: -15) // Default offset like in your example
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var showDetails: Bool = false
    @State private var animateIn: Bool = false
    
    // Properties for when there's no intensity
    private var noIntensityColor: Color {
        colorScheme == .dark ? Color.gray.opacity(0.6) : Color.gray.opacity(0.5)
    }
    
    private var displayColor: Color {
        habitIntensity?.color ?? noIntensityColor
    }
    
    private var displayTitle: String {
        habitIntensity?.title ?? "No Intensity"
    }
    
    private var displayDescription: String {
        habitIntensity?.description ?? "No intensity level has been set."
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Styled title with rounded rectangle background
            HStack(spacing: 6) {
                // Circle with chevron icon
                ZStack {
                    Circle()
                        .fill(displayColor)
                        .frame(width: 14, height: 14)
                        .shadow(color: colorScheme == .dark ?
                            .black.opacity(0.3) :
                            displayColor.opacity(0.5),
                            radius: 1, x: 0, y: 1)
                    
                    Image(systemName: "chevron.up")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(colorScheme == .dark ? .black : .white)
                }
                
                // Title text
                Text(displayTitle)
                    .font(.customFont("Lexend", .medium, 13))
                    .foregroundColor(habitIntensity == nil ? .gray : .primary)
            }
            .padding(.vertical, 3)
            .padding(.horizontal, 6)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(displayColor.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(displayColor.opacity(0.2), lineWidth: 0.5)
                    )
            )
            .opacity(habitIntensity == nil ? 0.8 : 1.0)
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showDetails.toggle()
                }
            }
            
            // Description popup that overlays (doesn't push other content)
            if showDetails {
                VStack(alignment: .leading, spacing: 3) {
                    Text(displayDescription)
                        //.font(.system(size: condensed ? 10 : 11))
                        .font(.customFont("Lexend", .medium, condensed ? 8 : 9))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // Dismiss button
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showDetails = false
                        }
                    }) {
                        Text("Dismiss")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(displayColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(displayColor.opacity(0.1))
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.top, 2)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
                )
                .offset(x: 0, y: 25) // Position below the title (adjust as needed)
                .transition(.scale(scale: 0.95, anchor: .top).combined(with: .opacity))
                .zIndex(100) // Ensure it's on top
            }
        }
        //.offset(x: offset.x, y: offset.y)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showDetails)
    }
}

// Example of how to use this component
struct HabitIntensityIndicatorPreview: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.gray.opacity(0.1).edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                // All intensity levels
                ForEach(HabitIntensity.allCases) { intensity in
                    HabitIntensityIndicator(habitIntensity: intensity)
                }
                
                // No intensity example
                HabitIntensityIndicator(habitIntensity: nil)
                    .padding(.top, 20)
                
                // Custom offset example
                HabitIntensityIndicator(
                    habitIntensity: .extreme,
                    offset: CGPoint(x: 0, y: 0)
                )
            }
            .padding()
        }
    }
}
