//
//  PlaylistsDragManager.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 13.02.21.
//

import Foundation

class PlaylistsExportManager: NSObject {
	public static let playlistsIdentifier = "eleventunes.playlists"
	
	let playlist: AnyPlaylist
	
	init(playlist: AnyPlaylist) {
		self.playlist = playlist
	}
	
	static func read(fromPasteboard pasteboard: NSPasteboard, context: NSManagedObjectContext) -> [DBPlaylist]? {
		pasteboard.pasteboardItems?.compactMap { (item: NSPasteboardItem) -> DBPlaylist? in
			guard
				let data = item.data(forType: .init(rawValue: Self.playlistsIdentifier)),
				let url = URL(dataRepresentation: data, relativeTo: nil),
				let track = try? context.read(uri: url, as: DBPlaylist.self)
			else {
				return nil
			}
			
			return track
		}.nonEmpty
	}

//	func itemProvider() -> NSItemProvider {
//		let provider = NSItemProvider()
//
//		if let dragged = playlists.map(\.backend) as? [BranchingPlaylist] {
//			provider.registerDataRepresentation(forTypeIdentifier: Self.playlistsIdentifier, visibility: .ownProcess) {
//				return try JSONEncoder().encode(
//					dragged.map(\.cache.objectID).map { $0.uriRepresentation() }
//				)
//			}
//		}
//
//		provider.registerDummyIfNeeded()
//
//		return provider
//	}
	
	func pasteboardItem() -> NSPasteboardItem {
		let item = NSPasteboardItem()
		
		if let dragged = playlist as? BranchingPlaylist {
			// TODO Allow dragging more than one
			item.setData(dragged.cache.objectID.uriRepresentation().dataRepresentation, forType: .init(Self.playlistsIdentifier))
		}

		if let origin = playlist.origin {
			item.setData(origin.dataRepresentation, forType: .URL)
		}

		return item
	}
}
