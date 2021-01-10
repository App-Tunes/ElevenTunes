//
//  DBPlaylist+CoreDataClass.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 26.12.20.
//
//

import Foundation
import CoreData
import Combine
import CombineExt
import SwiftUI

protocol SelfChangeWatcher {
    func onSelfChange()
}

public class DBLibraryPlaylist: AnyPlaylist {
    let library: Library
    let cache: DBPlaylist
    let backend: AnyPlaylist?
    let isIndexed: Bool
    let cachedContentType: PlaylistContentType

    public var asToken: PlaylistToken { fatalError() }

	var cancellables: Set<AnyCancellable> = []
	
    init(library: Library, cache: DBPlaylist, backend: AnyPlaylist?, isIndexed: Bool, contentType: PlaylistContentType) {
        self.library = library
        self.cache = cache
        self.backend = backend
        self.isIndexed = isIndexed
        self.cachedContentType = contentType
		setupObservers()
    }
	
	func setupObservers() {
		guard let backend = backend else {
			return
		}
		
		backend.attributes
			.sink(receiveValue: cache.onUpdate)
			.store(in: &cancellables)
	}
    
    public var id: String { cache.uuid.uuidString }
    
    public var origin: URL? { nil }
    
    public var icon: Image {
        if let backend = backend {
            return backend.icon
        }
        
        switch cachedContentType {
        case .tracks:
            return Image(systemName: "music.note.list")
        case .playlists:
            return Image(systemName: "folder")
        case .hybrid:
            return Image(systemName: "questionmark.folder")
        }
    }
    
    public var accentColor: Color {
        backend?.accentColor ?? .secondary
    }
    
    public var hasCaches: Bool { backend != nil }
    
    public func invalidateCaches() {
        guard let backend = backend else {
			return  // No caches here!
        }
		
		// TODO Invalidate our caches
		backend.invalidateCaches()
    }

	lazy var _attributes: AnyPublisher<PlaylistAttributes.Update, Never> = {
		guard let backend = backend else {
			// Everything is always 'cached'
			return cache.attributes.$snapshot.eraseToAnyPublisher()
		}
		
		// Depending on setup, other values will be in cache.attributes.
		// This does not affect our logic here.
		return backend.attributes
			.combineLatest(cache.attributes.$snapshot)
			.compactMap { (backend, cache) -> PlaylistAttributes.Update in
				// TODO If change comes from cache, not from backend, 'change' value will be wrong.
				return (backend.0.merging(cache: cache.0), change: backend.change)
			}.eraseToAnyPublisher()
	}()
	public var attributes: AnyPublisher<PlaylistAttributes.Update, Never> {
		return _attributes
	}
	
	public func demand(_ demand: Set<PlaylistAttribute>) -> AnyCancellable {
		guard let backend = backend else {
			// TODO Only update the attributes if there's a watcher? Does that help?
			return AnyCancellable {}
		}
		
		// First figure out what we haven't cached yet
		let missing = demand.subtracting(cache.attributes.knownKeys)
		// Now explode so we get a cacheable package some time
		return backend.demand(DBPlaylist.attributeGroups.explode(missing))
	}
	
    public var contentType: PlaylistContentType {
        backend?.contentType ?? cachedContentType
    }
    
    public func `import`(library: AnyLibrary) -> Bool {
        guard let backend = backend else {
            // We have no backend, let's fucking gooo
            return Library.import(library, to: cache)
        }
        
        // Backend is responsible for resetting caches etc.
        return backend.import(library: library)
    }
    
    public func previewImage() -> AnyPublisher<NSImage?, Never> {
        backend?.previewImage() ?? Just(nil).eraseToAnyPublisher()
    }
}

@objc(DBPlaylist)
public class DBPlaylist: NSManagedObject {
    @Published var backendP: PlaylistToken? = nil
    @Published var isIndexedP: Bool = false
    @Published var contentTypeP: PlaylistContentType = .hybrid

	let attributes: VolatileAttributes<PlaylistAttribute, PlaylistVersion> = .init()
    
    public override func awakeFromFetch() { initialSetup() }
    public override func awakeFromInsert() {
        uuid = UUID()
        initialSetup()
    }
    
    func initialSetup() {
        backendP = backend
        isIndexedP = indexed
        contentTypeP = contentType

		// TODO
//        cacheMaskP = PlaylistContentMask(rawValue: backendCacheMask)
//        tracksP = tracks.array as! [DBTrack]
//        childrenP = children.array as! [DBPlaylist]
//        attributesP = cachedAttributes
    }
}
