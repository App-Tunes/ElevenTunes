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

public class SpotifyURIPlaylistToken: PlaylistToken, SpotifyURIConvertible, Hashable {
    enum SpotifyError: Error {
        case noURI
    }
    
    enum CodingKeys: String, CodingKey {
      case spotifyID
    }
    
    var spotifyID: String

    public var id: String { spotifyID }
    
    public var uri: String { "spotify:\(Self.urlComponent):\(id)" }
    public var origin: URL? { URL(string: "https://open.spotify.com/\(Self.urlComponent)/\(spotifyID)") }

    public required init(_ spotifyID: String) {
        self.spotifyID = spotifyID
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        spotifyID = try container.decode(String.self, forKey: .spotifyID)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(spotifyID, forKey: .spotifyID)
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
	
	public func expand(_ context: Library) throws -> AnyPlaylist {
		fatalError()
	}
	
	public func hash(into hasher: inout Hasher) {
		hasher.combine(uri)
	}
	
	public static func ==(lhs: SpotifyURIPlaylistToken, rhs: SpotifyURIPlaylistToken) -> Bool {
		lhs.uri == rhs.uri
	}
}

protocol SpotifyURIPlaylist: RemotePlaylist {
	var spotify: Spotify { get }
}

extension SpotifyURIPlaylist {
	public var accentColor: Color { Spotify.color }
}
