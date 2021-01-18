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
    
    static func create(_ spotify: Spotify, fromURL url: URL) -> AnyPublisher<SpotifyPlaylistToken, Error> {
        return Future { try playlistID(fromURL: url) }
            .flatMap { spotify.api.playlist(Self($0)) }
            .map { SpotifyPlaylistToken($0.id) }
            .eraseToAnyPublisher()
    }
}

public final class SpotifyPlaylist: SpotifyURIPlaylist {
    static let minimalQueryFilters = "offset,total,items(track(\(MinimalSpotifyTrack.filters)))"
    static let detailedQueryFilters = "offset,total,items(track(\(DetailedSpotifyTrack.filters)))"

	enum Request {
		case playlist, items
	}
	
	let mapper = Requests(relation: [
		.playlist: [.title],
		.items: [.tracks]
	])
	
	let token: SpotifyPlaylistToken
	let spotify: Spotify
	
    init(_ token: SpotifyPlaylistToken, spotify: Spotify) {
		self.token = token
		self.spotify = spotify
		mapper.delegate = self
    }
    
    convenience init(playlist: SpotifyWebAPI.Playlist<SpotifyWebAPI.PlaylistItems>, spotify: Spotify) {
        self.init(SpotifyPlaylistToken(playlist.id), spotify: spotify)
		self.mapper.offer(.playlist, update: .init(SpotifyPlaylist.attributes(of: playlist), state: .missing))
    }
	
	public var contentType: PlaylistContentType { .tracks }

    static func attributes(of playlist: SpotifyWebAPI.Playlist<SpotifyWebAPI.PlaylistItems>) -> TypedDict<PlaylistAttribute> {
        return .unsafe([
            .title: playlist.name
        ])
    }
	    
    func viewableTracks(_ uris: [SpotifyTrackToken], spotify: Spotify) -> AnyPublisher<[SpotifyTrack], Error> {
        guard !uris.isEmpty else {
            return Just([]).eraseError().eraseToAnyPublisher()
        }
        
        let split = min(100, uris.count)
        
        return spotify.api.filteredPlaylistItems(token, filters: SpotifyPlaylist.detailedQueryFilters, additionalTypes: [.track])
            .decodeSpotifyObject(MinimalPagingObject<MinimalPlaylistItemContainer<DetailedSpotifyTrack>>.self)
            .zip(Just(uris[split...]).eraseError()).map { (full, partial) in
                full.items
                    .map { SpotifyTrack(track: $0.track, spotify: spotify) }
                + partial.map { SpotifyTrack($0, spotify: spotify) }
            }
            .eraseToAnyPublisher()
    }
}

extension SpotifyPlaylist: RequestMapperDelegate {
	func onDemand(_ request: Request) -> AnyPublisher<VolatileAttributes<PlaylistAttribute, PlaylistVersion>.PartialGroupSnapshot, Error> {
		let spotify = self.spotify
		let token = self.token

		switch request {
		case .items:
			// There are actually playlists with up to 10.000 items lol
			let count = 100
			let paginationLimit = 100

			let getItems = { (offset: Int) in
				spotify.api.filteredPlaylistItems(token, filters: SpotifyPlaylist.minimalQueryFilters, additionalTypes: [.track], limit: count, offset: offset)
					.decodeSpotifyObject(MinimalPagingObject<MinimalPlaylistItemContainer<MinimalSpotifyTrack>>.self)
			}

			// funny how this is not part of the query
			// maybe filteredPlaylist?
			let snapshotID = spotify.api.playlist(token)
				.map { $0.snapshotId }

			return getItems(0)
				.unfold(limit: paginationLimit) {
					$0.offset + $0.items.count >= $0.total ? nil :
					getItems($0.offset + count)
				}
				.collect()
				.map { $0.flatMap { $0.items }.map { $0.track } }
				// Collapse the first few instantly, so they can be viewed quickly.
				.flatMap { self.viewableTracks($0.map { SpotifyTrackToken($0.id) }, spotify: spotify) }
				.combineLatest(snapshotID)
				.map { (tracks, snapshotID) in
					.init(.unsafe([
						PlaylistAttribute.tracks: tracks
					]), state: .version(snapshotID))
				}
				.eraseToAnyPublisher()
		case .playlist:
			return spotify.api.playlist(token)
				.map { .init(SpotifyPlaylist.attributes(of: $0), state: .version(nil)) }
				.eraseToAnyPublisher()
		}
	}
}
