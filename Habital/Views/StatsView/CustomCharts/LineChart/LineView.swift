//
//  LineView.swift
//  LineChart
//
//  Created by András Samu on 2019. 09. 02..
//  Copyright © 2019. András Samu. All rights reserved.
//

import SwiftUI

public struct LineView: View {
    @ObservedObject var data: ChartData
    public var title: String?
    public var legend: String?
    public var style: ChartStyle
    public var darkModeStyle: ChartStyle
    public var valueSpecifier: String
    public var legendSpecifier: String
    public var xAxisLabels: [String]?
    public var dataLabels: [String]? // Added: detailed labels for each data point
    
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @State private var showLegend = false
    @State private var dragLocation: CGPoint = .zero
    @State private var indicatorLocation: CGPoint = .zero
    @State private var closestPoint: CGPoint = .zero
    @State private var opacity: Double = 0
    @State private var currentDataNumber: Double = 0
    @State private var hideHorizontalLines: Bool = true
    @State private var currentPointIndex: Int = -1
    
    // Normalized data for fixed 0-100 scale
    private var normalizedData: ChartData {
        let points = self.data.onlyPoints()
        let normalizedPoints: [Double]
        
        // If data has values between 0-100, use them directly
        if let min = points.min(), let max = points.max(), min >= 0, max <= 100 {
            normalizedPoints = points
        }
        // Otherwise, normalize to 0-100 scale
        else if let min = points.min(), let max = points.max(), min != max {
            normalizedPoints = points.map { point in
                return ((point - min) / (max - min)) * 100
            }
        } else {
            // Default to 50 if all values are the same
            normalizedPoints = points.map { _ in 50 }
        }
        
        return ChartData(points: normalizedPoints)
    }
    
    public init(data: [Double],
                title: String? = nil,
                legend: String? = nil,
                style: ChartStyle = Styles.lineChartStyleOne,
                valueSpecifier: String? = "%.1f",
                legendSpecifier: String? = "%.2f",
                xAxisLabels: [String]? = nil,
                dataLabels: [String]? = nil) {
        
        self.data = ChartData(points: data)
        self.title = title
        self.legend = legend
        self.style = style
        self.valueSpecifier = valueSpecifier!
        self.legendSpecifier = legendSpecifier!
        self.darkModeStyle = style.darkModeStyle != nil ? style.darkModeStyle! : Styles.lineViewDarkMode
        self.xAxisLabels = xAxisLabels
        
        // If dataLabels is provided, use it; otherwise, use xAxisLabels
        if let dataLabels = dataLabels {
            self.dataLabels = dataLabels
        } else {
            self.dataLabels = xAxisLabels
        }
    }
    
    private var backgroundGradient: GradientColor {
        return GradientColor(
            start: Color.primary.opacity(0.3), // Keep the primary color at the top
            end: Color.clear                   // Fade to clear at the bottom
        )
    }
    
