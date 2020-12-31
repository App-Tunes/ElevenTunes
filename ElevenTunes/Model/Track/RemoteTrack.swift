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

    public var _attributes: CurrentValueSubjectPublishingDemand<TypedDict<TrackAttribute>, Never> = .init(.init())
    public func attributes() -> AnyPublisher<TypedDict<TrackAttribute>, Never> {
        _attributes.eraseToAnyPublisher()
    }
    
    init() {
        mergeDemandMask(
            TrackContentMask(), subjects: [
                (_attributes.$demand, .minimal)
            ]
        ).combineLatest(contentSet.$features)
        .map { $0.subtracting($1) }
        .removeDuplicates()
        // We may currently be in a feature change, let's defer this run
        .debounce(for: .milliseconds(10), scheduler: RunLoop.main)
        .sink { [weak self] in
            self?.load(atLeast: $0)
        }.store(in: &cancellables)
    }

    public func invalidateCaches(_ mask: TrackContentMask) {
        contentSet.subtract(mask)
    }
    
    public func emitter(context: PlayContext) -> AnyPublisher<AnyAudioEmitter, Error> {
        fatalError()
    }
    
    public func load(atLeast mask: TrackContentMask) {
        fatalError()
    }
}
