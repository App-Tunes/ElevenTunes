//
//  TracksView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 18.12.20.
//

import SwiftUI

struct TracksView: View {
    @ObservedObject var playlist: Playlist
    @State var tracks: [Track] = []
    
    @State var selected: Set<Track> = []

    @Environment(\.library) private var library: Library!
    
    var body: some View {
        List(selection: $selected) {
            ForEach(tracks) { track in
                TrackRowView(track: track, playlist: playlist)
                    .frame(height: 15)
                    .contextMenu {
                        Button(action: {
                            for track in selected.alIfContains(track) {
                                track.invalidateCaches([.minimal], reloadWith: library)
                            }
                        }) {
                            Image(systemName: "arrow.clockwise")
                            Text("Reload Metadata")
                        }
                    }
                    .tag(track)
            }
        }
        .onReceive(playlist.$tracks) { tracks = $0.map(Track.init) }
        .frame(minWidth: 200, maxWidth: .infinity, minHeight: 50, maxHeight: .infinity)
        .onDrop(of: ContentInterpreter.types, delegate: PlaylistDropInterpreter(library.interpreter, parent : playlist))
    }
}

struct TracksView_Previews: PreviewProvider {
    static var previews: some View {
        TracksView(playlist: Playlist(LibraryMock.playlist()))
    }
}
