//
//  PlayingTrackView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 01.01.21.
//

import Foundation

import SwiftUI
import Combine

struct FullTrackCellView: View {
	@State var track: Track?
	
	@ViewBuilder var contextMenu: some View {
		if let track = track {
			TrackActions(tracks: [track])()
		}
	}

	var body: some View {
		HStack {
			ZStack {
				Rectangle()
					.fill(Color.black)
					.opacity(0.2)
				
				TrackImageView(track: track)
			}
			.contextMenu(menuItems: { self.contextMenu })
			.frame(width: 28, height: 28)
			.cornerRadius(5)

			if let track = track {
				TrackCellView(track: track)
				
				Spacer()
				
				TrackTempoView(track: track)
				
				TrackKeyView(track: track)
					.padding(.horizontal)
				
				TrackDurationView(track: track)
					.frame(width: 60)
			}
			else {
				Text("Nothing Playing").opacity(0.5)
				
				Spacer()
			}
		}
	}
}

struct PlayingTrackView: View {
    @State var player: Player

	@State var current: Track?

    var body: some View {
		FullTrackCellView(track: current)
			.frame(height: 28)
			.padding(.top, 8)
			.onReceive(player.$current) { newTrack in
				guard newTrack?.id != current?.id else {
					return
				}
				
				self.current = Track(newTrack)
			}
			.id(current?.id)
    }
}
