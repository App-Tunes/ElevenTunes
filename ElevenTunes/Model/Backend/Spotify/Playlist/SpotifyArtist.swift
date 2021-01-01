//
//  SpotifyArtist.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 31.12.20.
//

import Foundation
import SwiftUI

class SpotifyArtist: TransientArtist {
    let artistID: String
    
    init(_ artistID: String, attributes: TypedDict<PlaylistAttribute>) {
        self.artistID = artistID
        super.init(attributes: attributes)
    }
        
    required init(from decoder: Decoder) throws {
        fatalError()
    }
    
    override var id: String { artistID }

    override var origin: URL? {
        URL(string: "https://open.spotify.com/artist/\(artistID)")
    }
    
    override var accentColor: Color { Spotify.color }
}
