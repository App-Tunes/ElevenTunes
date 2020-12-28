//
//  DBPlaylist+Changes.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 27.12.20.
//

import Foundation

extension DBPlaylist {
    func refreshObservation() {
        guard let context = managedObjectContext else { return }
        
        backendObservers = []
        if let backend = backend {
            backend.tracks
                .onMain()
                .sink { [unowned self] tracks in
                    let oldIDs = self.tracks.map { ($0 as! DBTrack).backendID }
                    if indexed, oldIDs != tracks.map(\.id) {
                        let old = self.tracks
                        let (dbTracks, _) = Library.convert(DirectLibrary(allTracks: tracks), context: context)
                        self.tracks = NSOrderedSet(array: dbTracks)
                        Library.prune(tracks: old.array as! [DBTrack], context: context)
                    }
                    else {
                        _anyTracks = tracks
                    }
                }
                .store(in: &backendObservers)
            
            backend.children
                .onMain()
                .sink { [unowned self] children in
                    let oldIDs = self.children.map { ($0 as! DBPlaylist).backendID }
                    if indexed, oldIDs != children.map(\.id) {
                        let old = self.children
                        let (_, dbPlaylists) = Library.convert(DirectLibrary(allPlaylists: children), context: context)
                        self.children = NSOrderedSet(array: dbPlaylists)
                        Library.prune(playlists: old.array as! [DBPlaylist], context: context)
                    }
                    else {
                        _anyChildren = children
                    }
                }
                .store(in: &backendObservers)

            backend.attributes
                .onMain()
                .sink { [unowned self] attributes in
                    merge(attributes: attributes)
                }
                .store(in: &backendObservers)

            backend.cacheMask
                .onMain()
                .sink { [unowned self] cacheMask in
                    self.backendCacheMask |= cacheMask.rawValue
                }
                .store(in: &backendObservers)
        }
    }
}

extension DBPlaylist: SelfChangeWatcher {
    func onSelfChange() {
        let changes = changedValues()
        
        if !DBPlaylist.attributeProperties.isDisjoint(with: changes.keys) {
            _attributes = cachedAttributes
        }
        
        if changes.keys.contains("backend") {
            refreshObservation()
            if let backend = backend, backend.id != backendID {
                // Invalidate stuff we stored for the backend
                backendID = backend.id
                if backendCacheMask != 0 { backendCacheMask = 0 }
                if tracks.firstObject != nil { tracks = NSOrderedSet() }
                if children.firstObject != nil { children = NSOrderedSet() }
                // Attributes will be either overriden by new playlist, or kept
                
                if isDirectory != backend.supportsChildren() { isDirectory = backend.supportsChildren() }
            }
        }
        
        if changes.keys.contains("backendCacheMask") {
            _cacheMask = PlaylistContentMask(rawValue: backendCacheMask)
        }
        
        if changes.keys.contains("tracks") {
            _anyTracks = tracks.array as! [DBTrack]
        }

        if changes.keys.contains("children") {
            _anyChildren = children.array as! [DBPlaylist]
        }
    }
}
