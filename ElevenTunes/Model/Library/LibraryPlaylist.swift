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

    @Published var id: UUID = UUID()
    
    @Published var isLoading: Bool = false
    @Published var isLoaded: Bool = false
    
    @Published var tracks: [Track] = []
    @Published var playlists: [Playlist] = []
    
    var children: [Playlist] { playlists }
    
    var cancellables = Set<AnyCancellable>()
    
    init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
    }
    
    static func == (lhs: LibraryPlaylist, rhs: LibraryPlaylist) -> Bool {
        lhs.id == rhs.id
    }

    @discardableResult
    func load(force: Bool) -> Bool {
        guard force || !isLoaded else { return false }
        
        Future {
            LibraryMock.directory()
        }
        .sink { [weak self] dir in
            guard let self = self else { return }
            self.tracks = dir.tracks
            self.playlists = dir.children
            self.isLoaded = true
        }
        .store(in: &cancellables)
        
        return true
    }
    
    subscript<T>(attribute: TypedKey<Playlist.AttributeKey, T>) -> T? {
        nil
    }

    var icon: Image { Image(systemName: "house.fill" ) }
    
    func add(tracks: [Track]) -> Bool {
        self.tracks += tracks
        return true
    }
    
    func add(children: [Playlist]) -> Bool {
        self.playlists += children
        return true
    }

}
