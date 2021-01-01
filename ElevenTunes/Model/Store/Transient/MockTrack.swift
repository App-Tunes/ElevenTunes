//
//  TransientTrack.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 26.12.20.
//

import Foundation
import Combine
import SwiftUI

class MockTrack: TrackToken, AnyTrack {
    class MockError: Error {}
    
    enum CodingKeys: String, CodingKey {
        case attributes
    }

    init(attributes: TypedDict<TrackAttribute>) {
        _attributes = attributes
        super.init()
    }
    
    public required init(from decoder: Decoder) throws {
        fatalError()
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        // TODO
//        try super.init(from: decoder)
    }

    public override func encode(to encoder: Encoder) throws {
        fatalError()
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        // TODO
//        try super.encode(to: encoder)
    }
    
    var asToken: TrackToken { self }
    
    var icon: Image { Image(systemName: "questionmark") }
    
    var accentColor: Color { .primary}

    let uuid = UUID()
    override var id: String { uuid.description }
    
    var origin: URL? { nil }
    
    override func expand(_ context: Library) -> AnyTrack { self }
    
    func cacheMask() -> AnyPublisher<TrackContentMask, Never> {
        Just(.minimal).eraseToAnyPublisher()
    }
    
    @Published var _artists: [AnyPlaylist] = []
    func artists() -> AnyPublisher<[AnyPlaylist], Never> {
        $_artists.eraseToAnyPublisher()
    }

    @Published var _album: AnyPlaylist? = nil
    func album() -> AnyPublisher<AnyPlaylist?, Never> {
        $_album.eraseToAnyPublisher()
    }

    @Published var _attributes: TypedDict<TrackAttribute> = .init()
    func attributes() -> AnyPublisher<TypedDict<TrackAttribute>, Never> {
        $_attributes.eraseToAnyPublisher()
    }

    func emitter(context: PlayContext) -> AnyPublisher<AnyAudioEmitter, Error> {
        Fail(error: MockError()).eraseToAnyPublisher()
    }
    
    func invalidateCaches(_ mask: TrackContentMask) { }
    
    func previewImage() -> AnyPublisher<NSImage?, Never> {
        Just(nil).eraseToAnyPublisher()
    }
}
