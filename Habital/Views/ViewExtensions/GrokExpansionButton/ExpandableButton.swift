//
//  ExpandableButton.swift
//  Habital
//
//  Created by Elias Osarumwense on 26.07.25.
//

import SwiftUI

struct ExpandableButton: View {
    @State var showMenu = false
    
    var body: some View {
        ZStack {
            if showMenu {
                let layout = AnyLayout(VStackLayout(alignment: .leading, spacing: 20))
                
                layout {
                    IconView(icon: "camera", title: "Camera", withBGColor: true, action: {
                        print("done")
                        showMenu = false
                    })
                    
                    IconView(icon: "photo.on.rectangle", title: "Photos",
                             withBGColor: true, action: {})
                    IconView(icon: "doc.on.doc", title: "File",
                    withBGColor: true, action: {})
                    .padding(.bottom, showMenu ? 40 : 0)
                    IconView(icon: "sparkles.rectangle.stack", title: "Create image",
                    withBGColor: false, action: {})
                    IconView(icon: "wand.and.rays", title: "Edit image",
                    withBGColor: false, action: {})
                }
                .blur(radius: showMenu ? 0 : 10)
                .opacity(showMenu ? 1 : 0)
                .padding(.horizontal, showMenu ? 47 : 25)
                .padding(.bottom, showMenu ? 90 : 25)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                .background(
                    .ultraThinMaterial
                        .opacity(showMenu ? 1 : 0)
                )
                .onTapGesture {
                    showMenu = false
                }
                .animation(.spring(duration: 0.2), value: showMenu)
            }
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Image(systemName: "paperclip")
                        .padding(10)
                        .background(.gray.opacity(0.3), in: .rect(cornerRadius: 42))
                        .onTapGesture { withAnimation { showMenu = true } }
                }
            }
        }
    }
}

#Preview {
    ExpandableButton()
}
