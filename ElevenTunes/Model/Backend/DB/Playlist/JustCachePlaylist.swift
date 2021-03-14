//
//  JustCachePlaylist.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 26.01.21.
//

import Foundation
import SwiftUI
import Combine
import CombineExt

final class JustCachePlaylist: RemotePlaylist {
	let cache: DBPlaylist
	let library: Library

	enum Request {
		case attributes, tracks, children
	}

	let mapper = Requests(relation: [
		.attributes: [.title],
		.tracks: [.tracks],
		.children: [.children]
	])

	init(_ cache: DBPlaylist, library: Library) {
		self.cache = cache
		self.library = library
		mapper.delegate = self
		
		NotificationCenter.default.addObserver(self, selector: #selector(objectsDidChange), name: .NSManagedObjectContextObjectsDidChange, object: cache.managedObjectContext!)
	}
			
	@objc func objectsDidChange(_ notification: NSNotification) {
		guard let userInfo = notification.userInfo else { return }

		// awakeFromInsert is only called on the original context. Not when it's inserted here
		let updates = (userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject> ?? []).union(userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject> ?? [])
		
		if updates.contains(cache) {
			mapper.invalidateCaches()  // TODO invalidate only what's needed
		}
	}

	var id: String { cache.uuid.uuidString }
	
	var origin: URL? { nil }
	
	var hasCaches: Bool { false }
	
	public func supports(_ capability: PlaylistCapability) -> Bool {
		switch capability {
		case .delete:
			return false  // "Remove from Library" is fine
		case .insertChildren:
			return true
		}
	}
	
	func `import`(library: UninterpretedLibrary, toIndex index: Int?) throws {
		try self.library.import(library, to: cache, atIndex: index)
	}
	
	func delete() throws {
		cache.delete()
	}
	
	var icon: Image {
		switch cache.contentType {
		case .tracks:
			return Image(systemName: "music.note.list")
		case .playlists:
			return Image(systemName: "folder")
		case .hybrid:
			return Image(systemName: "questionmark.folder")
		}
	}
	
	var contentType: PlaylistContentType {
		cache.contentType
	}
}

extension JustCachePlaylist: RequestMapperDelegate {
	func onDemand(_ request: Request) -> AnyPublisher<PlaylistAttributes.PartialGroupSnapshot, Error> {
		let cache = self.cache
		let library = self.library
		
		switch request {
		case .attributes:
			return Just(.init(.unsafe([
				.title: cache.title
			]), state: .valid)
			).eraseError().eraseToAnyPublisher()
		case .children:
			// TODO What if children or tracks want to re-generate representation?
			// first() is called so the request completes.
			// What we need as an alive-mode where the stream is cancelled when no more demand
			// is present.
			return cache.children.map { library.playlist(cachedBy: $0 as! DBPlaylist) }
				.combineLatestOrJust()
				.first()
				.map { children in
					PlaylistAttributes.PartialGroupSnapshot(.unsafe([
						.children: children
					]), state: .valid)
				}
				.eraseError().eraseToAnyPublisher()
		case .tracks:
			return cache.tracks.map { library.track(cachedBy: $0 as! DBTrack) }
				.combineLatestOrJust()
				.first()
				.map { tracks in
					PlaylistAttributes.PartialGroupSnapshot(.unsafe([
						.tracks: tracks
					]), state: .valid)
				}
				.eraseError().eraseToAnyPublisher()
		}
	}
}

extension JustCachePlaylist: BranchablePlaylist {
	func store(in playlist: DBPlaylist) throws -> DBPlaylist.Representation {
		.none
	}
}
