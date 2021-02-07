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

public class SpotifyUserToken: PlaylistToken {
    enum SpotifyError: Error {
        case noURI
    }
    
    enum CodingKeys: String, CodingKey {
      case userID
    }
        
    var userID: String?
    
    public override var id: String { userID ?? "spotify::playlist::currentuser" }
    
    var uri: String? { userID.map { "spotify:user:\($0)" } }

    init(_ userID: String? = nil) {
        self.userID = userID
        super.init()
    }
        
    init(user: SpotifyWebAPI.SpotifyUser) {
        self.userID = user.id
        super.init()
    }
        
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        userID = try container.decodeIfPresent(String.self, forKey: .userID)
        try super.init(from: decoder)
    }
    
    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(userID, forKey: .userID)
        try super.encode(to: encoder)
    }
    
    static func userID(fromURL url: URL) throws -> String {
        guard
            url.host == "open.spotify.com",
            url.pathComponents.dropFirst().first == "user",
            let id = url.pathComponents.last
        else {
            throw SpotifyError.noURI
        }
        return id
    }
    
    override func expand(_ context: Library) -> AnyPlaylist {
        SpotifyUser(self, spotify: context.spotify)
    }
}

public final class SpotifyUser: RemotePlaylist {
	enum Request {
		case info, playlists
	}

	let mapper = Requests(relation: [
		.info: [.title],
		.playlists: [.children]
	])

    let token: SpotifyUserToken
    let spotify: Spotify
    
    init(spotify: Spotify) {
        self.token = SpotifyUserToken(nil)
        self.spotify = spotify
		mapper.delegate = self
    }
    
    init(_ token: SpotifyUserToken, spotify: Spotify) {
        self.token = token
        self.spotify = spotify
		mapper.delegate = self
    }

	static func create(_ spotify: Spotify, fromURL url: URL?) -> AnyPublisher<SpotifyUser, Error> {
		return Future { try url.map { try SpotifyUserToken.userID(fromURL: $0) } }
			.map { SpotifyUserToken($0) }
			.map { SpotifyUser($0, spotify: spotify) }
			.eraseToAnyPublisher()
	}

//    convenience init(_ user: SpotifyWebAPI.SpotifyUser, spotify: Spotify) {
//        self.init(SpotifyUserToken(user.id), spotify: spotify)
//        self._attributes.value = SpotifyUser.attributes(of: user.name)
//        contentSet.formUnion([.tracks, .attributes])
//    }
    
    public var icon: Image { Image(systemName: "person") }
    
    public var accentColor: Color { Spotify.color }
    
    public var contentType: PlaylistContentType { .playlists }
	
	public var origin: URL? { token.origin }
	
	public var id: String { token.id }
    
    static func attributes(of user: SpotifyWebAPI.SpotifyUser) -> TypedDict<PlaylistAttribute> {
        var attributes = TypedDict<PlaylistAttribute>()
        attributes[PlaylistAttribute.title] = user.displayName ?? user.id
        return attributes
    }
}

extension SpotifyUser: RequestMapperDelegate {
	func onDemand(_ request: Request) -> AnyPublisher<VolatileAttributes<PlaylistAttribute, PlaylistVersion>.PartialGroupSnapshot, Error> {
		let uri = token.uri
		let spotify = self.spotify

		switch request {
		case .info:
			let userProfile = uri != nil
				? spotify.api.userProfile(uri!)
				: spotify.api.currentUserProfile()

			return userProfile
				.map { .init(SpotifyUser.attributes(of: $0), state: .valid) }
				.eraseToAnyPublisher()
		case .playlists:
			let count = 50
			let paginationLimit = 100

			let playlistsAt = { (offset: Int) in
				uri != nil
					? spotify.api.userPlaylists(for: uri!, limit: count, offset: offset)
					: spotify.api.currentUserPlaylists(limit: count, offset: offset)
			}

			return playlistsAt(0)
				.unfold(limit: paginationLimit) {
					$0.offset + $0.items.count >= $0.total ? nil
						: playlistsAt($0.offset + count)
				}
				.collect()
				.map { $0.flatMap { $0.items } }
				.map { items in
					items.compactMap { item -> SpotifyPlaylist? in
						SpotifyPlaylist(SpotifyPlaylistToken(item.id), spotify: spotify)
					}
				}
				.map {
					.init(.unsafe([
						.children: $0
					]), state: .valid)
				}
				.eraseToAnyPublisher()
		}
	}
}
