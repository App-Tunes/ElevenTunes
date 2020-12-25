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
    let mainPlaylist: Playlist
    
    init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
        self.mainPlaylist = Playlist(
            LibraryPlaylist(managedObjectContext: managedObjectContext),
            attributes: .init([
                AnyTypedKey.ptitle.id: "Library"
            ]))
    }
    
    var allTracks: [Track] {
        mainPlaylist.tracks
    }
    
    var allPlaylists: [Playlist] {
        mainPlaylist.children
    }
    
    func `import`(library: AnyLibrary) {
        mainPlaylist.add(children: library.allPlaylists)
        mainPlaylist.add(tracks: library.allTracks)
    }
}
