//
//  PlaylistsDragManager.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 13.02.21.
//

import Foundation

class PlaylistsExportManager {
	public static let playlistsIdentifier = "eleventunes.playlists"
	
	let playlists: Set<Playlist>
	
	init(playlist: Playlist, selection: Set<Playlist>) {
		self.playlists = selection.allIfContains(playlist)
	}

	func itemProvider() -> NSItemProvider {
		let provider = NSItemProvider()
		
		if let dragged = playlists.map(\.backend) as? [BranchingPlaylist] {
			provider.registerDataRepresentation(forTypeIdentifier: Self.playlistsIdentifier, visibility: .ownProcess) {
				return try JSONEncoder().encode(
					dragged.map(\.cache.objectID).map { $0.uriRepresentation() }
				)
			}
		}
		
		provider.registerDummyIfNeeded()
		
		return provider
	}
}
