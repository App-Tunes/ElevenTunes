//
//  NewPlaylistView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 07.02.21.
//

import SwiftUI

struct NewPlaylistView: View {
	let directory: Playlist
	let selection: ContextualSelection<Playlist>
	
	func createPlaylist(_ playlist: TransientPlaylist) {
		guard let insertPosition = selection.insertPosition else {
			NSAlert.warning(title: "Internal Error", text: "Unexpected position == nil")
			return
		}
		
		let library = UninterpretedLibrary(playlists: [playlist])
		
		do {
			try insertPosition.0.backend.import(library: library, toIndex: insertPosition.1)
		}
		catch let error {
			NSAlert.warning(
				title: "Failed to create new playlist",
				text: String(describing: error)
			)
		}
	}

    var body: some View {
		let canInsert = selection.insertPosition != nil
		
		HStack {
			Button {
				let playlist = TransientPlaylist(.tracks, attributes: .unsafe([
					.title: "New Playlist"
				]))
				createPlaylist(playlist)
			} label: {
				Image(systemName: "music.note.list")
					.badge(systemName: "plus.circle.fill")
			}
				.disabled(!canInsert)

			Button {
				let playlist = TransientPlaylist(.playlists, attributes: .unsafe([
					.title: "New Folder"
				]))
				createPlaylist(playlist)
			} label: {
				Image(systemName: "folder")
					.badge(systemName: "plus.circle.fill")
			}
				.disabled(!canInsert)

			Button {
				let playlist = TransientPlaylist(.hybrid, attributes: .unsafe([
					.title: "New Hybrid Folder"
				]))
				createPlaylist(playlist)
			} label: {
				Image(systemName: "questionmark.folder")
					.badge(systemName: "plus.circle.fill")
			}
				.disabled(!canInsert)
		}
    }
}

//struct NewPlaylistView_Previews: PreviewProvider {
//    static var previews: some View {
//        NewPlaylistView()
//    }
//}
