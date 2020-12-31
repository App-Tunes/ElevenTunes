//
//  SpotifyAlbum.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 31.12.20.
//

import Foundation

class SpotifyAlbum: TransientAlbum {
    let albumID: String
    
    init(_ albumID: String, attributes: TypedDict<PlaylistAttribute>) {
        self.albumID = albumID
        super.init(attributes: attributes)
    }
    
    required init(from decoder: Decoder) throws {
        fatalError()
    }
    
    override var id: String { albumID }
    
    override var origin: URL? {
        URL(string: "https://open.spotify.com/album/\(albumID)")
    }
}
