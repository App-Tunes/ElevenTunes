//
//  AnyPlaylist.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 25.12.20.
//

import Foundation
import SwiftUI
import Combine

public struct PlaylistContentMask: OptionSet {
    public let rawValue: Int16
    
    public init(rawValue: Int16) {
        self.rawValue = rawValue
    }
    
    public static let minimal      = PlaylistContentMask(rawValue: 1 << 0)
    public static let tracks       = PlaylistContentMask(rawValue: 1 << 1)
    public static let children     = PlaylistContentMask(rawValue: 1 << 2)
    public static let attributes   = PlaylistContentMask(rawValue: 1 << 3)
}

public protocol AnyPlaylist: AnyObject {
    var id: String { get }
    var icon: Image { get }
    var accentColor: Color { get }

    var anyTracks: AnyPublisher<[AnyTrack], Never> { get }
    var anyChildren: AnyPublisher<[AnyPlaylist], Never> { get }
    var attributes: AnyPublisher<TypedDict<PlaylistAttribute>, Never> { get }

    var cacheMask: AnyPublisher<PlaylistContentMask, Never> { get }

    func load(atLeast mask: PlaylistContentMask, deep: Bool, library: Library)
    func invalidateCaches(_ mask: PlaylistContentMask)
    
    func supportsChildren() -> Bool  // AKA isFertile
    
    @discardableResult
    func add(tracks: [PersistentTrack]) -> Bool
    
    @discardableResult
    func add(children: [PersistentPlaylist]) -> Bool
}

extension AnyPlaylist {
    public func load(atLeast level: PlaylistContentMask, library: Library) {
        load(atLeast: level, deep: false, library: library)
    }
    
    func invalidateCaches(_ mask: PlaylistContentMask, reloadWith library: Library) {
        invalidateCaches(mask)
        load(atLeast: mask, library: library)
    }
}

class PlaylistBackendTypedCodable: TypedCodable<String> {
    static let _registry = CodableRegistry<String>()
        .register(TransientPlaylist.self, for: "transient")
        .register(DirectoryPlaylist.self, for: "directory")
        .register(M3UPlaylist.self, for: "m3u")
        .register(SpotifyPlaylist.self, for: "spotify")

    override class var registry: CodableRegistry<String> { _registry }
}

extension NSValueTransformerName {
    static let playlistBackendName = NSValueTransformerName(rawValue: "PlaylistBackendTransformer")
}

@objc(PlaylistBackendTransformer)
class PlaylistBackendTransformer: TypedJSONCodableTransformer<String, PlaylistBackendTypedCodable> {}
