//
//  SpotifyPlaylist+CoreDataClass.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 25.12.20.
//
//

import Foundation
import SwiftUI
import Combine
import AVFoundation
import SpotifyWebAPI

//struct MinimalSpotifyPlaylist: Codable, Hashable {
//    static let filters = "uri,name"
//
//    var uri: String
//    var name: String
//}

public class SpotifyPlaylist: RemotePlaylist {
    enum SpotifyError: Error {
        case noURI
    }
        
    var uri: String

    static var _icon: Image { Image("spotify-logo") }
    
    public override var accentColor: Color { .green }

    init(uri: String) {
        self.uri = uri
        super.init()
    }
        
    init(playlist: SpotifyWebAPI.Playlist<SpotifyWebAPI.PlaylistItems>) {
        self.uri = playlist.uri
        super.init()
        self._attributes = SpotifyPlaylist.attributes(of: playlist)
    }
        
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        uri = try container.decode(String.self, forKey: .uri)
        try super.init(from: decoder)
    }
    
    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(uri, forKey: .uri)
        try super.encode(to: encoder)
    }

    public override var id: String { uri }
    
    override public var icon: Image { SpotifyPlaylist._icon }

    static func attributes(of playlist: SpotifyWebAPI.Playlist<SpotifyWebAPI.PlaylistItems>) -> TypedDict<PlaylistAttribute> {
        let attributes = TypedDict<PlaylistAttribute>()
        attributes[PlaylistAttribute.title] = playlist.name
        return attributes
    }
    
    static func spotifyURI(fromURL url: URL) throws -> String {
        guard
            url.host == "open.spotify.com",
            url.pathComponents.dropFirst().first == "playlist",
            let id = url.pathComponents.last
        else {
            throw SpotifyError.noURI
        }
        return "spotify:playlist:\(id)"
    }

    static func create(_ spotify: Spotify, fromURL url: URL) -> AnyPublisher<SpotifyPlaylist, Error> {
        return Future { try spotifyURI(fromURL: url) }
            .flatMap { spotify.api.playlist($0) }
            .map { SpotifyPlaylist(playlist: $0) }
            .eraseToAnyPublisher()
    }
    
    public override func load(atLeast mask: PlaylistContentMask, deep: Bool, library: Library) {
        let spotify = library.spotify
        let uri = self.uri
        
        let missing = mask.subtracting(_cacheMask)
        
        if !missing.isDisjoint(with: [.children]) {
            // How many times grandma, we will NEVER want children
            _cacheMask.formUnion(.children)
        }
        
        if !missing.isDisjoint(with: [.tracks]) {
            // There are actually playlists with up to 10.000 items lol
            let count = 100
            let paginationLimit = 100

            spotify.api.playlistTracks(uri, limit: count, offset: 0)
                .unfold(limit: paginationLimit) {
                    $0.offset + $0.items.count >= $0.total ? nil :
                    spotify.api.playlistTracks(uri, limit: count, offset: $0.offset + count)
                }
                .collect()
                .map { $0.flatMap { $0.items } }
                .map { items in
                    items.compactMap { item -> SpotifyTrack? in
                        return ExistingSpotifyTrack(item.item).map { SpotifyTrack(track: $0) }
                    }
                }
                .onMain()
                .sink(receiveCompletion: appLogErrors(_:)) { tracks in
                    self._tracks = tracks
                    self._cacheMask.formUnion(.tracks)
                }.store(in: &cancellables)
        }
        
        if !missing.isDisjoint(with: [.minimal, .attributes]) {
            spotify.api.playlist(uri).eraseToAnyPublisher()
                .onMain()
                .sink(receiveCompletion: appLogErrors) { info in
                    self._attributes = SpotifyPlaylist.attributes(of: info)
                    self._cacheMask.formUnion([.minimal, .attributes])
                }
                .store(in: &cancellables)
        }
    }
}

extension SpotifyPlaylist {
    enum CodingKeys: String, CodingKey {
      case uri
    }
}
