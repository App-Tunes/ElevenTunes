//
//  DBPlaylist+Changes.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 27.12.20.
//

import Foundation

//            backend.tracks
//                .dropFirst()
//                .onMain()
//                .sink { [unowned self] tracks in
//                    let oldIDs = self.tracks.map { ($0 as! DBTrack).backendID }
//                    if indexed, oldIDs != tracks.map(\.id) {
//                        let old = self.tracks
//                        let (dbTracks, _) = Library.convert(DirectLibrary(allTracks: tracks), context: context)
//                        self.tracks = NSOrderedSet(array: dbTracks)
//                        Library.prune(tracks: old.array as! [DBTrack], context: context)
//                    }
//                }
//                .store(in: &backendObservers)
//
//            backend.children
//                .dropFirst()
//                .onMain()
//                .sink { [unowned self] children in
//                    let oldIDs = self.children.map { ($0 as! DBPlaylist).backendID }
//                    if indexed, oldIDs != children.map(\.id) {
//                        let old = self.children
//                        let (_, dbPlaylists) = Library.convert(DirectLibrary(allPlaylists: children), context: context)
//                        self.children = NSOrderedSet(array: dbPlaylists)
//                        Library.prune(playlists: old.array as! [DBPlaylist], context: context)
//                    }
//                }
//                .store(in: &backendObservers)

extension DBPlaylist: SelfChangeWatcher {
    func onSelfChange() {
        let changes = changedValues()

        if !DBPlaylist.attributeProperties.isDisjoint(with: changes.keys) {
            attributesP = cachedAttributes
        }
        
        if changes.keys.contains("backend") {
            if let backend = backend, backend.id != backendID {
                // Invalidate stuff we stored for the backend
                backendID = backend.id
                if backendCacheMask != 0 { backendCacheMask = 0 }
                if tracks.firstObject != nil { tracks = NSOrderedSet() }
                if children.firstObject != nil { children = NSOrderedSet() }
            }
            
            backendP = backend
        }
        
        if changes.keys.contains("contentType") {
            contentTypeP = contentType
        }
        
        if changes.keys.contains("tracks") {
            tracksP = tracks.array as! [DBTrack]
        }

        if changes.keys.contains("children") {
            childrenP = children.array as! [DBPlaylist]
        }

        if changes.keys.contains("backendCacheMask") {
            cacheMaskP = PlaylistContentMask(rawValue: backendCacheMask)
        }

        if changes.keys.contains("indexed") {
            isIndexedP = indexed
        }
    }
}
