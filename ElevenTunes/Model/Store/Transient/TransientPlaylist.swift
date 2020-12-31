//
//  TransientPlaylis.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 26.12.20.
//

import Foundation
import Combine
import SwiftUI

class TransientPlaylist: PlaylistToken, AnyPlaylist {
    enum CodingKeys: String, CodingKey {
      case attributes, tracks, children
    }
    
    enum CodingError: Error {
        case encode, decode
    }

    var uuid = UUID()
    override var id: String { uuid.description }
    
    var icon: Image { Image(systemName: "music.note.list") }
    var accentColor: Color { .primary }
    
    var type: PlaylistType { .playlist }
    
    var hasCaches: Bool { false }
    func invalidateCaches(_ mask: PlaylistContentMask) {}
    
    func supportsChildren() -> Bool { false }

    init(attributes: TypedDict<PlaylistAttribute>, children: [AnyPlaylist] = [], tracks: [AnyTrack] = []) {
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
    
    override func expand(_ context: Library) -> AnyPlaylist { self }
    
    var asToken: PlaylistToken { self }

    func cacheMask() -> AnyPublisher<PlaylistContentMask, Never> {
        Just([.minimal, .children, .tracks, .attributes]).eraseToAnyPublisher()
    }
    
    @Published var _attributes: TypedDict<PlaylistAttribute> = .init()
    func attributes() -> AnyPublisher<TypedDict<PlaylistAttribute>, Never> {
        $_attributes.eraseToAnyPublisher()
    }

    @Published var _tracks: [AnyTrack]
    func tracks() -> AnyPublisher<[AnyTrack], Never> {
        $_tracks.eraseToAnyPublisher()
    }
    
    @Published var _children: [AnyPlaylist]
    func children() -> AnyPublisher<[AnyPlaylist], Never> {
        $_children.eraseToAnyPublisher()
    }

    @discardableResult
    func add(tracks: [TrackToken]) -> Bool {
//        _tracks += tracks
        // TODO
        return true
    }
    
    @discardableResult
    func add(children: [PlaylistToken]) -> Bool {
//        _children += children
        // TODO
        return true
    }
}