    public var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 0) {
                Group {
                    if (self.title != nil) {
                        Text(self.title!)
                            .font(.title)
                            .bold().foregroundColor(self.colorScheme == .dark ? self.darkModeStyle.textColor : self.style.textColor)
                    }
                    if (self.legend != nil) {
                        Text(self.legend!)
                            .font(.callout)
                            .foregroundColor(self.colorScheme == .dark ? self.darkModeStyle.legendTextColor : self.style.legendTextColor)
                    }
                }.offset(x: 0, y: 20)
                
                ZStack {
                    GeometryReader { reader in
                        Rectangle()
                            .foregroundColor(Color.clear)
                        
                        if(self.showLegend) {
                            Legend(data: self.data,
                                   frame: .constant(reader.frame(in: .local)),
                                   hideHorizontalLines: self.$hideHorizontalLines,
                                   specifier: legendSpecifier)
                                .transition(.opacity)
                                .animation(Animation.easeOut(duration: 1).delay(1), value: self.showLegend)
                                .opacity(self.opacity > 0 ? 0.3 : 0.6)
                                .animation(.easeInOut(duration: 0.3), value: self.opacity)
                                .offset(x: -10)
                        }
                        
                        // Use Line with fixed 0-100 scale
                        Line(data: self.data,  // Original data for indicator values
                             frame: .constant(CGRect(x: 0, y: 0, width: reader.frame(in: .local).width - 40, height: reader.frame(in: .local).height + 25)),
                             touchLocation: self.$indicatorLocation,
                             showIndicator: self.$hideHorizontalLines,
                             minDataValue: .constant(0),   // Fixed min value (0)
                             maxDataValue: .constant(100), // Fixed max value (100)
                             showBackground: true,
                             gradient: self.backgroundGradient
                        )
                        .offset(x: 30, y: 0)
                        .onAppear(){
                            self.showLegend = true
                        }
                        .onDisappear(){
                            self.showLegend = false
                        }
                    }
                    .frame(width: geometry.frame(in: .local).size.width, height: 180)
                    .offset(x: 0, y: 40)
                    
                    // Updated MagnifierRect with context label based on current point index
                    MagnifierRect(
                        currentNumber: self.$currentDataNumber,
                        valueSpecifier: self.valueSpecifier,
                        contextLabel: self.getCurrentContextLabel() // Get context label for current point
                    )
                    .opacity(self.opacity)
                    .offset(x: self.indicatorLocation.x - geometry.frame(in: .local).size.width/2 + 30, y: 56)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: self.indicatorLocation)
                }
                .frame(width: geometry.frame(in: .local).size.width, height: 140)
                .gesture(DragGesture()
                    .onChanged({ value in
                        self.dragLocation = value.location
                        
                        let chartWidth = geometry.frame(in: .local).size.width - 40
                        let pointCount = self.data.points.count
                        
                        guard pointCount > 1 else { return }
                        
                        let stepWidth = chartWidth / CGFloat(pointCount - 1)
                        let relativeXPosition = (value.location.x - 30) / stepWidth
                        let closestPointIndex = Int(round(relativeXPosition))
                        
                        if closestPointIndex >= 0 && closestPointIndex < pointCount {
                            if self.currentPointIndex != closestPointIndex {
                                self.currentPointIndex = closestPointIndex
                                
                                triggerHapticFeedback()
                                
                                let points = self.data.onlyPoints()
                                if closestPointIndex < points.count {
                                    self.currentDataNumber = points[closestPointIndex]
                                }
                                
                                let xPosition = CGFloat(closestPointIndex) * stepWidth
                                
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    self.indicatorLocation = CGPoint(x: xPosition, y: 0)
                                }
                            }
                            
                            if self.opacity == 0 {
                                withAnimation(.easeIn(duration: 0.2)) {
                                    self.opacity = 1
                                }
                            }
                            self.hideHorizontalLines = true
                        }
                    })
                    .onEnded({ value in
                        withAnimation(.easeOut(duration: 0.2)) {
                            self.opacity = 0
                        }
                        self.hideHorizontalLines = true
                        self.currentPointIndex = -1
                    })
                )
                
                if let labels = self.xAxisLabels, !labels.isEmpty {
                    HStack(alignment: .center, spacing: 0) {
                        Color.clear
                            .frame(width: 10)
                        
                        HStack(alignment: .center, spacing: 14.5) {
                            ForEach(0..<labels.count, id: \.self) { index in
                                // Map the current point index to the corresponding label index
                                // Calculate the highlight status outside of the View content
                                /*
                                let isHighlighted: Bool = {
                                    // Special handling for different data point counts
                                    switch self.data.points.count {
                                    case 30: // Last 30 days
                                        let labelIndices = [0, 5, 10, 15, 19, 24, 29]
                                        // Use a computed value instead of a for loop
                                        let mappedIndex = labelIndices.firstIndex(where: { self.currentPointIndex <= $0 }) ?? 0
                                        return mappedIndex == index
                                        
                                    case let count where count >= 90 && count < 100: // 3 months
                                        // For 13 weeks with 7 labels, map week indices to label indices
                                        let weekIndex = self.currentPointIndex / 7 // Determine which week we're in
                                        let mappedIndex = min(weekIndex * 7 / count * labels.count, labels.count - 1)
                                        return Int(mappedIndex) == index
                                        
                                    case 26: // 6 months
                                        // For 26 weeks with 7 labels
                                        let ranges: [Range<Int>] = [0..<4, 4..<8, 8..<12, 12..<17, 17..<21, 21..<25, 25..<26]
                                        // Use a computed value instead of a for loop
                                        let mappedIndex = ranges.firstIndex(where: { self.currentPointIndex >= 0 && $0.contains(self.currentPointIndex) }) ?? 0
                                        return mappedIndex == index
                                        
                                    case 36: // 3 years
                                        // For 36 months with 7 labels
                                        let monthsPerLabel = 36 / labels.count
                                        let mappedIndex = self.currentPointIndex / monthsPerLabel
                                        return mappedIndex == index
                                        
                                    case 52: // 1 year
                                        // For 52 weeks with 7 labels
                                        let weeksPerLabel = 52 / labels.count
                                        let mappedIndex = self.currentPointIndex / weeksPerLabel
                                        return mappedIndex == index
                                        
                                    default:
                                        // Default behavior for 7 data points or other counts
                                        return self.currentPointIndex == index
                                    }
                                }()
                                */
                                Text(labels[index])
                                    .customFont("Lexend", .regular, 11)
                                    .foregroundColor(self.colorScheme == .dark ?
                                                     self.darkModeStyle.legendTextColor.opacity(0.8) :
                                                        self.style.legendTextColor.opacity(0.8))
                                    .frame(width: (geometry.size.width - 90) / CGFloat(labels.count))
                                    //.scaleEffect(isHighlighted ? 1.2 : 1.0)
                                    //.animation(.easeInOut(duration: 0.2), value: isHighlighted)
                            }
                        }
                        
                        Color.clear
                            .frame(width: 10)
                    }
                    .offset(y: 60)
                    .frame(height: 20)
                    .padding(.top, 5)
                }            }
        }
    }
    
   
    
    private func triggerHapticFeedback() {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
        #endif
    }
    
    private func getCurrentContextLabel() -> String? {
        // If no point is selected or no data points exist, return nil
        guard currentPointIndex >= 0, currentPointIndex < data.points.count else {
            return nil
        }
        
        // If we have detailed data labels matching our data points directly, use them
        if let dataLabels = self.dataLabels, dataLabels.count == data.points.count {
            return currentPointIndex < dataLabels.count ? dataLabels[currentPointIndex] : nil
        }
        
        // Otherwise, if we have fewer labels than data points, we need special handling
        if let dataLabels = self.dataLabels, !dataLabels.isEmpty {
            // For 30 days data (30 data points but only 7 labels)
            if data.points.count == 30 && dataLabels.count == 30 {
                return dataLabels[currentPointIndex]
            }
            // For 3 months data (90 data points but only 90 labels)
            else if data.points.count == 90 && dataLabels.count == 90 {
                return dataLabels[currentPointIndex]
            }
            // For yearly data (52 data points but only 52 labels)
            else if data.points.count == 52 && dataLabels.count == 52 {
                return dataLabels[currentPointIndex]
            }
            // Fallback - just show the label directly
            else if currentPointIndex < dataLabels.count {
                return dataLabels[currentPointIndex]
            }
        }
        
        // No appropriate label found
        return nil
    }
}
struct LineView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LineView(
                data: [8, 23, 54, 32, 12, 37, 7],
                title: "Weekly Data",
                style: Styles.lineChartStyleOne,
                xAxisLabels: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
            )
            .frame(height: 450)
            .previewLayout(.fixed(width: 375, height: 350))
            .previewDisplayName("Weekly Data with Labels")
            
            LineView(data: [8, 23, 54, 32, 12, 37, 7, 23, 43],
                    title: "Full chart",
                    style: Styles.lineChartStyleOne)
                .previewDisplayName("Multiple Data Points")
            
            LineView(data: [282.502, 284.495, 283.51, 285.019, 285.197, 286.118, 288.737, 288.455, 289.391],
                    title: "Full chart",
                    style: Styles.lineChartStyleOne)
                .previewDisplayName("Large Values")
        }
    }
}

