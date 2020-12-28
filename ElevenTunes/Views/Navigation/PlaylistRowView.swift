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
                .foregroundColor(playlist.accentColor)
                .saturation(0.5)

            if !playlist.cacheMask.contains(.minimal) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(0.5)
                
                title(playlist[PlaylistAttribute.title] ?? "...")
                    .opacity(0.5)
            }
            else {
                NavigationLink(destination: PlaylistView(playlist: playlist)) {
                    title(playlist[PlaylistAttribute.title] ?? "Unknown Playlist")
                        .opacity((playlist.tracks.isEmpty && playlist.children.isEmpty) ? 0.6 : 1)
                }
            }
        }
        .frame(height: playlist.isTopLevel ? 24 : 4) // The 4 is ridiculous but this counteracts the enormous default padding lol
    }
}
