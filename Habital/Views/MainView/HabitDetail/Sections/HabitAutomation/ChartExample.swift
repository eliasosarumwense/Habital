//
//  ChartExample.swift
//  Habital
//
//  Created by Elias Osarumwense on 30.10.25.
//

/*
 //
 //  ChartExample.swift
 //  GymP
 //
 //  Created by Elias Osarumwense on 30.07.24.
 //
 import SwiftUI
 import Charts
 import CoreData

 struct DemoChart: View {
     @EnvironmentObject var colorSettings: ColorSettings
     
     @FetchRequest(sortDescriptors: []) private var traininginstances: FetchedResults<TrainingInstance>
     @Namespace var animations
     var training: Training?
     var exercise: Exercise?

     @State private var selectedLogData: AvgLogData? = nil
     @State private var nearestLogData: AvgLogData? = nil

     @State private var showSelectionBar = false
     @State private var offsetX = 0.0
     @State private var selectedWeight = ""
     @State private var selectedReps = ""
     @State private var selectedFullWeight = ""
     @State private var xChartDate = ""
     @State private var selectedDate = ""
     @State private var pointMarkSize: CGFloat = 10.0

     @State private var timeScale: TimeScale = .week
     @State private var showDatePickerSheet = false
     @State private var customStartDate = Date()
     @State private var customEndDate = Date()
     @State private var selectedDays: Int = 7
     @State private var useDatePickers = true

     @State private var showFullWeight = false
     @State private var showGridLines = false
         @State private var showMoreOptions = false
     
    /*
     private var areaBackground: Gradient {
             return Gradient(colors: [colorSettings.selectedColor.opacity(0.3), colorSettings.selectedColor.opacity(0.1)])
         }
     */
     private var areaBackground: Color {
         Color.gray.opacity(0.3) // Adjust opacity as needed
     }
      
     
     private var cutoutRect: CGRect {
             // Define the rectangle to cut out (left side)
             CGRect(x: -200, y: 0, width: 10, height: 200)
         }

     
     var body: some View {
         VStack {
             ZStack {
                 Chart {
                     
                     // Draw normal line for data within the domain
                     ForEach(avgLogData) { data in
                         LineMark(
                             x: .value("Date", data.date, unit: .day),
                             y: .value("Avg Reps", showFullWeight ? data.avgWeight * data.avgReps : data.avgReps),
                             series: .value("Avg Reps", "B")
                         )
                         .foregroundStyle(Color.gray.opacity(0.8))
                         .interpolationMethod(.catmullRom)
                         
                         PointMark(
                             x: .value("Date", data.date, unit: .day),
                             y: .value("Avg Reps", showFullWeight ? data.avgWeight * data.avgReps : data.avgReps)
                         )
                         .foregroundStyle(data.id == nearestLogData?.id ? Color.white : Color.gray.opacity(0.8))
                         .symbolSize(data.id == nearestLogData?.id ? pointMarkSize : 20)
                     }
                 }
                 
                 //.areaBackground(areaBackground)
                 .areaBackground(Color.gray.opacity(0.2))
                 .chartYScale(domain: showFullWeight ? yAxisDomain : yAxisDomainAvgReps)
                 .chartXScale(domain: xAxisDomain)
                 .chartYAxisLabel(alignment: .leading) {
                     HStack {
                         if showFullWeight {
                             Text("Reps")
                                 .font(.customFont(.medium, 8))
                                 .foregroundStyle(Color.gray)
                                 .offset(x: -300) // Move text 300 pixels to the right
                                 .animation(.easeInOut(duration: 1), value: showFullWeight) // Add animation
                         } else {
                             Text("Reps")
                                 .font(.customFont(.medium, 8))
                                 .foregroundStyle(Color.gray)
                                 .offset(x: 5) // No offset when showFullWeight is false
                                 .offset(y: 3)
                                 .animation(.easeIn(duration: 1), value: showFullWeight) // Add animation
                         }
                     }
                 }
                 .chartYAxis {
                     AxisMarks(values: .automatic(desiredCount: 4)) { value in
                         AxisTick()
                         AxisValueLabel() {
                             if let reps = value.as(Double.self) {
                                 if !showFullWeight {
                                     Text(String(format: "%.0f x", reps))
                                         .customFont(.light, 9)
                                         .foregroundStyle(Color.white)
                                         .frame(width: 30, height: 20, alignment: .center)
                                         .offset(x: -335)
                                 } else {
                                     Text("")
                                         .customFont(.light, 10)
                                         .foregroundStyle(Color.white)
                                         .frame(width: 30, height: 20, alignment: .leading)
                                 }
                             }
                         }
                     }
                 }
                 .chartXAxis {
                     AxisMarks(values: xAxisValues) { value in
                         AxisTick()
                         AxisValueLabel() {
                             if let date = value.as(Date.self) {
                                 Text("")
                                     .customFont(.light, 10)
                                     .foregroundStyle(Color.gray)
                             }
                         }
                     }
                 }
                 
                 Chart {
                     ForEach(avgLogData) { data in
                         if showGridLines {
                             if let firstVisible = firstVisibleDataPoint, let lastVisible = lastVisibleDataPoint {
                                 RuleMark(y: .value("First Point", showFullWeight ? firstVisible.avgWeight * firstVisible.avgReps : firstVisible.avgWeight))
                                     .foregroundStyle(Color.red.opacity(0.5))
                                     .lineStyle(StrokeStyle(lineWidth: 1.1, dash: [5]))
                                 
                                 RuleMark(y: .value("Last Point", showFullWeight ? lastVisible.avgWeight * lastVisible.avgReps : lastVisible.avgWeight))
                                     .foregroundStyle(Color.red.opacity(0.5))
                                     .lineStyle(StrokeStyle(lineWidth: 1.1, dash: [5]))
                             }
                         }
                         LineMark(
                             x: .value("Date", data.date, unit: .day),
                             y: .value("Avg Weight", showFullWeight ? data.avgWeight * data.avgReps : data.avgWeight),
                             series: .value("Avg Weight", "A")
                         )
                         .foregroundStyle(colorSettings.selectedColor)
                         .interpolationMethod(.catmullRom)

                         
                         PointMark(
                             x: .value("Date", data.date, unit: .day),
                             y: .value("Avg Weight", showFullWeight ? data.avgWeight * data.avgReps : data.avgWeight)
                         )
                         .foregroundStyle(data.id == nearestLogData?.id ? colorSettings.selectedColor : colorSettings.selectedColor.opacity(0.8))
                         .symbolSize(data.id == nearestLogData?.id ? pointMarkSize : 20)
                     }
                 }
                 .chartYScale(domain: showFullWeight ? yAxisDomain : yAxisDomainAvgWeight)
                 .chartXScale(domain: xAxisDomain)
                 .chartYAxisLabel(alignment: .trailing) {
                     Text("Weight")
                         .font(.customFont(.medium, 8))
                         .foregroundStyle(colorSettings.selectedColor)
                         .offset(x: -5)
                         .offset(y: 3)
                 }
                 .chartXAxis {
                     AxisMarks(values: xAxisValues) { value in
                         AxisGridLine()
                         AxisTick()
                         AxisValueLabel() {
                             if let date = value.as(Date.self) {
                                 Text(dateFormatterForXChartDate.string(from: date))
                                     .customFont(.light, 10)
                                     .foregroundStyle(Color.gray)
                             }
                         }
                     }
                     if timeScale == .week || timeScale == .twoWeeks || timeScale == .month {
                         AxisMarks(values: generateMondayDates(start: xAxisDomain.lowerBound, end: xAxisDomain.upperBound)) { _ in
                             AxisGridLine()
                                 .foregroundStyle(colorSettings.selectedColor.opacity(0.3))
                         }
                     } else if timeScale == .threeMonths || timeScale == .sixMonths || timeScale == .year {
                         AxisMarks(values: generateFirstDayOfMonthDates(start: xAxisDomain.lowerBound, end: xAxisDomain.upperBound)) { _ in
                             AxisGridLine()
                                 .foregroundStyle(colorSettings.selectedColor.opacity(0.6))
                         }
                     }
                 }
                 .chartYAxis {
                     AxisMarks(values: .automatic(desiredCount: 4)) { value in
                         AxisGridLine()
                         AxisTick()
                         AxisValueLabel() {
                             if let weight = value.as(Double.self) {
                                 Text(String(format: "%.0f kg", weight))
                                     .customFont(.light, 10)
                                     .foregroundStyle(Color.white)
                                     .frame(width: 30, height: 30, alignment: .leading)
                             }
                         }
                     }
                 }
                 .chartOverlay { pr in
                     GeometryReader { geoProxy in
                         Rectangle().foregroundStyle(colorSettings.selectedColor.gradient)
                             .frame(width: 1, height: geoProxy.size.height * 0.97)
                             .opacity(showSelectionBar ? 1.0 : 0.0)
                             .offset(x: offsetX)
                             .offset(y: 5)
                             
                         if(self.avgLogData.count > 0) {
                             let halfWidth: CGFloat = 105 / 2  // Half of the rectangle's width
                             let safeOffsetX = min(max(offsetX, halfWidth), 360 - halfWidth) // Clamping X position

                             Rectangle()
                                 .foregroundStyle(.black)
                                 .frame(width: 105, height: 25)
                                 .cornerRadius(5)
                                 .overlay {
                                     HStack {
                                         if showFullWeight {
                                             VStack {
                                                 HStack (spacing: 3) {
                                                     Text("\(getFullWeight(selectedWeight, selectedReps) ?? "")")
                                                         .font(.customFont(.semiBold, 13))
                                                         .foregroundColor(.white)
                                                     Text("kg")
                                                         .font(.customFont(.semiBold, 8))
                                                         .foregroundColor(.white)
                                                 }
                                                 
                                 
                                                 Text("\(selectedDate)")
                                                     .font(.customFont(.medium, 11))
                                                     .foregroundColor(.gray)
                                                     .onChange(of: selectedWeight) {
                                                         triggerHapticFeedbackRigid()
                                                     }
                                             }
                                         } else {
                                             VStack {
                                                 HStack (spacing: 3) {
                                                     Text("\(selectedReps) x \(selectedWeight)")
                                                         .font(.customFont(.semiBold, 13))
                                                         .foregroundColor(.white)
                                                         .onChange(of: selectedWeight) {
                                                             triggerHapticFeedbackRigid()
                                                         }
                                                     Text("kg")
                                                         .font(.customFont(.semiBold, 8))
                                                         .foregroundColor(.white)
                                                 }
                                                 
                                                 Text("\(selectedDate)")
                                                     .font(.customFont(.medium, 11))
                                                     .foregroundColor(.gray)
                                                     .onChange(of: selectedWeight) {
                                                         triggerHapticFeedbackRigid()
                                                     }
                                             }
                                         }
                                     }
                                 }
                                 .opacity(showSelectionBar ? 1.0 : 0.0)
                                 .offset(x: safeOffsetX - 52.5, y: 3) // Using the clamped offset
                                 .matchedGeometryEffect(id: "animation", in: animations)
                         }
                         if(self.avgLogData.count > 0) {
                             Rectangle().fill(.clear).contentShape(Rectangle())
                                 .gesture(DragGesture().onChanged { value in
                                     if !showSelectionBar {
                                         showSelectionBar = true
                                     }
                                     let origin = geoProxy[pr.plotFrame!].origin
                                     let location = CGPoint(
                                         x: value.location.x - origin.x,
                                         y: value.location.y - origin.y
                                     )
                                     offsetX = location.x + origin.x
                                     
                                     if let nearestData = findNearestDataPoint(to: location, in: pr, geoProxy: geoProxy) {
                                         selectedWeight = String(format: "%.1f", nearestData.avgWeight)
                                         selectedReps = String(format: "%.1f", nearestData.avgReps)
                                         
                                         xChartDate = dateFormatterForXChartDate.string(from: nearestData.date)
                                         selectedDate = dateFormatterForSelectedDate.string(from: nearestData.date)
                                         nearestLogData = nearestData
                                         
                                         withAnimation(.easeIn(duration: 0.5)) {
                                             pointMarkSize = 50.0  // Increase the size when nearest
                                         }
                                     }
                                 }
                                     .onEnded { _ in
                                         withAnimation(.easeInOut(duration: 0.5)) {
                                             pointMarkSize = 20.0  // Reset the size back to normal
                                         }
                                         showSelectionBar = false
                                         nearestLogData = nil
                                     })
                         }
                     }
                 }
                 CutoutShape(cutoutRect: cutoutRect)
                     .stroke(Color.gray, lineWidth: 3)
                                 .cornerRadius(10)
                                 .opacity(0.2)
                 if(self.avgLogData.isEmpty) {
                     Text("No Logs yet")
                         .customFont(.semiBold, 13)
                             .frame(height: 200)
                             .frame(width: 360)
                             .opacity(0.4)
                 }
                 
                  
             }
             .frame(height: 200)
             .frame(width: 360)
             .padding(.bottom, 2)
             //.clipShape(Rectangle())
             .clipped()
             //.frame(width: 350)
             //.padding()
             .overlay(alignment: .leading) {
                 if showGridLines {
                     if let percentageDifference = calculatePercentageDifference() {
                         HStack (spacing: 0) {
                             if percentageDifference > 0 {
                                 Image(systemName: "arrow.up")
                                     .foregroundColor(.green)
                                     .offset(x: 7)
                             }
                             else
                             {
                                 Image(systemName: "arrow.down")
                                     .foregroundColor(.red)
                                     .offset(x: 7)
                             }
                             Text(String(format: "%.2f%%", abs(percentageDifference)))
                                 .font(.customFont(.bold, 10))
                                 .foregroundColor(.white)
                                 .padding(.leading, 10)
                             
                         }
                         .offset(y: -60)
                         .offset(x: 30)
                     }
                 }
             }
             
             
             HStack {

                 Button(action: {
                         withAnimation {
                             if let lastPoint = avgLogData.last {
                                 customStartDate = Calendar.current.date(byAdding: .day, value: -1, to: changeHourOfDate(to: 0, minute: 0, from: lastPoint.date) ?? Date()) ?? lastPoint.date
                                 customEndDate = changeHourOfDate(to: 0, minute: 0, from: Date()) ?? Date()
                                 timeScale = .lastlog
                             }
                         }
                 }) {
                     Image(systemName: "text.line.last.and.arrowtriangle.forward")
                         .font(.customFont(.medium, 14))
                         .padding(5)
                         .padding(.leading, 5)
                         .padding(.trailing, 5)
                         .background(timeScale == .lastlog ? colorSettings.selectedColor.opacity(0.8) : Color.gray.opacity(0.8))
                         .foregroundColor(.black)
                         .cornerRadius(8)
                 }

                 
                 Button(action: {
                     withAnimation {
                         timeScale = .week
                     }
                 }
                 ) {
                     Text("1 w")
                         .font(.customFont(.medium, 13))
                         .padding(5)
                         .background(timeScale == .week ? colorSettings.selectedColor.opacity(0.8) : Color.gray.opacity(0.8))
                         .foregroundColor(.black)
                         .cornerRadius(8)
                     
                 }
                 
                 Button(action: {
                     withAnimation {
                         timeScale = .twoWeeks
                     }
                 }) {
                     Text("2 w")
                         .font(.customFont(.medium, 13))
                         .padding(5)
                         .background(timeScale == .twoWeeks ? colorSettings.selectedColor.opacity(0.8) : Color.gray.opacity(0.8))
                         .foregroundColor(.black)
                         .cornerRadius(8)
                 }
                
                 Button(action: {
                     withAnimation {
                         timeScale = .month
                     }
                 }) {
                     Text("1 m")
                         .font(.customFont(.medium, 13))
                         .padding(5)
                         .background(timeScale == .month ? colorSettings.selectedColor.opacity(0.8) : Color.gray.opacity(0.8))
                         .foregroundColor(.black)
                         .cornerRadius(8)
                 }
                 
                 Button(action: {
                     withAnimation {
                         timeScale = .threeMonths
                     }
                 }) {
                     Text("3 m")
                         .font(.customFont(.medium, 13))
                         .padding(5)
                         .background(timeScale == .threeMonths ? colorSettings.selectedColor.opacity(0.8) : Color.gray.opacity(0.8))
                     //.frame(width: 50, height: 40)
                         .foregroundColor(.black)
                         .cornerRadius(8)
                 }
                
                 Button(action: {
                         withAnimation {
                             timeScale = .sixMonths
                         }
                     }) {
                         Text("6 m")
                             .font(.customFont(.medium, 13))
                             .padding(5)
                             .background(timeScale == .sixMonths ? colorSettings.selectedColor.opacity(0.8) : Color.gray.opacity(0.8))
                             .foregroundColor(.black)
                             .cornerRadius(8)
                     }
                   
                 Button(action: {
                     withAnimation {
                         timeScale = .year
                     }
                 }) {
                     Text("1 y")
                         .font(.customFont(.medium, 13))
                         .padding(5)
                         .background(timeScale == .year ? colorSettings.selectedColor.opacity(0.8) : Color.gray.opacity(0.8))
                         .foregroundColor(.black)
                         .cornerRadius(8)
                 }
        
                 Button(action: {
                         withAnimation {
                             timeScale = .threeYears
                         }
                     }) {
                         Text("3 y")
                             .font(.customFont(.medium, 13))
                             .padding(5)
                             .background(timeScale == .threeYears ? colorSettings.selectedColor.opacity(0.8) : Color.gray.opacity(0.8))
                             .foregroundColor(.black)
                             .cornerRadius(8)
                     }
                    
                 Button(action: {
                         withAnimation {
                             showMoreOptions.toggle()
                     }
                 }) {
                     Text("More")
                         .font(.customFont(.medium, 13))
                         .padding(5)
                         .background(showMoreOptions ? colorSettings.selectedColor : Color.gray)
                         .foregroundColor(.black)
                         .cornerRadius(8)
                 }
                
             }
             .padding(.bottom, 2)
             
             if showMoreOptions {
                 HStack {
                     HStack (spacing: 0) {
                         
                         Toggle("Show %", isOn: $showGridLines)
                             .toggleStyle(CustomToggle())
                             .font(.customFont(.medium, 13))
                             .animation(.default, value: showGridLines)
                             .scaleEffect(0.9)
                             .offset(x: -40)
                         
                         Toggle("kg/Set", isOn: $showFullWeight)
                             .toggleStyle(CustomToggle())
                             .font(.customFont(.medium, 13))
                             .animation(.default, value: showFullWeight)
                             .scaleEffect(0.9)
                             .offset(x: -60)
                     }
                     HStack (spacing: 1) {

                         Button(action: {
                             withAnimation {
                                 timeScale = .custom
                                 showDatePickerSheet = true
                             }
                         }) {
                             Text("Pick Date")
                                 .font(.customFont(.medium, 13))
                                 .padding(5)
                                 .background(timeScale == .custom ? colorSettings.selectedColor.opacity(0.8) : Color.gray.opacity(0.8))
                                 .foregroundColor(.black)
                                 .cornerRadius(8)
                         }
                         
                     }
                     .offset(x: -57)
                     /*if timeScale == .custom {
                         Text("\(dateFormatterForSelectedDate.string(from: customStartDate)) - \(dateFormatterForSelectedDate.string(from: customEndDate))")
                             .customFont(.medium, 13)
                     }*/
                         

                 }
             }
         }
         Spacer()
             .sheet(isPresented: $showDatePickerSheet) {
                 DateSelectionSheet(
                     useDatePickers: $useDatePickers,
                     customStartDate: $customStartDate,
                     customEndDate: $customEndDate,
                     selectedDays: $selectedDays,
                     showDatePickerSheet: $showDatePickerSheet,
                     timeScale: $timeScale
                 )
                 .presentationDetents([.height(250)])
             }
     }

     private func findNearestDataPoint(to location: CGPoint, in pr: ChartProxy, geoProxy: GeometryProxy) -> AvgLogData? {
         let distances = avgLogData.map { data in
             let xPosition = pr.position(forX: data.date) ?? 0
             let distance = abs(xPosition - location.x)
             return (data, distance)
         }
         return distances.min(by: { $0.1 < $1.1 })?.0
     }

     private var dateFormatterForXChartDate: DateFormatter {
         let formatter = DateFormatter()
         switch timeScale {
         case .year:
             formatter.dateFormat = "M"
         case .threeYears:
             formatter.dateFormat = "M"
         default:
             formatter.dateFormat = "dd.MM"
         }
         return formatter
     }
     
     private var dateFormatterForSelectedDate: DateFormatter {
         let formatter = DateFormatter()
         switch timeScale {
         case .year:
             formatter.dateFormat = "d. MMMM yyyy"
         case .threeYears:
             formatter.dateFormat = "d. MMMM yyyy"
         default:
             formatter.dateFormat = "d. MMMM yyyy"
         }
         return formatter
     }

     private var dateFormatterForSelectedYear: DateFormatter {
         let formatter = DateFormatter()
         formatter.dateFormat = "MM"
         return formatter
     }

     func convertStringToDate(_ dateString: String) -> Date? {
         let formatter = DateFormatter()
         formatter.dateFormat = "yyyy-MM-dd"
         return formatter.date(from: dateString)
     }
     
     func convertStringFromRectangleBoxToDate(_ dateString: String) -> Date? {
         let formatter = DateFormatter()
         formatter.dateFormat = "dd. MMMM yyy"
         return formatter.date(from: dateString)
     }

     enum TimeScale {
         case week
         case twoWeeks
         case month
         case threeMonths
         case year
         case custom
         case lastlog
         case sixMonths
         case threeYears
     }

     struct AvgLogData: Identifiable {
         let id: UUID
         let date: Date
         let avgWeight: Double
         let avgReps: Double
     }

     private func extractLogs(from instances: [TrainingInstance]) -> [Log] {
         instances.flatMap { $0.log?.allObjects as? [Log] ?? [] }
     }

     private func filterLogs(_ logs: [Log], by training: Training?, exercise: Exercise?) -> [Log] {
         logs.filter { log in
             (training == nil || log.training == training) &&
             (exercise == nil || log.exercise == exercise)
         }
     }

     private func calculateAverageWeight(for instances: [TrainingInstance]) -> [AvgLogData] {
         instances.compactMap { instance in
             let logs = (instance.log?.allObjects as? [Log] ?? [])
                 .filter { log in
                     (training == nil || log.training == training) &&
                     (exercise == nil || log.exercise == exercise) &&
                     (log.trainingTemplate?.isWarmup == false)
                 }
             let avgWeight = logs.isEmpty ? 0 : logs.map { $0.weight }.reduce(0, +) / Double(logs.count)
             let avgReps = logs.isEmpty ? 0 : logs.map { Double($0.reps) }.reduce(0, +) / Double(logs.count)
             return avgWeight > 0 ? AvgLogData(id: instance.id ?? UUID(), date: instance.date ?? Date(), avgWeight: avgWeight, avgReps: avgReps) : nil
         }
     }

     private var avgLogData: [AvgLogData] {
         let allInstances = Array(traininginstances)
             
         return calculateAverageWeight(for: allInstances).sorted(by: { $0.date < $1.date })
     }

     private var yAxisDomain: ClosedRange<Double> {
         let weights = showFullWeight ? avgLogData.map { $0.avgWeight * $0.avgReps } : avgLogData.map { $0.avgWeight }
         let minWeight = 0.0
         let maxWeight = (weights.max() ?? 0) + ((weights.max() ?? 0 ) - ((weights.max() ?? 0 ) / 2))
         return minWeight...maxWeight
     }

     private var yAxisDomainAvgReps: ClosedRange<Double> {
         let reps = avgLogData.map { $0.avgReps }
         let maxReps = (reps.max() ?? 1) * 1.5
         return 0.0...maxReps
     }

     private var yAxisDomainAvgWeight: ClosedRange<Double> {
         let weights = avgLogData.map { $0.avgWeight }
         let minWeight = (weights.min() ?? 0) * 0.5
         let maxWeight = (weights.max() ?? 1) * 1.5
         return minWeight...maxWeight
     }

     private var combinedYAxisDomain: ClosedRange<Double> {
         let weights = avgLogData.map { $0.avgWeight }
         let reps = avgLogData.map { $0.avgReps }
         let fullWeights = avgLogData.map { $0.avgWeight * $0.avgReps }
         let minWeight = min((weights.min() ?? 0), (reps.min() ?? 0), (fullWeights.min() ?? 0)) * 0.9
         let maxWeight = max((weights.max() ?? 1), (reps.max() ?? 1), (fullWeights.max() ?? 1)) * 1.1
         return minWeight...maxWeight
     }

     private var xAxisDomain: ClosedRange<Date> {
         let now = changeHourOfDate(to: 0, minute: 0, from: Date()) ?? Date()
         
         switch timeScale {
         case .week:
             let startDate = Calendar.current.date(byAdding: .weekOfMonth, value: -1, to: now)!
             let endDate = Calendar.current.date(byAdding: .day, value: 1, to: now)!
             return startDate...endDate
         case .twoWeeks:
             let startDate = Calendar.current.date(byAdding: .weekOfMonth, value: -2, to: now)!
             let endDate = Calendar.current.date(byAdding: .day, value: 1, to: now)!
             return startDate...endDate
         case .month:
             let startDate = Calendar.current.date(byAdding: .month, value: -1, to: now)!
             let endDate = Calendar.current.date(byAdding: .day, value: 1, to: now)!
             return startDate...endDate
         case .threeMonths:
             let startDate = Calendar.current.date(byAdding: .month, value: -3, to: now)!
             let endDate = Calendar.current.date(byAdding: .day, value: 1, to: now)!
             return startDate...endDate
         case .sixMonths:
             let startDate = Calendar.current.date(byAdding: .month, value: -6, to: now)!
             let endDate = Calendar.current.date(byAdding: .day, value: 1, to: now)!
             return startDate...endDate
         case .year:
             let startDate = Calendar.current.date(byAdding: .year, value: -1, to: now)!
             let endDate = Calendar.current.date(byAdding: .day, value: 1, to: now)!
             return startDate...endDate
         case .threeYears:
             let startDate = Calendar.current.date(byAdding: .year, value: -3, to: now)!
             let endDate = Calendar.current.date(byAdding: .day, value: 1, to: now)!
             return startDate...endDate
         case .custom:
             let endDate = Calendar.current.date(byAdding: .day, value: 1, to: customEndDate) ?? customEndDate
             return customStartDate...endDate
         case .lastlog:
             let endDate = Calendar.current.date(byAdding: .day, value: 1, to: showGridLines ? adjustedCustomEndDate : customEndDate) ?? customEndDate
             return (showGridLines ? adjustedCustomStartDate : customStartDate)...endDate
             
         }
         
         
     }
     
     
     private var xAxisValues: [Date] {
         let calendar = Calendar.current
             let startDate: Date
             let endDate: Date

             switch timeScale {
             case .week:
                 return generateStrideDates(start: calendar.date(byAdding: .weekOfMonth, value: -1, to: changeHourOfDate(to: 0, minute: 0, from: Date()) ?? Date())!, step: .day, value: 1)
             case .twoWeeks:
                 return generateStrideDates(start: calendar.date(byAdding: .weekOfMonth, value: -2, to: changeHourOfDate(to: 0, minute: 0, from: Date()) ?? Date())!, step: .day, value: 2)
             case .month:
                 return generateWeekStartDates(start: calendar.date(byAdding: .month, value: -1, to: changeHourOfDate(to: 0, minute: 0, from: Date()) ?? Date())!)
             case .threeMonths:
                 return generateWeekStartDates(start: calendar.date(byAdding: .month, value: -3, to: changeHourOfDate(to: 0, minute: 0, from: Date()) ?? Date())!, everyTwoWeeks: true)
             case .sixMonths:
                 return generateMonthStartDates(start: calendar.date(byAdding: .month, value: -6, to: changeHourOfDate(to: 0, minute: 0, from: Date()) ?? Date())!)
             case .year:
                 return generateMonthStartDates(start: calendar.date(byAdding: .year, value: -1, to: changeHourOfDate(to: 0, minute: 0, from: Date()) ?? Date())!)
             case .threeYears:
                 return generateThreeMonthStartDates(start: calendar.date(byAdding: .year, value: -3, to: changeHourOfDate(to: 0, minute: 0, from: Date()) ?? Date())!)
             case .custom:
  
                     let dayDifference = calendar.dateComponents([.day], from: showGridLines ? adjustedCustomStartDate : customStartDate, to: showGridLines ? adjustedCustomEndDate : customEndDate).day!
                     
                     switch dayDifference {
                     case let days where days <= 7:
                         return generateStrideDates(start: showGridLines ? adjustedCustomStartDate : customStartDate, end: showGridLines ? adjustedCustomEndDate : customEndDate, step: .day, value: 1) // Every day
                     case let days where days <= 14:
                         return generateStrideDates(start: showGridLines ? adjustedCustomStartDate : customStartDate, end: showGridLines ? adjustedCustomEndDate : customEndDate, step: .day, value: 2) // Every second day
                     case let days where days <= 60:
                         return generateStrideDates(start: showGridLines ? adjustedCustomStartDate : customStartDate, end: showGridLines ? adjustedCustomEndDate : customEndDate, step: .weekOfYear, value: 1) // Every week
                     case let days where days <= 180:
                         return generateStrideDates(start: showGridLines ? adjustedCustomStartDate : customStartDate, end: showGridLines ? adjustedCustomEndDate : customEndDate, step: .weekOfYear, value: 2) // Every two weeks
                     default:
                         return generateFirstDayOfMonthDates(start: showGridLines ? adjustedCustomStartDate : customStartDate, end: showGridLines ? adjustedCustomEndDate : customEndDate) // First day of each month
                     }
             case .lastlog:
                 let dayDifference = calendar.dateComponents([.day], from: showGridLines ? adjustedCustomStartDate : customStartDate, to: showGridLines ? adjustedCustomEndDate : customEndDate).day!
                 
                 switch dayDifference {
                 case let days where days <= 7:
                     return generateStrideDates(start: showGridLines ? adjustedCustomStartDate : customStartDate, end: showGridLines ? adjustedCustomEndDate : customEndDate, step: .day, value: 1) // Every day
                 case let days where days <= 14:
                     return generateStrideDates(start: showGridLines ? adjustedCustomStartDate : customStartDate, end: showGridLines ? adjustedCustomEndDate : customEndDate, step: .day, value: 2) // Every second day
                 case let days where days <= 60:
                     return generateStrideDates(start: showGridLines ? adjustedCustomStartDate : customStartDate, end: showGridLines ? adjustedCustomEndDate : customEndDate, step: .weekOfYear, value: 1) // Every week
                 case let days where days <= 180:
                     return generateStrideDates(start: showGridLines ? adjustedCustomStartDate : customStartDate, end: showGridLines ? adjustedCustomEndDate : customEndDate, step: .weekOfYear, value: 2) // Every two weeks
                 default:
                     return generateFirstDayOfMonthDates(start: showGridLines ? adjustedCustomStartDate : customStartDate, end: showGridLines ? adjustedCustomEndDate : customEndDate) // First day of each month
                 }
                 }
     }
     
     private var adjustedCustomStartDate: Date {
         guard showGridLines, timeScale == .lastlog else { return customStartDate }

         let allDates = avgLogData.map { $0.date }.sorted()
         guard allDates.count >= 2 else { return customStartDate }

         // Get the second newest data point and set the start date to one day before it
         let secondNewestDate = allDates[allDates.count - 2]
         let adjustedStartDate = Calendar.current.date(byAdding: .day, value: 0, to: changeHourOfDate(to: 0, minute: 0, from: secondNewestDate) ?? secondNewestDate) ?? secondNewestDate

         return adjustedStartDate
     }

     private var adjustedCustomEndDate: Date {
         guard showGridLines, timeScale == .lastlog else { return customEndDate }

         let allDates = avgLogData.map { $0.date }.sorted()
         guard allDates.count >= 1 else { return customEndDate }

         // Get the newest data point and set the end date to one day before it
         let newestDate = allDates.last!
         let adjustedEndDate = Calendar.current.date(byAdding: .day, value: 1, to: changeHourOfDate(to: 0, minute: 0, from: newestDate) ?? newestDate) ?? newestDate

         return adjustedEndDate
     }
     
     private func generateMondayDates(start: Date, end: Date = Date()) -> [Date] {
         var dates: [Date] = []
         var currentDate = start

         // Adjust currentDate to the next Monday if it isn't already Monday
         let calendar = Calendar.current
         while calendar.component(.weekday, from: currentDate) != 2 { // 2 represents Monday
             currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
         }

         while currentDate <= end {
             dates.append(currentDate)
             currentDate = calendar.date(byAdding: .weekOfYear, value: 1, to: currentDate)!
         }

         return dates
     }

     private func generateFirstDayOfMonthDates(start: Date, end: Date = Date()) -> [Date] {
         var dates: [Date] = []
         var currentDate = start

         let calendar = Calendar.current
         var components = calendar.dateComponents([.year, .month], from: currentDate)
         components.day = 1
         currentDate = calendar.date(from: components)!

         while currentDate <= end {
             dates.append(currentDate)
             currentDate = calendar.date(byAdding: .month, value: 1, to: currentDate)!
         }

         return dates
     }

     private func generateStrideDates(start: Date, end: Date = Date(), step: Calendar.Component, value: Int) -> [Date] {
         var dates: [Date] = []
         var currentDate = start
         let adjustedEndDate = Calendar.current.date(byAdding: .day, value: 1, to: end) ?? end
         while currentDate <= adjustedEndDate {
             dates.append(currentDate)
             currentDate = Calendar.current.date(byAdding: step, value: value, to: currentDate)!
         }
         return dates
     }
     
     

     private func generateWeekStartDates(start: Date, everyTwoWeeks: Bool = false) -> [Date] {
         var dates: [Date] = []
         let calendar = Calendar.current
         var currentDate = start
         while currentDate <= Date() {
             dates.append(currentDate)
             currentDate = calendar.date(byAdding: .weekOfYear, value: everyTwoWeeks ? 2 : 1, to: currentDate)!
         }
         return dates
     }

     private func generateMonthStartDates(start: Date) -> [Date] {
         var dates: [Date] = []
         let calendar = Calendar.current
         var currentDate = start
         while currentDate <= Date() {
             dates.append(currentDate)
             currentDate = calendar.date(byAdding: .month, value: 1, to: currentDate)!
         }
         return dates
     }
     
     private func generateThreeMonthStartDates(start: Date) -> [Date] {
         var dates: [Date] = []
         let calendar = Calendar.current
         var currentDate = start
         while currentDate <= Date() {
             dates.append(currentDate)
             currentDate = calendar.date(byAdding: .month, value: 3, to: currentDate)!
         }
         return dates
     }

     private var dateFormatter: DateFormatter {
         let formatter = DateFormatter()
         formatter.dateStyle = .short
         return formatter
     }

     func changeHourOfDate(to hour: Int, minute: Int, from date: Date) -> Date? {
         var calendar = Calendar.current
         calendar.timeZone = TimeZone.current
         
         var components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
         components.hour = hour
         components.minute = minute
         components.second = 0
         
         return calendar.date(from: components)
     }
     
     func getFullWeight(_ num1: String, _ num2: String) -> String? {
         // Convert strings to Double
         guard let number1 = Double(num1), let number2 = Double(num2) else {
             return nil // Return nil if conversion fails
         }

         // Multiply the numbers
         let result = number1 * number2

         // Convert the result back to a string
         let resultString = String(format: "%.2f", result)

         return resultString
     }

     private var firstVisibleDataPoint: AvgLogData? {
             avgLogData.first { data in
                 data.date >= xAxisDomain.lowerBound
             }
         }

         private var lastVisibleDataPoint: AvgLogData? {
             avgLogData.last { data in
                 data.date <= xAxisDomain.upperBound
             }
         }

         private func calculatePercentageDifference() -> Double? {
             guard let first = firstVisibleDataPoint, let last = lastVisibleDataPoint else {
                 return nil
             }

             let firstValue = showFullWeight ? first.avgWeight * first.avgReps : first.avgWeight
             let lastValue = showFullWeight ? last.avgWeight * last.avgReps : last.avgWeight

             guard firstValue != 0 else {
                 return nil
             }

             let percentageDifference = ((lastValue - firstValue) / firstValue) * 100
             return percentageDifference
         }
 }
 extension Collection {
     subscript(safe index: Index) -> Element? {
         return indices.contains(index) ? self[index] : nil
     }
 }
 struct DemoChart_Previews: PreviewProvider {
     static var previews: some View {
         let context = DataManager.preview.container.viewContext
         createDemoInstances(context: context)
         
         return DemoChart()
             .environment(\.managedObjectContext, context)
     }
     
     static func createDemoInstances(context: NSManagedObjectContext) {
         let calendar = Calendar.current
         var createdDates = Set<Date>()
         
         for i in 0..<20 {
             guard let date = calendar.date(byAdding: .day, value: -i, to: Date()) else { continue }
             
             if !createdDates.contains(date) {
                 let instance = TrainingInstance(context: context)
                 instance.date = date
                 instance.id = UUID()
                 createdDates.insert(date)
                 
                 
                     let log = Log(context: context)
                     log.id = UUID()
                     log.date = instance.date
                     log.weight = Double.random(in: 70...100)
                     log.reps = Int32.random(in: 8...15)
                     log.trainingInstance = instance
                     instance.addToLog(log)
                 
             }
         }
         try? context.save()
     }
 }

 */
