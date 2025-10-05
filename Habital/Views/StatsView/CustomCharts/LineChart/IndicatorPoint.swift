//
//  IndicatorPoint.swift
//  LineChart
//
//  Created by András Samu on 2019. 09. 03..
//  Copyright © 2019. András Samu. All rights reserved.
//

import SwiftUI

struct IndicatorPoint: View {
    var body: some View {
        ZStack{
            Circle()
                .fill(.primary)
            Circle()
                .stroke(Color.white, style: StrokeStyle(lineWidth: 2))
        }
        .frame(width: 12, height: 12)
        .shadow(color: Colors.LegendColor, radius: 3, x: 0, y: 0)
    }
}

struct IndicatorPoint_Previews: PreviewProvider {
    static var previews: some View {
        IndicatorPoint()
    }
}
