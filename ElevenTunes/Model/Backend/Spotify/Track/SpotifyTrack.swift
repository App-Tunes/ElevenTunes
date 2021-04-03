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
    static let filters = "id,name,duration_ms,album(id),artists(id,name)"

    struct Album: Codable, Hashable {
        var id: String
    }
    
    struct Artist: Codable, Hashable {
        var id: String
		var name: String
    }
    
    var id: String
	var name: String
	var duration: TimeInterval
    var album: Album?
    var artists: [Artist]
    
    static func from(_ track: SpotifyWebAPI.Track) -> DetailedSpotifyTrack {
		DetailedSpotifyTrack(
			id: track.id!,
			name: track.name,
			duration: TimeInterval(track.durationMS!) / 1000,
			album: track.album.map { Album(id: $0.id!) },
			artists: (track.artists ?? []).map { Artist(id: $0.id!, name: $0.name) })
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

    public var id: String { trackID }
    
    public var uri: String { "spotify:track:\(id)" }
	
	public var origin: URL? {
		URL(string: "https://open.spotify.com/track/\(trackID)")
	}

    init(_ uri: String) {
        self.trackID = uri
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
    
	static func create(fromURL url: URL) throws -> SpotifyTrackToken {
		SpotifyTrackToken(try SpotifyTrackToken.trackID(fromURL: url))
	}

	public func expand(_ context: Library) throws -> AnyTrack {
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
		.track: [.title, .album, .artists, .duration],
		.analysis: [.tempo, .key]
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
    
    public var accentColor: Color { Spotify.color }
	
	public var id: String { token.id }
	
	public var origin: URL? { token.origin }
	    
	public func audioTrack(forDevice device: BranchingAudioDevice) throws -> AnyPublisher<AudioTrack, Error> {
		guard let device = device.spotify else {
			throw UnsupportedAudioDeviceError()
		}
		
		let spotifyTrack = spotify.api.track(token)
			.compactMap(ExistingSpotifyTrack.init)
		
		return spotifyTrack
			.map({ track -> AudioTrack in
				RemoteAudioEmitter(SpotifyAudioEmitter(
					device.spotify,
					device: device.device,
					context: .uris([track]),
					track: track
				)) as AudioTrack
			})
			.eraseToAnyPublisher()
	}
	
	public func supports(_ capability: TrackCapability) -> Bool {
		false
	}
    
    func extractAttributes(from track: DetailedSpotifyTrack) -> TypedDict<TrackAttribute> {
		.unsafe([
			.title: track.name,
			.duration: track.duration,
			.album: track.album.map { spotify.album(SpotifyAlbumToken($0.id)) },
			.artists:  track.artists.map {
				spotify.artist(SpotifyArtistToken($0.id), details: $0)
			}
		])
    }
    
    func extractAttributes(from features: AudioFeatures) -> TypedDict<TrackAttribute> {
		.unsafe([
			.tempo: Tempo(bpm: features.tempo),
			.key: MusicalNote(pitchClass: features.key).map { MusicalKey(note: $0, mode: features.mode == 1 ? .major : .minor) }
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
	
	func onUpdate(_ snapshot: VolatileAttributes<TrackAttribute, String>.PartialGroupSnapshot, from request: Request) {
		// TODO
	}
}

extension SpotifyTrack: BranchableTrack {
	func store(in track: DBTrack) throws -> DBTrack.Representation {
		guard
			let context = track.managedObjectContext,
			let model = context.persistentStoreCoordinator?.managedObjectModel,
			let trackModel = model.entitiesByName["DBSpotifyTrack"]
		else {
			fatalError("Failed to find model in MOC")
		}

		let cache = DBSpotifyTrack(entity: trackModel, insertInto: context)
		cache.spotifyID = token.trackID
		
		track.spotifyRepresentation = cache
		
		return .spotify
	}
}
