//
//  Library.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 25.12.20.
//

import Cocoa
import Combine

protocol AnyLibrary {
    var allTracks: [TrackToken] { get }
    var allPlaylists: [PlaylistToken] { get }
}

struct DirectLibrary: AnyLibrary {
    var allTracks: [TrackToken] = []
    var allPlaylists: [PlaylistToken] = []
}

public class Library {
    let managedObjectContext: NSManagedObjectContext

    var _mainPlaylist: LibraryPlaylist! = nil
    var mainPlaylist: LibraryPlaylist { _mainPlaylist }
        
    let spotify: Spotify
    let interpreter: ContentInterpreter
    
    let player: Player

    init(managedObjectContext: NSManagedObjectContext, spotify: Spotify) {
        self.managedObjectContext = managedObjectContext
        self.spotify = spotify
        self.interpreter = ContentInterpreter.createDefault(spotify: spotify)

        let playContext = PlayContext(spotify: spotify)
        
        player = Player(context: playContext)

        _mainPlaylist = LibraryPlaylist(library: self, playContext: playContext)

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
