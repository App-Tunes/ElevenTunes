//
//  TransientPlaylis.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 26.12.20.
//

import Foundation
import Combine

class TransientPlaylist: PersistentPlaylist {
    enum CodingKeys: String, CodingKey {
      case attributes, tracks, children
    }

    var uuid = UUID()
    var id: String { uuid.description }
    
    init(attributes: TypedDict<PlaylistAttribute>, children: [PersistentPlaylist] = [], tracks: [PersistentTrack] = []) {
        _attributes = attributes
        _tracks = tracks
        _children = children
    }
    
    public required init(from decoder: Decoder) throws {
        fatalError()
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        _tracks = try container.decode([PersistentTrack].self, forKey: .tracks)
//        _children = try container.decode([PersistentPlaylist].self, forKey: .children)
    }

    public func encode(to encoder: Encoder) throws {
        fatalError()
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(_tracks, forKey: .tracks)
//        try container.encode(_children, forKey: .children)
    }

    var loadLevel: AnyPublisher<LoadLevel, Never> {
        Just(.detailed).eraseToAnyPublisher()
    }
    
    @Published var _attributes: TypedDict<PlaylistAttribute> = .init()
    var attributes: AnyPublisher<TypedDict<PlaylistAttribute>, Never> {
        $_attributes.eraseToAnyPublisher()
    }

    @discardableResult
    func load(atLeast level: LoadLevel, deep: Bool) -> Bool {
        if deep { _children.forEach { $0.load(atLeast: level, deep: true) } }
        return true
    }

    @Published var _tracks: [PersistentTrack]
    var tracks: AnyPublisher<[PersistentTrack], Never> {
        $_tracks.eraseToAnyPublisher()
    }
    
    @Published var _children: [PersistentPlaylist]
    var children: AnyPublisher<[PersistentPlaylist], Never> {
        $_children.eraseToAnyPublisher()
    }

    @discardableResult
    func add(tracks: [PersistentTrack]) -> Bool {
        _tracks += tracks
        return true
    }
    
    @discardableResult
    func add(children: [PersistentPlaylist]) -> Bool {
        _children += children
        return true
    }
}
