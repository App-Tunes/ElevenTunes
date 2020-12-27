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
    
    enum CodingError: Error {
        case encode, decode
    }

    var uuid = UUID()
    override var id: String { uuid.description }
    
    init(attributes: TypedDict<PlaylistAttribute>, children: [PersistentPlaylist] = [], tracks: [PersistentTrack] = []) {
        _attributes = attributes
        _tracks = tracks
        _children = children
        super.init()
    }
    
    public required init(from decoder: Decoder) throws {
        throw CodingError.decode
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        _tracks = try container.decode([PersistentTrack].self, forKey: .tracks)
//        _children = try container.decode([PersistentPlaylist].self, forKey: .children)
    }

    public override func encode(to encoder: Encoder) throws {
        throw CodingError.encode
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(_tracks, forKey: .tracks)
//        try container.encode(_children, forKey: .children)
    }

    override var loadLevel: AnyPublisher<LoadLevel, Never> {
        Just(.detailed).eraseToAnyPublisher()
    }
    
    @Published var _attributes: TypedDict<PlaylistAttribute> = .init()
    override var attributes: AnyPublisher<TypedDict<PlaylistAttribute>, Never> {
        $_attributes.eraseToAnyPublisher()
    }

    @discardableResult
    override func load(atLeast level: LoadLevel, deep: Bool, library: Library) -> Bool {
        if deep {
            _children.forEach { $0.load(atLeast: level, deep: true, library: library) }
        }
        return true
    }

    @Published var _tracks: [PersistentTrack]
    override var tracks: AnyPublisher<[PersistentTrack], Never> {
        $_tracks.eraseToAnyPublisher()
    }
    
    @Published var _children: [PersistentPlaylist]
    override var children: AnyPublisher<[PersistentPlaylist], Never> {
        $_children.eraseToAnyPublisher()
    }

    @discardableResult
    override func add(tracks: [PersistentTrack]) -> Bool {
        _tracks += tracks
        return true
    }
    
    @discardableResult
    override func add(children: [PersistentPlaylist]) -> Bool {
        _children += children
        return true
    }
}
