//
//  SpotifyUserPlaylist+CoreDataClass.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 25.12.20.
//
//

import Foundation
import Combine
import SwiftUI
import SpotifyWebAPI

public class SpotifyUserPlaylist: RemotePlaylist {
    enum SpotifyError: Error {
        case noURI
    }
        
    var uri: String?
    
    init(uri: String? = nil) {
        self.uri = uri
        super.init()
    }
        
    init(user: SpotifyWebAPI.SpotifyUser) {
        self.uri = user.uri
        super.init()
        self._attributes = SpotifyUserPlaylist.attributes(of: user)
    }
        
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        uri = try container.decodeIfPresent(String.self, forKey: .uri)
        try super.init(from: decoder)
    }
    
    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(uri, forKey: .uri)
        try super.encode(to: encoder)
    }
    
    override public var icon: Image { SpotifyPlaylist._icon }

    public override var id: String { uri ?? "spotify::playlist::currentuser" }
    
    public override func supportsChildren() -> Bool { true }
    
    static func attributes(of user: SpotifyWebAPI.SpotifyUser) -> TypedDict<PlaylistAttribute> {
        let attributes = TypedDict<PlaylistAttribute>()
        attributes[PlaylistAttribute.title] = user.displayName ?? user.id
        return attributes
    }
    
    static func spotifyURI(fromURL url: URL) throws -> String {
        guard
            url.host == "open.spotify.com",
            url.pathComponents.dropFirst().first == "user",
            let id = url.pathComponents.last
        else {
            throw SpotifyError.noURI
        }
        return "spotify:user:\(id)"
    }

    static func create(_ spotify: Spotify, fromURL url: URL?) -> AnyPublisher<SpotifyUserPlaylist, Error> {
        return Future { try url.map { try spotifyURI(fromURL: $0) } }
            .flatMap { $0.map { spotify.api.userProfile($0) } ?? spotify.api.currentUserProfile() }
            .map { SpotifyUserPlaylist(user: $0) }
            .eraseToAnyPublisher()
    }
        
    public override func load(atLeast level: LoadLevel, deep: Bool, context: PlayContext) -> Bool {
        let spotify = context.spotify
        let count = 50
        let uri = self.uri
        
        let paginationLimit = 100

        let playlistsAt = { (offset: Int) in
            uri != nil
                ? spotify.api.userPlaylists(for: uri!, limit: count, offset: offset)
                : spotify.api.currentUserPlaylists(limit: count, offset: offset)
        }
        
        let playlists = playlistsAt(0)
            .unfold(limit: paginationLimit) {
                $0.offset + $0.items.count >= $0.total ? nil
                    : playlistsAt($0.offset + count)
            }
            .collect()
            .map { $0.flatMap { $0.items } }
            .map { items in
                items.compactMap { item -> SpotifyPlaylist? in
                    return SpotifyPlaylist(uri: item.uri)
                }
            }
            .eraseToAnyPublisher()
            
        let userProfile = uri != nil
            ? spotify.api.userProfile(uri!)
            : spotify.api.currentUserProfile()
        
        userProfile.eraseToAnyPublisher().zip(playlists)
            .onMain()
            .sink(receiveCompletion: appLogErrors) { (info, playlists) in
                self._attributes = SpotifyUserPlaylist.attributes(of: info)
                self._children = playlists
                self._loadLevel = .detailed
            }
            .store(in: &cancellables)
        
        return true
    }
}

extension SpotifyUserPlaylist {
    enum CodingKeys: String, CodingKey {
      case uri
    }
}
