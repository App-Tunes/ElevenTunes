//
//  Library.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 25.12.20.
//

import Cocoa
import Combine

public struct UninterpretedLibrary {
	public var tracks: [AnyTrack] = []
	public var playlists: [AnyPlaylist] = []
}

public struct InterpretedLibrary {
	public var tracks: [BranchingTrack] = []
	public var playlists: [BranchingPlaylist] = []
}

public class Library {
    static let defaultPlaylistKey = "defaultPlaylist"
    
    let managedObjectContext: NSManagedObjectContext
	
	let playContext: PlayContext
        
    let settings: LibrarySettingsLevel
    var _interpreter: ContentInterpreter! = nil
	var interpreter: ContentInterpreter { _interpreter }
    
    let player: Player
    
    var defaultPlaylist: DBPlaylist? {
        didSet { settings.defaultPlaylist = defaultPlaylist?.uuid }
    }
    
    init(managedObjectContext: NSManagedObjectContext, settings: LibrarySettingsLevel) {
        self.managedObjectContext = managedObjectContext
        self.settings = settings

        let playContext = PlayContext(spotify: settings.spotify)
		self.playContext = playContext
        
        player = Player(context: playContext)
        
		_interpreter = ContentInterpreter.createDefault(settings: settings, library: self)

        defaultPlaylist = settings.defaultPlaylist.flatMap { try? managedObjectContext.fetch(DBPlaylist.createFetchRequest(id: $0)).first }

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
