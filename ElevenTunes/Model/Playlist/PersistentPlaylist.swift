//
//  PersistentPlaylist.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 27.12.20.
//

import Foundation
import Combine
import SwiftUI

public class PersistentPlaylist: NSObject, AnyPlaylist, Codable {
    public var id: String { fatalError() }
    public var icon: Image { Playlist.defaultIcon }
    
    public var loadLevel: AnyPublisher<LoadLevel, Never> { fatalError() }
    
    public var attributes: AnyPublisher<TypedDict<PlaylistAttribute>, Never> { fatalError() }
    
    public func supportsChildren() -> Bool { false }

    @discardableResult
    public func add(tracks: [PersistentTrack]) -> Bool { false }
    
    @discardableResult
    public func add(children: [PersistentPlaylist]) -> Bool { false }
    
    @discardableResult
    public func load(atLeast level: LoadLevel, deep: Bool, library: Library) -> Bool {
        fatalError()
    }

    var tracks: AnyPublisher<[PersistentTrack], Never> { fatalError() }
    var children: AnyPublisher<[PersistentPlaylist], Never> { fatalError() }
}

extension PersistentPlaylist {
    public var anyTracks: AnyPublisher<[AnyTrack], Never> {
        tracks.map { $0 as [AnyTrack] }
            .eraseToAnyPublisher()
    }
    
    public var anyChildren: AnyPublisher<[AnyPlaylist], Never> {
        children.map { $0 as [AnyPlaylist] }
            .eraseToAnyPublisher()
    }
}
