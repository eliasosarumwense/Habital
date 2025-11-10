//
//  PieChartRow.swift
//  ChartView
//
//  Created by András Samu on 2019. 06. 12..
//  Copyright © 2019. András Samu. All rights reserved.
//

import SwiftUI

public struct PieChartRow: View {
    var data: [Double]
    var colors: [Color]  // New array of colors
    var backgroundColor: Color
    var accentColor: Color
    var slices: [PieSlice] {
        var tempSlices:[PieSlice] = []
        var lastEndDeg:Double = 0
        let maxValue = data.reduce(0, +)
        for (i, slice) in data.enumerated() {
            let normalized:Double = Double(slice)/Double(maxValue)
            let startDeg = lastEndDeg
            let endDeg = lastEndDeg + (normalized * 360)
            lastEndDeg = endDeg
            
            // Get color for this slice (use accentColor as fallback)
            let color = i < colors.count ? colors[i] : accentColor
            
            tempSlices.append(PieSlice(startDeg: startDeg, endDeg: endDeg, value: slice, normalizedValue: normalized, color: color))
        }
        return tempSlices
    }
    
    @Binding var showValue: Bool
    @Binding var currentValue: Double
    
    @State private var currentTouchedIndex = -1 {
        didSet {
            if oldValue != currentTouchedIndex {
                showValue = currentTouchedIndex != -1
                currentValue = showValue ? slices[currentTouchedIndex].value : 0
            }
        }
    }
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(self.slices.indices, id: \.self) { i in
                    PieChartCell(
                        rect: geometry.frame(in: .local),
                        startDeg: self.slices[i].startDeg,
                        endDeg: self.slices[i].endDeg,
                        index: i,
                        backgroundColor: self.backgroundColor,
                        accentColor: self.slices[i].color  // Use slice-specific color
                    )
                    .scaleEffect(self.currentTouchedIndex == i ? 1.1 : 1)
                    .animation(.spring(), value: self.currentTouchedIndex)
                }
            }
            .gesture(DragGesture()
                .onChanged({ value in
                    let rect = geometry.frame(in: .local)
                    let isTouchInPie = isPointInCircle(point: value.location, circleRect: rect)
                    if isTouchInPie {
                        let touchDegree = degree(for: value.location, inCircleRect: rect)
                        self.currentTouchedIndex = self.slices.firstIndex(where: { $0.startDeg < touchDegree && $0.endDeg > touchDegree }) ?? -1
                    } else {
                        self.currentTouchedIndex = -1
                    }
                })
                .onEnded({ value in
                    self.currentTouchedIndex = -1
                }))
        }
    }
}


