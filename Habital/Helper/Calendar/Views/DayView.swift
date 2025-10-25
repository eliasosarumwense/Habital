import SwiftUI
import CoreData
struct DayView: View {
    let date: Date
       @Binding var selectedDate: Date?
       
       // Parameters for habit rings
       let getFilteredHabits: (Date) -> [Habit]
       let animateRings: Bool
       
       private let hapticFeedback = UIImpactFeedbackGenerator(style: .soft)
       @Binding var isDragging: Bool
       
       @State private var shouldAnimateRings: Bool = false
       @State private var isPressed: Bool = false
       
       // App storage values for settings
       @AppStorage("showEllipse") private var showEllipse = true
       @AppStorage("useSegmentedRings") private var useSegmentedRings = false
       @AppStorage("accentColorIndex") private var accentColorIndex: Int = 0
       @AppStorage("includeBadHabitsInStats") private var includeBadHabitsInStats = true
       
       @EnvironmentObject private var cacheManager: CalendarCacheManager
       @EnvironmentObject private var habitManager: HabitPreloadManager
       @Environment(\.colorScheme) private var colorScheme
       @Environment(\.managedObjectContext) private var viewContext
       
       let refreshTrigger: UUID
       let isShownInHabitDetails: Bool?
       let habitColor: Color?
       
       // Pre-calculate dayKey once for this view
       private var dayKey: String {
           DayKeyFormatter.localKey(from: date)
       }
       
       private var accentColor: Color {
           return ColorPalette.color(at: accentColorIndex)
       }
       
       var body: some View {
           let isToday = Calendar.current.isDateInToday(date)
           let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate ?? Date.distantPast)
           let isFuture = date > Date()
           
           let isDateAccessible = habitManager.canNavigateToDate(date)
           
           // Get filtered habits for this day
           let habits = !isDragging ? getFilteredHabits(date) : []
           
           // ✅ Use optimized calculation with dayKey
           let (hasActiveHabits, completionPercentage, ringColors) = (showEllipse && !isDragging) ?
               calculateHabitDataOptimized(habits: habits, dayKey: dayKey) : (false, 0.0, [Color]())
           
