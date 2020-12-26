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
            if directory._loadLevel < .minimal {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            }
            else if directory._children.isEmpty {
                Text("No Contents!")
            }
            else {
                ForEach(directory._children.map { Playlist($0) }) { playlist in
                    NavigationLink(destination: PlaylistView(playlist: playlist)) {
                        playlist.icon
                        Text(playlist[PlaylistAttribute.title] ?? "Unknown Playlist")
                    }
                    .onAppear { playlist.load(atLeast: .minimal) }
                }
            }
        }
        .onAppear { directory.load(atLeast: .minimal) }
        .frame(minWidth: 0, maxWidth: 800, maxHeight: .infinity)
        .onDrop(of: ContentInterpreter.types, delegate: PlaylistDropInterpreter(interpreter, parent: directory))
   }
}

struct PlaylistsView_Previews: PreviewProvider {
    static var previews: some View {
        PlaylistsView(directory: Playlist(LibraryMock.directory()))
    }
}
