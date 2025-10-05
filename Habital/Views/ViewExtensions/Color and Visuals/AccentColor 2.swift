//
//  AccentColor.swift
//  Habital
//
//  Created by Elias Osarumwense on 12.04.25.
//

import SwiftUI

struct ColorPalette {
    // Predefined accent color options
    static let accentColors: [Color] = [
        .primary.opacity(0.7), .blue.opacity(0.5), .red.opacity(0.5), .green.opacity(0.5), .orange.opacity(0.5), .purple.opacity(0.5),
         .yellow.opacity(0.5), .mint.opacity(0.5)
    ]
    
    // Helper method to get color by index safely
    static func color(at index: Int) -> Color {
        guard accentColors.indices.contains(index) else {
            return .primary // Default to blue if index is invalid
        }
        return accentColors[index]
    }
}

// Helper extension for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

extension Color {
    func blended(with other: Color) -> Color {
        // Simple color blending - you might want to use a more sophisticated approach
        return Color(
            red: (self.components.red + other.components.red) / 2,
            green: (self.components.green + other.components.green) / 2,
            blue: (self.components.blue + other.components.blue) / 2,
            opacity: max(self.components.opacity, other.components.opacity)
        )
    }
    
    private var components: (red: Double, green: Double, blue: Double, opacity: Double) {
        // This is a simplified approach - in production you'd want to use UIColor conversion
        return (red: 1.0, green: 1.0, blue: 1.0, opacity: 1.0) // Placeholder
    }
}

extension Color {
    var red: Double {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        uiColor.getRed(&red, green: nil, blue: nil, alpha: nil)
        return Double(red)
    }
    
    var green: Double {
        let uiColor = UIColor(self)
        var green: CGFloat = 0
        uiColor.getRed(nil, green: &green, blue: nil, alpha: nil)
        return Double(green)
    }
    
    var blue: Double {
        let uiColor = UIColor(self)
        var blue: CGFloat = 0
        uiColor.getRed(nil, green: nil, blue: &blue, alpha: nil)
        return Double(blue)
    }
}
