//
//  ThinNavBar.swift
//  Habital
//
//  Created by Elias Osarumwense on 16.05.25.
//

import SwiftUI

import SwiftUI

struct UltraThinMaterialNavBar: View {
    var title: String
    var leftIcon: String?
    var rightIcon: String?
    var leftAction: (() -> Void)?
    var rightAction: (() -> Void)?
    var titleColor: Color = .primary
    var leftIconColor: Color = .primary
    var rightIconColor: Color = .primary
    var backgroundColor: Color? = nil
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            /*
            // Background material
            if let backgroundColor = backgroundColor {
                Rectangle()
                    .fill(backgroundColor)
                    .frame(height: 55)
            } else {
                VibrancyBlurView(blurStyle: .prominent, vibrancy: .fill)
                        .frame(height: 55)
            }
            */
            // Content
            HStack(spacing: 0) {
                // Left button
                if let leftIcon = leftIcon, let leftAction = leftAction {
                    Button(action: {
                        triggerHaptic(.impactMedium) // Add haptic feedback
                        leftAction()
                    }) {
                        Image(systemName: leftIcon)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(leftIconColor)
                            .padding(8)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .contentShape(Circle())
                    }
                    .padding(.leading, 30)
                } else {
                    Spacer(minLength: 60)
                }
                
                Spacer()
                
                // Title
                Text(title)
                    .customFont("Lexend", .semiBold, 17)
                    .foregroundColor(titleColor)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, 8)
                
                Spacer()
                
                // Right button
                if let rightIcon = rightIcon, let rightAction = rightAction {
                    Button(action: {
                        triggerHaptic(.impactMedium) // Add haptic feedback
                        rightAction()
                    }) {
                        Image(systemName: rightIcon)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(rightIconColor)
                            .padding(8)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .contentShape(Circle())
                    }
                    .padding(.trailing, 30)
                } else {
                    Spacer(minLength: 60)
                }
            }
            .frame(height: 55)
        }
    }
}

// Usage example with preview
struct UltraThinMaterialNavBar_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Light mode with both buttons
            VStack {
                UltraThinMaterialNavBar(
                    title: "Sheet Title",
                    leftIcon: "xmark",
                    rightIcon: "checkmark",
                    leftAction: {},
                    rightAction: {},
                    titleColor: .primary,
                    leftIconColor: .red,
                    rightIconColor: .green
                )
                
                Spacer()
            }
            .previewDisplayName("Light Mode - Custom Colors")
            
            // Dark mode with left button only
            VStack {
                UltraThinMaterialNavBar(
                    title: "Sheet Title",
                    leftIcon: "arrow.left",
                    leftAction: {},
                    titleColor: .white,
                    leftIconColor: .blue
                )
                
                Spacer()
            }
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode - Left Button Only")
            
            // Example in a sheet context
            ZStack {
                Color.gray.opacity(0.3).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    UltraThinMaterialNavBar(
                        title: "Settings",
                        leftIcon: "xmark",
                        rightIcon: "gear",
                        leftAction: {},
                        rightAction: {},
                        titleColor: .purple,
                        leftIconColor: .orange,
                        rightIconColor: .blue
                    )
                    
                    // Sheet content would go here
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.white.opacity(0.8))
                        .padding()
                    
                    Spacer()
                }
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.regularMaterial)
                )
                .padding(.top, 40)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .previewDisplayName("Sheet Example")
            
            // Example with custom background color
            VStack {
                UltraThinMaterialNavBar(
                    title: "Custom Background",
                    leftIcon: "arrow.left",
                    rightIcon: "star.fill",
                    leftAction: {},
                    rightAction: {},
                    titleColor: .white,
                    leftIconColor: .white,
                    rightIconColor: .yellow,
                    backgroundColor: .blue.opacity(0.8)
                )
                
                Spacer()
            }
            .previewDisplayName("Custom Background")
        }
    }
}

struct VibrancyBlurView: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style
    var vibrancy: UIVibrancyEffectStyle
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        // Create the blur effect
        let blurEffect = UIBlurEffect(style: blurStyle)
        let blurView = UIVisualEffectView(effect: blurEffect)
        
        // Add vibrancy effect which enhances colors
        let vibrancyEffect = UIVibrancyEffect(blurEffect: blurEffect, style: vibrancy)
        let vibrancyView = UIVisualEffectView(effect: vibrancyEffect)
        vibrancyView.frame = .infinite
        
        // Add the vibrancy view to the blur view
        blurView.contentView.addSubview(vibrancyView)
        
        return blurView
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        // Update if needed
    }
}
