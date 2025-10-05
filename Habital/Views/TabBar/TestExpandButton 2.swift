//
//  TestExpandButton.swift
//  Habital
//
//  Created by Elias Osarumwense on 07.08.25.
//

import SwiftUI

struct ExpandableButton2: View {
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ZStack {
                // Main button (always visible)
                Button(action: {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: "plus")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(Color.blue)
                        .clipShape(Circle())
                        .rotationEffect(.degrees(isExpanded ? 45 : 0))
                }
                
                // Left button
                Button(action: {
                    print("Left button tapped")
                }) {
                    Image(systemName: "heart.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 48, height: 48)
                        .background(Color.red)
                        .clipShape(Circle())
                }
                .offset(x: isExpanded ? -80 : 0, y: isExpanded ? -80 : 0)
                .opacity(isExpanded ? 1 : 0)
                .scaleEffect(isExpanded ? 1 : 0.5)
                
                // Middle button
                Button(action: {
                    print("Middle button tapped")
                }) {
                    Image(systemName: "star.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 48, height: 48)
                        .background(Color.orange)
                        .clipShape(Circle())
                }
                .offset(x: 0, y: isExpanded ? -80 : 0)
                .opacity(isExpanded ? 1 : 0)
                .scaleEffect(isExpanded ? 1 : 0.5)
                
                // Right button
                Button(action: {
                    print("Right button tapped")
                }) {
                    Image(systemName: "bookmark.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 48, height: 48)
                        .background(Color.green)
                        .clipShape(Circle())
                }
                .offset(x: isExpanded ? 80 : 0, y: isExpanded ? -80 : 0)
                .opacity(isExpanded ? 1 : 0)
                .scaleEffect(isExpanded ? 1 : 0.5)
            }
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Preview
struct ExpandableButton2_Previews: PreviewProvider {
    static var previews: some View {
        ExpandableButton2()
            .preferredColorScheme(.light)
            .previewDisplayName("Light Mode")
        
        ExpandableButton2()
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
    }
}
