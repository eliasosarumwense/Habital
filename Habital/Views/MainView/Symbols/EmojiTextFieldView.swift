//
//  EmojiTextFieldView.swift
//  Habital
//
//  Created by Elias Osarumwense on 11.04.25.
//

import SwiftUI

struct EmojiTextField: View {
    @Binding var text: String
    let color: Color
    let onSubmit: (String) -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Enter a single emoji")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
            
            HStack {
                TextField("", text: $text)
                    .font(.system(size: 24))
                    .frame(height: 44)
                    .padding(.horizontal, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .multilineTextAlignment(.center)
                    .onChange(of: text) { newValue in
                        // Limit to just the first emoji character
                        if newValue.count > 0 {
                            let firstEmoji = String(newValue.first ?? Character(""))
                            if firstEmoji != text {
                                text = firstEmoji
                            }
                        }
                    }
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .placeholder(when: text.isEmpty) {
                        Text("Type emoji")
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                
                Button(action: {
                    if !text.isEmpty {
                        onSubmit(text)
                        text = ""
                    }
                }) {
                    Text("Use")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(colorScheme == .dark ? .black : .white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(text.isEmpty ? Color.gray : color)
                        .cornerRadius(8)
                        .opacity(text.isEmpty ? 0.5 : 1.0)
                }
                .disabled(text.isEmpty)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

// Extension to create a placeholder for TextField
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .center,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

// Preview for development
struct EmojiTextField_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            EmojiTextField(
                text: .constant(""),
                color: .blue,
                onSubmit: { _ in }
            )
            .previewDisplayName("Light Mode")
            
            EmojiTextField(
                text: .constant(""),
                color: .blue,
                onSubmit: { _ in }
            )
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
