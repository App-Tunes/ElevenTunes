//
//  RemotePlaylist.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 26.12.20.
//

import Foundation
import Combine
import SwiftUI

public class RemotePlaylist: AnyPlaylist {
    var cancellables = Set<AnyCancellable>()
    
    let contentSet: FeatureSet<PlaylistContentMask, PlaylistContentMask> = .init()
    
    public var id: String { asToken.id }
    public var asToken: PlaylistToken { fatalError() }

    public var accentColor: Color { .primary }
    public var icon: Image { Image(systemName: "music.note.list") }
    
    public var hasCaches: Bool { true }
    public func supportsChildren() -> Bool { false }
    
    public func cacheMask() -> AnyPublisher<PlaylistContentMask, Never> {
        contentSet.$features.eraseToAnyPublisher()
    }
    
    public func invalidateCaches(_ mask: PlaylistContentMask) {
        contentSet.subtract(mask)
    }
    
    @Published public var _tracks: [AnyTrack] = []
    public func tracks() -> AnyPublisher<[AnyTrack], Never> {
        $_tracks.eraseToAnyPublisher()
    }
    
    @Published public var _children: [AnyPlaylist] = []
    public func children() -> AnyPublisher<[AnyPlaylist], Never> {
        $_children.eraseToAnyPublisher()
    }
    
    @Published public var _attributes: TypedDict<PlaylistAttribute> = .init()
    public func attributes() -> AnyPublisher<TypedDict<PlaylistAttribute>, Never> {
        $_attributes.eraseToAnyPublisher()
    }
    
    public func load(atLeast mask: PlaylistContentMask, library: Library) {
        fatalError()
    }
    
    public func add(tracks: [TrackToken]) -> Bool { false }
    
    public func add(children: [PlaylistToken]) -> Bool { false }
}
