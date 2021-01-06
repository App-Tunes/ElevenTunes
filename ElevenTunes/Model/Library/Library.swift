//
//  Library.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 25.12.20.
//

import Cocoa
import Combine

public protocol AnyLibrary {
    var allTracks: [TrackToken] { get }
    var allPlaylists: [PlaylistToken] { get }
}

public struct DirectLibrary: AnyLibrary {
    public var allTracks: [TrackToken] = []
    public var allPlaylists: [PlaylistToken] = []
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
        didSet { settings.defaultPlaylist = defaultPlaylist?.uuid }
    }
    
    init(managedObjectContext: NSManagedObjectContext, settings: LibrarySettingsLevel) {
        self.managedObjectContext = managedObjectContext
        self.settings = settings
        self.interpreter = ContentInterpreter.createDefault(settings: settings)

        let playContext = PlayContext(spotify: settings.spotify)
        
        player = Player(context: playContext)
        
        defaultPlaylist = settings.defaultPlaylist.flatMap { try? managedObjectContext.fetch(DBPlaylist.createFetchRequest(id: $0)).first }
        _mainPlaylist = LibraryPlaylist(library: self, playContext: playContext)

        NotificationCenter.default.addObserver(self, selector: #selector(objectsDidChange), name: .NSManagedObjectContextObjectsDidChange, object: managedObjectContext)
    }
    
    var spotify: Spotify { settings.spotify }
        
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
