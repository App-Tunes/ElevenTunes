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
import SwiftUI

protocol SelfChangeWatcher {
    func onSelfChange()
}

@objc(DBPlaylist)
public class DBPlaylist: NSManagedObject, AnyPlaylist {
    var backendObservers = Set<AnyCancellable>()

    public var id: String { objectID.description }
    
    public var icon: Image {
        backend?.icon ?? Playlist.defaultIcon
    }
    
    public var accentColor: Color {
        backend?.accentColor ?? .secondary
    }
    
    @Published var _anyTracks: [AnyTrack] = []
    public var anyTracks: AnyPublisher<[AnyTrack], Never> {
        $_anyTracks.eraseToAnyPublisher()
    }
    
    @Published var _anyChildren: [AnyPlaylist] = []
    public var anyChildren: AnyPublisher<[AnyPlaylist], Never> {
        $_anyChildren.eraseToAnyPublisher()
    }
    
    @Published var _cacheMask: PlaylistContentMask = []
    public var cacheMask: AnyPublisher<PlaylistContentMask, Never> {
        $_cacheMask.eraseToAnyPublisher()
    }
    
    @Published var _attributes: TypedDict<PlaylistAttribute> = .init()
    public var attributes: AnyPublisher<TypedDict<PlaylistAttribute>, Never> {
        $_attributes.eraseToAnyPublisher()
    }
        
    public override func awakeFromFetch() { initialSetup() }
    public override func awakeFromInsert() { initialSetup() }

    func initialSetup() {
        _anyTracks = tracks.array as! [DBTrack]
        _anyChildren = children.array as! [DBPlaylist]
        _attributes = cachedAttributes

        refreshObservation()
    }
    
    public var hasCaches: Bool { backend != nil }
    
    public func load(atLeast mask: PlaylistContentMask, deep: Bool, library: Library) {
        guard let backend = backend else {
            // Fetch requests have already set the values
            _cacheMask = [.minimal, .children, .tracks, .attributes]
            return
        }
        
        // If indexed, tracks and children are NEVER in our cache
        let currentCache = _cacheMask.subtracting(indexed ? [.children, .tracks] : [])
        let missing = mask.subtracting(currentCache)
        
        if missing.isEmpty {
            // We have everything we need! Yay!
            return
        }
        
        // Only reload what's missing
        backend.load(atLeast: missing, deep: false, library: library)
    }
    
    public func invalidateCaches(_ mask: PlaylistContentMask) {
        if let backend = backend {
            let newMask = _cacheMask.subtracting(mask)
            _cacheMask = newMask
            backendCacheMask = newMask.rawValue
            backend.invalidateCaches(mask)
        }
    }
    
    public func supportsChildren() -> Bool { backend?.supportsChildren() ?? isDirectory }

    @discardableResult
    public func add(tracks: [PersistentTrack]) -> Bool {
        if let backend = backend {
            return backend.add(tracks: tracks)
        }
        
        guard let context = managedObjectContext else {
            return false
        }
        
        // We are without backend, aka transient
        guard !isDirectory else {
            return false
        }
        
        let (tracks, _) = Library.convert(DirectLibrary(allTracks: tracks), context: context)
        addToTracks(NSOrderedSet(array: tracks))
        
        return true
    }
    
    @discardableResult
    public func add(children: [PersistentPlaylist]) -> Bool {
        if let backend = backend {
            return backend.add(children: children)
        }
        
        guard let context = managedObjectContext else {
            return false
        }

        // We are without backend, aka transient
        guard isDirectory else {
            return false
        }
        
        let (_, playlists) = Library.convert(DirectLibrary(allPlaylists: children), context: context)
        addToChildren(NSOrderedSet(array: playlists))
        
        return true
    }
}
