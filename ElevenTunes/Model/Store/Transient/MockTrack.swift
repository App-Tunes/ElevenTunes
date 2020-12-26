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
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // TODO
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        // TODO
    }

    let uuid = UUID()
    var id: String { uuid.description }
    
    var loadLevel: AnyPublisher<LoadLevel, Never> {
        Just(.detailed).eraseToAnyPublisher()
    }
    
    @Published var _attributes: TypedDict<TrackAttribute> = .init()
    var attributes: AnyPublisher<TypedDict<TrackAttribute>, Never> {
        $_attributes.eraseToAnyPublisher()
    }

    func emitter() -> AnyPublisher<AnyAudioEmitter, Error> {
        Fail(error: MockError()).eraseToAnyPublisher()
    }
    
    @discardableResult
    func load(atLeast level: LoadLevel) -> Bool { true }
}
