//
//  Library+Prune.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 27.12.20.
//

import Foundation
import CoreData

extension Library {
    static func prune(tracks: [DBTrack], context: NSManagedObjectContext) {
        for track in tracks {
            if track.references.anyObject() == nil {
                context.delete(track)
            }
        }
    }
    
    static func prune(playlists: [DBPlaylist], context: NSManagedObjectContext) {
        for playlist in playlists {
            if playlist.parent == nil {
                context.delete(playlist)
            }
        }
    }
}
