//
//  StreakbadgeView.swift
//  Habital
//
//  Created by Elias Osarumwense on 06.04.25.
//

import SwiftUI

struct StreakBadge: View {
    let streak: Int
    let isActive: Bool
    
    @State private var animationScale: CGFloat = 0
    @State private var animationRotation: Double = 0
    @State private var animationOpacity: Double = 0
    
    var body: some View {
        Group {
            if streak > 0 {
                ZStack {
                    Circle()
                        .fill(isActive ? Color.red : Color.black)
                        .frame(width: 16, height: 16)
                    
                    Text("\(streak)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                }
                .background(Circle().fill(Color.white).frame(width: 12, height: 12))
                .offset(x: 15, y: 15) // Position at bottom right of the icon
                .scaleEffect(animationScale)
                .rotationEffect(.degrees(animationRotation))
                .opacity(animationOpacity)
                .onAppear {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0.5)) {
                        animationScale = 1
                        animationRotation = 360
                        animationOpacity = 1
                    }
                }
            }
        }
    }
}
