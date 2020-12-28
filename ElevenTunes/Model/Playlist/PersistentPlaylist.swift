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
    public var accentColor: Color { .secondary }
    
    public var cacheMask: AnyPublisher<PlaylistContentMask, Never> { fatalError() }
    
    public var attributes: AnyPublisher<TypedDict<PlaylistAttribute>, Never> { fatalError() }
    
    public func supportsChildren() -> Bool { false }

    @discardableResult
    public func add(tracks: [PersistentTrack]) -> Bool { false }
    
    @discardableResult
    public func add(children: [PersistentPlaylist]) -> Bool { false }
    
    public var hasCaches: Bool { true }
    
    public func load(atLeast mask: PlaylistContentMask, deep: Bool, library: Library) {
        fatalError()
    }
    
    public func invalidateCaches(_ mask: PlaylistContentMask) { }

    var tracks: AnyPublisher<[PersistentTrack], Never> { fatalError() }
    var children: AnyPublisher<[PersistentPlaylist], Never> { fatalError() }
    
    // NSObject gedöns
    
    public override var hash: Int { id.hash }
    
    public override func isEqual(_ other: Any?) -> Bool {
        guard let other = other as? PersistentPlaylist else { return false }
        return self.id == other.id
    }
}

extension PersistentPlaylist: Identifiable {}

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
