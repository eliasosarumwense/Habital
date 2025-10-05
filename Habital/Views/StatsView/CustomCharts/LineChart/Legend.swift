//
//  Legend.swift
//  LineChart
//
//  Created by András Samu on 2019. 09. 02..
//  Copyright © 2019. András Samu. All rights reserved.
//

import SwiftUI

struct Legend: View {
    @ObservedObject var data: ChartData
    @Binding var frame: CGRect
    @Binding var hideHorizontalLines: Bool
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    var specifier: String = "%.0f"
    let padding: CGFloat = 3
    
    // Fixed values to always display
    let fixedValues: [Double] = [0, 25, 50, 75, 100]
    
    var stepWidth: CGFloat {
        if data.points.count < 2 {
            return 0
        }
        return frame.size.width / CGFloat(data.points.count-1)
    }
    
    var stepHeight: CGFloat {
        return (frame.size.height-padding) / 100.0
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(0..<5, id: \.self) { index in
                HStack(alignment: .center) {
                    Text("\(Int(fixedValues[index]))%")
                        .customFont("Lexend", .semiBold, 11)
                        .offset(x: 0, y: self.getYposition(height: index))
                        
                        .foregroundColor(Colors.LegendText)
                        
                        //.font(.caption.bold())
                    
                    // Conditional line style - no dashes at 0% (index 0)
                    self.line(atHeight: fixedValues[index], width: self.frame.width)
                        .stroke(self.colorScheme == .dark ? Colors.LegendDarkColor : Colors.LegendColor,
                                style: StrokeStyle(lineWidth: 1.5, lineCap: .round,
                                                  dash: index == 4 ? [] : [5, 10]))
                        .opacity((self.hideHorizontalLines && index != 4) ? 0 : 1)
                        .rotationEffect(.degrees(180), anchor: .center)
                        .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                        .animation(.easeOut(duration: 0.2))
                        .clipped()
                     
                }
            }
        }
    }
    
    func getYposition(height: Int) -> CGFloat {
        return (self.frame.height - (fixedValues[height] * self.stepHeight)) - (self.frame.height/2)
    }
    
    func line(atHeight: CGFloat, width: CGFloat) -> Path {
        var hLine = Path()
        hLine.move(to: CGPoint(x: 5, y: (100 - atHeight) * stepHeight))
        hLine.addLine(to: CGPoint(x: width, y: (100 - atHeight) * stepHeight))
        return hLine
    }
}

struct Legend_Previews: PreviewProvider {
    static var previews: some View {
        GeometryReader { geometry in
            Legend(data: ChartData(points: [0.2, 0.4, 1.4, 4.5]),
                  frame: .constant(geometry.frame(in: .local)),
                  hideHorizontalLines: .constant(false))
        }.frame(width: 320, height: 200)
    }
}

