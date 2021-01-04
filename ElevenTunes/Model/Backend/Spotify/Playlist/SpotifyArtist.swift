//
//  SpotifyArtist.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 31.12.20.
//

import Foundation
import SwiftUI
import SpotifyWebAPI
import Combine

public class SpotifyArtistToken: SpotifyURIPlaylistToken {
    class NoArtistID: Error {}
    
    override class var urlComponent: String { "artist" }
    
    override func expand(_ context: Library) -> AnyPlaylist {
        SpotifyArtist(self, spotify: context.spotify)
    }
    
    static func create(_ spotify: Spotify, fromURL url: URL) -> AnyPublisher<SpotifyArtistToken, Error> {
        return Future { try playlistID(fromURL: url) }
            .flatMap { spotify.api.artist(Self($0)) }
            .tryMap { SpotifyArtistToken(try $0.id.unwrap(orThrow: NoArtistID())) }
            .eraseToAnyPublisher()
    }
}

public class SpotifyArtist: SpotifyURIPlaylist<SpotifyArtistToken>, AnyArtist {
    convenience init(_ artistID: String, artist: SpotifyWebAPI.Artist, spotify: Spotify) {
        self.init(SpotifyArtistToken(artistID), spotify: spotify)
        self._attributes.value = SpotifyArtist.attributes(of: artist)
        contentSet.insert(.minimal)
    }
    
    public override var contentType: PlaylistContentType { .hybrid }
    
    public override var icon: Image { Image(systemName: "person") }
    
    static func attributes(of artist: SpotifyWebAPI.Artist) -> TypedDict<PlaylistAttribute> {
        let attributes = TypedDict<PlaylistAttribute>()
        attributes[PlaylistAttribute.title] = artist.name
        return attributes
    }
    
    public func bestImageForPreview(_ images: [SpotifyWebAPI.SpotifyImage]) -> URL? {
        guard let image = (images.sorted {
                max($0.width ?? 0, $0.height ?? 0) <
                    max($1.width ?? 0, $1.height ?? 0)
            }
            .drop { min($0.width ?? 0, $0.height ?? 0) < 50 }
            .first ?? images.first) else {
                return nil
            }
        
        return URL(string: image.url)
    }
        
    public override func load(atLeast mask: PlaylistContentMask) {
        contentSet.promise(mask) { promise in
            // TODO Not supported yet
            promise.fulfill(.tracks)

            let spotify = self.spotify
            let token = self.token

            if promise.includes(.children) {
                // There are actually playlists with up to 10.000 items lol
                let count = 50
                let paginationLimit = 100

                let getItems = { (offset: Int) in
                    spotify.api.artistAlbums(token, limit: count, offset: offset)
                }

                getItems(0)
                    .unfold(limit: paginationLimit) {
                        $0.offset + $0.items.count >= $0.total ? nil :
                        getItems($0.offset + count)
                    }
                    .collect()
                    .map { $0.flatMap { $0.items }}
                    .map { items in
                        items.map { SpotifyAlbum($0.id!, album: $0, spotify: spotify) }
                    }
                    .onMain()
                    .fulfillingAny(.children, of: promise)
                    .sink(receiveCompletion: appLogErrors(_:)) { albums in
                        self._children.value = albums
                    }.store(in: &cancellables)
            }

            if promise.includesAny([.minimal, .attributes]) {
                spotify.api.artist(token).eraseToAnyPublisher()
                    .onMain()
                    .fulfillingAny([.minimal, .attributes], of: promise)
                    .sink(receiveCompletion: appLogErrors) { info in
                        self._attributes.value = SpotifyArtist.attributes(of: info)
                    }
                    .store(in: &cancellables)
            }
        }
    }
}
