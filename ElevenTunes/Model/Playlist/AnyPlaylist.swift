//
//  AnyPlaylist.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 25.12.20.
//

import Foundation
import SwiftUI

protocol AnyPlaylist: ObservableObject, Hashable, Identifiable {
    var id: UUID { get }

    var isLoading: Bool { get }
    var isLoaded: Bool { get }

    var tracks: [Track] { get }
    var children: [Playlist] { get }

    var icon: Image { get }

    @discardableResult
    func load(force: Bool) -> Bool

    subscript<T>(_ attribute: TypedKey<Playlist.AttributeKey, T>) -> T? { get }
    
    @discardableResult
    func add(tracks: [Track]) -> Bool
    
    @discardableResult
    func add(children: [Playlist]) -> Bool
}

extension AnyPlaylist {
    func load() {
        load(force: false)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}
