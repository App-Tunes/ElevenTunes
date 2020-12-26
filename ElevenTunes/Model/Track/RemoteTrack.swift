//
//  RemoteTrack.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 26.12.20.
//

import Foundation
import Combine

public class RemoteTrack: PersistentTrack {
    var cancellables = Set<AnyCancellable>()
    
    init() {
        
    }
    
    public required init(from decoder: Decoder) throws { }
    public func encode(to encoder: Encoder) throws { }

    var id: String { fatalError() }
    
    @discardableResult
    func load(atLeast level: LoadLevel) -> Bool {
        fatalError()
    }

    @Published var _loadLevel: LoadLevel = .none
    var loadLevel: AnyPublisher<LoadLevel, Never> {
        $_loadLevel.eraseToAnyPublisher()
    }

    @Published var _attributes: TypedDict<TrackAttribute> = .init()
    var attributes: AnyPublisher<TypedDict<TrackAttribute>, Never> {
        $_attributes.eraseToAnyPublisher()
    }
    
    func emitter() -> AnyPublisher<AnyAudioEmitter, Error> {
        fatalError()
    }
}
