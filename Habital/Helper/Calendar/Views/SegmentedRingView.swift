//
//  SegmentedRingView.swift
//  Habital
//
//  Created by Elias Osarumwense on 08.04.25.
//

import SwiftUI

struct SegmentedRing: View {
    let colors: [Color]
    let progress: Double
    let lineWidth: CGFloat
    
    var body: some View {
        ZStack {
            // If there's only one color, use a simple trimmed circle
            if colors.count == 1 {
                Circle()
                    .trim(from: 0, to: CGFloat(progress))
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [colors[0].opacity(0.7), colors[0]]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90)) // Start from top (12 o'clock)
            } else {
                // Multiple colors - create segments clockwise
                GeometryReader { geometry in
                    ZStack {
                        // Calculate how much of the circle each habit should take
                        let segmentSize = progress / Double(colors.count)
                        
                        ForEach(0..<colors.count, id: \.self) { index in
                            // Only draw segments up to the progress amount
                            if Double(index) * segmentSize < progress {
                                // Calculate start and end for this segment
                                let startAngle = Double(index) * segmentSize
                                let endAngle = min(startAngle + segmentSize, progress)
                                
                                Circle()
                                    .trim(from: CGFloat(startAngle), to: CGFloat(endAngle))
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                colors[index].opacity(0.7),
                                                colors[index]
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ),
                                        style: StrokeStyle(
                                            lineWidth: lineWidth,
                                            lineCap: endAngle >= progress ? .round : .butt
                                        )
                                    )
                                    .rotationEffect(.degrees(-90)) // Start from top (12 o'clock)
                            }
                        }
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                }
            }
        }
    }
}
