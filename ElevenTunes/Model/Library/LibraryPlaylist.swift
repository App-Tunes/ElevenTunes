//
//  LibraryPlaylist.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 25.12.20.
//

import Cocoa
import SwiftUI
import Combine

class LibraryPlaylist: PlaylistBackend {
    let managedObjectContext: NSManagedObjectContext

    // TODO Temporary
    var backingPlaylist: Playlist? = nil
    
    init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
    }

    var icon: Image? { Image(systemName: "house.fill" ) }
    
    func load() -> AnyPublisher<([Track], [Playlist]), Error> {
        Future { [weak self] in
            guard let self = self else { throw CocoaError(.coderInvalidValue) }
            let dir = LibraryMock.directory()
            self.backingPlaylist = dir
            return (dir.tracks, dir.children)
        }
        .eraseToAnyPublisher()
    }
    
    func add(tracks: [Track]) -> Bool {
        backingPlaylist?.add(tracks: tracks) ?? false
    }
    
    func add(children: [Playlist]) -> Bool {
        backingPlaylist?.add(children: children) ?? false
    }
}
