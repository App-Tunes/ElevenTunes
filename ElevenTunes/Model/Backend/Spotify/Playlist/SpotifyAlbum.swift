//
//  SpotifyAlbum.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 31.12.20.
//

import Foundation
import SwiftUI
import SpotifyWebAPI
import Combine

public class SpotifyAlbumToken: SpotifyURIPlaylistToken {
    class NoAlbumID: Error {}
    
    override class var urlComponent: String { "album" }
    
    override func expand(_ context: Library) -> AnyPlaylist {
        SpotifyAlbum(self, spotify: context.spotify)
    }
    
    static func create(_ spotify: Spotify, fromURL url: URL) -> AnyPublisher<SpotifyAlbumToken, Error> {
        return Future { try playlistID(fromURL: url) }
            .flatMap { spotify.api.album(Self($0)) }
            .tryMap { SpotifyAlbumToken(try $0.id.unwrap(orThrow: NoAlbumID())) }
            .eraseToAnyPublisher()
    }
}

public class SpotifyAlbum: SpotifyURIPlaylist<SpotifyAlbumToken> {
    @Published var previewImageURL: URL?
    let coverImages = RemoteImageCollection()
    
    override init(_ token: SpotifyAlbumToken, spotify: Spotify) {
        super.init(token, spotify: spotify)
        coverImages.delegate = self
    }
    
    convenience init(_ albumID: String, album: SpotifyWebAPI.Album, spotify: Spotify) {
        self.init(SpotifyAlbumToken(albumID), spotify: spotify)
        self._attributes.value = SpotifyAlbum.attributes(of: album)
        contentSet.insert(.minimal)
    }
    
    public override var type: PlaylistType { .album }
    
    public override var icon: Image { Image(systemName: "opticaldisc") }
    
    static func attributes(of album: SpotifyWebAPI.Album) -> TypedDict<PlaylistAttribute> {
        let attributes = TypedDict<PlaylistAttribute>()
        attributes[PlaylistAttribute.title] = album.name
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
            // Children will always be []
            promise.fulfill(.children)

            let spotify = self.spotify
            let token = self.token

            if promise.includes(.tracks) {
                // There are actually playlists with up to 10.000 items lol
                let count = 50
                let paginationLimit = 100

                let getItems = { (offset: Int) in
                    spotify.api.albumTracks(token, limit: count, offset: offset)
                }

                getItems(0)
                    .unfold(limit: paginationLimit) {
                        $0.offset + $0.items.count >= $0.total ? nil :
                        getItems($0.offset + count)
                    }
                    .collect()
                    .map { $0.flatMap { $0.items }.compactMap(ExistingSpotifyTrack.init) }
                    .map { items in
                        items.map { SpotifyTrack(track: $0, spotify: spotify) }
                    }
                    .onMain()
                    .fulfillingAny(.tracks, of: promise)
                    .sink(receiveCompletion: appLogErrors(_:)) { tracks in
                        self._tracks.value = tracks
                    }.store(in: &cancellables)
            }

            if promise.includesAny([.minimal, .attributes]) {
                spotify.api.album(token).eraseToAnyPublisher()
                    .onMain()
                    .fulfillingAny([.minimal, .attributes], of: promise)
                    .sink(receiveCompletion: appLogErrors) { info in
                        self._attributes.value = SpotifyAlbum.attributes(of: info)
                        self.previewImageURL = info.images.flatMap(self.bestImageForPreview(_:))
                    }
                    .store(in: &cancellables)
            }
        }
    }
    
    public override func previewImage() -> AnyPublisher<NSImage?, Never> {
        coverImages.preview.eraseToAnyPublisher()
    }
}

extension SpotifyAlbum: RemoteImageCollectionDelegate {
    func url(for feature: RemoteImageCollection.Feature) -> AnyPublisher<URL?, Error> {
        // We combine on attributes to push demand up to it. It will update the url string
        attributes().combineLatest($previewImageURL)
            .map { $1 }
            .eraseError()
            .eraseToAnyPublisher()
    }
}
