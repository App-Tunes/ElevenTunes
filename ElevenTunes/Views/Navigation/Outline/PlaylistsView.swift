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
	let navigator: Navigator

	@Environment(\.library) private var library: Library!

	func makeNSViewController(context: Context) -> PlaylistsViewController {
		PlaylistsViewController(directory, library: library, navigator: navigator)
	}
	
	func updateNSViewController(_ nsViewController: PlaylistsViewController, context: Context) {
		setIfDifferent(nsViewController, \.directory, directory)
		nsViewController.library = library
		nsViewController.navigator = navigator
	}
}

//struct PlaylistsView_Previews: PreviewProvider {
//    static var previews: some View {
//        PlaylistsView(directory: Playlist(LibraryMock.directory()))
//    }
//}
