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

public class SpotifyPlaylist: RemotePlaylist {
    enum SpotifyError: Error {
        case noURI
    }
    
    static let minimalQueryFilters = "offset,total,items(track(\(MinimalSpotifyTrack.filters)))"
        
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
        contentSet.promise(mask) { promise in
            // Children will always be []
            promise.fulfill(.children)
            
            let spotify = library.spotify
            let uri = self.uri
            
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
                        items.map(SpotifyTrack.init)
                    }
                    .onMain()
                    .fulfillingAny(.tracks, of: promise)
                    .sink(receiveCompletion: appLogErrors(_:)) { tracks in
                        self._tracks = tracks
                    }.store(in: &cancellables)
            }
            
            if promise.includesAny([.minimal, .attributes]) {
                spotify.api.playlist(uri).eraseToAnyPublisher()
                    .onMain()
                    .fulfillingAny([.minimal, .attributes], of: promise)
                    .sink(receiveCompletion: appLogErrors) { info in
                        self._attributes = SpotifyPlaylist.attributes(of: info)
                    }
                    .store(in: &cancellables)
            }
        }
    }
}

extension SpotifyPlaylist {
    enum CodingKeys: String, CodingKey {
      case uri
    }
}
