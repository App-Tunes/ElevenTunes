//
//  PlaylistsView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 18.12.20.
//

import SwiftUI
import Combine

struct PlaylistSectionView: View {
	let playlist: Playlist
	let selection: Set<Playlist>
	
    @State var children: [Playlist] = []
    
    var isTopLevel: Bool = false
    
    @ViewBuilder var _body: some View {
        if playlist.backend.contentType != .tracks {
            if isTopLevel {
                Section(header:
					PlaylistRowView(playlist: playlist)
						.contextMenu(menuItems: PlaylistsContextMenu(playlist: playlist, selection: selection).callAsFunction)
				) {
                    ForEach(children) { child in
						PlaylistSectionView(playlist: child, selection: selection)
                    }
                }
                .tag(playlist)
            }
            else {
                DisclosureGroup {
                    ForEach(children) { child in
                        PlaylistSectionView(playlist: child, selection: selection)
                    }
                } label: {
                    PlaylistRowView(playlist: playlist)
						.contextMenu(menuItems: PlaylistsContextMenu(playlist: playlist, selection: selection).callAsFunction)
                }
                .tag(playlist)
            }
        }
        else {
            PlaylistRowView(playlist: playlist)
				.contextMenu(menuItems: PlaylistsContextMenu(playlist: playlist, selection: selection).callAsFunction)
				.tag(playlist)
        }
    }
    
    var body: some View {
        _body
			.id(playlist.id)
			.whileActive(playlist.backend.demand([PlaylistAttribute.children]))
			.onReceive(playlist.backend.attribute(PlaylistAttribute.children)) { newValue in
				withAnimation {
					children ?= (newValue.value ?? []).map(Playlist.init)
				}
			}
    }
}

struct PlaylistsView: View {
    let directory: Playlist
	let selection: Set<Playlist>

	@State var topLevelChildren: [Playlist] = []
            
    var body: some View {
		ForEach(topLevelChildren) { category in
			PlaylistSectionView(playlist: category, selection: selection, isTopLevel: true)
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
