//
//  BlinkingImage.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 27.12.20.
//

import Foundation

import SwiftUI
import Combine

extension Image {
    func blinking(opacity: (Double, Double), animates: Published<Bool>.Publisher) -> BlinkingImage {
        BlinkingImage(image: self, opacity: opacity, animates: animates)
    }
}

struct BlinkingImage: View {
    @State var image: Image
    @State var opacity: (Double, Double)
    @State var animates: Published<Bool>.Publisher
    
    @State var animatingOpacity: Double = 0
    @State var animation: Animation = Animation.linear(duration: 0.6)
    
    var body: some View {
        image.opacity(animatingOpacity)
        .onAppear {
            withAnimation(.instant) { animatingOpacity = opacity.0 }
        }
        .onReceive(animates) {
            if $0 {
                withAnimation(animation.repeatForever()) { animatingOpacity = opacity.1 }
            }
            else {
                withAnimation(animation) { animatingOpacity = opacity.0 }
            }
        }
    }
}
