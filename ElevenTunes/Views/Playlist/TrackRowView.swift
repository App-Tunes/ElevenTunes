//
//  TrackRowView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 28.12.20.
//

import Foundation
import SwiftUI

struct PlayTrackView: View {
    @State var track: AnyTrack
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

struct TrackRowView: View {
    @State var track: AnyTrack
    @State var context: PlayHistoryContext

    @State var attributes: TypedDict<TrackAttribute> = .init()
    @State var contentMask: TrackContentMask = []

    @Environment(\.library) var library: Library!
    
    var body: some View {
        HStack {
            PlayTrackView(track: track, context: context)

            if !contentMask.contains(.minimal) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(0.5, anchor: .center)
                
                Text(attributes[TrackAttribute.title] ?? "...")
                    .opacity(0.5)
            }
            else {
                track.icon.resizable().aspectRatio(contentMode: .fit).frame(width: 15, height: 15)
                
                Text(attributes[TrackAttribute.title] ?? "Unknown Track")
            }
        }
        .onReceive(track.attributes()) { attributes = $0 }
        .onReceive(track.cacheMask()) { contentMask = $0 }
    }
}
