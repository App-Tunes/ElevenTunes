//
//  Playlist.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 18.12.20.
//

import Foundation
import SwiftUI
import Combine

class Playlist: AnyPlaylist {    
    var backend: PlaylistBackend?

    let id = UUID()
    private let attributes: TypedDict<AttributeKey>

    @Published private(set) var isLoading = false
    @Published private(set) var isLoaded = false

    @Published private(set) var tracks: [Track] = []
    @Published private(set) var children: [Playlist] = []

    private var cancellables = Set<AnyCancellable>()
    
    init(_ backend: PlaylistBackend, attributes: TypedDict<AttributeKey>) {
        self.backend = backend
        self.attributes = attributes
    }
    
    init(attributes: TypedDict<AttributeKey>, tracks: [Track] = [], children: [Playlist] = []) {
        self.attributes = attributes
        self.tracks = tracks
        self.children = children
        self.isLoaded = true
    }
    
    static func == (lhs: Playlist, rhs: Playlist) -> Bool {
        lhs.id == rhs.id
    }
    
    subscript<T>(_ attribute: TypedKey<AttributeKey, T>) -> T? {
        return self.attributes[attribute]
    }
    
    @discardableResult
    func load(force: Bool) -> Bool {
        guard !isLoaded || force else { return false }
        guard !isLoading else { return false }
        
        guard let backend = backend else {
            isLoaded = true
            return true
        }
        
        backend.load()
            .onMain()
            .sink(receiveCompletion: appLogErrors(_:)) { [weak self] (tracks, children) in
                guard let self = self else { return }
                
                withAnimation {
                    self.tracks = tracks
                    self.children = children
                    self.isLoaded = true
                    self.isLoading = false
                }
            }
            .store(in: &cancellables)
        
        return true
    }

    var icon: Image {
        return backend?.icon ?? Image(systemName: "music.note.list")
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

