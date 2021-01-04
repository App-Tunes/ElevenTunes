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
    
    public var accentColor: Color { .primary }
    
    public var origin: URL? { nil }
    
    let contentSet: FeatureSet<TrackContentMask, TrackContentMask> = .init()
    
    public func cacheMask() -> AnyPublisher<TrackContentMask, Never> {
        contentSet.$features.eraseToAnyPublisher()
    }

    public var _artists: CurrentValueSubjectPublishingDemand<[AnyPlaylist], Never> = .init([])
    public func artists() -> AnyPublisher<[AnyPlaylist], Never> {
        _artists.eraseToAnyPublisher()
    }
    
    public var _album: CurrentValueSubjectPublishingDemand<AnyPlaylist?, Never> = .init(nil)
    public func album() -> AnyPublisher<AnyPlaylist?, Never> {
        _album.eraseToAnyPublisher()
    }
    
    public var _attributes: CurrentValueSubjectPublishingDemand<TypedDict<TrackAttribute>, Never> = .init(.init())
    public func attributes() -> AnyPublisher<TypedDict<TrackAttribute>, Never> {
        _attributes.eraseToAnyPublisher()
    }
    
    init() {
        mergeDemandMask(
            TrackContentMask(), subjects: [
                (_artists.$demand, .minimal),
                (_album.$demand, .minimal),
                (_attributes.$demand, TrackContentMask([.minimal, .analysis]))
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
    
    public func previewImage() -> AnyPublisher<NSImage?, Never> {
        album().flatMap {
            $0?.previewImage() ?? Just(nil).eraseToAnyPublisher()
        }.eraseToAnyPublisher()
    }
}
