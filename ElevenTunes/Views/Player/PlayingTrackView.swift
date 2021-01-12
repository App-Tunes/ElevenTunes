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
	@State var image: TrackAttributes.ValueSnapshot<NSImage?> = .missing()

    var body: some View {
        HStack {
            ZStack {
                Rectangle()
                    .fill(Color.black)
                    .opacity(0.2)
                
				if let image = image.value {
                    Image(nsImage: image)
                        .resizable().scaledToFit()
                }
                else {
                    Image(systemName: "music.note")
                }
            }
            .frame(width: 28, height: 28)
            .cornerRadius(5)

            if let current = current {
                TrackCellView(track: current)
            }
            else {
                Text("Nothing Playing").opacity(0.5)
            }
        }
        .padding(.top, 8)
        .onReceive(player.$current) { self.current = Track($0) }
		.whileActive(current?.backend.demand([.previewImage]))
		.onReceive(current?.backend.attributes.filtered(toJust: TrackAttribute.previewImage), default: .missing()) { self.image = $0 }
    }
}
