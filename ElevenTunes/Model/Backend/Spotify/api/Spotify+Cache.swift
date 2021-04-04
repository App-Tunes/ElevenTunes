//
//  Spotify+Cache.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 04.01.21.
//

import Foundation
import SpotifyWebAPI

extension Spotify {
	func artist(_ token: SpotifyArtistToken, info: SpotifyWebAPI.Artist? = nil, details: DetailedSpotifyTrack.Artist? = nil) -> SpotifyArtist {
        let artist = artistCaches.get(token, insertingDefault: SpotifyArtist(token, spotify: self))
        
        if let info = info {
            artist.offerCache(info)
        }
		if let details = details {
			artist.offerCache(details)
		}
        
        return artist
    }

	func album(_ token: SpotifyAlbumToken, info: SpotifyWebAPI.Album? = nil, details: DetailedSpotifyTrack.Album? = nil) -> SpotifyAlbum {
		let album = albumCaches.get(token, insertingDefault: SpotifyAlbum(token, spotify: self))
		
		if let info = info {
			album.offerCache(info)
		}
		if let details = details {
			album.offerCache(details)
		}

		return album
	}

	func track(_ token: SpotifyTrackToken, info: SpotifyWebAPI.Track? = nil, details: DetailedSpotifyTrack? = nil) -> SpotifyTrack {
		let track = trackCaches.get(token, insertingDefault: SpotifyTrack(token, spotify: self))
		
		if let info = info {
			track.offerCache(info)
		}
		if let details = details {
			track.offerCache(details)
		}

		return track
	}
}
