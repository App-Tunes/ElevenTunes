//
//  TracksView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 07.03.21.
//

import SwiftUI
import Combine

struct TracksView: NSViewControllerRepresentable {
	let playlist: Playlist

	@Environment(\.library) private var library: Library!

	func makeNSViewController(context: Context) -> TracksViewController {
		TracksViewController(playlist, library: library)
	}
	
	func updateNSViewController(_ nsViewController: TracksViewController, context: Context) {
		setIfDifferent(nsViewController, \.playlist, playlist)
		nsViewController.library = library
	}
}

//struct PlaylistsView_Previews: PreviewProvider {
//    static var previews: some View {
//        PlaylistsView(directory: Playlist(LibraryMock.directory()))
//    }
//}
