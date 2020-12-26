//
//  SpotifyPlaylistBackend.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 26.12.20.
//

import Foundation

extension CodingUserInfoKey {
    static let spotify = CodingUserInfoKey(rawValue: "spotify")!
}

enum SpotifyDecodeError: Error {
    case noSpotify
}

public class SpotifyPlaylistBackend: RemotePlaylist {
    var spotify: Spotify
    
    init(_ spotify: Spotify) {
        self.spotify = spotify
        super.init()
    }
    
    public required init(from decoder: Decoder) throws {
        guard let spotify = decoder.userInfo[CodingUserInfoKey.spotify] as? Spotify else {
            throw SpotifyDecodeError.noSpotify
        }
        self.spotify = spotify
        try super.init(from: decoder)
    }
}
