//
//  PlaylistsDragManager.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 13.02.21.
//

import Foundation

class PlaylistsExportManager: NSObject {
	public static let playlistsIdentifier = "eleventunes.playlists"
	
	let playlists: Set<Playlist>
	
	init(playlists: Set<Playlist>) {
		self.playlists = playlists
	}

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

extension PlaylistsExportManager: NSPasteboardWriting {
	func writableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType] {
		[.URL]
	}
	
	func pasteboardPropertyList(forType type: NSPasteboard.PasteboardType) -> Any? {
		if let dragged = playlists.map(\.backend) as? [BranchingPlaylist] {
			return dragged.map(\.cache.objectID).map { $0.uriRepresentation().dataRepresentation }
		}
		
		return nil
	}
}
