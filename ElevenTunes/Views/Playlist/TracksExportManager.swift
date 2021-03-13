//
//  TrackExportManager.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 07.03.21.
//

import Foundation

class TracksExportManager: NSObject {
	public static let tracksIdentifier = "eleventunes.tracks"
	
	let track: AnyTrack
	
	init(track: AnyTrack) {
		self.track = track
	}
	
	static func read(fromPasteboard pasteboard: NSPasteboard, context: NSManagedObjectContext) -> [DBTrack]? {
		pasteboard.pasteboardItems?.compactMap { (item: NSPasteboardItem) -> DBTrack? in
			guard
				let data = item.data(forType: .init(rawValue: Self.tracksIdentifier)),
				let url = URL(dataRepresentation: data, relativeTo: nil),
				let track = try? context.read(uri: url, as: DBTrack.self)
			else {
				return nil
			}
			
			return track
		}.nonEmpty
	}

//	func itemProvider() -> NSItemProvider {
//		let provider = NSItemProvider()
//
//		if let dragged = tracks.map(\.backend) as? [BranchingTrack] {
//			provider.registerDataRepresentation(forTypeIdentifier: Self.tracksIdentifier, visibility: .ownProcess) {
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
//
	func pasteboardItem() -> NSPasteboardItem {
		let item = NSPasteboardItem()
		
		if let dragged = track as? BranchingTrack {
			// TODO Allow dragging more than one
			item.setData(dragged.cache.objectID.uriRepresentation().dataRepresentation, forType: .init(Self.tracksIdentifier))
		}

		if let origin = track.origin {
			item.setData(origin.dataRepresentation, forType: .URL)
		}

		return item
	}
}
