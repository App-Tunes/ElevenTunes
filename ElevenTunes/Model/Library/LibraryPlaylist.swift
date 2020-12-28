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
    var playContext: PlayContext

    @Published var staticPlaylists: [AnyPlaylist] = []

    var cancellables = Set<AnyCancellable>()
        
    init(managedObjectContext: NSManagedObjectContext, playContext: PlayContext) {
        self.managedObjectContext = managedObjectContext
        self.playContext = playContext
        
        anyTracks = CDPublisher(request: DBTrack.createFetchRequest(), context: managedObjectContext)
            .map { $0 as [AnyTrack] }
            .replaceError(with: [])
            .eraseToAnyPublisher()

        _anyChildren = CDPublisher(request: LibraryPlaylist.playlistFetchRequest, context: managedObjectContext)
            .map { $0 as [AnyPlaylist] }
            .zip($staticPlaylists.eraseError()).map { $1 + $0 }
            .replaceError(with: [])
            .eraseToAnyPublisher()
        
        staticPlaylists = [
            SpotifyUserPlaylist()
        ]
    }
    
    var id: String {
        "Library" // TODO
    }
    
    var accentColor: Color { .accentColor }
    
    var cacheMask: AnyPublisher<PlaylistContentMask, Never> =
        Just([.minimal, .children, .tracks, .attributes]).eraseToAnyPublisher()
    
    // TODO
    @Published var _attributes: TypedDict<PlaylistAttribute> = .init()
    var attributes: AnyPublisher<TypedDict<PlaylistAttribute>, Never> {
        $_attributes.eraseToAnyPublisher()
    }

    var anyTracks: AnyPublisher<[AnyTrack], Never>
    
    var _anyChildren: AnyPublisher<[AnyPlaylist], Never>!
    var anyChildren: AnyPublisher<[AnyPlaylist], Never> { _anyChildren }

    static var playlistFetchRequest: NSFetchRequest<DBPlaylist> {
        let request = DBPlaylist.createFetchRequest()
        request.predicate = NSPredicate(format: "parent == nil")
        request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        return request
    }
    
    func load(atLeast level: PlaylistContentMask, deep: Bool, library: Library) {
        // TODO Deep
    }
    
    func invalidateCaches(_ mask: PlaylistContentMask) {
        // We have no caches per se, everything is stream
    }
    
    var icon: Image { Image(systemName: "house.fill" ) }
    
    func supportsChildren() -> Bool { true }  // lol imagine if this were false
    
    @discardableResult
    func add(tracks: [PersistentTrack]) -> Bool {
        // Fetch requests auto-update content
        let context = managedObjectContext.child(concurrencyType: .privateQueueConcurrencyType)
        context.perform {
            let _ = Library.convert(
                DirectLibrary(allTracks: tracks),
                context: context
            )
            
            do {
                try context.save()
            }
            catch let error {
                appLogger.error("Failed to import tracks: \(error)")
            }
        }

        return true
    }
    
    @discardableResult
    func add(children: [PersistentPlaylist]) -> Bool {
        // Fetch requests auto-update content
        let context = managedObjectContext.child(concurrencyType: .privateQueueConcurrencyType)
        context.perform {
            let _ = Library.convert(
                DirectLibrary(allPlaylists: children),
                context: context
            )

            do {
                try context.save()
            }
            catch let error {
                appLogger.error("Failed to import playlists: \(error)")
            }
        }

        return true
    }
}
