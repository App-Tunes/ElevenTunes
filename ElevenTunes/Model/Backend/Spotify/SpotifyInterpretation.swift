//
//  SpotifyInterpretation.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 04.01.21.
//

import Foundation
import Combine

extension ContentInterpreter {
    static func defaultSpotify() -> [Interpreter] {
        var interpreters: [Interpreter] = []
        
        interpreters.append(simple {
            _ = try SpotifyTrackToken.trackID(fromURL: $0)
            return true
        } interpret: { (url, settings) in
			SpotifyTrack.create(settings.spotify, fromURL: url)
                .map { Content.track($0) }
                .eraseToAnyPublisher()
        })
        
        interpreters.append(simple {
            _ = try SpotifyPlaylistToken.playlistID(fromURL: $0)
            return true
        } interpret: { (url, settings) in
			SpotifyPlaylist.create(settings.spotify, fromURL: url)
                .map { Content.playlist($0) }
                .eraseToAnyPublisher()
        })
        
        interpreters.append(simple {
            _ = try SpotifyUserToken.userID(fromURL: $0)
            return true
        } interpret: { (url, settings) in
			SpotifyUser.create(settings.spotify, fromURL: url)
                .map { Content.playlist($0) }
                .eraseToAnyPublisher()
        })
        
        interpreters.append(simple {
            _ = try SpotifyAlbumToken.playlistID(fromURL: $0)
            return true
        } interpret: { (url, settings) in
			SpotifyAlbum.create(settings.spotify, fromURL: url)
                .map { Content.playlist($0) }
                .eraseToAnyPublisher()
        })
        
        interpreters.append(simple {
            _ = try SpotifyArtistToken.playlistID(fromURL: $0)
            return true
        } interpret: { (url, settings) in
			SpotifyArtist.create(settings.spotify, fromURL: url)
                .map { Content.playlist($0) }
                .eraseToAnyPublisher()
        })
        
        return interpreters
    }
}
