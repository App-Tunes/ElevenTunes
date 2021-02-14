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
	let selectionObserver: (Set<Playlist>) -> Void

	@Environment(\.library) private var library: Library!

	func makeNSViewController(context: Context) -> PlaylistsViewController {
		PlaylistsViewController(directory, library: library, selectionObserver: selectionObserver)
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
