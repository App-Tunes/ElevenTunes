//
//  TransientPlaylist.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 26.12.20.
//

import Foundation
import Combine
import SwiftUI

class Playlist: ObservableObject {
    let backend: AnyPlaylist
    
    init(_ backend: AnyPlaylist) {
        self.backend = backend

        anyChildren = backend.anyChildren
        anyTracks = backend.anyTracks
        loadLevel = backend.loadLevel
        attributes = backend.attributes
        
        backend.anyChildren.assign(to: &$_children)
        backend.anyTracks.assign(to: &$_tracks)
        backend.loadLevel.assign(to: &$_loadLevel)
        backend.attributes.assign(to: &$_attributes)
        print(_attributes)
    }
        
    var uuid = UUID()
    var id: String { backend.id }
    
    var icon: Image { backend.icon }

    @Published var _children: [AnyPlaylist] = []
    var anyChildren: AnyPublisher<[AnyPlaylist], Never>
    
    @Published var _tracks: [AnyTrack] = []
    var anyTracks: AnyPublisher<[AnyTrack], Never>
    
    @Published var _loadLevel: LoadLevel = .none
    var loadLevel: AnyPublisher<LoadLevel, Never>
    
    @Published var _attributes: TypedDict<PlaylistAttribute> = .init()
    var attributes: AnyPublisher<TypedDict<PlaylistAttribute>, Never>

    subscript<T: PlaylistAttribute & TypedKey>(_ attribute: T) -> T.Value? {
        _attributes[attribute]
    }

    @discardableResult
    func load(atLeast level: LoadLevel, deep: Bool = false) -> Bool {
        // TODO Deep, must somehow react upon other things having loaded lawl
        guard _loadLevel < level else {
            return false
        }
        
        return backend.load(atLeast: level, deep: deep)
    }

    @discardableResult
    func add(tracks: [PersistentTrack]) -> Bool {
        backend.add(tracks: tracks)
    }
    
    @discardableResult
    func add(children: [PersistentPlaylist]) -> Bool {
        backend.add(children: children)
    }
}

extension Playlist: Hashable, Identifiable {
    static func == (lhs: Playlist, rhs: Playlist) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
