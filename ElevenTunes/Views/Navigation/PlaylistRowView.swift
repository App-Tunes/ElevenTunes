//
//  PlaylistBarView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 27.12.20.
//

import SwiftUI

struct PlaylistRowView: View {
    @ObservedObject var playlist: Playlist
    
    @Environment(\.library) private var library: Library!

    var body: some View {
        HStack {
            playlist.icon.resizable().aspectRatio(contentMode: .fit).frame(width: 15, height: 15)

            if playlist._loadLevel < .minimal {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(0.5)
                
                Text(playlist[PlaylistAttribute.title] ?? "...")
                    .foregroundColor(Color.primary.opacity(0.5))
            }
            else {
                NavigationLink(destination: PlaylistView(playlist: playlist)) {
                    Text(playlist[PlaylistAttribute.title] ?? "Unknown Playlist")
                }
            }
        }
        .frame(height: 15)
        .onAppear { playlist.load(atLeast: .minimal, library: library) }
    }
}
