//
//  SpotifyPlaylist+CoreDataClass.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 25.12.20.
//
//

import Foundation
import SwiftUI
import Combine
import AVFoundation
import SpotifyWebAPI

struct MinimalSpotifyPlaylist: Codable, Hashable {
    static let filters = "uri,name"
    
    var uri: String
    var name: String
}

public class SpotifyPlaylist: SpotifyPlaylistBackend {
    enum SpotifyError: Error {
        case noURI
    }
        
    // FIXME Needs context
    var uri: String

    init(_ spotify: Spotify, uri: String) {
        self.uri = uri
        super.init(spotify)
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        uri = try container.decode(String.self, forKey: .uri)
        try super.init(from: decoder)
    }
    
    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(uri, forKey: .uri)
        try super.encode(to: encoder)
    }

    static func spotifyURI(fromURL url: URL) throws -> String {
        guard
            url.host == "open.spotify.com",
            url.pathComponents.dropFirst().first == "playlist",
            let id = url.pathComponents.last
        else {
            throw SpotifyError.noURI
        }
        return "spotify:playlist:\(id)"
    }

    static func create(_ spotify: Spotify, fromURL url: URL) -> AnyPublisher<SpotifyPlaylist, Error> {
        return Future { try spotifyURI(fromURL: url) }
            .flatMap { uri in
                spotify.api.filteredPlaylist(uri, filters: MinimalSpotifyPlaylist.filters, additionalTypes: [.track])
            }
            .decodeSpotifyObject(MinimalSpotifyPlaylist.self)
            .map { playlist in
                SpotifyPlaylist(spotify, uri: playlist.uri)
            }
            .eraseToAnyPublisher()
    }
}

extension SpotifyPlaylist {
    enum CodingKeys: String, CodingKey {
      case uri
    }
}
