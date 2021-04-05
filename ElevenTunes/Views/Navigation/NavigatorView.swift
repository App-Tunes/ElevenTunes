//
//  NavigatorView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 15.12.20.
//

import SwiftUI
import Combine

struct NavigatorView: View {
	let navigator: Navigator
	
    @Environment(\.library) private var library: Library!

    var body: some View {
		ZStack(alignment: .top) {
			VStack(spacing: 0) {
				NavigationSearchBar()
					.padding()
					.visualEffectBackground(material: .sidebar)

				PlaylistsView(directory: navigator.root, navigator: navigator)
					.frame(maxWidth: .infinity, maxHeight: .infinity)
					.layoutPriority(2)

				NavigationBarView(playlist: navigator.root, navigator: navigator)
			}

			VisualEffectView(material: .sidebar, blendingMode: .behindWindow, emphasized: false)
				.frame(height: 50)
				.edgesIgnoringSafeArea(.top)
		}
    }
}

//struct NavigatorView_Previews: PreviewProvider {
//    static var previews: some View {
//        NavigatorView(directory: Playlist(LibraryMock.directory()))
//    }
//}
