//
//  MultiPlaylist.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 02.01.21.
//

import Foundation
import Combine
import CombineExt
import SwiftUI

class MultiPlaylist: AnyPlaylist {
    let playlists: [AnyPlaylist]
    
    init(_ playlists: [AnyPlaylist]) {
        self.playlists = playlists
    }
    
    var id: String { "multi:\(playlists.map { $0.id }.joined(separator: ":"))" }
    
    var asToken: PlaylistToken { fatalError() }
    
    var contentType: PlaylistContentType { .tracks }
    
    var origin: URL? { nil }
    
    var hasCaches: Bool { playlists.contains { $0.hasCaches } }
    
    func invalidateCaches(_ mask: PlaylistContentMask) {
        playlists.forEach { $0.invalidateCaches(mask) }
    }
    
    func cacheMask() -> AnyPublisher<PlaylistContentMask, Never> {
        playlists.map { $0.cacheMask() }
            .combineLatest()
            .map { masks in
                masks.reduce(into: PlaylistContentMask.all) { $0.formIntersection($1) }
            }
            .eraseToAnyPublisher()
    }
    
    func tracks() -> AnyPublisher<[AnyTrack], Never> {
        playlists.map { $0.tracks() }
            .combineLatest()
            .map { $0.flatMap { $0 } }
            .eraseToAnyPublisher()
    }
    
    func children() -> AnyPublisher<[AnyPlaylist], Never> {
        playlists.map { $0.children() }
            .combineLatest()
            .map { $0.flatMap { $0 } }
            .eraseToAnyPublisher()
    }
    
    func attributes() -> AnyPublisher<TypedDict<PlaylistAttribute>, Never> {
        playlists.map { $0.cacheMask() }
            .combineLatest()
            .map { _ in
                TypedDict<PlaylistAttribute>([
                    .title: "Multiple Playlists"
                ])
            }
            .eraseToAnyPublisher()
    }
    
    func `import`(library: AnyLibrary) -> Bool { false }
    
    func previewImage() -> AnyPublisher<NSImage?, Never> {
        Just(nil).eraseToAnyPublisher()
    }
}
