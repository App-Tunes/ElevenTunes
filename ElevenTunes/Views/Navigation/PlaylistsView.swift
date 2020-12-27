//
//  PlaylistsView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 18.12.20.
//

import SwiftUI

struct PlaylistsView: View {
    @ObservedObject var directory: Playlist
        
    @Environment(\.library) private var library: Library!

    var body: some View {
        List {
            ForEach(directory.children!, id: \.id) { playlist in
                if playlist.backend.supportsChildren() {
                    OutlineGroup(playlist, children: \.children ) { playlist in
                        PlaylistRowView(playlist: playlist)
                            .padding(.leading, 8)
                    }
                    .frame(height: 20)
                }
                else {
                    PlaylistRowView(playlist: playlist)
                }
            }
        }
        .frame(minWidth: 0, maxWidth: 800, maxHeight: .infinity)
        .onDrop(of: ContentInterpreter.types, delegate: PlaylistDropInterpreter(library.interpreter, parent: directory))
   }
}

struct PlaylistsView_Previews: PreviewProvider {
    static var previews: some View {
        PlaylistsView(directory: Playlist(LibraryMock.directory()))
    }
}
