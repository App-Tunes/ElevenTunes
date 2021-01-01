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

    var body: some View {
        Button(action: {
            player.play(PlayHistory(context: context))
        }) {
            ZStack {
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
            }
        }
        .buttonStyle(BorderlessButtonStyle())
        .onReceive(player.$current) { self.current = $0 }
        .onReceive(player.$next) { self.next = $0 }
    }
}
