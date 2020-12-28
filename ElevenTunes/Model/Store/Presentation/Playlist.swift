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
    let isTopLevel: Bool  // bit hacky but k
    
    init(_ backend: AnyPlaylist, isTopLevel: Bool = false) {
        self.backend = backend
        self.isTopLevel = isTopLevel

        backend.anyChildren.assign(to: &$children)
        backend.anyTracks.assign(to: &$tracks)
        backend.cacheMask.assign(to: &$cacheMask)
        backend.attributes.assign(to: &$attributes)
    }
        
    var uuid = UUID()
    var id: String { backend.id }
    
    var icon: Image { backend.icon }
    var accentColor: Color {
        (isTopLevel && backend.supportsChildren()) ? .secondary : backend.accentColor
    }

    @Published var children: [AnyPlaylist] = []
    
    var viewChildren: [Playlist]? {
        guard backend.supportsChildren() else { return nil }
        return children.map { Playlist($0) }
    }
    
    var topLevelChildren: [Playlist] {
        return children.map { Playlist($0, isTopLevel: true) }
    }
    
    @Published var tracks: [AnyTrack] = []
    @Published var cacheMask: PlaylistContentMask = []
    @Published var attributes: TypedDict<PlaylistAttribute> = .init()

    subscript<T: PlaylistAttribute & TypedKey>(_ attribute: T) -> T.Value? {
        attributes[attribute]
    }

    func load(atLeast mask: PlaylistContentMask, deep: Bool = false, library: Library) {
        // TODO Deep, must somehow react upon other things having loaded lawl
        
        let missing = mask.subtracting(cacheMask)
        guard !missing.isEmpty else {
            return
        }
        
        backend.load(atLeast: missing, deep: deep, library: library)
    }

    func invalidateCaches(_ mask: PlaylistContentMask) {
        cacheMask.subtract(mask)  // Let's immediately invalidate ourselves
        backend.invalidateCaches(mask)
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

extension Playlist {
    static let defaultIcon: Image = Image(systemName: "music.note.list")
}
