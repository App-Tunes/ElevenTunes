//
//  PlayTrackView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 01.01.21.
//

import SwiftUI
import Combine

struct PlayTrackView: View {
    let track: Track
    @State var context: PlayHistoryContext

    @Environment(\.player) private var player: Player!
    @State var current: AnyTrack?
    @State var next: AnyTrack?

    @State var isHovering = false
    
    var body: some View {
        Button(action: {
            player.play(PlayHistory(context: context))
        }) {
            ZStack(alignment: .center) {
                Rectangle()
                    .fill(Color.black)
                    .opacity(0.7)
                    .opacity((isHovering || [next?.id, current?.id].contains(track.id)) ? 1 : 0)

                if track.id == next?.id {
                    Image(systemName: "play.fill")
                        .blinking(
                            // If track is next AND current, start with 1 and blink downwards.
                            // otherwise, start half translucent and blink upwards
                            opacity: track.id == current?.id ? (1, 0.5) : (0.35, 1),
                            animates: player.$isAlmostNext
                        )
                }
                else if track.id == current?.id {
                    Image(systemName: "play.fill")
                }
                
                Image(systemName: "play")
                    .opacity(isHovering ? 1 : 0)
            }
        }
        .onHover { isHovering = $0 }
        .buttonStyle(BorderlessButtonStyle())
        .onReceive(player.$current) { self.current = $0 }
        .onReceive(player.$next) { self.next = $0 }
    }
}

struct PlayTrackImageView: View {
	let track: Track
	
	@State var context: PlayHistoryContext

	var body: some View {
		ZStack(alignment: .center) {
			Rectangle()
				.fill(Color.black)
				.opacity(0.2)
			
			TrackImageView(track: track)
			
			PlayTrackView(track: track, context: context)
				.font(.system(size: 14))
		}
		.cornerRadius(5)
	}
}
