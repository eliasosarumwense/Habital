//
//  ShadowModifier.swift
//  Habital
//
//  Created by Elias Osarumwense on 09.04.25.
//
import SwiftUI

struct AdaptiveShadowModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    
    func body(content: Content) -> some View {
        if colorScheme == .light {
            content
                .shadow(color: Color(.sRGB, white: 0, opacity: 0.2), radius: 1.5, x: 0, y: 1)
        } else {
            content
                .shadow(color: Color(.sRGB, white: 1, opacity: 0.1), radius: 1, x: 0, y: 1)
        }
    }
}
