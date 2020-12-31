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

public class SpotifyPlaylistToken: PlaylistToken, SpotifyURIConvertible {
    enum SpotifyError: Error {
        case noURI
    }
    
    enum CodingKeys: String, CodingKey {
      case playlistID
    }
    
    var playlistID: String

    public override var id: String { playlistID }
    
    public var uri: String { "spotify:playlist:\(id)" }

    init(_ playlistID: String) {
        self.playlistID = playlistID
        super.init()
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        playlistID = try container.decode(String.self, forKey: .playlistID)
        try super.init(from: decoder)
    }
    
    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(playlistID, forKey: .playlistID)
        try super.encode(to: encoder)
    }
    
    static func playlistID(fromURL url: URL) throws -> String {
        guard
            url.host == "open.spotify.com",
            url.pathComponents.dropFirst().first == "playlist",
            let id = url.pathComponents.last
        else {
            throw SpotifyError.noURI
        }
        return id
    }

    static func create(_ spotify: Spotify, fromURL url: URL) -> AnyPublisher<SpotifyPlaylistToken, Error> {
        return Future { try playlistID(fromURL: url) }
            .flatMap { spotify.api.playlist($0) }
            .map { SpotifyPlaylistToken($0.id) }
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
    
    public override var origin: URL? {
        URL(string: "https://open.spotify.com/playlist/\(token.playlistID)")
    }

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
            let token = self.token

            if promise.includes(.tracks) {
                // There are actually playlists with up to 10.000 items lol
                let count = 100
                let paginationLimit = 100

                let getItems = { (offset: Int) in
                    spotify.api.filteredPlaylistItems(token, filters: SpotifyPlaylist.minimalQueryFilters, additionalTypes: [.track], limit: count, offset: offset)
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
                        items.map { SpotifyTrack(SpotifyTrackToken($0.id), spotify: spotify) }
                    }
                    .onMain()
                    .fulfillingAny(.tracks, of: promise)
                    .sink(receiveCompletion: appLogErrors(_:)) { tracks in
                        self._tracks.value = tracks
                    }.store(in: &cancellables)
            }

            if promise.includesAny([.minimal, .attributes]) {
                spotify.api.playlist(token).eraseToAnyPublisher()
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
