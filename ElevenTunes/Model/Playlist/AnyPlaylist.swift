//
//  AnyPlaylist.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 25.12.20.
//

import Foundation
import SwiftUI
import Combine

public struct PlaylistContentMask: OptionSet, Hashable {
    public let rawValue: Int16
    
    public init(rawValue: Int16) {
        self.rawValue = rawValue
    }
    
    public static let minimal      = PlaylistContentMask(rawValue: 1 << 0)
    public static let tracks       = PlaylistContentMask(rawValue: 1 << 1)
    public static let children     = PlaylistContentMask(rawValue: 1 << 2)
    public static let attributes   = PlaylistContentMask(rawValue: 1 << 3)
    
    public static let all          = PlaylistContentMask([.minimal, .tracks, .children, .attributes])
}

@objc public enum PlaylistContentType: Int16 {
    /// Can only contain tracks
    case tracks
    /// Can only contain playlists (as children)
    case playlists
    /// Can contain both tracks and playlists (e.g. filesystem folders, artists)
    case hybrid
}

public protocol AnyPlaylist: AnyObject {
    var id: String { get }
    var asToken: PlaylistToken { get }

    var contentType: PlaylistContentType { get }
    
    var origin: URL? { get }
    
    var icon: Image { get }
    var accentColor: Color { get }

    var hasCaches: Bool { get }
    func invalidateCaches(_ mask: PlaylistContentMask)

    func cacheMask() -> AnyPublisher<PlaylistContentMask, Never>
    func tracks() -> AnyPublisher<[AnyTrack], Never>
    func children() -> AnyPublisher<[AnyPlaylist], Never>
    func attributes() -> AnyPublisher<TypedDict<PlaylistAttribute>, Never>

    @discardableResult
    func add(tracks: [TrackToken]) -> Bool
    
    @discardableResult
    func add(children: [PlaylistToken]) -> Bool
    
    func previewImage() -> AnyPublisher<NSImage?, Never>
}

extension AnyPlaylist {
    var icon: Image { Image(systemName: "music.note.list") }
    var accentColor: Color { .primary }
}

class PlaylistBackendTypedCodable: TypedCodable<String> {
    static let _registry = CodableRegistry<String>()
        .register(TransientPlaylist.self, for: "transient")
        .register(DirectoryPlaylistToken.self, for: "directory")
        .register(M3UPlaylistToken.self, for: "m3u")
        .register(SpotifyPlaylistToken.self, for: "spotify")
        .register(SpotifyUserToken.self, for: "spotify-user")
        .register(SpotifyAlbumToken.self, for: "spotify-album")
        .register(SpotifyArtistToken.self, for: "spotify-artist")

    override class var registry: CodableRegistry<String> { _registry }
}

extension NSValueTransformerName {
    static let playlistBackendName = NSValueTransformerName(rawValue: "PlaylistBackendTransformer")
}

@objc(PlaylistBackendTransformer)
class PlaylistBackendTransformer: TypedJSONCodableTransformer<String, PlaylistBackendTypedCodable> {}
