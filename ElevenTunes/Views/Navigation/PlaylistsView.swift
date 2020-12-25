//
//  PlaylistsView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 18.12.20.
//

import SwiftUI

struct PlaylistsView: View {
    @ObservedObject var directory: Playlist
        
    @Environment(\.interpreter) private var interpreter: ContentInterpreter!

    var body: some View {
        List() {
            if !directory.isLoaded {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            }
            else {
                ForEach(directory.children) { playlist in
                    NavigationLink(destination: PlaylistView(playlist: playlist)) {
                        playlist.icon
                        Text(playlist[.ptitle] ?? "Unknown Playlist")
                    }
                }
            }
        }
        .onAppear { directory.load() }
        .frame(minWidth: 0, maxWidth: 800, maxHeight: .infinity)
        .onDrop(of: ContentInterpreter.types, delegate: PlaylistDropInterpreter(interpreter, parent: directory))
   }
}

struct PlaylistsView_Previews: PreviewProvider {
    static var previews: some View {
        PlaylistsView(directory: LibraryMock.directory())
    }
}
