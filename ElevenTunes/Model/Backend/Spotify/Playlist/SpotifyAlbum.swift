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
        context.spotify.album(self)
    }
    
    static func create(_ spotify: Spotify, fromURL url: URL) -> AnyPublisher<SpotifyAlbumToken, Error> {
        return Future { try playlistID(fromURL: url) }
            .flatMap { spotify.api.album(Self($0)) }
            .tryMap { SpotifyAlbumToken(try $0.id.unwrap(orThrow: NoAlbumID())) }
            .eraseToAnyPublisher()
    }
}

public final class SpotifyAlbum: SpotifyURIPlaylist, AnyAlbum {
    @Published var previewImageURL: URL?
    let coverImages = RemoteImageCollection()
    
	enum Request {
		case info, tracks
	}
	
	let mapper = Requests(relation: [
		.info: [.title],
		.tracks: [.tracks]
	])
	
	let token: SpotifyAlbumToken
	let spotify: Spotify

    init(_ token: SpotifyAlbumToken, spotify: Spotify) {
		self.token = token
		self.spotify = spotify
        coverImages.delegate = self
    }
    
    public var contentType: PlaylistContentType { .tracks }
    
    public var icon: Image { Image(systemName: "opticaldisc") }
    
    func offerCache(_ album: SpotifyWebAPI.Album) {
		mapper.requestFeatureSet.fulfilling(.info) {
            read(album)
        }
    }
    
    func read(_ album: SpotifyWebAPI.Album) {
		mapper.attributes.update(.init([
            PlaylistAttribute.title: album.name
		]), state: .version(""))
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
        
//    public override func load(atLeast mask: PlaylistContentMask) {
//        contentSet.promise(mask) { promise in
//            // Children will always be []
//            promise.fulfill(.children)
//
//            let spotify = self.spotify
//            let token = self.token
//
//            if promise.includes(.tracks) {
//                // There are actually playlists with up to 10.000 items lol
//                let count = 50
//                let paginationLimit = 100
//
//                let getItems = { (offset: Int) in
//                    spotify.api.albumTracks(token, limit: count, offset: offset)
//                }
//
//                getItems(0)
//                    .unfold(limit: paginationLimit) {
//                        $0.offset + $0.items.count >= $0.total ? nil :
//                        getItems($0.offset + count)
//                    }
//                    .collect()
//                    .map { $0.flatMap { $0.items } }
//                    .map { items in
//                        items.map {
//                            var track = DetailedSpotifyTrack.from($0)
//                            track.album = .init(id: token.id)  // Album requests don't return albums
//                            return SpotifyTrack(track: track, spotify: spotify) }
//                    }
//                    .onMain()
//                    .fulfillingAny(.tracks, of: promise)
//                    .sink(receiveCompletion: appLogErrors(_:)) { tracks in
//                        self._tracks.value = TracksSnapshot(tracks, version: "")
//                    }.store(in: &cancellables)
//            }
//
//            if promise.includes(.attributes) {
//                spotify.api.album(token).eraseToAnyPublisher()
//                    .onMain()
//                    .fulfillingAny([.attributes], of: promise)
//                    .sink(receiveCompletion: appLogErrors) { info in
//                        self.read(info)
//                        self.previewImageURL = info.images.flatMap(self.bestImageForPreview(_:))
//                    }
//                    .store(in: &cancellables)
//            }
//        }
//    }
    
    public func previewImage() -> AnyPublisher<NSImage?, Never> {
        coverImages.preview.eraseToAnyPublisher()
    }
}

extension SpotifyAlbum: RequestMapperDelegate {
	func onDemand(_ request: Request) -> AnyPublisher<VolatileAttributes<PlaylistAttribute, PlaylistVersion>.ValueGroupSnapshot, Error> {
		// TODO
		fatalError()
	}
}

extension SpotifyAlbum: RemoteImageCollectionDelegate {
    func url(for feature: RemoteImageCollection.Feature) -> AnyPublisher<URL?, Error> {
		// TODO Push demand
        attributes.combineLatest($previewImageURL)
            .map { $1 }
            .eraseError()
            .eraseToAnyPublisher()
    }
}
