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

    @Published var _loadLevel: LoadLevel = .none
    public override var loadLevel: AnyPublisher<LoadLevel, Never> {
        $_loadLevel.eraseToAnyPublisher()
    }

    @Published var _attributes: TypedDict<TrackAttribute> = .init()
    public override var attributes: AnyPublisher<TypedDict<TrackAttribute>, Never> {
        $_attributes.eraseToAnyPublisher()
    }
}