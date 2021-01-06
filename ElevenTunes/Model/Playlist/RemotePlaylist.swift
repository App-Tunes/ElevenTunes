//
//  RemotePlaylist.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 26.12.20.
//

import Foundation
import Combine
import SwiftUI

public class RemotePlaylist: AnyPlaylist {
    var cancellables = Set<AnyCancellable>()
    
    let contentSet: FeatureSet<PlaylistContentMask, PlaylistContentMask> = .init()
    
    public var id: String { asToken.id }
    public var asToken: PlaylistToken { fatalError() }
    
    public var origin: URL? { nil }

    public var accentColor: Color { .primary }
    public var icon: Image { Image(systemName: "music.note.list") }
    
    public var contentType: PlaylistContentType { .tracks }
    
    public var hasCaches: Bool { true }
    
    public func cacheMask() -> AnyPublisher<PlaylistContentMask, Never> {
        contentSet.$features.eraseToAnyPublisher()
    }
    
    public func invalidateCaches(_ mask: PlaylistContentMask) {
        contentSet.subtract(mask)
    }
    
    @Published var demandMask: PlaylistContentMask = []
    
    public var _tracks: CurrentValueSubjectPublishingDemand<[AnyTrack], Never> = .init([])
    public func tracks() -> AnyPublisher<[AnyTrack], Never> {
        _tracks.eraseToAnyPublisher()
    }
    
    public var _children: CurrentValueSubjectPublishingDemand<[AnyPlaylist], Never> = .init([])
    public func children() -> AnyPublisher<[AnyPlaylist], Never> {
        _children.eraseToAnyPublisher()
    }
    
    public var _attributes: CurrentValueSubjectPublishingDemand<TypedDict<PlaylistAttribute>, Never> = .init(.init())
    public func attributes() -> AnyPublisher<TypedDict<PlaylistAttribute>, Never> {
        _attributes.eraseToAnyPublisher()
    }
    
    init() {
        mergeDemandMask(
            PlaylistContentMask(), subjects: [
                (_tracks.$demand, .tracks),
                (_children.$demand, .children),
                (_attributes.$demand, .init([.minimal, .attributes]))
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
    
    public func load(atLeast mask: PlaylistContentMask) {
        fatalError()
    }
    
    public func `import`(library: AnyLibrary) -> Bool { false }
    
    public func previewImage() -> AnyPublisher<NSImage?, Never> {
        Just(nil).eraseToAnyPublisher()
    }
}
