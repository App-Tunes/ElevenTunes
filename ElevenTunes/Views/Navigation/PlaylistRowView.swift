//
//  PlaylistBarView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 27.12.20.
//

import SwiftUI

struct PlaylistRowView: View {
    let playlist: Playlist

	@State var title: PlaylistAttributes.ValueSnapshot<String?> = .missing()
    
    var body: some View {
        HStack {
			if !title.state.isVersioned {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(0.4)
                    .frame(width: 15, height: 15)
                    // This is the dumbest shit but for whatever reason,
                    // if it's missing SwiftUI HStack won't add auto-spacing
                    .padding(.trailing, 0.001)
            }
            else {
                playlist.backend.icon
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(playlist.backend.accentColor)
                    .frame(width: 15, height: 15)
            }

            if title.state.isVersioned {
				Text(title.value ?? "Unknown Playlist")
//                        .opacity((playlist.tracks.isEmpty && playlist.children.isEmpty) ? 0.6 : 1)
            }
            else {
                Text(title.value ?? "...")
                    .opacity(0.5)
            }
        }
        .contextMenu(menuItems: PlaylistsContextMenu(playlist: playlist.backend).callAsFunction)
		.whileActive(playlist.backend.demand([.title]))
		.onReceive(playlist.backend.attribute(PlaylistAttribute.title)) { title ?= $0 }
		.frame(height: 15)
    }
}
