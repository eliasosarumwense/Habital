import SwiftUI

struct CreateHabitScheduleSection: View {
    // Existing bindings
    @Binding var startDate: Date
    @Binding var repeatsPerDay: Int

    // NEW bindings for tracking types
    @Binding var habitTrackingType: HabitTrackingType
    @Binding var durationMinutes: Int
    @Binding var targetQuantity: Int
    @Binding var quantityUnit: String

    let selectedColor: Color
    let isBadHabit: Bool
    let repeatPatternText: String
    let firstOccurrenceText: String
    let showRepeatPattern: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var showQuantityUnitPicker = false

    // Available quantity units
    private let quantityUnits = ["pages", "glasses", "words", "items", "reps", "custom"]

    // ——————————————————————————————————————————————————————————————
    // Layout constants
    private let sectionInnerPadding: CGFloat = 6
    private let stackSpacing: CGFloat = 8
    // ——————————————————————————————————————————————————————————————

    var body: some View {
        VStack(spacing: stackSpacing) {
            // Start Date
            startDateSection

            // Repeat Pattern
            repeatPatternButton

            // Tracking Type + dynamic inputs (for good habits)
            if !isBadHabit {
                trackingTypeSection

                switch habitTrackingType {
                case .repetitions:
                    timesPerDaySection
                case .duration:
                    durationInputSection
                case .quantity:
                    quantityInputSection
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .glassBackground()
    }

    // MARK: - Start Date

    private var startDateSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 6) {
                SectionHeader(icon: "calendar.badge.clock", title: "START DATE")
                DatePicker("", selection: $startDate, displayedComponents: .date)
                    .labelsHidden()
                    .scaleEffect(0.9)
                    .clipped()
                    .tint(.primary)
            }

            Spacer()

            VStack(spacing: 1) {
                Text(startDate, format: .dateTime.day())
                    .font(.custom("Lexend-Bold", size: 15))
                    .foregroundColor(.primary)

                Text(startDate, format: .dateTime.month(.abbreviated))
                    .font(.custom("Lexend-Medium", size: 8))
                    .foregroundColor(.primary.opacity(0.7))
                    .textCase(.uppercase)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(.primary.opacity(0.1))
            )
        }
        .padding(sectionInnerPadding)
    }

    // MARK: - Repeat Pattern

