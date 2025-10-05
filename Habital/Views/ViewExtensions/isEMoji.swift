//
//  isEMoji.swift
//  Habital
//
//  Created by Elias Osarumwense on 14.08.25.
//
import SwiftUI

extension Character {
    var isEmoji: Bool {
        guard let scalar = unicodeScalars.first else { return false }
        return scalar.properties.isEmoji && (scalar.value > 0x231A || unicodeScalars.count > 1)
    }
}  
