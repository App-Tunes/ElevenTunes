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
        List(directory.topLevelChildren, children: \.viewChildren) { playlist in
            PlaylistRowView(playlist: playlist)
                .onAppear { playlist.load(atLeast: [.minimal, .children], library: library) }
                .padding(.leading, 8)
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
