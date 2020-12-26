//
//  TransientTrack.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 26.12.20.
//

import Foundation
import Combine

class MockTrack: PersistentTrack {
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

    let uuid = UUID()
    override var id: String { uuid.description }
    
    override var loadLevel: AnyPublisher<LoadLevel, Never> {
        Just(.detailed).eraseToAnyPublisher()
    }
    
    @Published var _attributes: TypedDict<TrackAttribute> = .init()
    override var attributes: AnyPublisher<TypedDict<TrackAttribute>, Never> {
        $_attributes.eraseToAnyPublisher()
    }

    override func emitter() -> AnyPublisher<AnyAudioEmitter, Error> {
        Fail(error: MockError()).eraseToAnyPublisher()
    }
    
    @discardableResult
    override func load(atLeast level: LoadLevel) -> Bool { true }
}
