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

	@ViewBuilder var contextMenu: some View {
		if let current = current {
			TrackActions(tracks: [current])()
		}
	}
	
    var body: some View {
        HStack {
            ZStack {
                Rectangle()
                    .fill(Color.black)
                    .opacity(0.2)
                
				TrackImageView(track: current)
            }
			.contextMenu(menuItems: { self.contextMenu })
            .frame(width: 28, height: 28)
            .cornerRadius(5)

            if let current = current {
                TrackCellView(track: current)
				
				Spacer()
				
				TrackTempoView(track: current)
				
				TrackKeyView(track: current)
					.padding(.horizontal)
				
				TrackDurationView(track: current)
					.frame(width: 52)
            }
            else {
                Text("Nothing Playing").opacity(0.5)
            }
        }
		.frame(height: 28)
        .padding(.top, 8)
        .onReceive(player.$current) { self.current = Track($0) }
		.id(current?.id)
    }
}
