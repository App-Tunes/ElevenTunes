//
//  AnyPlaylist.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 25.12.20.
//

import Foundation
import SwiftUI
import Combine

enum LoadLevel: Comparable {
    case none, minimal, detailed
}

protocol AnyPlaylist: AnyObject {
    var id: String { get }
    var icon: Image { get }
    
    var anyTracks: AnyPublisher<[AnyTrack], Never> { get }
    var anyChildren: AnyPublisher<[AnyPlaylist], Never> { get }

    var loadLevel: AnyPublisher<LoadLevel, Never> { get }
    
    var attributes: AnyPublisher<TypedDict<PlaylistAttribute>, Never> { get }

    @discardableResult
    func load(atLeast level: LoadLevel, deep: Bool) -> Bool

    @discardableResult
    func add(tracks: [PersistentTrack]) -> Bool
    
    @discardableResult
    func add(children: [PersistentPlaylist]) -> Bool
}

extension AnyPlaylist {
    var icon: Image { Image(systemName: "music.note.list") }
    
    @discardableResult
    func load(atLeast level: LoadLevel) -> Bool {
        load(atLeast: level, deep: false)
    }
}

protocol PersistentPlaylist: AnyPlaylist, Codable {
    var tracks: AnyPublisher<[PersistentTrack], Never> { get }
    var children: AnyPublisher<[PersistentPlaylist], Never> { get }
}

extension PersistentPlaylist {
    var anyTracks: AnyPublisher<[AnyTrack], Never> {
        tracks.map { $0 as [AnyTrack] }
            .eraseToAnyPublisher()
    }
    
    var anyChildren: AnyPublisher<[AnyPlaylist], Never> {
        children.map { $0 as [AnyPlaylist] }
            .eraseToAnyPublisher()
    }
}

class PlaylistBackendTransformer: CodableTransformer {
    override class var classes: [AnyClass] { [
        DirectoryPlaylist.self,
        SpotifyPlaylist.self,
        M3UPlaylist.self
    ]}
}
