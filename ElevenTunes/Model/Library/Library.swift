//
//  Library.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 25.12.20.
//

import Cocoa

protocol AnyLibrary {
    var allTracks: [Track] { get }
    var allPlaylists: [Playlist] { get }
}

struct DirectLibrary: AnyLibrary {
    var allTracks: [Track]
    var allPlaylists: [Playlist]
}

class Library: AnyLibrary {
    let managedObjectContext: NSManagedObjectContext
    let mainPlaylist: LibraryPlaylist
    
    init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
        self.mainPlaylist = LibraryPlaylist(managedObjectContext: managedObjectContext)
    }
    
    var allTracks: [Track] {
        mainPlaylist.tracks
    }
    
    var allPlaylists: [Playlist] {
        mainPlaylist.playlists
    }
    
    func `import`(library: AnyLibrary) {
        mainPlaylist.add(children: library.allPlaylists)
        mainPlaylist.add(tracks: library.allTracks)
    }
}
