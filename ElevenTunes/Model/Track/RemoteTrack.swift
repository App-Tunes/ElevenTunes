//
//  RemoteTrack.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 26.12.20.
//

import Foundation
import Combine
import SwiftUI

public class RemoteTrack: AnyTrack {
    var cancellables = Set<AnyCancellable>()

    public var asToken: TrackToken { fatalError() }
    public var id: String { asToken.id }

    public var icon: Image { Image(systemName: "music.note") }
    
    let contentSet: FeatureSet<TrackContentMask, TrackContentMask> = .init()
    
    public func cacheMask() -> AnyPublisher<TrackContentMask, Never> {
        contentSet.$features.eraseToAnyPublisher()
    }

    @Published var _attributes: TypedDict<TrackAttribute> = .init()
    public func attributes() -> AnyPublisher<TypedDict<TrackAttribute>, Never> {
        $_attributes.eraseToAnyPublisher()
    }
    
    public func invalidateCaches(_ mask: TrackContentMask) {
        contentSet.subtract(mask)
    }
    
    public func emitter(context: PlayContext) -> AnyPublisher<AnyAudioEmitter, Error> {
        fatalError()
    }
    
    public func load(atLeast mask: TrackContentMask, library: Library) {
        fatalError()
    }
}
