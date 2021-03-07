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

    var body: some View {
        HStack {
            ZStack {
                Rectangle()
                    .fill(Color.black)
                    .opacity(0.2)
                
				TrackImageView(track: current)
            }
            .frame(width: 28, height: 28)
            .cornerRadius(5)

            if let current = current {
                TrackCellView(track: current)
				
				Spacer()
				
				TrackTempoView(track: current)
				
				TrackKeyView(track: current)
					.padding(.leading)
            }
            else {
                Text("Nothing Playing").opacity(0.5)
            }
        }
        .padding(.top, 8)
        .onReceive(player.$current) { self.current = Track($0) }
		.id(current?.id)
    }
}
