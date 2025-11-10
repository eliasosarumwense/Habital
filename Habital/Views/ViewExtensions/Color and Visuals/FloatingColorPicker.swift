//
//  FloatingColorPicker.swift
//  Habital
//
//  Created by Elias Osarumwense on 01.11.25.
//

import SwiftUI

// MARK: - FloatingColorPicker

struct FloatingColorPicker: View {
    let direction: ButtonDirection
    let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple]

    @Binding var selectedColor: Color
    @State private var showButtons = true
    @State private var rotation: Double = 0
    @State private var showColorPicker = false

    // Layout
    private let itemSize: CGFloat = 32
    private let itemRadius: CGFloat = 10
    private let spacing: CGFloat = 45
    private let collapsedNudge: CGFloat = 20

    var body: some View {
        ZStack {
            // Color choices
            ForEach(colors.indices, id: \.self) { index in
                let color = colors[index]

                RoundedRectangle(cornerRadius: itemRadius)
                    .fill(color)
                    .frame(width: itemSize, height: itemSize)
                    .overlay {
                        if selectedColor == color {
                            RoundedRectangle(cornerRadius: itemRadius)
                                .stroke(Color.white, lineWidth: 3)
                        }
                    }
                    // fun spin on the selected one
                    .rotationEffect(selectedColor == color ? .degrees(rotation) : .degrees(0), anchor: .center)
                    // interaction
                    .onTapGesture {
                        selectedColor = color
                        
                        // Haptic feedback
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            rotation += 180
                        }
                        // Keep buttons open - removed auto-close
                    }
                    // entrance / exit
                    .scaleEffect(showButtons ? 1 : 0)
                    .opacity(showButtons ? 1 : 0)
                    .offset(direction.offset(
                        forIndex: index,
                        spacing: spacing,
                        collapsedNudge: collapsedNudge,
                        expanded: showButtons
                    ))
                    .animation(.easeOut.delay(Double(index) * 0.1), value: showButtons)
            }
            
            // Apple Color Picker Button
            RoundedRectangle(cornerRadius: itemRadius)
                .fill(Color.gray.opacity(0.3))
                .frame(width: itemSize, height: itemSize)
                .overlay {
                    Image(systemName: "eyedropper.halffull")
                        .foregroundColor(.primary)
                        .font(.system(size: 14, weight: .medium))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: itemRadius)
                        .stroke(Color.primary.opacity(0.3), lineWidth: 1)
                }
                .onTapGesture {
                    // Haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                    
                    showColorPicker = true
                }
                .scaleEffect(showButtons ? 1 : 0)
                .opacity(showButtons ? 1 : 0)
                .offset(direction.offset(
                    forIndex: colors.count, // Position after all color swatches
                    spacing: spacing,
                    collapsedNudge: collapsedNudge,
                    expanded: showButtons
                ))
                .animation(.easeOut.delay(Double(colors.count) * 0.1), value: showButtons)
                .sheet(isPresented: $showColorPicker) {
                    ColorPicker("Select Color", selection: $selectedColor)
                        .presentationDetents([.medium])
                        .presentationDragIndicator(.visible)
                }

            // Main opener button
            OpenButton
        }
        // Rotate the whole control so the fan opens toward the chosen direction
        .rotationEffect(direction.angle, anchor: .center)
    }

    private var OpenButton: some View {
        RoundedRectangle(cornerRadius: itemRadius)
            .fill(selectedColor)
            .frame(width: itemSize, height: itemSize)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
            .onTapGesture {
                // Haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
                
                withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                    showButtons.toggle()
                }
            }
    }
}

// MARK: - Direction

enum ButtonDirection {
    case left, right, top, bottom

    var angle: Angle {
        switch self {
        case .left:   return .degrees(-90)
        case .right:  return .degrees(90)
        case .top:    return .degrees(0)
        case .bottom: return .degrees(180)
        }
    }

    /// Compute offset for each color swatch given the direction.
    func offset(forIndex index: Int,
                spacing: CGFloat,
                collapsedNudge: CGFloat,
                expanded: Bool) -> CGSize {
        let step = CGFloat(index + 1) * spacing
        // open "up" in the unrotated coordinate space; rotationEffect on the parent handles the direction
        let openOffset = CGSize(width: 0, height: -step)
        let closedOffset = CGSize(width: 0, height: -collapsedNudge)
        return expanded ? openOffset : closedOffset
    }
}

// MARK: - Example usage
/*

#Preview {
    FloatingColorPicker()
}
*/
