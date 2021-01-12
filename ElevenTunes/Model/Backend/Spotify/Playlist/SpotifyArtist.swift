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
        context.spotify.artist(self)
    }
    
    static func create(_ spotify: Spotify, fromURL url: URL) -> AnyPublisher<SpotifyArtistToken, Error> {
        return Future { try playlistID(fromURL: url) }
            .flatMap { spotify.api.artist(Self($0)) }
            .tryMap { SpotifyArtistToken(try $0.id.unwrap(orThrow: NoArtistID())) }
            .eraseToAnyPublisher()
    }
}

public final class SpotifyArtist: SpotifyURIPlaylist, AnyArtist {
	enum Request {
		case info, playlists
	}
	
	let mapper = Requests(relation: [
		.info: [.title],
		.playlists: [.children]
	])
	
	let token: SpotifyArtistToken
	let spotify: Spotify

	init(_ token: SpotifyArtistToken, spotify: Spotify) {
		self.token = token
		self.spotify = spotify
		mapper.delegate = self
	}

    public var contentType: PlaylistContentType { .hybrid }
    
    public var icon: Image { Image(systemName: "person") }
    
    func offerCache(_ artist: SpotifyWebAPI.Artist) {
		mapper.requestFeatureSet.fulfilling(.info) {
			mapper.attributes.update(read(artist), state: .version(nil))
        }
    }
    
    func read(_ artist: SpotifyWebAPI.Artist) -> TypedDict<PlaylistAttribute> {
		.init([
			.title: artist.name
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

extension SpotifyArtist: RequestMapperDelegate {
	func onDemand(_ request: Request) -> AnyPublisher<VolatileAttributes<PlaylistAttribute, PlaylistVersion>.ValueGroupSnapshot, Error> {
		let spotify = self.spotify
		let token = self.token

		switch request {
		case .info:
			return spotify.api.artist(token)
				.map(self.read)
				.map { .init($0, state: .version(nil)) }
				.eraseToAnyPublisher()
		case .playlists:
			let count = 50
			let paginationLimit = 100

			let getItems = { (offset: Int) in
				spotify.api.artistAlbums(token, limit: count, offset: offset)
			}

			return getItems(0)
				.unfold(limit: paginationLimit) {
					$0.offset + $0.items.count >= $0.total ? nil :
					getItems($0.offset + count)
				}
				.collect()
				.map { $0.flatMap { $0.items }}
				.map { items in
					items.map { spotify.album(SpotifyAlbumToken($0.id!), info: $0) }
				}
				.map { albums in
					.init(.init([
						.children: albums
					]), state: .version(nil))
				}
				.eraseToAnyPublisher()
		}
	}
}