           ZStack {
               // Background
               if isSelected {
                   liquidGlassBackground(isSelected: isSelected, isToday: isToday)
                       .frame(width: 44, height: 44)
               } else {
                   RoundedRectangle(cornerRadius: 12)
                       .fill(Color.clear)
                       .frame(width: 44, height: 44)
               }
               
               VStack(spacing: 0) {
                   ZStack {
                       // Ring background
                       if showEllipse && hasActiveHabits {
                           Circle()
                               .stroke(
                                   LinearGradient(
                                       colors: [
                                           Color.gray.opacity(colorScheme == .dark ? 0.4 : 0.25),
                                           Color.gray.opacity(colorScheme == .dark ? 0.3 : 0.18)
                                       ],
                                       startPoint: .topLeading,
                                       endPoint: .bottomTrailing
                                   ),
                                   lineWidth: 3
                               )
                               .frame(width: 32, height: 32)
                       }
                       
                       // Progress ring
                       if isShownInHabitDetails ?? false || (showEllipse && hasActiveHabits) {
                           if useSegmentedRings && !ringColors.isEmpty {
                               SegmentedRing(
                                   colors: ringColors,
                                   progress: shouldAnimateRings ? completionPercentage : 0,
                                   lineWidth: 3
                               )
                               .frame(width: 32, height: 32)
                           } else {
                               let progressGradient: AngularGradient = {
                                   if habitColor != nil {
                                       return AngularGradient(
                                           gradient: Gradient(colors: [.secondary, .primary]),
                                           center: .center,
                                           startAngle: .degrees(0),     // rotate gradient to 90°
                                           endAngle: .degrees(360)
                                       )
                                   } else {
                                       return AngularGradient(
                                           gradient: Gradient(colors: [
                                               accentColor.opacity(0.7),
                                               accentColor,
                                               accentColor.opacity(0.9)
                                           ]),
                                           center: .center,
                                           startAngle: .degrees(0),     // rotate gradient to 90°
                                           endAngle: .degrees(360)
                                       )
                                   }
                               }()

                               Circle()
                                   .trim(from: 0, to: shouldAnimateRings ? CGFloat(completionPercentage) : 0)
                                   .stroke(
                                       progressGradient,
                                       style: StrokeStyle(lineWidth: 4, lineCap: .round)
                                   )
                                   .frame(width: 32, height: 32)
                                   .rotationEffect(.degrees(-90)) // progress starts at top; gradient is rotated 90°
                           }
                       }
                       
                       // Day number
                       Text(getDayInDFormat(from: date))
                           .font(.system(
                               size: isSelected ? 16 : 14,
                               weight: isSelected ? .bold : .semibold,
                               design: .rounded
                           ))
                           .foregroundStyle(
                               !isDateAccessible ?
                                   LinearGradient(
                                       colors: [Color.gray.opacity(0.4), Color.gray.opacity(0.3)],
                                       startPoint: .top,
                                       endPoint: .bottom
                                   ) :
                               isToday ?
                                   LinearGradient(
                                       colors: [Color.red, Color.red.opacity(0.8)],
                                       startPoint: .top,
                                       endPoint: .bottom
                                   ) : (isFuture ?
                                   LinearGradient(
                                       colors: [Color.secondary, Color.secondary.opacity(0.9)],
                                       startPoint: .top,
                                       endPoint: .bottom
                                   ) :
                                   LinearGradient(
                                       colors: [Color.primary, Color.primary.opacity(0.9)],
                                       startPoint: .top,
                                       endPoint: .bottom
                                   ))
                           )
                   }
                   
                   // Today indicator
                   if isToday {
                       RoundedRectangle(cornerRadius: 1)
                           .fill(
                               LinearGradient(
                                   colors: [Color.red, Color.red.opacity(0.8)],
                                   startPoint: .leading,
                                   endPoint: .trailing
                               )
                           )
                           .frame(width: 12, height: 2)
                           .offset(y: 2)
                           .scaleEffect(isSelected ? 1.2 : 1.0)
                   }
               }
           }
           .scaleEffect(isSelected ? (isPressed ? 0.96 : 1.02) : 1.0)
           .opacity(!isDateAccessible ? 0.4 : 1.0)
           .onTapGesture {
               guard isDateAccessible else {
                   let errorFeedback = UINotificationFeedbackGenerator()
                   errorFeedback.notificationOccurred(.error)
                   return
               }
               
               withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                   hapticFeedback.impactOccurred()
                   selectedDate = date
               }
           }
           /*
           .simultaneousGesture(
               DragGesture(minimumDistance: 0)
                   .onChanged { value in
                       // Only handle small movements for press effects
                       // Let horizontal swipes pass through to parent ScrollView
                       let horizontalMovement = abs(value.translation.x)
                       let verticalMovement = abs(value.translation.y)
                       
                       // If horizontal movement is significant, don't handle this gesture
                       if horizontalMovement > 10 {
                           return
                       }
                       
                       if isSelected && isDateAccessible {
                           withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                               isPressed = true
                           }
                       }
                   }
                   .onEnded { value in
                       let horizontalMovement = abs(value.translation.x)
                       
                       // Only handle end if this wasn't a horizontal swipe
                       if horizontalMovement <= 10 {
                           if isSelected {
                               withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                                   isPressed = false
                               }
                           }
                       }
                   }
           )
            */
           .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isSelected)
           .animation(.spring(response: 0.8, dampingFraction: 0.8), value: shouldAnimateRings)
           .animation(.easeOut(duration: 1.5), value: shouldAnimateRings)
           
           .onChange(of: isDragging) { _, newValue in
               if !newValue {
                   shouldAnimateRings = false
                   DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                       withAnimation(.easeOut(duration: 1.2).delay(Double.random(in: 0...0.3))) {
                           shouldAnimateRings = true
                       }
                   }
               } else {
                   shouldAnimateRings = false
               }
           }
           .onAppear {
               if Calendar.current.isDateInToday(date) {
                   shouldAnimateRings = true
               } else if !isDragging {
                   DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                       withAnimation(.easeOut(duration: 1.2).delay(Double.random(in: 0...0.4))) {
                           shouldAnimateRings = true
                       }
                   }
               }
           }
       }
       
       // MARK: - ✅ OPTIMIZED Calculation using dayKey
       
       private func calculateHabitDataOptimized(habits: [Habit], dayKey: String) -> (hasActiveHabits: Bool, completionPercentage: Double, ringColors: [Color]) {
           // Check if future date
           let isFuture = date > Date()
           
           // Filter active habits
           let activeHabits = habits.filter { habit in
               HabitUtilities.isHabitActive(habit: habit, on: date)
           }
           
           // Filter out bad habits if needed
           let habitsForStats = activeHabits.filter { habit in
               return !(habit.isBadHabit && !includeBadHabitsInStats)
           }
           
           let hasActiveHabits = !habitsForStats.isEmpty
           
           guard hasActiveHabits else {
               return (false, 0.0, [])
           }
           
           // For future dates, return 0% completion
           if isFuture {
               let ringColors = useSegmentedRings ?
                   extractColorsFromHabits(habits: []) :
                   determineRingColors(activeHabits: habitsForStats, completedHabits: [])
               return (hasActiveHabits, 0.0, ringColors)
           }
           
           // ✅ OPTIMIZED: Use dayKey for fast completion check
           let completedHabits = habitsForStats.filter { habit in
               isHabitCompletedWithDayKey(habit, dayKey: dayKey)
           }
           
           let completionPercentage = Double(completedHabits.count) / Double(habitsForStats.count)
           
           let ringColors = useSegmentedRings ?
               extractColorsFromHabits(habits: completedHabits) :
               determineRingColors(activeHabits: habitsForStats, completedHabits: completedHabits)
           
           return (hasActiveHabits, completionPercentage, ringColors)
       }
       
       // ✅ FAST dayKey-based completion check
       private func isHabitCompletedWithDayKey(_ habit: Habit, dayKey: String) -> Bool {
           let request = NSFetchRequest<Completion>(entityName: "Completion")
           request.predicate = NSPredicate(
               format: "dayKey == %@ AND habit == %@ AND completed == YES",
               dayKey, habit
           )
           request.fetchLimit = 1
           
           do {
               let count = try viewContext.count(for: request)
               return count > 0
           } catch {
               print("Error checking completion: \(error)")
               return false
           }
       }
       
       // Keep your existing helper methods
    private func liquidGlassBackground(isSelected: Bool, isToday: Bool) -> some View {
        ZStack {
            // Base rounded rectangle - nearly transparent
            RoundedRectangle(cornerRadius: isSelected ? 14 : 10, style: .continuous)
                .fill(Color.primary.opacity(0.02))
            
            // Selection state
            if isSelected {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(accentColor.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(accentColor.opacity(0.3), lineWidth: 1.6)
                    )
            }
            
            // Today indicator (only when not selected)
            if isToday && !isSelected {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Color.red.opacity(0.4), lineWidth: 1.0)
            }
        }
    }
       
       private func getDayInDFormat(from date: Date) -> String {
           let formatter = DateFormatter()
           formatter.dateFormat = "d"
           return formatter.string(from: date)
       }
       
       private func determineRingColors(activeHabits: [Habit], completedHabits: [Habit]) -> [Color] {
           guard !activeHabits.isEmpty else {
               return [Color.gray.opacity(0.6), accentColor.opacity(0.8)]
           }
           
           guard !completedHabits.isEmpty else {
               return [Color.gray.opacity(0.6), accentColor.opacity(0.8)]
           }
           
           let colorCount = completedHabits.reduce(into: [Color: Int]()) { counts, habit in
               let color = Color(data: habit.color) ?? accentColor
               counts[color, default: 0] += 1
           }
           
           let dominantColor = colorCount.max { $0.value < $1.value }?.key ?? accentColor
           return [Color.gray.opacity(0.6), dominantColor.opacity(0.9)]
       }
       
       private func extractColorsFromHabits(habits: [Habit]) -> [Color] {
           guard !habits.isEmpty else {
               return [accentColor.opacity(0.8)]
           }
           
           let habitColors = habits
               .compactMap { habit -> (String, Color)? in
                   guard let id = habit.id?.uuidString else { return nil }
                   let color = Color(data: habit.color) ?? accentColor
                   return (id, color)
               }
               .sorted { $0.0 < $1.0 }
               .map { $0.1 }
           
           return habitColors.isEmpty ? [accentColor.opacity(0.8)] : habitColors
       }
   }

   // MARK: - Part 3: Global Cache Manager for dayKey

   class DayKeyCache: ObservableObject {
       static let shared = DayKeyCache()
       
       private var completionCache: [String: Bool] = [:]
       private var countCache: [String: Int] = [:]
       private let queue = DispatchQueue(label: "daykey.cache", attributes: .concurrent)
       
       func isCompleted(habit: Habit, dayKey: String, context: NSManagedObjectContext) -> Bool {
           let cacheKey = "\(habit.id?.uuidString ?? "")-\(dayKey)"
           
           // Check cache first
           return queue.sync {
               if let cached = completionCache[cacheKey] {
                   return cached
               }
               
               // Not in cache, fetch from Core Data
               let request = NSFetchRequest<Completion>(entityName: "Completion")
               request.predicate = NSPredicate(
                   format: "dayKey == %@ AND habit == %@ AND completed == YES",
                   dayKey, habit
               )
               request.fetchLimit = 1
               
               do {
                   let count = try context.count(for: request)
                   let isCompleted = count > 0
                   
                   // Update cache
                   queue.async(flags: .barrier) {
                       self.completionCache[cacheKey] = isCompleted
                   }
                   
                   return isCompleted
               } catch {
                   print("Error checking completion: \(error)")
                   return false
               }
           }
       }
       
       func invalidate(habit: Habit, dayKey: String) {
           let cacheKey = "\(habit.id?.uuidString ?? "")-\(dayKey)"
           queue.async(flags: .barrier) {
               self.completionCache.removeValue(forKey: cacheKey)
               self.countCache.removeValue(forKey: cacheKey + "-count")
           }
       }
       
       func invalidateAll() {
           queue.async(flags: .barrier) {
               self.completionCache.removeAll()
               self.countCache.removeAll()
           }
       }
   }
