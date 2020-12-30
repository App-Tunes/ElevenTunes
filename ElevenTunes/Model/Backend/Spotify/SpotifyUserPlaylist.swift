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

public class SpotifyUserPlaylistToken: PlaylistToken {
    enum SpotifyError: Error {
        case noURI
    }
    
    enum CodingKeys: String, CodingKey {
      case uri
    }
        
    var uri: String?
    
    public override var id: String { uri ?? "spotify::playlist::currentuser" }

    init(_ uri: String? = nil) {
        self.uri = uri
        super.init()
    }
        
    init(user: SpotifyWebAPI.SpotifyUser) {
        self.uri = user.uri
        super.init()
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
            .map { SpotifyUserPlaylist($0, spotify: spotify) }
            .eraseToAnyPublisher()
    }
}

public class SpotifyUserPlaylist: RemotePlaylist {
    let token: SpotifyUserPlaylistToken
    let spotify: Spotify
    
    init(spotify: Spotify) {
        self.token = SpotifyUserPlaylistToken(nil)
        self.spotify = spotify
    }
    
    init(_ user: SpotifyUser, spotify: Spotify) {
        self.token = SpotifyUserPlaylistToken(user.uri)
        self.spotify = spotify
        super.init()
        self._attributes = SpotifyUserPlaylist.attributes(of: user)
        contentSet.formUnion([.tracks, .attributes])
    }

    public override var asToken: PlaylistToken { token }
    
    override public var icon: Image { SpotifyPlaylist._icon }
    
    public override func supportsChildren() -> Bool { true }
    
    static func attributes(of user: SpotifyWebAPI.SpotifyUser) -> TypedDict<PlaylistAttribute> {
        let attributes = TypedDict<PlaylistAttribute>()
        attributes[PlaylistAttribute.title] = user.displayName ?? user.id
        return attributes
    }
            
    public override func load(atLeast mask: PlaylistContentMask, library: Library) {
        contentSet.promise(mask) { promise in
            // Tracks will always be []
            promise.fulfill(.tracks)
            
            let spotify = library.spotify
            let uri = token.uri

            if promise.includes(.children) {
                let count = 50
                let paginationLimit = 100

                let playlistsAt = { (offset: Int) in
                    uri != nil
                        ? spotify.api.userPlaylists(for: uri!, limit: count, offset: offset)
                        : spotify.api.currentUserPlaylists(limit: count, offset: offset)
                }
                
                playlistsAt(0)
                    .unfold(limit: paginationLimit) {
                        $0.offset + $0.items.count >= $0.total ? nil
                            : playlistsAt($0.offset + count)
                    }
                    .collect()
                    .map { $0.flatMap { $0.items } }
                    .map { items in
                        items.compactMap { item -> SpotifyPlaylist? in
                            SpotifyPlaylist(SpotifyPlaylistToken(item.uri), spotify: spotify)
                        }
                    }
                    .onMain()
                    .fulfillingAny(.children, of: promise)
                    .sink(receiveCompletion: appLogErrors(_:)) { playlists in
                        self._children = playlists
                    }.store(in: &cancellables)
            }
            
            if promise.includesAny([.minimal, .attributes]) {
                let userProfile = uri != nil
                    ? spotify.api.userProfile(uri!)
                    : spotify.api.currentUserProfile()
                
                userProfile.eraseToAnyPublisher()
                    .onMain()
                    .fulfillingAny([.minimal, .attributes], of: promise)
                    .sink(receiveCompletion: appLogErrors) { info in
                        self._attributes = SpotifyUserPlaylist.attributes(of: info)
                    }
                    .store(in: &cancellables)
            }
        }
    }
}
