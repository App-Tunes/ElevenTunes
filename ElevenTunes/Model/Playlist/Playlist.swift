//
//  Playlist.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 18.12.20.
//

import Foundation

class Playlist {
    var backend: PlaylistBackend?

    let id = UUID()
    private let attributes: TypedDict<AttributeKey>

    private(set) var tracks: [Track] = []
    private(set) var children: [Playlist] = []

    init(_ backend: PlaylistBackend?, attributes: TypedDict<AttributeKey>, tracks: [Track] = [], children: [Playlist] = []) {
        self.backend = backend
        self.tracks = tracks
        self.children = children
        self.attributes = attributes
    }
    
    subscript<T>(_ attribute: TypedKey<AttributeKey, T>) -> T {
        return self.attributes[attribute]
    }
    
    @discardableResult
    func add(tracks: [Track]) -> Bool {
        guard !tracks.isEmpty else {
            return false
        }
        
        if let backend = backend, !backend.add(tracks: tracks) {
            return false
        }

        DispatchQueue.main.async {
            self.objectWillChange.send()
            self.tracks += tracks
        }
        
        return true
    }
    
    @discardableResult
    func add(children: [Playlist]) -> Bool {
        guard !children.isEmpty else {
            return false
        }
        
        if let backend = backend, !backend.add(children: children) {
            return false
        }

        DispatchQueue.main.async {
            self.objectWillChange.send()
            self.children += children
        }
        
        return true
    }
}

extension Playlist {
    final class AttributeKey: Hashable {
        let id: String
        
        init(_ id: String) {
            self.id = id
        }
        
        static func == (lhs: AttributeKey, rhs: AttributeKey) -> Bool {
            lhs.id == rhs.id
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(self.id)
        }
    }
}

extension AnyTypedKey {
    static let ptitle = TypedKey<Playlist.AttributeKey, String>(.init("Title"))
}

extension Playlist: Hashable, Identifiable {
    static func == (lhs: Playlist, rhs: Playlist) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}

extension Playlist: ObservableObject {
    
}
