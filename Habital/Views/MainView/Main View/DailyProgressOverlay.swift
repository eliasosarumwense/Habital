//
//  DailyProgressOverlay.swift
//  Habital
//
//  Created by Elias Osarumwense on 28.07.25.
//
import SwiftUI

struct DailyProgressOverlay: View {
    let progress: Double // 0.0 to 1.0
    let isActive: Bool // When habits are being toggled
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var isExpanded = false
    
    // Progress color based on percentage
    private var progressColor: Color {
        let percentage = progress * 100
        if percentage < 33 {
            return .red
        } else if percentage < 66 {
            return .orange
        } else {
            return .green
        }
    }
    
    // Formatted percentage text
    private var percentageText: String {
        return "\(Int(progress * 100))%"
    }
    
    // Dynamic height based on state
    private var containerHeight: CGFloat {
        return isExpanded ? 30 : 4
    }
    
    // Dynamic corner radius
    private var cornerRadius: CGFloat {
        return isExpanded ? 16 : 2
    }
    
    var body: some View {
        VStack {
            Spacer()
            
            // Progress container
            HStack(spacing: 12) {
                // Progress bar with background wrapper
                ProgressView(value: progress)
                    .progressViewStyle(SlickProgressViewStyle(
                        color: .secondary, // Changed from progressColor to .secondary
                        isExpanded: isExpanded
                    ))
                    .frame(height: isExpanded ? 6 : 4) // Increased from 2 to 4
                    .background(
                        // Background only around progress bar when not expanded
                        Group {
                            if !isExpanded {
                                RoundedRectangle(cornerRadius: cornerRadius)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: cornerRadius)
                                            .strokeBorder(
                                                progressColor.opacity(0.08),
                                                lineWidth: 0.3
                                            )
                                    )
                                    .opacity(0.6)
                                    .padding(.horizontal, -4) // Slightly wider
                                    .padding(.vertical, -2) // Slightly taller
                            }
                        }
                    )
                
                // Percentage text (only when expanded with additional check)
                Group {
                    if isExpanded && isActive {
                        Text(percentageText)
                            .font(.customFont("Lexend", .medium, 12))
                            .foregroundColor(.primary)
                            .monospacedDigit()
                            .frame(width: 40, alignment: .trailing)
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.8).combined(with: .opacity),
                                removal: .scale(scale: 0.8).combined(with: .opacity)
                            ))
                    }
                }
            }
            .padding(.horizontal, isExpanded ? 16 : 16)
            .padding(.vertical, isExpanded ? 8 : 0)
            .frame(height: containerHeight)
            .background(
                // Expanded background (full width)
                isExpanded ? AnyView(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .strokeBorder(
                                    progressColor.opacity(0.15),
                                    lineWidth: 1
                                )
                        )
                ) : AnyView(Color.clear)
            )
            .padding(.horizontal, 5)
            .padding(.bottom, 90) // Position above tab bar
        }
        .onChange(of: isActive) { _, newValue in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                isExpanded = newValue
            }
        }
        .animation(.easeInOut(duration: 0.4), value: progress)
    }
}

// Enhanced progress view style with idle/active states
struct SlickProgressViewStyle: ProgressViewStyle {
    let color: Color
    let isExpanded: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track - thinner and more subtle
                RoundedRectangle(cornerRadius: isExpanded ? 3 : 2) // Increased from 1 to 2
                    .fill(Color.primary.opacity(isExpanded ? 0.08 : 0.05))
                    .frame(height: isExpanded ? 6 : 4) // Increased from 2 to 4
                
                // Progress fill with beautiful gradient
                RoundedRectangle(cornerRadius: isExpanded ? 3 : 2) // Increased from 1 to 2
                    .fill(
                        LinearGradient(
                            colors: isExpanded ? [
                                color.opacity(0.7),
                                color,
                                color.opacity(0.9)
                            ] : [
                                color.opacity(0.6),
                                color.opacity(0.8)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(
                        width: geometry.size.width * CGFloat(configuration.fractionCompleted ?? 0),
                        height: isExpanded ? 6 : 4 // Increased from 2 to 4
                    )
                    .animation(.easeOut(duration: 0.5), value: configuration.fractionCompleted)
            }
        }
        .frame(height: isExpanded ? 6 : 4) // Increased from 2 to 4
    }
}

// ULTRA LIGHTWEIGHT - Zero-calculation state manager
class ProgressOverlayManager: ObservableObject {
    @Published var isActive = false
    @Published var progress: Double = 0.0
    
    private var activeTimer: Timer?
    
    // OPTIMIZATION: Store last known values to avoid any recalculation
    private var lastProgress: Double = 0.0
    private var lastActiveCount: Int = 0
    private var lastCompletedCount: Int = 0
    
    func showProgress(_ progress: Double) {
        // OPTIMIZATION: Skip if exactly the same
        if abs(self.progress - progress) < 0.001 {
            triggerActiveStateOnly()
            return
        }
        
        // Update progress
        self.progress = progress
        self.lastProgress = progress
        triggerActiveStateOnly()
    }
    
    // OPTIMIZATION: Direct count update (no calculation needed)
    func updateWithCounts(completed: Int, total: Int) {
        guard total > 0 else {
            self.progress = 0.0
            return
        }
        
        // Only update if counts actually changed
        if completed != lastCompletedCount || total != lastActiveCount {
            lastCompletedCount = completed
            lastActiveCount = total
            
            let newProgress = Double(completed) / Double(total)
            if abs(self.progress - newProgress) > 0.001 {
                self.progress = newProgress
            }
        }
    }
    
    private func triggerActiveStateOnly() {
        // OPTIMIZATION: Minimal animation
        if !isActive {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                self.isActive = true
            }
        }
        
        // Auto-hide after 2.5 seconds (increased from 1.5 seconds)
        activeTimer?.invalidate()
        activeTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { _ in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                self.isActive = false
            }
        }
    }
    
    func updateProgressSilently(_ progress: Double) {
        // Silent update without animation
        self.progress = progress
        self.lastProgress = progress
    }
    
    func setIdleState() {
        activeTimer?.invalidate()
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            isActive = false
        }
    }
    
    deinit {
        activeTimer?.invalidate()
    }
}

