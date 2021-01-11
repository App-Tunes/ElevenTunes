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
	}

    public var contentType: PlaylistContentType { .hybrid }
    
    public var icon: Image { Image(systemName: "person") }
    
    func offerCache(_ artist: SpotifyWebAPI.Artist) {
		mapper.requestFeatureSet.fulfilling(.info) {
            read(artist)
        }
    }
    
    func read(_ artist: SpotifyWebAPI.Artist) {
		mapper.attributes.update(.init([
			PlaylistAttribute.title: artist.name
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
//            // TODO Not supported yet
//            promise.fulfill(.tracks)
//
//            let spotify = self.spotify
//            let token = self.token
//
//            if promise.includes(.children) {
//                // There are actually playlists with up to 10.000 items lol
//                let count = 50
//                let paginationLimit = 100
//
//                let getItems = { (offset: Int) in
//                    spotify.api.artistAlbums(token, limit: count, offset: offset)
//                }
//
//                getItems(0)
//                    .unfold(limit: paginationLimit) {
//                        $0.offset + $0.items.count >= $0.total ? nil :
//                        getItems($0.offset + count)
//                    }
//                    .collect()
//                    .map { $0.flatMap { $0.items }}
//                    .map { items in
//                        items.map { spotify.album(SpotifyAlbumToken($0.id!), info: $0) }
//                    }
//                    .onMain()
//                    .fulfillingAny(.children, of: promise)
//                    .sink(receiveCompletion: appLogErrors(_:)) { albums in
//                        self._children.value = .init(albums)
//                    }.store(in: &cancellables)
//            }
//
//            if promise.includesAny(.attributes) {
//                spotify.api.artist(token).eraseToAnyPublisher()
//                    .onMain()
//                    .fulfillingAny(.attributes, of: promise)
//                    .sink(receiveCompletion: appLogErrors) { info in
//                        self.read(info)
//                    }
//                    .store(in: &cancellables)
//            }
//        }
//    }
}

extension SpotifyArtist: RequestMapperDelegate {
	func onDemand(_ request: Request) -> AnyPublisher<VolatileAttributes<PlaylistAttribute, PlaylistVersion>.ValueGroupSnapshot, Error> {
		 // TODO
		fatalError()
	}
}
