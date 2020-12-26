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
    
    init() {
        
    }
    
    public required init(from decoder: Decoder) throws { }
    public func encode(to encoder: Encoder) throws { }

    var id: String { fatalError() }
    
    @Published var _loadLevel: LoadLevel = .none
    var loadLevel: AnyPublisher<LoadLevel, Never> {
        $_loadLevel.eraseToAnyPublisher()
    }
    
    @Published var _tracks: [PersistentTrack] = []
    var tracks: AnyPublisher<[PersistentTrack], Never> {
        $_tracks.eraseToAnyPublisher()
    }
    
    @Published var _children: [PersistentPlaylist] = []
    var children: AnyPublisher<[PersistentPlaylist], Never> {
        $_children.eraseToAnyPublisher()
    }
    
    @Published var _attributes: TypedDict<PlaylistAttribute> = TypedDict()
    var attributes: AnyPublisher<TypedDict<PlaylistAttribute>, Never> {
        $_attributes.eraseToAnyPublisher()
    }
    
    @discardableResult
    func load(atLeast level: LoadLevel, deep: Bool) -> Bool { fatalError() }

    @discardableResult
    func add(tracks: [PersistentTrack]) -> Bool { false }
    
    @discardableResult
    func add(children: [PersistentPlaylist]) -> Bool { false }
}
