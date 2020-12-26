//
//  LibraryPlaylist.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 25.12.20.
//

import Cocoa
import SwiftUI
import Combine

class LibraryPlaylist: AnyPlaylist {
    let managedObjectContext: NSManagedObjectContext
            
    var cancellables = Set<AnyCancellable>()
    
    init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
    }
    
    var id: String {
        "Library" // TODO
    }
    
    @Published var _loadLevel: LoadLevel = .none
    var loadLevel: AnyPublisher<LoadLevel, Never> {
        $_loadLevel.eraseToAnyPublisher()
    }
    
    // TODO
    @Published var _attributes: TypedDict<PlaylistAttribute> = .init()
    var attributes: AnyPublisher<TypedDict<PlaylistAttribute>, Never> {
        $_attributes.eraseToAnyPublisher()
    }

    @Published var _tracks: [AnyTrack] = []
    var anyTracks: AnyPublisher<[AnyTrack], Never> {
        $_tracks.eraseToAnyPublisher()
    }

    @Published var _playlists: [AnyPlaylist] = []
    var anyChildren: AnyPublisher<[AnyPlaylist], Never> {
        $_playlists.eraseToAnyPublisher()
    }

    @discardableResult
    func load(atLeast level: LoadLevel, deep: Bool) -> Bool {
        let context = self.managedObjectContext

        Future<[DBPlaylist], Error> {
            let request = DBPlaylist.createFetchRequest()
            request.predicate = NSPredicate(format: "parent == nil")
            return try context.fetch(request)
        }
        .sink(receiveCompletion: appLogErrors(_:)) { [weak self] children in
            guard let self = self else { return }
            self._playlists = children
            self._loadLevel = .detailed
        }
        .store(in: &cancellables)
        
        return true
    }
    
    var icon: Image { Image(systemName: "house.fill" ) }
    
    @discardableResult
    func add(tracks: [PersistentTrack]) -> Bool {
        let (dbTracks, _) = Library.convert(
            DirectLibrary(allTracks: tracks),
            context: managedObjectContext
        )

        self._tracks += dbTracks

        return true
    }
    
    @discardableResult
    func add(children: [PersistentPlaylist]) -> Bool {
        let (dbTracks, dbPlaylists) = Library.convert(
            DirectLibrary(allPlaylists: children),
            context: managedObjectContext
        )

        self._tracks += dbTracks
        self._playlists += dbPlaylists

        return true
    }
}
