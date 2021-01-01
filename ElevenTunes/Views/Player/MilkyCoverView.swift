//
//  MilkCoverView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 01.01.21.
//

import SwiftUI
import Combine

struct PlayerMilkyCoverView: View {
    @Environment(\.player) private var player: Player!

    @State var track: AnyTrack?
    
    var body: some View {
        MilkyCoverView(track: track)
            .onReceive(player.$current) { track = $0 }
    }
}

struct MilkyCoverView: View {
    var track: AnyTrack?
    
    @State var image: NSImage? = nil

    var body: some View {
        MilkyImageView(image: image)
            .onReceive(track?.previewImage(), default: nil) { image in
                withAnimation(.linear(duration: 0.5)) {
                    self.image = image
                }
            }
    }
}

struct MilkyCoverView_Previews: PreviewProvider {
    static var previews: some View {
        MilkyCoverView()
    }
}
