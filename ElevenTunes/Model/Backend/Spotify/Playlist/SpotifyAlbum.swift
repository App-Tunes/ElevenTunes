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
    override class var urlComponent: String { "album" }
    
	public override func expand(_ context: Library) throws -> AnyPlaylist {
		context.spotify.album(self)
	}
	
	static func create(fromURL url: URL) throws -> SpotifyAlbumToken {
		SpotifyAlbumToken(try SpotifyAlbumToken.playlistID(fromURL: url))
	}
}

public final class SpotifyAlbum: SpotifyURIPlaylist, AnyAlbum {
	class NoAlbumID: Error {}

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
	
	public var id: String { token.id }
	
	public var origin: URL? { token.origin }
    
	func offerCache(_ album: SpotifyWebAPI.Album) {
		mapper.offer(.info, update: read(album))
	}
	
	func offerCache(_ album: DetailedSpotifyTrack.Album) {
		mapper.offer(.info, update: read(album))
	}
	
	func read(_ album: SpotifyWebAPI.Album) -> PlaylistAttributes.PartialGroupSnapshot {
		.init(.unsafe([
			.title: album.name
		]), state: .valid)
	}
	
	func read(_ album: DetailedSpotifyTrack.Album) -> PlaylistAttributes.PartialGroupSnapshot {
		.init(.unsafe([
			.title: album.name
		]), state: .valid)
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
	
	public func supports(_ capability: PlaylistCapability) -> Bool {
		false
	}
}

extension SpotifyAlbum: RequestMapperDelegate {
	func onDemand(_ request: Request) -> AnyPublisher<VolatileAttributes<PlaylistAttribute, PlaylistVersion>.PartialGroupSnapshot, Error> {
		let spotify = self.spotify
		let token = self.token

		switch request {
		case .info:
			return spotify.api.album(token)
				.map { self.read($0) }
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
						// TODO This does NOT include the album, we should set this
						// so the track doesn't have to fetch this info itself
						spotify.track(SpotifyTrackToken(model.id!), info: model)
					}
				}
				.map { tracks in
					.init(.unsafe([
						.tracks: tracks
					]), state: .valid)
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
				.map { (image: NSImage) -> VolatileAttributes<PlaylistAttribute, PlaylistVersion>.PartialGroupSnapshot in
					.init(.unsafe([
						.previewImage: image
					]), state: .valid)
				}
				.eraseError()
				.eraseToAnyPublisher()
		}
	}
	
	func onUpdate(_ snapshot: VolatileAttributes<PlaylistAttribute, String>.PartialGroupSnapshot, from request: Request) {
		// TODO
	}
}
