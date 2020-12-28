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

    @Published var _cacheMask: TrackContentMask = []
    public override var cacheMask: AnyPublisher<TrackContentMask, Never> {
        $_cacheMask.eraseToAnyPublisher()
    }

    @Published var _attributes: TypedDict<TrackAttribute> = .init()
    public override var attributes: AnyPublisher<TypedDict<TrackAttribute>, Never> {
        $_attributes.eraseToAnyPublisher()
    }
    
    public override func invalidateCaches(_ mask: TrackContentMask) {
        _cacheMask.subtract(mask)
    }
}
