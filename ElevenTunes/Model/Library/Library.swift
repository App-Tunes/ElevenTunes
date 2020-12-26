//
//  Library.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 25.12.20.
//

import Cocoa
import Combine

protocol AnyLibrary {
    var allTracks: [PersistentTrack] { get }
    var allPlaylists: [PersistentPlaylist] { get }
}

struct DirectLibrary: AnyLibrary {
    var allTracks: [PersistentTrack]
    var allPlaylists: [PersistentPlaylist]
}

class Library {
    let managedObjectContext: NSManagedObjectContext
    let mainPlaylist: LibraryPlaylist
        
    init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
        self.mainPlaylist = LibraryPlaylist(managedObjectContext: managedObjectContext)
    }
        
    func `import`(library: AnyLibrary) {
        mainPlaylist.add(children: library.allPlaylists)
        mainPlaylist.add(tracks: library.allTracks)
    }
}
