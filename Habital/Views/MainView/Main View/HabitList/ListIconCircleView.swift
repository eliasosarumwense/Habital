//
//  ListIconCircleView.swift
//  Habital
//
//  Created by Elias Osarumwense on 13.04.25.
//

import SwiftUI

struct ListIconCircleView: View {
    let icon: String?
    let color: Color
    let size: CGFloat
    
    init(icon: String?, color: Color, size: CGFloat = 28) {
        self.icon = icon
        self.color = color
        self.size = size
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: size, height: size)
            
            if let iconString = icon {
                // Check if icon is an emoji or an SF Symbol
                if iconString.first?.isEmoji ?? false {
                    Text(iconString)
                        .font(.system(size: size * 0.5))
                } else {
                    Image(systemName: iconString)
                        .foregroundColor(color)
                        .font(.system(size: size * 0.4))
                }
            } else {
                // Default icon if none is set
                Image(systemName: "list.bullet")
                    .foregroundColor(color)
                    .font(.system(size: size * 0.4))
            }
        }
    }
}

// Preview
struct ListIconCircleView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ListIconCircleView(icon: "star.fill", color: .blue)
            ListIconCircleView(icon: "🚀", color: .red)
            ListIconCircleView(icon: "heart.fill", color: .green, size: 40)
            ListIconCircleView(icon: nil, color: .purple)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
