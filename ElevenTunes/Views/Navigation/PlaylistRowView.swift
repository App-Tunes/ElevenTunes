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

    func title(_ text: String) -> Text {
        if playlist.isTopLevel, playlist.backend.supportsChildren() {
            return Text(text)
                .bold()
                .foregroundColor(.secondary)
        }
        else {
            return Text(text)
        }
    }
        
    var body: some View {
        HStack {
            playlist.icon
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 15, height: 15)
                .foregroundColor((playlist.isTopLevel && playlist.backend.supportsChildren()) ? .secondary : .primary)

            if playlist._loadLevel < .minimal {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(0.5)
                
                title(playlist[PlaylistAttribute.title] ?? "...")
                    .opacity(0.5)
            }
            else {
                NavigationLink(destination: PlaylistView(playlist: playlist)) {
                    title(playlist[PlaylistAttribute.title] ?? "Unknown Playlist")
                }
            }
        }
        .frame(height: playlist.isTopLevel ? 24 : 12)
        .onAppear { playlist.load(atLeast: .minimal, library: library) }
    }
}
