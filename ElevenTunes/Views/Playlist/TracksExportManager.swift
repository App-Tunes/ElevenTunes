//
//  TrackExportManager.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 07.03.21.
//

import Foundation

class TracksExportManager: NSObject {
	public static let tracksIdentifier = "eleventunes.tracks"
	
	let tracks: Set<Track>
	
	init(tracks: Set<Track>) {
		self.tracks = tracks
	}

	init(track: Track, selection: Set<Track>) {
		self.tracks = selection.allIfContains(track)
	}
	
	static func read(fromPasteboard pasteboard: NSPasteboard, context: NSManagedObjectContext) -> [DBTrack]? {
		pasteboard.pasteboardItems?.compactMap { (item: NSPasteboardItem) -> DBTrack? in
			guard
				let data = item.data(forType: .init(rawValue: Self.tracksIdentifier)),
				let url = URL(dataRepresentation: data, relativeTo: nil),
				let track = context.read(uri: url, as: DBTrack.self)
			else {
				return nil
			}
			
			return track
		}
	}

	func itemProvider() -> NSItemProvider {
		let provider = NSItemProvider()
		
		if let dragged = tracks.map(\.backend) as? [BranchingTrack] {
			provider.registerDataRepresentation(forTypeIdentifier: Self.tracksIdentifier, visibility: .ownProcess) {
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
		
		if let dragged = tracks.map(\.backend) as? [BranchingTrack], let track = dragged.one {
			// TODO Allow dragging more than one
			item.setData(track.cache.objectID.uriRepresentation().dataRepresentation, forType: .init(Self.tracksIdentifier))
		}
		
		return item
	}
}
