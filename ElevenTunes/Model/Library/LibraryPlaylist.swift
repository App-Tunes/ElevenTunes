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
        
        _loadLevel = .detailed
        _playlists = [LibraryMock.playlist()]
        
        // TODO
//        let context = self.managedObjectContext
//
//        Future<[DBPlaylist], Error> {
//            let request = DBPlaylist.createFetchRequest()
//            request.predicate = NSPredicate(format: "parent == nil")
//            return try context.fetch(request)
//        }
//        .sink(receiveCompletion: appLogErrors(_:)) { [weak self] children in
//            guard let self = self else { return }
//            self.playlists = children
//            self.isLoaded = true
//            self.isLoading = false
//        }
//        .store(in: &cancellables)
        
        return true
    }
    
    var icon: Image { Image(systemName: "house.fill" ) }
    
    @discardableResult
    func add(tracks: [PersistentTrack]) -> Bool {
            // TODO Add as DBTrack
//            tracks.forEach(managedObjectContext.insert)
//
//            do {
//                try managedObjectContext.save()
//                self.tracks += tracks
//            }
//            catch let error {
//                appLogger.critical("Error adding tracks: \(error)")
//            }
        
        return true
    }
    
    @discardableResult
    func add(children: [PersistentPlaylist]) -> Bool {
        // If a user drops a playlist into us, and expects them to appear,
        // the parent must be nil
            // TODO Add as DBPlaylists
//            children.forEach { $0.parent = nil }
//            children.forEach(managedObjectContext.insert)
//
//            do {
//                try managedObjectContext.save()
//                self.playlists += children
//            }
//            catch let error {
//                appLogger.critical("Error adding playlists: \(error)")
//            }
        return true
    }
}
