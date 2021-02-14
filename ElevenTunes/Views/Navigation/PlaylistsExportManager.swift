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
	
	static func read(fromPasteboard pasteboard: NSPasteboard, context: NSManagedObjectContext) -> Set<DBPlaylist>? {
		guard
			let data = pasteboard.data(forType: .init(rawValue: Self.playlistsIdentifier)),
			let url = URL(dataRepresentation: data, relativeTo: nil),
			let playlist = context.read(uri: url, as: DBPlaylist.self)
		else {
			return nil
		}
		
		return [playlist]
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
		[.init(rawValue: Self.playlistsIdentifier)]
	}
	
	func pasteboardPropertyList(forType type: NSPasteboard.PasteboardType) -> Any? {
		if let dragged = playlists.map(\.backend) as? [BranchingPlaylist] {
			return dragged.map(\.cache.objectID).map { $0.uriRepresentation().dataRepresentation }
		}
		
		return nil
	}
}
