//
//  Library+Conversion.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 26.12.20.
//

import Foundation
import CoreData

extension Library {
	enum InterpretationError: Error {
		case unconvertibleType
	}
	
	static func asBranched(_ track: AnyTrack, insertInto context: NSManagedObjectContext) throws -> BranchingTrack {
		guard
			let model = context.persistentStoreCoordinator?.managedObjectModel,
			let trackModel = model.entitiesByName["DBTrack"]
		else {
			fatalError("Failed to find model in MOC")
		}

		guard
			let primary = track as? BranchableTrack
		else {
			throw InterpretationError.unconvertibleType
		}

		let cache = DBTrack(entity: trackModel, insertInto: context)
		let primaryType = try primary.store(in: cache)
		cache.primaryRepresentation = primaryType

		return BranchingTrack(
			cache: cache,
			primary: primaryType != .none ? track : JustCacheTrack(cache),
			secondary: []
		)
	}
	
	func asBranched(_ playlist: AnyPlaylist, insertInto context: NSManagedObjectContext) throws -> BranchingPlaylist {
		guard
			let model = context.persistentStoreCoordinator?.managedObjectModel,
			let playlistModel = model.entitiesByName["DBPlaylist"]
		else {
			fatalError("Failed to find model in MOC")
		}
		
		guard
			let primary = playlist as? BranchablePlaylist
		else {
			throw InterpretationError.unconvertibleType
		}

		let cache = DBPlaylist(entity: playlistModel, insertInto: context)
		let primaryType = try primary.store(in: cache)
		cache.primaryRepresentation = primaryType
		cache.contentType = playlist.contentType
		
		return BranchingPlaylist(
			cache: cache,
			primary: primaryType != .none ? playlist : JustCachePlaylist(cache, library: self),
			secondary: [],
			contentType: playlist.contentType
		)
	}
	
	/// Inserts the pre-interpreted library into the context, by expanding its contents into connected caches.
	/// The objects are modified in-place. The return value is the newly inserted objects
	@discardableResult
	func insert(_ library: UninterpretedLibrary, to context: NSManagedObjectContext) throws -> InterpretedLibrary {
		// ================= Discover all static content =====================
		// (all deeper playlists' conversion can be deferred)

		let originalTracks = library.tracks
		
		var allTracks: [String: AnyTrack] = Dictionary(uniqueKeysWithValues: originalTracks.map {
			($0.id, $0)
		})
		
		var playlistTracks: [BranchingPlaylist: [String]] = [:]
		var playlistChildren: [BranchingPlaylist: [BranchingPlaylist]] = [:]

		let originalPlaylists = try library.playlists
			.map { try self.asBranched($0, insertInto: context) }
		
		for _ in flatSequence(first: originalPlaylists, next: { branched in
			let playlist = branched.primary
			
			if let playlist = playlist as? TransientPlaylist {
				if let tracks = playlist._attributes.snapshot.attributes[PlaylistAttribute.tracks] {
					allTracks.merge(Dictionary(uniqueKeysWithValues: tracks.map {
						($0.id, $0)
					})) { $1 }
					
					playlistTracks[branched] = tracks.map(\.id)
				}
				else {
					playlistTracks[branched] = []
				}
				
				// TODO try should be normal try
				let children = try! playlist._attributes.snapshot
					.attributes[PlaylistAttribute.children]?.map {
						try self.asBranched($0, insertInto: context)
					} ?? []
				
				playlistChildren[branched] = children
				
				return children
			}
			
			playlistTracks[branched] = []
			playlistChildren[branched] = []
			
			return []
		}) {}
		
		// TODO Avoid duplication by looking up existing tracks first
		let convertedTracks = try allTracks.mapValues {
			try Library.asBranched($0, insertInto: context)
		}
		
		for (playlist, tracks) in playlistTracks {
			let cache = playlist.cache
			cache.addToTracks(NSOrderedSet(array: tracks.map { convertedTracks[$0]!.cache }))
		}
		
		for (playlist, children) in playlistChildren {
			let cache = playlist.cache
			cache.addToChildren(NSOrderedSet(array: children.map { $0.cache }))
		}
		
		return InterpretedLibrary(
			tracks: originalTracks.map { convertedTracks[$0.id]! },
			playlists: originalPlaylists
		)
	}
	
	/// Import playlists and tracks to a playlist without updating its backends.
	func `import`(_ library: UninterpretedLibrary, to parent: DBPlaylist) throws {
		guard !library.tracks.isEmpty || !library.playlists.isEmpty else {
			throw PlaylistImportError.empty  // lol why bother bro
		}
		
		let contentType = parent.contentType
		guard library.tracks.isEmpty || contentType != .playlists else {
			throw PlaylistImportError.unimportable  // Can't contain tracks
		}
		
		guard library.playlists.isEmpty || contentType != .tracks else {
			throw PlaylistImportError.unimportable  // Can't contain playlists
		}
		
		// Fetch requests auto-update content
		parent.managedObjectContext!.performChildTask(concurrencyType: .privateQueueConcurrencyType) { context in
			do {
				let library = try self.insert(library, to: context)

				if let parent = context.translate(parent) {
					if !library.playlists.isEmpty {
						parent.addToChildren(NSOrderedSet(array: library.playlists.map(\.cache)))
					}
					if !library.tracks.isEmpty {
						parent.addToTracks(NSOrderedSet(array: library.tracks.map(\.cache)))
					}
				}

				try context.save()
			}
			catch let error {
				appLogger.error("Failed import: \(error)")
			}
		}
	}
}
