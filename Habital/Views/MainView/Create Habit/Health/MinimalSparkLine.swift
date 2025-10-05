//
//  MinimalSparkline.swift
//  Habital
//
//  Created by AI Assistant on 20.08.25.
//

import SwiftUI

struct MinimalSparkline: View {
    let entries: [DailyEntry]
    let metric: HealthKitManager.Metric
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        GeometryReader { geometry in
            if entries.isEmpty {
                emptyState
            } else {
                chartContent(in: geometry)
            }
        }
    }
    
    private var emptyState: some View {
        VStack {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 24))
                .foregroundStyle(.tertiary)
            
            Text("No data")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func chartContent(in geometry: GeometryProxy) -> some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 8)
                .fill(.ultraThinMaterial)
            
            // Chart content
            VStack(spacing: 0) {
                chartArea(in: geometry)
                
                if entries.count > 1 {
                    xAxisLabels(in: geometry)
                        .padding(.top, 4)
                }
            }
            .padding(12)
        }
    }
    
    private func chartArea(in geometry: GeometryProxy) -> some View {
        let chartHeight = geometry.size.height - (entries.count > 1 ? 24 : 12)
        let chartWidth = geometry.size.width - 24
        
        return Canvas { context, size in
            guard entries.count > 1 else {
                // Single point
                if let entry = entries.first {
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)
                    context.fill(
                        Path(ellipseIn: CGRect(
                            x: center.x - 3,
                            y: center.y - 3,
                            width: 6,
                            height: 6
                        )),
                        with: .color(chartColor)
                    )
                }
                return
            }
            
            let points = calculatePoints(entries: entries, size: CGSize(width: chartWidth, height: chartHeight))
            
            // Draw area fill
            if points.count > 1 {
                var areaPath = Path()
                areaPath.move(to: CGPoint(x: points[0].x, y: chartHeight))
                areaPath.addLine(to: points[0])
                
                for point in points.dropFirst() {
                    areaPath.addLine(to: point)
                }
                
                areaPath.addLine(to: CGPoint(x: points.last!.x, y: chartHeight))
                areaPath.closeSubpath()
                
                context.fill(areaPath, with: .color(chartColor.opacity(0.2)))
            }
            
            // Draw line
            if points.count > 1 {
                var linePath = Path()
                linePath.move(to: points[0])
                
                for point in points.dropFirst() {
                    linePath.addLine(to: point)
                }
                
                context.stroke(
                    linePath,
                    with: .color(chartColor),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                )
            }
            
            // Draw points
            for point in points {
                context.fill(
                    Path(ellipseIn: CGRect(
                        x: point.x - 2,
                        y: point.y - 2,
                        width: 4,
                        height: 4
                    )),
                    with: .color(chartColor)
                )
            }
        }
        .frame(height: chartHeight)
    }
    
    private func xAxisLabels(in geometry: GeometryProxy) -> some View {
        HStack {
            if let first = entries.first {
                Text(formatDateShort(first.date))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if let last = entries.last {
                Text(formatDateShort(last.date))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private func calculatePoints(entries: [DailyEntry], size: CGSize) -> [CGPoint] {
        guard entries.count > 1 else {
            return entries.isEmpty ? [] : [CGPoint(x: size.width / 2, y: size.height / 2)]
        }
        
        let values = entries.map(\.value)
        let minValue = values.min() ?? 0
        let maxValue = values.max() ?? 1
        let valueRange = maxValue - minValue
        
        return entries.enumerated().map { index, entry in
            let x = CGFloat(index) / CGFloat(entries.count - 1) * size.width
            let normalizedValue = valueRange > 0 ? (entry.value - minValue) / valueRange : 0.5
            let y = size.height - (CGFloat(normalizedValue) * size.height)
            
            return CGPoint(x: x, y: y)
        }
    }
    
    private var chartColor: Color {
        switch metric {
        case .sleep: return .purple
        case .steps: return .green
        case .walkingHeartRateAvg, .restingHeartRate: return .red
        case .mindfulMinutes: return .blue
        case .activeEnergy: return .orange
        case .workouts: return .pink
        }
    }
    
    private func formatDateShort(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
}
