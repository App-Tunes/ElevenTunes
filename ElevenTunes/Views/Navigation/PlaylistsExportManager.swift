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
	
	static func read(fromPasteboard pasteboard: NSPasteboard, context: NSManagedObjectContext) -> [DBPlaylist]? {
		pasteboard.pasteboardItems?.compactMap { (item: NSPasteboardItem) -> DBPlaylist? in
			guard
				let data = item.data(forType: .init(rawValue: Self.playlistsIdentifier)),
				let url = URL(dataRepresentation: data, relativeTo: nil),
				let track = context.read(uri: url, as: DBPlaylist.self)
			else {
				return nil
			}
			
			return track
		}
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
	
	func pasteboardItem() -> NSPasteboardItem {
		let item = NSPasteboardItem()
		
		if let dragged = playlists.map(\.backend) as? [BranchingPlaylist], let playlist = dragged.one {
			// TODO Allow dragging more than one
			item.setData(playlist.cache.objectID.uriRepresentation().dataRepresentation, forType: .init(Self.playlistsIdentifier))
		}
		
		return item
	}
}
