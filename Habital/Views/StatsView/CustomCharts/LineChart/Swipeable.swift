//
//  Swipeable.swift
//  Habital
//
//  Created by Elias Osarumwense on 04.05.25.
//

import SwiftUI

// Data structure to hold each page's chart data
struct ChartPage {
    let data: [Double]
    let title: String
    let legend: String
    let xAxisLabels: [String]
    let dataLabels: [String]
    let dateRange: DateRange // A new struct to represent the date range
}

// Helper to manage date ranges
struct DateRange: Equatable {
    let startDate: Date
    let endDate: Date
    let displayName: String
    
    static func == (lhs: DateRange, rhs: DateRange) -> Bool {
        return lhs.startDate == rhs.startDate && lhs.endDate == rhs.endDate
    }
}

struct SwipeableLineChartView: View {
    @State private var currentPageIndex: Int
    @State private var chartPages: [ChartPage]
    @State private var dragOffset: CGFloat = 0
    @State private var swipingActive = false
    @State private var isLoading = false
    
    // Customizable properties
    let style: ChartStyle
    let valueSpecifier: String
    let onRangeChanged: (DateRange) -> Void  // Callback for when date range changes
    
    // Animation configs
    let swipeThreshold: CGFloat = 50.0
    let animationDuration: Double = 0.3
    
    init(initialRanges: [DateRange],
         dataProvider: @escaping (DateRange) -> ([Double], [String], [String]),
         style: ChartStyle = Styles.lineChartStyleOne,
         valueSpecifier: String = "%.1f",
         onRangeChanged: @escaping (DateRange) -> Void = { _ in }) {
        
        // Set the style and callbacks
        self.style = style
        self.valueSpecifier = valueSpecifier
        self.onRangeChanged = onRangeChanged
        
        // Initialize state variables
        var initialPages: [ChartPage] = []
        
        for range in initialRanges {
            let (data, xAxisLabels, dataLabels) = dataProvider(range)
            
            initialPages.append(ChartPage(
                data: data,
                title: range.displayName,
                legend: "Habit Completion",
                xAxisLabels: xAxisLabels,
                dataLabels: dataLabels,
                dateRange: range
            ))
        }
        
        // Initialize state variables
        self._chartPages = State(initialValue: initialPages)
        self._currentPageIndex = State(initialValue: 0)
    }
    
    var body: some View {
        ZStack {
            VStack {
                // Navigation header
                HStack {
                    Button(action: switchToPreviousPage) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(currentPageIndex > 0 ? .primary : .gray)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(Color.gray.opacity(0.1))
                            )
                    }
                    .disabled(currentPageIndex <= 0)
                    
                    Spacer()
                    
                    // Page indicator
                    Text("\(chartPages[currentPageIndex].dateRange.displayName)")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.gray.opacity(0.1))
                        )
                    
                    Spacer()
                    
