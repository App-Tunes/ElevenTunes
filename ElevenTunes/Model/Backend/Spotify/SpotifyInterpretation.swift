//
//  SpotifyInterpretation.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 04.01.21.
//

import Foundation
import Combine

extension ContentInterpreter {
    static func defaultSpotify(spotify: Spotify) -> [Interpreter] {
        var interpreters: [Interpreter] = []
        
        interpreters.append(simple {
            _ = try SpotifyTrackToken.trackID(fromURL: $0)
            return true
        } interpret: {
            SpotifyTrackToken.create(spotify, fromURL: $0)
                .map { Content.track($0) }
                .eraseToAnyPublisher()
        })
        
        interpreters.append(simple {
            _ = try SpotifyPlaylistToken.playlistID(fromURL: $0)
            return true
        } interpret: { (url: URL) -> AnyPublisher<Content, Error> in
            SpotifyPlaylistToken.create(spotify, fromURL: url)
                .map { Content.playlist($0) }
                .eraseToAnyPublisher()
        })
        
        interpreters.append(simple {
            _ = try SpotifyUserToken.userID(fromURL: $0)
            return true
        } interpret: { (url: URL) -> AnyPublisher<Content, Error> in
            SpotifyUserToken.create(spotify, fromURL: url)
                .map { Content.playlist($0) }
                .eraseToAnyPublisher()
        })
        
        interpreters.append(simple {
            _ = try SpotifyAlbumToken.playlistID(fromURL: $0)
            return true
        } interpret: { (url: URL) -> AnyPublisher<Content, Error> in
            SpotifyAlbumToken.create(spotify, fromURL: url)
                .map { Content.playlist($0) }
                .eraseToAnyPublisher()
        })
        
        interpreters.append(simple {
            _ = try SpotifyArtistToken.playlistID(fromURL: $0)
            return true
        } interpret: { (url: URL) -> AnyPublisher<Content, Error> in
            SpotifyArtistToken.create(spotify, fromURL: url)
                .map { Content.playlist($0) }
                .eraseToAnyPublisher()
        })

        interpreters.append(simple { $0.pathExtension == "m3u" } interpret: {
            .playlist(try M3UPlaylistToken.create(fromURL: $0))
        })
        
        interpreters.append(simple {
            try $0.isFileDirectory()
        } interpret: {
            .playlist(try DirectoryPlaylistToken.create(fromURL: $0))
        })
        
        return interpreters
    }
}
