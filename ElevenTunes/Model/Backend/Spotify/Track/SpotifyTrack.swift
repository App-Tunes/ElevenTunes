//
//  SpotifyTrack+CoreDataClass.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 25.12.20.
//
//

import Foundation
import CoreData
import AVFoundation
import SpotifyWebAPI
import SwiftUI
import Combine

struct MinimalSpotifyTrack: Codable, Hashable {
    static let filters = "id"

    var id: String
}

struct DetailedSpotifyTrack: Codable, Hashable {
    static let filters = "id,name,album(id),artists(id)"

    struct Album: Codable, Hashable {
        var id: String
    }
    
    struct Artist: Codable, Hashable {
        var id: String
    }
    
    var id: String
    var name: String
    var album: Album?
    var artists: [Artist]
    
    static func from(_ track: SpotifyWebAPI.Track) -> DetailedSpotifyTrack {
        DetailedSpotifyTrack(id: track.id!, name: track.name, album: track.album.map { Album(id: $0.id!) }, artists: (track.artists ?? []).map { Artist(id: $0.id!) })
    }
}

public class SpotifyTrackToken: TrackToken, SpotifyURIConvertible {
    enum CodingKeys: String, CodingKey {
      case trackID
    }
    
    enum SpotifyError: Error {
        case noURI
    }

    var trackID: String

    public override var id: String { trackID }
    
    public var uri: String { "spotify:track:\(id)" }
	
	override var origin: URL? {
		URL(string: "https://open.spotify.com/track/\(trackID)")
	}

    init(_ uri: String) {
        self.trackID = uri
        super.init()
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        trackID = try container.decode(String.self, forKey: .trackID)
        try super.init(from: decoder)
    }

    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(trackID, forKey: .trackID)
        try super.encode(to: encoder)
    }
    
    static func trackID(fromURL url: URL) throws -> String {
        guard
            url.host == "open.spotify.com",
            url.pathComponents.dropFirst().first == "track",
            let id = url.pathComponents.last
        else {
            throw SpotifyError.noURI
        }
        return id
    }
    
    override func expand(_ context: Library) -> AnyTrack {
        SpotifyTrack(self, spotify: context.spotify)
    }
}

public final class SpotifyTrack: RemoteTrack {
    let spotify: Spotify
    public let token: SpotifyTrackToken
	
	enum Request {
		case track, analysis
	}
	
	let mapper = Requests(relation: [
		.track: [.title, .album, .artists],
		.analysis: [.bpm, .key]
	])

    init(_ token: SpotifyTrackToken, spotify: Spotify) {
        self.token = token
        self.spotify = spotify
		mapper.delegate = self
    }

    convenience init(track: DetailedSpotifyTrack, spotify: Spotify) {
		self.init(SpotifyTrackToken(track.id), spotify: spotify)
		mapper.offer(.track, update: .init(extractAttributes(from: track), state: .valid))
    }
    
	static func create(_ spotify: Spotify, fromURL url: URL) -> AnyPublisher<SpotifyTrack, Error> {
		return Future { try SpotifyTrackToken.trackID(fromURL: url) }
			.flatMap {
				spotify.api.track(SpotifyTrackToken($0)).compactMap(ExistingSpotifyTrack.init)
			}
			.map { SpotifyTrackToken($0.id) }
			.map { SpotifyTrack($0, spotify: spotify) }
			.eraseToAnyPublisher()
	}

    public var accentColor: Color { Spotify.color }
	
	public var id: String { token.id }
	
	public var origin: URL? { token.origin }
	    
    public func emitter(context: PlayContext) -> AnyPublisher<AnyAudioEmitter, Error> {
        let spotify = context.spotify
        
        let spotifyTrack = spotify.api.track(token)
            .compactMap(ExistingSpotifyTrack.init)
        let device = spotify.devices.$selected
            .compactMap { $0 }
            .eraseError()
        
        return spotifyTrack.combineLatest(device)
            .map({ (track, device) -> AnyAudioEmitter in
                RemoteAudioEmitter(SpotifyAudioEmitter(
                    spotify,
                    device: device,
                    context: .uris([track]),
                    track: track
                )) as AnyAudioEmitter
            })
            .eraseToAnyPublisher()
    }
    
    func extractAttributes(from track: DetailedSpotifyTrack) -> TypedDict<TrackAttribute> {
		.unsafe([
			.title: track.name,
			.album: track.album.map { spotify.album(SpotifyAlbumToken($0.id)) },
			.artists:  track.artists.map {
				spotify.artist(SpotifyArtistToken($0.id))
			}
		])
    }
    
    func extractAttributes(from features: AudioFeatures) -> TypedDict<TrackAttribute> {
		.unsafe([
			.bpm: Tempo(features.tempo),
			.key: MusicalKey(features.key)
		])
    }
}

extension SpotifyTrack: RequestMapperDelegate {
	func onDemand(_ request: Request) -> AnyPublisher<VolatileAttributes<TrackAttribute, TrackVersion>.PartialGroupSnapshot, Error> {
		switch request {
		case .track:
			return spotify.api.track(token)
				.map { [unowned self] track in
					.init(
						self.extractAttributes(from: DetailedSpotifyTrack.from(track)),
						state: .valid
					)
				}
				.eraseToAnyPublisher()
		case .analysis:
			return spotify.api.trackAudioFeatures(token)
				.map { [unowned self] features in
					.init(
						self.extractAttributes(from: features),
						state: .valid
					)
				}
				.eraseToAnyPublisher()
		}
	}
}
