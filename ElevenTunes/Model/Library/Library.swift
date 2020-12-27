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
    var allTracks: [PersistentTrack] = []
    var allPlaylists: [PersistentPlaylist] = []
}

class Library {
    let managedObjectContext: NSManagedObjectContext
    let mainPlaylist: LibraryPlaylist
        
    init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
        self.mainPlaylist = LibraryPlaylist(managedObjectContext: managedObjectContext)
        
        NotificationCenter.default.addObserver(self, selector: #selector(objectsDidChange), name: .NSManagedObjectContextObjectsDidChange, object: managedObjectContext)
    }
        
    func `import`(library: AnyLibrary) {
        mainPlaylist.add(children: library.allPlaylists)
        mainPlaylist.add(tracks: library.allTracks)
    }
    
    @objc func objectsDidChange(_ notification: NSNotification) {
        guard let userInfo = notification.userInfo else { return }

        // awakeFromInsert is only called on the original context. Not when it's inserted here
        let updates = (userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject> ?? []).union(userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject> ?? [])
        
        for object in updates {
            if let object = object as? SelfChangeWatcher {
                object.onSelfChange()
            }
        }
    }
}
