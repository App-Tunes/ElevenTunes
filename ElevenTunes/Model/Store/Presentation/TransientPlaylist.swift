//
//  TransientPlaylist.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 26.12.20.
//

import Foundation

class Playlist: AnyPlaylist {
    var backend: AnyPlaylistBackend?
    
    init(_ backend: PlaylistBackend) {
        self.backend = backend
    }
    
    init(attributes: TypedDict<PlaylistAttribute>, children: [AnyPlaylist] = [], tracks: [AnyTrack] = []) {
        self.attributes = attributes
        self.children = children
        self.tracks = tracks
        self.status = .done
    }
    
    var status: LoadStatus = .blank

    var children: [AnyPlaylist] = []
    var tracks: [AnyTrack] = []
    
    var attributes: TypedDict<PlaylistAttribute> = TypedDict()

    @discardableResult
    func load(force: Bool) -> Bool {
        guard status == .blank || force else {
            return false
        }
        
        guard let backend = backend else {
            status = .done
        }
        
        backend.load()
        return true
    }

    subscript<T: PlaylistAttribute & TypedKey>(_ attribute: T) -> T.Value? {
        attributes[attribute]
    }

    @discardableResult
    func add(tracks: [TrackBackend]) -> Bool {
        false
    }
    
    @discardableResult
    func add(children: [PlaylistBackend]) -> Bool {
        false
    }
}
