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

    func album(_ token: SpotifyAlbumToken, info: SpotifyWebAPI.Album? = nil) -> SpotifyAlbum {
        let album = albumCaches.get(token, insertingDefault: SpotifyAlbum(token, spotify: self))
        
        if let info = info {
            album.offerCache(info)
        }

        return album
    }
}
