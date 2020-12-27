//
//  PlaylistsView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 18.12.20.
//

import SwiftUI

struct PlaylistRowView: View {
    @ObservedObject var playlist: Playlist
    
    @Environment(\.library) private var library: Library!

    var body: some View {
        HStack {
            if playlist._loadLevel < .minimal {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(0.5)
                
                Text("...").foregroundColor(Color.primary.opacity(0.5))
            }
            
            NavigationLink(destination: PlaylistView(playlist: playlist)) {
                playlist.icon.resizable().aspectRatio(contentMode: .fit).frame(width: 15, height: 15)
                Text(playlist[PlaylistAttribute.title] ?? "Unknown Playlist")
            }
        }
        .frame(height: 15)
        .onAppear { playlist.load(atLeast: .minimal, context: library.player.context) }
    }
}

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
