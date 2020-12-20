//
//  PlaylistsView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 18.12.20.
//

import SwiftUI

struct PlaylistsView: View {
    @ObservedObject var directory: Playlist
        
    @Environment(\.playlistInterpreter) private var playlistInterpreter: PlaylistInterpreter

    var body: some View {
        List() {
            ForEach(directory.children) { playlist in
                NavigationLink(destination: PlaylistView(playlist: playlist)) {
                    Text(playlist[.ptitle])
                }
            }
        }
        .frame(minWidth: 0, maxWidth: 800, maxHeight: .infinity)
        .onDrop(of: PlaylistInterpreter.types, delegate: PlaylistDropInterpreter(playlistInterpreter, parent: directory))
   }
}

struct PlaylistsView_Previews: PreviewProvider {
    static var previews: some View {
        PlaylistsView(directory: LibraryMock.directory())
    }
}
