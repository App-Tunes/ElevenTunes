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

    var backendObservers = Set<AnyCancellable>()

    public var asToken: PlaylistToken { fatalError() }

    init(library: Library, cache: DBPlaylist, backend: AnyPlaylist?, isIndexed: Bool, contentType: PlaylistContentType) {
        self.library = library
        self.cache = cache
        self.backend = backend
        self.isIndexed = isIndexed
        self.cachedContentType = contentType
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
    
    public func invalidateCaches(_ mask: PlaylistContentMask) {
        if let backend = backend {
            let clearBits = cache.backendCacheMask & mask.rawValue
            if clearBits != 0 {
                cache.backendCacheMask -= clearBits
            }
            
            backend.invalidateCaches(mask)
        }
    }
    
    lazy var _cacheMask: AnyPublisher<PlaylistContentMask, Never> = {
        guard let backend = backend else {
            // If no backend, we don't even have a cache
            return Just(PlaylistContentMask.all).eraseToAnyPublisher()
        }
        
        if isIndexed {
            // If indexed, the cache is just the db cache
            return cache.$cacheMaskP.eraseToAnyPublisher()
        }
        
        // If not indexed, the cache consists of backend's children and tracks,
        // and the rest ours
        return backend.cacheMask()
//            .combineLatest(cache.$cacheMaskP)
//            .map { (backendMask, dbMask) in
//                backendMask.intersection([.children, .tracks])
//                .union(dbMask.subtracting([.children, .tracks]))
//            }
            .eraseToAnyPublisher()
    }()
    public func cacheMask() -> AnyPublisher<PlaylistContentMask, Never> {
        _cacheMask
    }
    
    lazy var _tracks: AnyPublisher<[AnyTrack], Never> = {
        guard let backend = backend, !isIndexed else {
            // Everything is cached
            let library = self.library
            
            return cache.$tracksP
                .flatMap {
                    $0.count == 0
                        ? Just([]).eraseToAnyPublisher()
                        : $0.map(library.track).combineLatest().eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
        }
        
        return backend.tracks()
    }()
    
    public func tracks() -> AnyPublisher<[AnyTrack], Never> {
        _tracks
    }
    
    lazy var _children: AnyPublisher<[AnyPlaylist], Never> = {
        guard let backend = backend, !isIndexed else {
            // Everything is cached
            let library = self.library
            return cache.$childrenP
                .flatMap {
                    $0.count == 0
                        ? Just([]).eraseToAnyPublisher()
                        : $0.map(library.playlist).combineLatest().eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
        }
        
        return backend.children()
    }()
    
    public func children() -> AnyPublisher<[AnyPlaylist], Never> {
        _children
    }
    
    lazy var _attributes: AnyPublisher<TypedDict<PlaylistAttribute>, Never> = {
        guard let backend = backend else {
            return cache.$attributesP.eraseToAnyPublisher()
        }
        
        return backend.attributes()
    }()
    public func attributes() -> AnyPublisher<TypedDict<PlaylistAttribute>, Never> {
        _attributes
    }
    
    public var contentType: PlaylistContentType {
        backend?.contentType ?? cachedContentType
    }
    
    public func `import`(library: AnyLibrary) -> Bool {
        guard let backend = backend else {
            // We have no backend, let's fucking gooo
            Library.import(library, to: cache)
            return true
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

    @Published var cacheMaskP: PlaylistContentMask = []
    @Published var tracksP: [DBTrack] = []
    @Published var childrenP: [DBPlaylist] = []
    @Published var attributesP: TypedDict<PlaylistAttribute> = .init()
    
    public override func awakeFromFetch() { initialSetup() }
    public override func awakeFromInsert() {
        uuid = UUID()
        initialSetup()
    }
    
    func initialSetup() {
        backendP = backend
        isIndexedP = indexed
        contentTypeP = contentType

        cacheMaskP = PlaylistContentMask(rawValue: backendCacheMask)
        tracksP = tracks.array as! [DBTrack]
        childrenP = children.array as! [DBPlaylist]
        attributesP = cachedAttributes
    }
}
