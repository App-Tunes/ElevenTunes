//
//  PlayingTrackView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 01.01.21.
//

import Foundation

import SwiftUI
import Combine

struct PlayingTrackView: View {
    @State var player: Player

    @State var current: Track?
    @State var attributes: TypedDict<TrackAttribute> = .init()
    @State var image: NSImage?

    var body: some View {
        HStack {
            ZStack {
                Rectangle()
                    .fill(Color.black)
                    .opacity(0.2)
                
                if let image = image {
                    Image(nsImage: image)
                        .resizable().scaledToFit()
                }
                else {
                    Image(systemName: "music.note")
                }
            }
            .frame(width: 24, height: 24)
            .cornerRadius(5)

            if let current = current {
                TrackCellView(track: current, showType: false)
            }
            else {
                Text("Nothing Playing").opacity(0.5)
            }
        }
        .padding(.top, 8)
        .onReceive(player.$current) { self.current = Track($0) }
        .onReceive(current?.backend.previewImage(), default: nil) { self.image = $0 }
    }
}
