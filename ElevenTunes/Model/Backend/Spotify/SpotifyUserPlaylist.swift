//
//  SpotifyUserPlaylist.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 25.12.20.
//

import Foundation
import Combine
import SwiftUI

class SpotifyUserPlaylist: PlaylistBackend {
    let spotify: Spotify
    
    init(_ spotify: Spotify) {
        self.spotify = spotify
    }
    
    static func create(_ spotify: Spotify) -> AnyPublisher<Playlist, Error> {
        Future { Playlist(SpotifyUserPlaylist(spotify), attributes: .init([
            .title: "Spotify Playlists"
        ])) }
            .eraseToAnyPublisher()
    }
    
    func load()  -> AnyPublisher<([Track], [Playlist]), Error> {
        let spotify = self.spotify
        let count = 50
        
        // Let's stop here lol
        let paginationLimit = 100

        return spotify.api.currentUserPlaylists(limit: count, offset: 0)
            .unfold(limit: paginationLimit) {
                $0.offset + $0.items.count >= $0.total ? nil :
                spotify.api.currentUserPlaylists(limit: count, offset: $0.offset + count)
            }
            .collect()
            .map { $0.flatMap { $0.items } }
            .map { items in
                ([], items.compactMap { item -> Playlist? in
                    nil
                })
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
