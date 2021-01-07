//
//  TracksView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 18.12.20.
//

import SwiftUI

struct TracksView: View {
    let playlist: Playlist
    
    @State var tracks: [AnyTrack] = []
    
    @State var selected: Set<Int> = []

    @Environment(\.library) private var library: Library!
    @Environment(\.player) private var player: Player!

    var body: some View {
        ZStack {
            List(selection: $selected) {
                ForEach(Array(tracks.enumerated()), id: \.0) { (idx, track) in
                    TrackRowView(track: Track(track), context: .playlist(playlist.backend, tracks: tracks, index: idx))
                        .frame(height: 26)
                        .contextMenu(menuItems: TracksContextMenu(tracks: tracks, idx: idx, selected: selected).callAsFunction)
                        .tag(idx)
                }
                .onMove { (source, dest) in
                    print(source)
                }
                
                Spacer()
                    // For bottom bar
                    .frame(height: 25)
            }
            
            Button.invisible {
                if let idx = selected.one {
                    player.play(PlayHistory(context: .playlist(playlist.backend, tracks: tracks, index: idx)))
                }
                else {
                    let tracks = selected.compactMap { self.tracks[$0] }
                    player.play(PlayHistory(tracks.shuffled()))
                }
            }
            .keyboardShortcut(.return, modifiers: [])
        }
        .onReceive(playlist.backend.tracks()) {
            self.tracks = $0
        }
        .frame(minWidth: 200, idealWidth: 250, maxWidth: .infinity, minHeight: 50, idealHeight: 150, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onDrop(of: ContentInterpreter.types, delegate: PlaylistDropInterpreter(library.interpreter, parent : playlist.backend))
    }
}
//
//struct TracksView_Previews: PreviewProvider {
//    static var previews: some View {
//        TracksView(playlist: Playlist(LibraryMock.playlist()))
//    }
//}
