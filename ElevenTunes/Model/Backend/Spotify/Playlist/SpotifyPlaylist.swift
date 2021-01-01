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

struct MinimalPagingObject<Item: Codable & Hashable>: Codable, Hashable {
    let offset: Int
    let total: Int
    let items: [Item]
}

struct MinimalPlaylistItemContainer<Item: Codable & Hashable>: Codable, Hashable {
    var track: Item
}

public class SpotifyPlaylistToken: SpotifyURIPlaylistToken {
    override class var urlComponent: String { "playlist" }
    
    override func expand(_ context: Library) -> AnyPlaylist {
        SpotifyPlaylist(self, spotify: context.spotify)
    }
}

public class SpotifyPlaylist: SpotifyURIPlaylist<SpotifyPlaylistToken> {
    static let minimalQueryFilters = "offset,total,items(track(\(MinimalSpotifyTrack.filters)))"
    
    override init(_ token: SpotifyPlaylistToken, spotify: Spotify) {
        super.init(token, spotify: spotify)
    }
    
    init(_ albumID: String, album: SpotifyWebAPI.Playlist<SpotifyWebAPI.PlaylistItems>, spotify: Spotify) {
        super.init(SpotifyPlaylistToken(albumID), spotify: spotify)
        self._attributes.value = SpotifyPlaylist.attributes(of: album)
    }

    static func attributes(of playlist: SpotifyWebAPI.Playlist<SpotifyWebAPI.PlaylistItems>) -> TypedDict<PlaylistAttribute> {
        let attributes = TypedDict<PlaylistAttribute>()
        attributes[PlaylistAttribute.title] = playlist.name
        return attributes
    }
        
    public override func load(atLeast mask: PlaylistContentMask) {
        contentSet.promise(mask) { promise in
            // Children will always be []
            promise.fulfill(.children)

            let spotify = self.spotify
            let token = self.token

            if promise.includes(.tracks) {
                // There are actually playlists with up to 10.000 items lol
                let count = 100
                let paginationLimit = 100

                let getItems = { (offset: Int) in
                    spotify.api.filteredPlaylistItems(token, filters: SpotifyPlaylist.minimalQueryFilters, additionalTypes: [.track], limit: count, offset: offset)
                        .decodeSpotifyObject(MinimalPagingObject<MinimalPlaylistItemContainer<MinimalSpotifyTrack>>.self)
                }

                getItems(0)
                    .unfold(limit: paginationLimit) {
                        $0.offset + $0.items.count >= $0.total ? nil :
                        getItems($0.offset + count)
                    }
                    .collect()
                    .map { $0.flatMap { $0.items }.map { $0.track } }
                    .map { items in
                        items.map { SpotifyTrack(SpotifyTrackToken($0.id), spotify: spotify) }
                    }
                    .onMain()
                    .fulfillingAny(.tracks, of: promise)
                    .sink(receiveCompletion: appLogErrors(_:)) { tracks in
                        self._tracks.value = tracks
                    }.store(in: &cancellables)
            }

            if promise.includesAny([.minimal, .attributes]) {
                spotify.api.playlist(token).eraseToAnyPublisher()
                    .onMain()
                    .fulfillingAny([.minimal, .attributes], of: promise)
                    .sink(receiveCompletion: appLogErrors) { info in
                        self._attributes.value = SpotifyPlaylist.attributes(of: info)
                    }
                    .store(in: &cancellables)
            }
        }
    }
}
