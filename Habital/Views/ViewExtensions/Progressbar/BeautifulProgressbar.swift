//
//  BeautifulProgressbar.swift
//  Habital
//
//  Created by Elias Osarumwense on 04.04.25.
//

import SwiftUI

//
//  BeautifulProgressbar.swift
//  Habital
//
//  Created by Elias Osarumwense on 04.04.25.
//

struct BeautifulProgressBar: View {
    var progress: Double
    var color: Color = .blue
    var height: CGFloat = 12
    var showPercentage: Bool = true
    var cornerRadius: CGFloat = 8
    var totalWidth: CGFloat // Fixed total width
    
    // Animation properties
    @State private var animatedProgress: Double = 0
    
    var body: some View {
        VStack(spacing: showPercentage ? 8 : 0) {
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: totalWidth, height: height)
                
                // Progress fill with gradient
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [color.opacity(0.7), color]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: min(CGFloat(animatedProgress) * totalWidth, totalWidth), height: height)
                
                // Shine effect
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.white.opacity(0.3), Color.white.opacity(0)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: min(CGFloat(animatedProgress) * totalWidth, totalWidth), height: height/2)
                    .offset(y: -height/4)
                    .mask(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .frame(width: min(CGFloat(animatedProgress) * totalWidth, totalWidth), height: height)
                    )
            }
            
            // Percentage text
            if showPercentage {
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .frame(width: totalWidth, alignment: .trailing)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 1.0, dampingFraction: 0.8)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { newValue in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animatedProgress = newValue
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        Text("Progress Bar Examples")
            .font(.headline)
        
        // 25% progress
        BeautifulProgressBar(
            progress: 0.25,
            color: .blue,
            height: 12,
            showPercentage: true,
            cornerRadius: 8,
            totalWidth: 270
        )
        
        // 90% progress
        BeautifulProgressBar(
            progress: 0.9,
            color: .green,
            height: 14,
            showPercentage: true,
            cornerRadius: 6,
            totalWidth: 270
        )
        
        // 75% progress
        BeautifulProgressBar(
            progress: 0.75,
            color: .purple,
            height: 16,
            showPercentage: true,
            cornerRadius: 10,
            totalWidth: 270
        )
        
        // 90% progress without percentage
        BeautifulProgressBar(
            progress: 0.9,
            color: .orange,
            height: 20,
            showPercentage: false,
            cornerRadius: 12,
            totalWidth: 270
        )
    }
    .padding()
}