    private var repeatPatternButton: some View {
        Button(action: showRepeatPattern) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    SectionHeader(icon: "repeat", title: "REPEAT PATTERN")

                    HStack(spacing: 5) {
                        Text(repeatPatternText)
                            .font(.custom("Lexend-SemiBold", size: 12))
                            .foregroundColor(.primary)

                        if repeatPatternText != "Never" {
                            Image(systemName: repeatPatternIcon)
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.primary)
                        }
                    }
                }

                Spacer()

                HStack(spacing: 4) {
                    Text("Change")
                        .font(.custom("Lexend-Medium", size: 10))
                        .foregroundColor(.primary)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(.primary.opacity(0.12)))
            }
            .padding(sectionInnerPadding)
        }
        .buttonStyle(InteractiveButtonStyle())
    }

    // MARK: - Tracking Type

    private var trackingTypeSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                SectionHeader(icon: "target", title: "TRACKING METHOD")

                HStack(spacing: 8) {
                    ForEach(HabitTrackingType.allCases, id: \.self) { type in
                        trackingTypeButton(type)
                    }
                }
                .padding(.top, 2)
            }

            Spacer()
        }
        .padding(sectionInnerPadding)
    }

    private func trackingTypeButton(_ type: HabitTrackingType) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                habitTrackingType = type
            }
            triggerHaptic(.impactLight)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: type.icon)
                    .font(.system(size: 11, weight: .medium))

                Text(type.title)
                    .font(.custom("Lexend-Medium", size: 11))
                    .foregroundColor(habitTrackingType == type ? Color(.systemBackground) : .secondary)
            }
            .foregroundColor(habitTrackingType == type ? Color(.systemBackground) : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(habitTrackingType == type ? Color.primary.opacity(0.7) : Color(.secondarySystemFill))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Daily Frequency

    private var timesPerDaySection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                SectionHeader(icon: "arrow.trianglehead.2.clockwise", title: "DAILY FREQUENCY")
                Text(frequencyDescription)
                    .font(.custom("Lexend-Regular", size: 10))
                    .foregroundColor(.secondary)
                    .opacity(0.8)
            }

            Spacer()

            HStack(spacing: 0) {
                StepButton(systemName: "minus", isEnabled: repeatsPerDay > 1, activeColor: selectedColor) {
                    if repeatsPerDay > 1 {
                        repeatsPerDay -= 1
                        triggerHaptic(.impactLight)
                    }
                }

                VStack(spacing: 1) {
                    Text("\(repeatsPerDay)")
                        .font(.custom("Lexend-Bold", size: 16))
                    Text(repeatsPerDay == 1 ? "time" : "times")
                        .font(.custom("Lexend-Regular", size: 8))
                        .foregroundColor(.secondary)
                        .opacity(0.6)
                }
                .frame(minWidth: 44)

                StepButton(systemName: "plus", isEnabled: repeatsPerDay < 20) {
                    if repeatsPerDay < 20 {
                        repeatsPerDay += 1
                        triggerHaptic(.impactLight)
                    }
                }
            }
            .padding(3)
            .background(Capsule().fill(Color(UIColor.secondarySystemGroupedBackground)))
        }
        .padding(sectionInnerPadding)
    }

    // MARK: - Target Duration

    private var durationInputSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                SectionHeader(icon: "clock", title: "TARGET DURATION")
                Text(durationDescription)
                    .font(.custom("Lexend-Regular", size: 10))
                    .foregroundColor(.secondary)
                    
                    .opacity(0.7)
                    
                    .kerning(0.5)
            }

            Spacer()

            HStack(spacing: 0) {
                StepButton(systemName: "minus", isEnabled: durationMinutes > 5, activeColor: selectedColor) {
                    if durationMinutes > 5 {
                        durationMinutes = max(5, durationMinutes - 5)
                        triggerHaptic(.impactLight)
                    }
                }

                Text(formatDuration(durationMinutes))
                    .font(.custom("Lexend-Bold", size: 14))
                    .frame(minWidth: 60)

                StepButton(systemName: "plus", isEnabled: durationMinutes < 480) {
                    if durationMinutes < 480 {
                        durationMinutes = min(480, durationMinutes + 5)
                        triggerHaptic(.impactLight)
                    }
                }
            }
            .padding(3)
            .background(Capsule().fill(Color(UIColor.secondarySystemGroupedBackground)))
        }
        .padding(sectionInnerPadding)
    }

    // MARK: - Target Amount

    private var quantityInputSection: some View {
        HStack(spacing: 8) {
            // Left: label + helper text
            VStack(alignment: .leading, spacing: 6) {
                SectionHeader(icon: "number", title: "TARGET AMOUNT")
                Text(quantityDescription)
                    .font(.custom("Lexend-Regular", size: 10))
                    .foregroundColor(.primary)
                    .opacity(0.7)
                    
                    .kerning(0.5)
            }

            Spacer()

            // Middle: unit picker
            Menu {
                Picker("Unit", selection: $quantityUnit) {
                    ForEach(quantityUnits, id: \.self) { unit in
                        Text(unit.capitalized).tag(unit)
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(quantityUnitLabel.capitalized)
                        .font(.custom("Lexend-Medium", size: 10))
                        .lineLimit(1)
                        .foregroundColor(.primary)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                )
            }
            .menuOrder(.fixed)

            // Right: amount stepper
            HStack(spacing: 0) {
                StepButton(systemName: "minus", isEnabled: targetQuantity > 1, activeColor: selectedColor) {
                    if targetQuantity > 1 {
                        targetQuantity -= 1
                        triggerHaptic(.impactLight)
                    }
                }

                Text("\(targetQuantity)")
                    .font(.custom("Lexend-Bold", size: 16))
                    .frame(minWidth: 44)

                StepButton(systemName: "plus", isEnabled: targetQuantity < 999) {
                    if targetQuantity < 999 {
                        targetQuantity += 1
                        triggerHaptic(.impactLight)
                    }
                }
            }
            .padding(3)
            .background(Capsule().fill(Color(UIColor.secondarySystemGroupedBackground)))
        }
        .padding(sectionInnerPadding)
    }

    // MARK: - Computed

    private var quantityUnitLabel: String {
        let label = quantityUnit.trimmingCharacters(in: .whitespacesAndNewlines)
        return label.isEmpty ? "unit" : label
    }

    private var quantityDescription: String {
        let raw = quantityUnit.trimmingCharacters(in: .whitespacesAndNewlines)
        let base = raw.isEmpty ? "unit" : raw
        let needsS = targetQuantity != 1 && !base.lowercased().hasSuffix("s")
        return "\(targetQuantity) \(base)\(needsS ? "s" : "")"
    }

    private var repeatPatternIcon: String {
        switch repeatPatternText.lowercased() {
        case "daily": return "calendar.day.timeline.left"
        case "weekly": return "calendar.badge.plus"
        case "monthly": return "calendar.circle"
        case "custom": return "slider.horizontal.3"
        default: return "calendar"
        }
    }

    private var frequencyDescription: String {
        switch repeatsPerDay {
        case 1: return "Once daily"
        case 2: return "Twice daily"
        case 3: return "Three times daily"
        case 4...6: return "Multiple times"
        case 7...10: return "Frequent practice"
        default: return "Intensive practice"
        }
    }

    private var durationDescription: String {
        if durationMinutes < 30 { return "Quick session" }
        else if durationMinutes < 60 { return "Moderate session" }
        else if durationMinutes < 120 { return "Extended practice" }
        else { return "Deep focus session" }
    }

    private func formatDuration(_ minutes: Int) -> String {
        if minutes < 60 { return "\(minutes)m" }
        let hours = minutes / 60
        let mins = minutes % 60
        return mins == 0 ? "\(hours)h" : "\(hours)h \(mins)m"
    }
}