                    Button(action: switchToNextPage) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(currentPageIndex < chartPages.count - 1 ? .primary : .gray)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(Color.gray.opacity(0.1))
                            )
                    }
                    .disabled(currentPageIndex >= chartPages.count - 1)
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Swipeable chart container
                GeometryReader { geometry in
                    ZStack {
                        // Show loading indicator if loading
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(1.5)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                        
                        // Main chart
                        HStack(spacing: 0) {
                            // Current chart view
                            LineView(
                                data: chartPages[currentPageIndex].data,
                                title: "",    // We're handling the title in our custom header
                                legend: chartPages[currentPageIndex].legend,
                                style: style,
                                valueSpecifier: valueSpecifier,
                                xAxisLabels: chartPages[currentPageIndex].xAxisLabels,
                                dataLabels: chartPages[currentPageIndex].dataLabels
                            )
                            .frame(width: geometry.size.width)
                            .offset(x: dragOffset)
                            
                            // Next chart (if available) for preview during swipe
                            if currentPageIndex < chartPages.count - 1 && dragOffset < 0 {
                                LineView(
                                    data: chartPages[currentPageIndex + 1].data,
                                    title: "",
                                    legend: chartPages[currentPageIndex + 1].legend,
                                    style: style,
                                    valueSpecifier: valueSpecifier,
                                    xAxisLabels: chartPages[currentPageIndex + 1].xAxisLabels,
                                    dataLabels: chartPages[currentPageIndex + 1].dataLabels
                                )
                                .frame(width: geometry.size.width)
                                .offset(x: geometry.size.width + dragOffset)
                            }
                            
                            // Previous chart (if available) for preview during swipe
                            if currentPageIndex > 0 && dragOffset > 0 {
                                LineView(
                                    data: chartPages[currentPageIndex - 1].data,
                                    title: "",
                                    legend: chartPages[currentPageIndex - 1].legend,
                                    style: style,
                                    valueSpecifier: valueSpecifier,
                                    xAxisLabels: chartPages[currentPageIndex - 1].xAxisLabels,
                                    dataLabels: chartPages[currentPageIndex - 1].dataLabels
                                )
                                .frame(width: geometry.size.width)
                                .offset(x: -geometry.size.width + dragOffset)
                            }
                        }
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    // Only respond to horizontal dragging
                                    let horizontalAmount = value.translation.width
                                    
                                    // Check bounds to prevent swiping beyond available pages
                                    if (currentPageIndex == 0 && horizontalAmount > 0) ||
                                       (currentPageIndex == chartPages.count - 1 && horizontalAmount < 0) {
                                        // Reduce the drag effect at edges
                                        dragOffset = horizontalAmount / 3
                                    } else {
                                        dragOffset = horizontalAmount
                                    }
                                    
                                    swipingActive = true
                                }
                                .onEnded { value in
                                    swipingActive = false
                                    
                                    withAnimation(.easeInOut(duration: animationDuration)) {
                                        handleSwipe(value.translation.width, screenWidth: geometry.size.width)
                                    }
                                }
                        )
                        .animation(swipingActive ? nil : .easeInOut(duration: animationDuration), value: dragOffset)
                    }
                }
            }
        }
        .onChange(of: currentPageIndex) { _, newIndex in
            // Trigger the callback when the date range changes
            onRangeChanged(chartPages[newIndex].dateRange)
        }
    }
    
    // Handle drag gesture completion
    private func handleSwipe(_ translationWidth: CGFloat, screenWidth: CGFloat) {
        // Determine if the swipe was significant enough to change page
        if abs(translationWidth) > swipeThreshold {
            if translationWidth > 0 && currentPageIndex > 0 {
                // Swipe right: go to previous page
                currentPageIndex -= 1
            } else if translationWidth < 0 && currentPageIndex < chartPages.count - 1 {
                // Swipe left: go to next page
                currentPageIndex += 1
            }
        }
        
        // Reset drag offset
        dragOffset = 0
    }
    
    // Programmatic page changes
    private func switchToPreviousPage() {
        withAnimation(.easeInOut(duration: animationDuration)) {
            if currentPageIndex > 0 {
                currentPageIndex -= 1
                dragOffset = 0
                
                // Trigger haptic feedback
                triggerHapticFeedback()
            }
        }
    }
    
    private func switchToNextPage() {
        withAnimation(.easeInOut(duration: animationDuration)) {
            if currentPageIndex < chartPages.count - 1 {
                currentPageIndex += 1
                dragOffset = 0
                
                // Trigger haptic feedback
                triggerHapticFeedback()
            }
        }
    }
    
    // Add a new page dynamically (for pagination or loading more data)
    func addPage(data: [Double], title: String, legend: String, xAxisLabels: [String], dataLabels: [String], dateRange: DateRange) {
        chartPages.append(ChartPage(
            data: data,
            title: title,
            legend: legend,
            xAxisLabels: xAxisLabels,
            dataLabels: dataLabels,
            dateRange: dateRange
        ))
    }
    
    // Replace all pages (for refreshing data)
    func updatePages(with newPages: [ChartPage]) {
        isLoading = true
        
        // Use a slight delay to show loading indicator if needed
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            chartPages = newPages
            
            // Make sure current index is valid
            if currentPageIndex >= newPages.count {
                currentPageIndex = max(0, newPages.count - 1)
            }
            
            // Reset drag offset
            dragOffset = 0
            
            // Hide loading indicator
            isLoading = false
        }
    }
    
    private func triggerHapticFeedback() {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
        #endif
    }
}

// Helper extension to create initial date ranges
extension DateRange {
    // Factory methods to create common date ranges
    static func createWeeklyRanges(count: Int) -> [DateRange] {
        let calendar = Calendar.current
        let today = Date()
        var ranges: [DateRange] = []
        
        for i in 0..<count {
            let endDate = calendar.date(byAdding: .day, value: -7 * i, to: today)!
            let startDate = calendar.date(byAdding: .day, value: -6, to: endDate)!
            
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            let displayName = "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
            
            ranges.append(DateRange(startDate: startDate, endDate: endDate, displayName: displayName))
        }
        
        return ranges
    }
    
    static func createMonthlyRanges(count: Int) -> [DateRange] {
        let calendar = Calendar.current
        let today = Date()
        var ranges: [DateRange] = []
        
        for i in 0..<count {
            let endDateMonth = calendar.date(byAdding: .month, value: -i, to: today)!
            
            // Get the last day of the current month
            let endDate = calendar.date(
                from: calendar.dateComponents([.year, .month], from: endDateMonth)
            )!.endOfMonth(calendar: calendar)
            
            // Get the first day of the current month
            let startDate = calendar.date(
                from: calendar.dateComponents([.year, .month], from: endDateMonth)
            )!
            
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            let displayName = formatter.string(from: startDate)
            
            ranges.append(DateRange(startDate: startDate, endDate: endDate, displayName: displayName))
        }
        
        return ranges
    }
}

// Helper extension to get end of month
extension Date {
    func endOfMonth(calendar: Calendar = Calendar.current) -> Date {
        let comps = calendar.dateComponents([.year, .month], from: self)
        let startOfNextMonth = calendar.date(
            from: DateComponents(year: comps.year, month: comps.month! + 1, day: 1)
        )!
        return calendar.date(byAdding: .day, value: -1, to: startOfNextMonth)!
    }
}
