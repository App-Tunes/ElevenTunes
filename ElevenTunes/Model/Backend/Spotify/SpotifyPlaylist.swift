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

class SpotifyPlaylist: PlaylistBackend {
    enum SpotifyError: Error {
        case noURI
    }

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
                spotify.api.playlist(uri)
            }
            .map { spotifyPlaylist -> (SpotifyWebAPI.Playlist<SpotifyWebAPI.PlaylistItems>, [Track]) in
                // TODO These items things have limits. We need to query all for big ones
                // TODO Lazily evaluate tracks
                let tracks = spotifyPlaylist.items.items.compactMap { item -> Track? in
                    switch item.item {
                    case .track(let track):
                        return ExistingSpotifyTrack(track).map { SpotifyTrack.convert(spotify, from: $0) }
                    default:
                        return nil
                    }
                }
                return (spotifyPlaylist, tracks)
            }
            .map { pair in
                let (spotifyPlaylist, tracks) = pair
                
                return Playlist(SpotifyPlaylist(spotify, uri: spotifyPlaylist.uri), attributes: .init([
                    AnyTypedKey.ptitle.id: spotifyPlaylist.name
                ]), tracks: tracks)
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
