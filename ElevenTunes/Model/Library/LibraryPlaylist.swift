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
        
        anyTracks = CDPublisher(request: DBTrack.createFetchRequest(), context: managedObjectContext)
            .map { $0 as [AnyTrack] }
            .replaceError(with: [])
            .eraseToAnyPublisher()

        anyChildren = CDPublisher(request: LibraryPlaylist.playlistFetchRequest, context: managedObjectContext)
            .map { $0 as [AnyPlaylist] }
            .replaceError(with: [])
            .eraseToAnyPublisher()
    }
    
    var id: String {
        "Library" // TODO
    }
    
    var loadLevel: AnyPublisher<LoadLevel, Never> = Just(.detailed).eraseToAnyPublisher()
    
    // TODO
    @Published var _attributes: TypedDict<PlaylistAttribute> = .init()
    var attributes: AnyPublisher<TypedDict<PlaylistAttribute>, Never> {
        $_attributes.eraseToAnyPublisher()
    }

    var anyTracks: AnyPublisher<[AnyTrack], Never>
    var anyChildren: AnyPublisher<[AnyPlaylist], Never>

    static var playlistFetchRequest: NSFetchRequest<DBPlaylist> {
        let request = DBPlaylist.createFetchRequest()
        request.predicate = NSPredicate(format: "parent == nil")
        request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        return request
    }
    
    @discardableResult
    func load(atLeast level: LoadLevel, deep: Bool) -> Bool {
        // TODO Deep
        true
    }
    
    var icon: Image { Image(systemName: "house.fill" ) }
    
    @discardableResult
    func add(tracks: [PersistentTrack]) -> Bool {
        // Fetch requests auto-update content
        let _ = Library.convert(
            DirectLibrary(allTracks: tracks),
            context: managedObjectContext
        )

        return true
    }
    
    @discardableResult
    func add(children: [PersistentPlaylist]) -> Bool {
        // Fetch requests auto-update content
        let _ = Library.convert(
            DirectLibrary(allPlaylists: children),
            context: managedObjectContext
        )

        return true
    }
}
