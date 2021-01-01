//
//  PlaylistBarView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 27.12.20.
//

import SwiftUI

struct PlaylistRowView: View {
    @State var playlist: AnyPlaylist
    
    @State var contentMask: PlaylistContentMask = []
    @State var attributes: TypedDict<PlaylistAttribute> = .init()
    
    func title(_ text: String) -> Text {
        // TODO false = isTopLevel
        if false, playlist.supportsChildren() {
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
            if !contentMask.contains(.minimal) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(0.5)
            }
            else {
                playlist.icon
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 15, height: 15)
                    .foregroundColor(playlist.accentColor)
            }

            NavigationLink(destination: PlaylistView(playlist: playlist)) {
                if contentMask.contains(.minimal) {
                    title(attributes[PlaylistAttribute.title] ?? "Unknown Playlist")
//                        .opacity((playlist.tracks.isEmpty && playlist.children.isEmpty) ? 0.6 : 1)
                }
                else {
                    title(attributes[PlaylistAttribute.title] ?? "...")
                        .opacity(0.5)
                }
            }
        }
        .contextMenu(menuItems: PlaylistsContextMenu(playlist: playlist).callAsFunction)
        // TODO false = isTopLevel
        .frame(height: false ? 24 : 4) // The 4 is ridiculous but this counteracts the enormous default padding lol
        .onReceive(playlist.cacheMask()) { contentMask = $0 }
        .onReceive(playlist.attributes()) { attributes = $0 }
    }
}
