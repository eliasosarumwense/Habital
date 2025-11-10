//
//  OldFloatingColorPicker.swift
//  Habital
//
//  Created by Elias Osarumwense on 01.11.25.
//

/*
 import SwiftUI

 // MARK: - FloatingColorPicker

 struct FloatingColorPicker: View {
     let direction: ButtonDirection
     let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple]

     @Binding var selectedColor: Color
     @State private var showButtons = false
     @State private var rotation: Double = 0

     // Layout
     private let itemSize: CGFloat = 40
     private let itemRadius: CGFloat = 12
     private let spacing: CGFloat = 55
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
                         withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                             rotation += 180
                         }
                         // auto close after a moment
                         DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                             withAnimation(.easeInOut) { showButtons = false }
                         }
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

 struct ContentView: View {
     @State private var picked: Color = .blue

     var body: some View {
         ZStack {
             picked.ignoresSafeArea()
             FloatingColorPicker(direction: .bottom, selectedColor: $picked)
                 .padding(40)
         }
     }
 }

 #Preview {
     ContentView()
 }

 */
