//
//  NavigatorView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 15.12.20.
//

import SwiftUI
import Combine

struct ContextualSelection<T: Hashable> {
	var insertPosition: (T, Int?)?
	var playlists: Set<T>
	
	static var empty: ContextualSelection {
		.init(insertPosition: nil, playlists: [])
	}
}

class Navigator: ObservableObject {
	@Published var selection: ContextualSelection<Playlist> = .empty
	
	var playlists: [Playlist] {
		selection.playlists.sorted { $0.id < $1.id }
	}
}

struct NavigatorView: View {
    let directory: Playlist
	@ObservedObject var navigator: Navigator
	
    @Environment(\.library) private var library: Library!

    var body: some View {
        VStack(spacing: 0) {
			NavigationSearchBar()
				.padding()
				.visualEffectBackground(material: .sidebar)

			PlaylistsView(directory: directory, selectionObserver: {
				navigator.selection = $0
			})
				.frame(maxWidth: .infinity, maxHeight: .infinity)
				.layoutPriority(2)

			NavigationBarView(playlist: directory, selection: navigator.selection)
        }
    }
}

//struct NavigatorView_Previews: PreviewProvider {
//    static var previews: some View {
//        NavigatorView(directory: Playlist(LibraryMock.directory()))
//    }
//}
