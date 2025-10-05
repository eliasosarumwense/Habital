//
//  TesScroller.swift
//  Habital
//
//  Created by Elias Osarumwense on 21.05.25.
//

import SwiftUI

// Preference key to track scroll offset

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGPoint = .zero
    
    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {
        value = nextValue()
    }
}

struct BlurredScrollView2<Content: View>: View {
    let content: Content
    let blur: CGFloat
    let coordinateSpaceName = "scroll"
    
    @State private var scrollPosition: CGPoint = .zero
    
    init(blur: CGFloat = 10, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.blur = blur
    }
    
    var body: some View {
        let gradient = LinearGradient(
            stops: [
                Gradient.Stop(color: .white, location: 0.10),
                Gradient.Stop(color: .clear, location: 0.25)
            ],
            startPoint: .bottom,
            endPoint: .top
        )
        
        let invertedGradient = LinearGradient(
            stops: [
                Gradient.Stop(color: .clear, location: 0.10),
                Gradient.Stop(color: .white, location: 0.25)
            ],
            startPoint: .bottom,
            endPoint: .top
        )
        
        GeometryReader { topGeo in
            ScrollView {
                ZStack(alignment: .top) {
                    content
                        .mask(
                            VStack {
                                invertedGradient
                                    .frame(height: topGeo.size.height, alignment: .top)
                                    .offset(y: -scrollPosition.y)
                                Spacer()
                            }
                        )
                    
                    content
                        .blur(radius: blur)
                        .frame(height: topGeo.size.height, alignment: .top)
                        .mask(
                            gradient
                                .frame(height: topGeo.size.height)
                                .offset(y: -scrollPosition.y)
                        )
                        .ignoresSafeArea()
                }
                .padding(.bottom, topGeo.size.height * 0.25)
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .preference(key: ScrollOffsetPreferenceKey.self, value: geo.frame(in: .named(coordinateSpaceName)).origin)
                    }
                )
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    scrollPosition = value
                }
            }
            .coordinateSpace(name: coordinateSpaceName)
        }
        .ignoresSafeArea()
    }
}

// Preview for testing
struct BlurredScrollView2_Previews: PreviewProvider {
    static var previews: some View {
        BlurredScrollView2 {
            VStack {
                ForEach(0..<50) { index in
                    Text("Item \(index)")
                        .frame(height: 50)
                }
            }
        }
    }
}
