//
//  CreateHabitNavigationHeader.swift
//  Habital
//
//  Created by Elias Osarumwense on 23.08.25.
//

import SwiftUI

struct CreateHabitNavigationHeader: View {
    let selectedColor: Color
    let isNameEmpty: Bool
    let dismiss: () -> Void
    let createAction: () -> Void
    
    var body: some View {
        HStack {
            // Cancel button
            Button(action: dismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.red)
                    .frame(width: 32, height: 32)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            
            Spacer()
            
            // Title
            Text("Create Habit")
                .font(.custom("Lexend-Bold", size: 20))
                .foregroundColor(.primary)
            
            Spacer()
            
            // Save button
            Button(action: createAction) {
                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isNameEmpty ? .gray : selectedColor)
                    .frame(width: 32, height: 32)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .disabled(isNameEmpty)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 16)
    }
}
