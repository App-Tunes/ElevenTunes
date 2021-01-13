//
//  PlaylistsView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 18.12.20.
//

import SwiftUI
import Combine

struct PlaylistSectionView: View {
    @State var playlist: Playlist
    @State var children: [Playlist] = []
    
    var isTopLevel: Bool = false
    
    @ViewBuilder var _body: some View {
        if playlist.backend.contentType != .tracks {
            if isTopLevel {
                Section(header: PlaylistRowView(playlist: playlist)) {
                    ForEach(children) { child in
                        PlaylistSectionView(playlist: child)
                    }
                }
                .tag(playlist)
            }
            else {
                DisclosureGroup {
                    ForEach(children) { child in
                        PlaylistSectionView(playlist: child)
                    }
                } label: {
                    PlaylistRowView(playlist: playlist)
                }
                .tag(playlist)
            }
        }
        else {
            PlaylistRowView(playlist: playlist)
                .tag(playlist)
        }
    }
    
    var body: some View {
        _body
			.id(playlist.id)
			.whileActive(playlist.backend.demand([PlaylistAttribute.children]))
			.onReceive(playlist.backend.attribute(PlaylistAttribute.children)) {
				children ?= ($0.value ?? []).map(Playlist.init)
			}
    }
}

struct PlaylistsView: View {
    @State var directory: Playlist
    @State var topLevelChildren: [Playlist] = []
            
    var body: some View {
		ForEach(topLevelChildren) { category in
			PlaylistSectionView(playlist: category, isTopLevel: true)
		}
		
		Text("") // FIXME WTF, apparently updates aren't executed on empty views???
			.whileActive(directory.backend.demand([PlaylistAttribute.children]))
			.onReceive(directory.backend.attribute(PlaylistAttribute.children)) {
				topLevelChildren ?= ($0.value ?? []).map(Playlist.init)
			}
			.frame(minWidth: 0, maxWidth: 800, maxHeight: .infinity, alignment: .leading)
   }
}

//struct PlaylistsView_Previews: PreviewProvider {
//    static var previews: some View {
//        PlaylistsView(directory: Playlist(LibraryMock.directory()))
//    }
//}
