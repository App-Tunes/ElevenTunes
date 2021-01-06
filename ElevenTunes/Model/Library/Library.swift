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
    static let defaultPlaylistKey = "defaultPlaylist"
    
    let managedObjectContext: NSManagedObjectContext

    var _mainPlaylist: LibraryPlaylist! = nil
    var mainPlaylist: LibraryPlaylist { _mainPlaylist }
        
    let settings: LibrarySettingsLevel
    let interpreter: ContentInterpreter
    
    let player: Player
    
    var defaultPlaylist: DBPlaylist? {
        didSet { settings.defaultPlaylist = defaultPlaylist?.objectID.uriRepresentation() }
    }
    
    init(managedObjectContext: NSManagedObjectContext, settings: LibrarySettingsLevel) {
        self.managedObjectContext = managedObjectContext
        self.settings = settings
        self.interpreter = ContentInterpreter.createDefault(spotify: settings.spotify)

        let playContext = PlayContext(spotify: settings.spotify)
        
        player = Player(context: playContext)
        
        func getPlaylist(_ uri: URL?) -> DBPlaylist? {
            uri.flatMap { managedObjectContext.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: $0) }
                .flatMap { managedObjectContext.object(with: $0) } as? DBPlaylist
        }
        
        defaultPlaylist = getPlaylist(settings.defaultPlaylist)
        _mainPlaylist = LibraryPlaylist(library: self, playContext: playContext)

        NotificationCenter.default.addObserver(self, selector: #selector(objectsDidChange), name: .NSManagedObjectContextObjectsDidChange, object: managedObjectContext)
    }
    
    var spotify: Spotify { settings.spotify }
        
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