// MARK: - Reusable bits

private struct SectionHeader: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.primary.opacity(0.85))

            Text(title)
                .font(.custom("Lexend-Medium", size: 9))
                .foregroundColor(.primary)
                .opacity(0.7)
                .textCase(.uppercase)
                .kerning(0.5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct StepButton: View {
    let systemName: String
    var isEnabled: Bool = true
    var activeColor: Color? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(isEnabled ? (activeColor ?? .primary) : .gray.opacity(0.3))
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(isEnabled ? Color.primary.opacity(0.1)
                                        : Color.gray.opacity(0.05))
                )
        }
        .disabled(!isEnabled)
        .buttonStyle(.plain)
    }
}

// Interactive button style for the pattern button
struct InteractiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview

struct CreateHabitScheduleSection_Previews: PreviewProvider {
    @State static var startDate = Date()
    @State static var repeatsPerDay = 2
    @State static var habitTrackingType: HabitTrackingType = .repetitions
    @State static var durationMinutes = 25
    @State static var targetQuantity = 3
    @State static var quantityUnit = "pages"

    static var previews: some View {
        ScrollView {
            VStack(spacing: 20) {
                CreateHabitScheduleSection(
                    startDate: $startDate,
                    repeatsPerDay: $repeatsPerDay,
                    habitTrackingType: $habitTrackingType,
                    durationMinutes: $durationMinutes,
                    targetQuantity: $targetQuantity,
                    quantityUnit: $quantityUnit,
                    selectedColor: .blue,
                    isBadHabit: false,
                    repeatPatternText: "Daily",
                    firstOccurrenceText: "Tomorrow",
                    showRepeatPattern: {}
                )
            }
            .padding()
            .background(Color(UIColor.systemGroupedBackground))
        }
        .previewDisplayName("Habit Schedule Section")
    }
}
