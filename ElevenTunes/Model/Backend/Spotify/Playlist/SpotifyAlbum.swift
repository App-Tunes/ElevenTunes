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
	enum Request {
		case info, tracks, previewImage
	}
	
	let mapper = Requests(relation: [
		.info: [.title],
		.previewImage: [.previewImage],
		.tracks: [.tracks]
	])
	
	let token: SpotifyAlbumToken
	let spotify: Spotify

    init(_ token: SpotifyAlbumToken, spotify: Spotify) {
		self.token = token
		self.spotify = spotify
		mapper.delegate = self
    }
    
    public var contentType: PlaylistContentType { .tracks }
    
    public var icon: Image { Image(systemName: "opticaldisc") }
    
    func offerCache(_ album: SpotifyWebAPI.Album) {
		mapper.requestFeatureSet.fulfilling(.info) {
			mapper.attributes.update(read(album), state: .version(nil))
        }
    }
    
    func read(_ album: SpotifyWebAPI.Album) -> TypedDict<PlaylistAttribute> {
		.init([
            .title: album.name
		])
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
}

extension SpotifyAlbum: RequestMapperDelegate {
	func onDemand(_ request: Request) -> AnyPublisher<VolatileAttributes<PlaylistAttribute, PlaylistVersion>.ValueGroupSnapshot, Error> {
		let spotify = self.spotify
		let token = self.token

		switch request {
		case .info:
			return spotify.api.album(token)
				.map {
					.init(self.read($0), state: .version(nil))
				}
				.eraseToAnyPublisher()
		case .tracks:
			let count = 50
			let paginationLimit = 100

			let getItems = { (offset: Int) in
				spotify.api.albumTracks(token, limit: count, offset: offset)
			}

			return getItems(0)
				.unfold(limit: paginationLimit) {
					$0.offset + $0.items.count >= $0.total ? nil :
					getItems($0.offset + count)
				}
				.collect()
				.map { $0.flatMap { $0.items } }
				.map { items in
					items.map { (model: SpotifyWebAPI.Track) -> SpotifyTrack in
						var track = DetailedSpotifyTrack.from(model)
						track.album = .init(id: token.id)  // Album requests don't return albums
						return SpotifyTrack(track: track, spotify: spotify) }
				}
				.map { tracks in
					.init(.init([
						.tracks: tracks
					]), state: .version(nil))
				}
				.eraseToAnyPublisher()
		case .previewImage:
			// TODO Don't do this request twice
			return spotify.api.album(token)
				.tryMap {
					try $0.images.flatMap(self.bestImageForPreview(_:))
						.unwrap(orThrow: RemoteImageCollection.RemoteError.noURL)
				}
				.flatMap { (url: URL) -> AnyPublisher<Data, Error> in
					URLSession.shared.dataTaskPublisher(for: url)
						.map { (data, response) in data }
						.eraseError()
						.eraseToAnyPublisher()
				}
				.tryMap { try NSImage(data: $0).unwrap(orThrow: RemoteImageCollection.RemoteError.notAnImage) }
				.map { (image: NSImage) -> VolatileAttributes<PlaylistAttribute, PlaylistVersion>.ValueGroupSnapshot in
					.init(.init([
						.previewImage: image
					]), state: .version(nil))
				}
				.eraseError()
				.eraseToAnyPublisher()
		}
	}
}
