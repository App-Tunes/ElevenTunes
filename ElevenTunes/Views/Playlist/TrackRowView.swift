//
//  TrackRowView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 28.12.20.
//

import Foundation
import SwiftUI

struct PlayTrackView: View {
    @State var track: Track
    @State var playlist: Playlist

    @Environment(\.player) private var player: Player!
    @State var current: Track?
    @State var next: Track?

    var body: some View {
        Button(action: {
            player.play(PlayHistory(playlist, at: track))
        }) {
            ZStack {
                if track == next {
                    Image(systemName: "play.fill")
                        .blinking(opacity: (0.35, 1), animates: player.$isAlmostNext)
                }
                else if track == current {
                    Image(systemName: "play.fill")
                        .opacity(track == current ? 1 : 0.35)
                }
                
                Image(systemName: "play")
            }
        }
        .buttonStyle(BorderlessButtonStyle())
        .disabled(!track.cacheMask.contains(.minimal))
        .onReceive(player.$current) { self.current = $0 }
        .onReceive(player.$next) { self.next = $0 }
    }
}

struct TrackRowView: View {
    @ObservedObject var track: Track
    @ObservedObject var playlist: Playlist
    
    @Environment(\.library) var library: Library!
    
    var body: some View {
        HStack {
            PlayTrackView(track: track, playlist: playlist)

            if !track.cacheMask.contains(.minimal) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(0.5, anchor: .center)
                
                Text("...")
            }
            else {
                track.icon.resizable().aspectRatio(contentMode: .fit).frame(width: 15, height: 15)
                
                Text(track[TrackAttribute.title] ?? "Unknown Track")
            }
        }
        .tag(track)
        .onAppear() { track.load(atLeast: .minimal, library: library) }
    }
}
