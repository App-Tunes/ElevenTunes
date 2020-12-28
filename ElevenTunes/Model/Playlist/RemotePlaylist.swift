//
//  RemotePlaylist.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 26.12.20.
//

import Foundation
import Combine

public class RemotePlaylist: PersistentPlaylist {
    var cancellables = Set<AnyCancellable>()
    
    public override init() { super.init() }
    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    public override func encode(to encoder: Encoder) throws { }
    
    @Published var _cacheMask: PlaylistContentMask = []
    public override var cacheMask: AnyPublisher<PlaylistContentMask, Never> {
        $_cacheMask.eraseToAnyPublisher()
    }
    
    public override func invalidateCaches(_ mask: PlaylistContentMask) {
        _cacheMask.subtract(mask)
    }
    
    @Published var _tracks: [PersistentTrack] = []
    public override var tracks: AnyPublisher<[PersistentTrack], Never> {
        $_tracks.eraseToAnyPublisher()
    }
    
    @Published var _children: [PersistentPlaylist] = []
    public override var children: AnyPublisher<[PersistentPlaylist], Never> {
        $_children.eraseToAnyPublisher()
    }
    
    @Published var _attributes: TypedDict<PlaylistAttribute> = TypedDict()
    public override var attributes: AnyPublisher<TypedDict<PlaylistAttribute>, Never> {
        $_attributes.eraseToAnyPublisher()
    }
}
