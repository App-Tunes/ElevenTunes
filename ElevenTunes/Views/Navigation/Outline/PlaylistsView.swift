//
//  PlaylistsView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 18.12.20.
//

import SwiftUI
import Combine

struct PlaylistsView: NSViewControllerRepresentable {
	let directory: Playlist
	let selectionObserver: (ContextualSelection<Playlist>) -> Void

	@Environment(\.library) private var library: Library!

	func makeNSViewController(context: Context) -> PlaylistsViewController {
		PlaylistsViewController(directory, library: library)
	}
	
	func updateNSViewController(_ nsViewController: PlaylistsViewController, context: Context) {
		setIfDifferent(nsViewController, \.directory, directory)
		nsViewController.library = library
		nsViewController.selectionObserver = selectionObserver
	}
}

//struct PlaylistsView_Previews: PreviewProvider {
//    static var previews: some View {
//        PlaylistsView(directory: Playlist(LibraryMock.directory()))
//    }
//}
