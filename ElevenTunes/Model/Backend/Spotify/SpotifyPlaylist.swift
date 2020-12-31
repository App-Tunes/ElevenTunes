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

struct MinimalPagingObject<Item: Codable & Hashable>: Codable, Hashable {
    let offset: Int
    let total: Int
    let items: [Item]
}

struct MinimalPlaylistItemContainer<Item: Codable & Hashable>: Codable, Hashable {
    var track: Item
}

public class SpotifyPlaylistToken: PlaylistToken {
    enum SpotifyError: Error {
        case noURI
    }
    
    enum CodingKeys: String, CodingKey {
      case uri
    }
    
    var uri: String

    public override var id: String { uri }

    init(_ uri: String) {
        self.uri = uri
        super.init()
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

    static func create(_ spotify: Spotify, fromURL url: URL) -> AnyPublisher<SpotifyPlaylistToken, Error> {
        return Future { try spotifyURI(fromURL: url) }
            .flatMap { spotify.api.playlist($0) }
            .map { SpotifyPlaylistToken($0.uri) }
            .eraseToAnyPublisher()
    }
    
    override func expand(_ context: Library) -> AnyPlaylist {
        SpotifyPlaylist(self, spotify: context.spotify)
    }
}

public class SpotifyPlaylist: RemotePlaylist {
    static let minimalQueryFilters = "offset,total,items(track(\(MinimalSpotifyTrack.filters)))"

    let token: SpotifyPlaylistToken
    let spotify: Spotify
    
    public override var accentColor: Color { .green }

    init(_ token: SpotifyPlaylistToken, spotify: Spotify) {
        self.token = token
        self.spotify = spotify
        super.init()
    }
    
//    init(playlist: SpotifyWebAPI.Playlist<SpotifyWebAPI.PlaylistItems>, spotify: Spotify) {
//        self.token = playlist.uri
//        super.init()
//        self._attributes = SpotifyPlaylist.attributes(of: playlist)
//    }

    public override var asToken: PlaylistToken { token }
    
    static func attributes(of playlist: SpotifyWebAPI.Playlist<SpotifyWebAPI.PlaylistItems>) -> TypedDict<PlaylistAttribute> {
        let attributes = TypedDict<PlaylistAttribute>()
        attributes[PlaylistAttribute.title] = playlist.name
        return attributes
    }
        
    public override func load(atLeast mask: PlaylistContentMask) {
        contentSet.promise(mask) { promise in
            // Children will always be []
            promise.fulfill(.children)

            let spotify = self.spotify
            let uri = token.uri

            if promise.includes(.tracks) {
                // There are actually playlists with up to 10.000 items lol
                let count = 100
                let paginationLimit = 100

                let getItems = { (offset: Int) in
                    spotify.api.filteredPlaylistItems(uri, filters: SpotifyPlaylist.minimalQueryFilters, additionalTypes: [.track], limit: count, offset: offset)
                        .decodeSpotifyObject(MinimalPagingObject<MinimalPlaylistItemContainer<MinimalSpotifyTrack>>.self)
                }

                getItems(0)
                    .unfold(limit: paginationLimit) {
                        $0.offset + $0.items.count >= $0.total ? nil :
                        getItems($0.offset + count)
                    }
                    .collect()
                    .map { $0.flatMap { $0.items.map { $0.track } } }
                    .map { items in
                        items.map { SpotifyTrack(SpotifyTrackToken($0.uri), spotify: spotify) }
                    }
                    .onMain()
                    .fulfillingAny(.tracks, of: promise)
                    .sink(receiveCompletion: appLogErrors(_:)) { tracks in
                        self._tracks.value = tracks
                    }.store(in: &cancellables)
            }

            if promise.includesAny([.minimal, .attributes]) {
                spotify.api.playlist(uri).eraseToAnyPublisher()
                    .onMain()
                    .fulfillingAny([.minimal, .attributes], of: promise)
                    .sink(receiveCompletion: appLogErrors) { info in
                        self._attributes.value = SpotifyPlaylist.attributes(of: info)
                    }
                    .store(in: &cancellables)
            }
        }
    }
}
