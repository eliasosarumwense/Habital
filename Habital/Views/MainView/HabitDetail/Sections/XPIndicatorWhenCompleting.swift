//
//  XPIndicatorWhenCompleting.swift
//  Habital
//
//  Created by Elias Osarumwense on 30.04.25.
//

import SwiftUI

//
//  XPIndicatorWhenCompleting.swift
//  Habital
//
//  Created by Elias Osarumwense on 30.04.25.
//

struct HabitXPIndicator: View {
    let habit: Habit
    let streak: Int
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var habitIntensity: HabitIntensity {
        return HabitIntensity(rawValue: habit.intensityLevel) ?? .light
    }
    
    private func calculateStreakMultiplier() -> Double {
        if streak >= 100 {
            return 10.0
        } else if streak >= 50 {
            return 5.0
        } else if streak >= 40 {
            return 4.0
        } else if streak >= 30 {
            return 3.0
        } else if streak >= 20 {
            return 2.0
        } else if streak >= 10 {
            return 1.5
        } else {
            return 1.0
        }
    }
    
    private func calculateXP() -> Int {
        if habit.isBadHabit {
            // Bad habits have a penalty of -100 XP × intensity multiplier
            return -100 * Int(habitIntensity.multiplier)
        } else {
            // Good habits: baseXP × streak multiplier × intensity multiplier
            let baseXP = 10 // UserLevelData.BASE_XP_PER_COMPLETION
            let streakMultiplier = calculateStreakMultiplier()
            return Int(Double(baseXP) * streakMultiplier * habitIntensity.multiplier)
        }
    }
    
    // Progressive color from orange to red based on multiplier
    private func getStreakColor(for multiplier: Double) -> Color {
        if multiplier <= 1.0 {
            return .gray
        } else if multiplier >= 5.0 {
            return .red
        } else {
            // Interpolate between orange and red
            let progress = (multiplier - 1.0) / 4.0 // 0 to 1
            return Color.orange.interpolated(to: .red, amount: progress)
        }
    }
    
    var body: some View {
        // Calculate once to avoid multiple calculations
        let xpValue = calculateXP()
        let isNegative = xpValue < 0
        let displayXP = abs(xpValue)
        let xpColor = isNegative ? Color.red : Color.green
        let streakMultiplierValue = calculateStreakMultiplier()
        let streakColor = getStreakColor(for: streakMultiplierValue)
        
        HStack(spacing: 0) {
            // Intensity indicator with multiplier
            VStack(spacing: 1) {
                Text("Intensity")
                    .customFont("Lexend", .medium, 10)
                    .foregroundColor(.secondary)
                
                Text("×\(String(format: "%.1f", habitIntensity.multiplier))")
                    .customFont("Lexend", .semiBold, 15)
                    .foregroundColor(habitIntensity.color.opacity(0.8))
                /*
                Text(habitIntensity.title)
                    .customFont("Lexend", .regular, 8)
                    .foregroundColor(habitIntensity.color)
                 */
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            
            
            Divider()
                .frame(height: 30)
                .padding(.horizontal, 1)
            
            // Streak multiplier
            VStack(spacing: 1) {
                Text("Streak")
                    .customFont("Lexend", .medium, 10)
                    .foregroundColor(.secondary)
                
                Text("×\(String(format: "%.1f", streakMultiplierValue))")
                    .customFont("Lexend", .semiBold, 15)
                    .foregroundColor(streakColor.opacity(0.8))
                /*
                Text("\(streak) days")
                    .customFont("Lexend", .regular, 8)
                    .foregroundColor(streakColor)
                 */
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            
            
            Divider()
                .frame(height: 30)
                .padding(.horizontal, 1)
            
            // XP reward
            VStack(spacing: 1) {
                Text("XP Reward")
                    .customFont("Lexend", .medium, 11)
                    .foregroundColor(.secondary)
                HStack (spacing: 2){
                    Text("\(isNegative ? "-" : "+")\(displayXP)")
                        .customFont("Lexend", .bold, 15)
                        .foregroundColor(xpColor)
                    
                    Text("XP")
                        .customFont("Lexend", .regular, 8)
                        .foregroundColor(xpColor)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(xpColor.opacity(colorScheme == .dark ? 0.1 : 0.08))
            )
        }
        .frame(height: 45)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(colorScheme == .dark ?
                      Color(UIColor.systemGray6) :
                      Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}

// Color interpolation extension
extension Color {
    func interpolated(to other: Color, amount: Double) -> Color {
        let clampedAmount = min(max(amount, 0), 1)
        
        let startComponents = UIColor(self).cgColor.components ?? [0, 0, 0, 1]
        let endComponents = UIColor(other).cgColor.components ?? [0, 0, 0, 1]
        
        let r = startComponents[0] + (endComponents[0] - startComponents[0]) * clampedAmount
        let g = startComponents[1] + (endComponents[1] - startComponents[1]) * clampedAmount
        let b = startComponents[2] + (endComponents[2] - startComponents[2]) * clampedAmount
        let a = startComponents[3] + (endComponents[3] - startComponents[3]) * clampedAmount
        
        return Color(red: r, green: g, blue: b, opacity: a)
    }
}

struct HabitXPIndicator_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        
        let goodHabit = Habit(context: context)
        goodHabit.name = "Morning Meditation"
        goodHabit.intensityLevel = 2 // Moderate
        goodHabit.isBadHabit = false
        
        let extremeHabit = Habit(context: context)
        extremeHabit.name = "Marathon Training"
        extremeHabit.intensityLevel = 4 // Extreme
        extremeHabit.isBadHabit = false
        
        let badHabit = Habit(context: context)
        badHabit.name = "Late Night Snacking"
        badHabit.intensityLevel = 3 // High
        badHabit.isBadHabit = true
        
        return Group {
            VStack(spacing: 20) {
                // Good habit with 0 streak
                HabitXPIndicator(habit: goodHabit, streak: 0)
                
                // Good habit with streak
                HabitXPIndicator(habit: extremeHabit, streak: 25)
                
                // Good habit with long streak
                HabitXPIndicator(habit: goodHabit, streak: 100)
                
                // Bad habit
                HabitXPIndicator(habit: badHabit, streak: 0)
            }
            .padding()
            .previewLayout(.sizeThatFits)
        }
    }
}
