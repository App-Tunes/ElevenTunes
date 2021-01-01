//
//  Wrappers.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 01.01.21.
//

import Foundation

/// These are needed so SwiftUI knows if anything has changed.
/// Unfortunately, AnyPlaylist etc. can't inherit from Identifiable / Hashable because it's a protocol.
/// Might be fixable in the future.
struct Playlist: Hashable, Identifiable {
    let backend: AnyPlaylist

    var id: String
    
    init(_ backend: AnyPlaylist) {
        self.backend = backend
        id = backend.id
    }
    
    init?(_ backend: AnyPlaylist?) {
        guard let backend = backend else { return nil}
        self.init(backend)
    }
    
    static func == (lhs: Playlist, rhs: Playlist) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct Track: Hashable, Identifiable {
    let backend: AnyTrack

    var id: String
    
    init(_ backend: AnyTrack) {
        self.backend = backend
        id = backend.id
    }
    
    init?(_ backend: AnyTrack?) {
        guard let backend = backend else { return nil}
        self.init(backend)
    }
    
    static func == (lhs: Track, rhs: Track) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
