//
//  SpotifyPlaylist.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 20.12.20.
//

import Foundation

import SwiftUI
import Combine
import AVFoundation
import SpotifyWebAPI

struct MinimalSpotifyPlaylist: Codable, Hashable {
    static let filters = "uri,name"
    
    var uri: String
    var name: String
}

class SpotifyPlaylist: PlaylistBackend {
    enum SpotifyError: Error {
        case noURI
    }
    
    weak var frontend: Playlist?

    let spotify: Spotify
    let uri: String
    
    init(_ spotify: Spotify, uri: String) {
        self.spotify = spotify
        self.uri = uri
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
    
    static func create(_ spotify: Spotify, fromURL url: URL) -> AnyPublisher<Playlist, Error> {
        return Future { try spotifyURI(fromURL: url) }
            .flatMap { uri in
                spotify.api.filteredPlaylist(uri, filters: MinimalSpotifyPlaylist.filters, additionalTypes: [.track])
            }
            .decodeSpotifyObject(MinimalSpotifyPlaylist.self)
            .map { playlist in
                return Playlist(SpotifyPlaylist(spotify, uri: playlist.uri), attributes: .init([
                    AnyTypedKey.ptitle.id: playlist.name
                ]))
            }
            .eraseToAnyPublisher()
    }
    
    func load()  -> AnyPublisher<([Track], [Playlist]), Error> {
        let spotify = self.spotify
        let count = 100
        let uri = self.uri
        
        // There are actually playlists with up to 10.000 items lol
        let paginationLimit = 100

        return spotify.api.playlistTracks(uri, limit: count, offset: 0)
            .fold(limit: paginationLimit) {
                $0.offset + $0.items.count >= $0.total ? nil :
                spotify.api.playlistTracks(uri, limit: count, offset: $0.offset + count)
            }
            .collect()
            .map { $0.flatMap { $0.items } }
            .map { items in
                (items.compactMap { item -> Track? in
                    return ExistingSpotifyTrack(item.item).map { SpotifyTrack.convert(spotify, from: $0) }
                }, [])
            }
            .eraseToAnyPublisher()
    }
    
    var icon: Image? { nil }
    
    func add(children: [Playlist]) -> Bool {
        return false
    }
    
    func add(tracks: [Track]) -> Bool {
        return false
    }
}
