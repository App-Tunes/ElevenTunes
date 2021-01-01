//
//  SpotifyURIPlaylistToken.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 01.01.21.
//

import Foundation
import Combine
import SpotifyWebAPI
import SwiftUI

public class SpotifyURIPlaylistToken: PlaylistToken, SpotifyURIConvertible {
    enum SpotifyError: Error {
        case noURI
    }
    
    enum CodingKeys: String, CodingKey {
      case spotifyID
    }
    
    var spotifyID: String

    public override var id: String { spotifyID }
    
    public var uri: String { "spotify:\(Self.urlComponent):\(id)" }
    public var origin: URL? { URL(string: "https://open.spotify.com/\(Self.urlComponent)/\(spotifyID)") }

    public required init(_ spotifyID: String) {
        self.spotifyID = spotifyID
        super.init()
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        spotifyID = try container.decode(String.self, forKey: .spotifyID)
        try super.init(from: decoder)
    }
    
    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(spotifyID, forKey: .spotifyID)
        try super.encode(to: encoder)
    }
    
    class func playlistID(fromURL url: URL) throws -> String {
        guard
            url.host == "open.spotify.com",
            url.pathComponents.dropFirst().first == Self.urlComponent,
            let id = url.pathComponents.last
        else {
            throw SpotifyError.noURI
        }
        return id
    }
    
    class var urlComponent: String { fatalError() }
}

public class SpotifyURIPlaylist<Token: SpotifyURIPlaylistToken>: RemotePlaylist {
    let token: Token
    let spotify: Spotify
    
    init(_ token: Token, spotify: Spotify) {
        self.token = token
        self.spotify = spotify
    }
    
    public override var accentColor: Color { Spotify.color }

    public override var asToken: PlaylistToken { token }
    
    public override var origin: URL? { token.origin }
}
