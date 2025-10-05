//
//  Untitled.swift
//  Habital
//
//  Created by Elias Osarumwense on 26.07.25.
//
import SwiftUI

struct IconView: View {
    var icon: String
    var title: String
    var withBGColor: Bool
    var action: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(withBGColor ? .clear : .primary)
                .padding(10)
                .background(withBGColor ? .clear : .clear,in:.circle)
                .overlay {
                    Circle()
                        .stroke(lineWidth: withBGColor ? 0 : 2)
                        .foregroundStyle(.gray)
                        .padding(2)
                }
            
            Text(title)
        }
        .onTapGesture {
            action()
        }
    }
}

