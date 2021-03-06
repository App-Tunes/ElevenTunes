//
//  SpotifyInterpretation.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 04.01.21.
//

import Foundation
import Combine

extension TrackInterpreter {
	func registerDefaultSpotify() {
		register(matches: {
            _ = try SpotifyTrackToken.trackID(fromURL: $0)
            return true
		}, interpret: SpotifyTrackToken.create)
    }
}

extension PlaylistInterpreter {
	func registerDefaultSpotify() {
		register(matches: {
			_ = try SpotifyPlaylistToken.playlistID(fromURL: $0)
			return true
		}, interpret: SpotifyPlaylistToken.create)
		
		register(matches: {
			_ = try SpotifyUserToken.userID(fromURL: $0)
			return true
		}, interpret: SpotifyUserToken.create)
		
		register(matches: {
			_ = try SpotifyAlbumToken.playlistID(fromURL: $0)
			return true
		}, interpret: SpotifyAlbumToken.create)
		
		register(matches: {
			_ = try SpotifyArtistToken.playlistID(fromURL: $0)
			return true
		}, interpret: SpotifyArtistToken.create)
	}
}
