//
//  TracksView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 18.12.20.
//

import SwiftUI

struct TracksView: View {
    @State var playlist: AnyPlaylist
    
    @State var tracks: [AnyTrack] = []
    
    @State var selected: Set<Int> = []

    @Environment(\.library) private var library: Library!
    @Environment(\.player) private var player: Player!

    var body: some View {
        ZStack {
            List(selection: $selected) {
                ForEach(Array(tracks.enumerated()), id: \.0) { (idx, track) in
                    TrackRowView(track: track, context: .playlist(playlist, tracks: tracks, index: idx))
                        .frame(height: 26)
                        .contextMenu {
                            Button(action: {
                                for idx in selected.alIfContains(idx) {
                                    tracks[idx].invalidateCaches([.minimal])
                                }
                            }) {
                                Image(systemName: "arrow.clockwise")
                                Text("Reload Metadata")
                            }
                        }
                        .tag(idx)
                }
            }
            
            Button.invisible {
                if let idx = selected.one {
                    player.play(PlayHistory(context: .playlist(playlist, tracks: tracks, index: idx)))
                }
                else {
                    let tracks = selected.compactMap { self.tracks[$0] }
                    player.play(PlayHistory(tracks.shuffled()))
                }
            }
            .keyboardShortcut(.return, modifiers: [])
        }
        .onReceive(playlist.tracks()) {
            self.tracks = $0
        }
        .frame(minWidth: 200, maxWidth: .infinity, minHeight: 50, maxHeight: .infinity)
        .onDrop(of: ContentInterpreter.types, delegate: PlaylistDropInterpreter(library.interpreter, parent : playlist))
    }
}
//
//struct TracksView_Previews: PreviewProvider {
//    static var previews: some View {
//        TracksView(playlist: Playlist(LibraryMock.playlist()))
//    }
//}
