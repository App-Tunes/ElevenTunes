//
//  Library+Conversion.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 26.12.20.
//

import Foundation
import CoreData

extension Library {
    static func convert(_ library: DirectLibrary, context: NSManagedObjectContext) -> ([DBTrack], [DBPlaylist]) {
        guard let model = context.persistentStoreCoordinator?.managedObjectModel else {
            fatalError("Failed to find model in MOC")
        }
        
        guard let trackModel = model.entitiesByName["DBTrack"],
              let playlistModel = model.entitiesByName["DBPlaylist"]
        else {
            fatalError("Failed to find track / playlist models in MOC")
        }

        // ================= Convert Tracks =====================
        
        var tracksByID: [String: DBTrack] = [:]

        let convertTrack = { (backend: PersistentTrack) -> DBTrack in
            let dbTrack = DBTrack(entity: trackModel, insertInto: context)
            // TODO attributes
            dbTrack.backend = backend
            return dbTrack
        }

        let convertedTrack = { (backend: PersistentTrack) -> DBTrack in
            if let track = tracksByID[backend.id] { return track }
            let dbTrack = convertTrack(backend)
            tracksByID[backend.id] = dbTrack
            return dbTrack
        }
        
        let originalTracks = library.allTracks.map(convertedTrack)
        
        // ================= Convert Static Playlists =====================
        // (all other playlists' conversion can be deferred)
        
        var playlistsByID: [String: DBPlaylist] = [:]
        var playlistChildren: [DBPlaylist: [String]] = [:]
        var playlistsToConvert = library.allPlaylists
        
        let convertPlaylist = { (backend: PersistentPlaylist) -> DBPlaylist in
            if let backend = backend as? TransientPlaylist {
                let dbPlaylist = DBPlaylist(entity: playlistModel, insertInto: context)
                
                let tracks = backend._tracks.map(convertedTrack)
                dbPlaylist.addToTracks(NSOrderedSet(array: tracks))
                
                let children = backend._children
                playlistsToConvert += children
                playlistChildren[dbPlaylist] = children.map(\.id)
                
                return dbPlaylist
            }
            
            // TODO If already exists, return that
            let dbPlaylist = DBPlaylist(entity: playlistModel, insertInto: context)
            dbPlaylist.backend = backend
            return dbPlaylist
        }
        
        let convertedPlaylist = { (backend: PersistentPlaylist) -> DBPlaylist in
            if let playlist = playlistsByID[backend.id] { return playlist }
            let dbPlaylist = convertPlaylist(backend)
            playlistsByID[backend.id] = dbPlaylist
            return dbPlaylist
        }
        
        let originalPlaylists = playlistsToConvert.map(convertedPlaylist)
        
        // ================= Convert Static Children =====================
        
        while let backend = playlistsToConvert.popLast() {
            _ = convertedPlaylist(backend)
        }
        
        for (playlist, children) in playlistChildren {
            let children = children.map { playlistsByID[$0]! }
            playlist.addToChildren(NSOrderedSet(array: children))
        }
        
        return (originalTracks, originalPlaylists)
    }
}
