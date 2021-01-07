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
    
    static func create(_ spotify: Spotify, fromURL url: URL) -> AnyPublisher<SpotifyTrackToken, Error> {
        return Future { try trackID(fromURL: url) }
            .flatMap {
                spotify.api.track(SpotifyTrackToken($0)).compactMap(ExistingSpotifyTrack.init)
            }
            .map { SpotifyTrackToken($0.id) }
            .eraseToAnyPublisher()
    }
    
    override func expand(_ context: Library) -> AnyTrack {
        SpotifyTrack(self, spotify: context.spotify)
    }
}

public class SpotifyTrack: RemoteTrack {
    let spotify: Spotify
    let token: SpotifyTrackToken
            
    init(_ token: SpotifyTrackToken, spotify: Spotify) {
        self.token = token
        self.spotify = spotify
        super.init()
    }

    init(track: DetailedSpotifyTrack, spotify: Spotify) {
        self.token = SpotifyTrackToken(track.id)
        self.spotify = spotify
        super.init()
        self.extractAttributes(from: track)
        contentSet.insert(.minimal)
    }

    public override var asToken: TrackToken { token }
    
    public override var accentColor: Color { Spotify.color }
    
    public override var origin: URL? {
        URL(string: "https://open.spotify.com/track/\(token.trackID)")
    }

    public override func emitter(context: PlayContext) -> AnyPublisher<AnyAudioEmitter, Error> {
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
    
    func extractAttributes(from track: DetailedSpotifyTrack) {
        let spotify = self.spotify
        
        self._attributes.value.merge(
            .init([
                .title: track.name
            ])
        )
        
        self._album.value = track.album.map { spotify.album(SpotifyAlbumToken($0.id)) }

        self._artists.value = track.artists
            .map {
                spotify.artist(SpotifyArtistToken($0.id))
            }
    }
    
    func extractAttributes(from features: AudioFeatures) {
        self._attributes.value.merge(
            .init([
                .bpm: Tempo(features.tempo),
                .key: MusicalKey(features.key)
            ])
        )
    }
    
    public override func load(atLeast mask: TrackContentMask) {
        contentSet.promise(mask) { promise in
            let spotify = self.spotify
            
            if promise.includes(.minimal) {
                spotify.api.track(token)
                    .onMain()
                    .fulfillingAny(.minimal, of: promise)
                    .sink(receiveCompletion: appLogErrors) { [unowned self] track in
                        self.extractAttributes(from: DetailedSpotifyTrack.from(track))
                    }
                    .store(in: &cancellables)
            }
            
            if promise.includes(.analysis) {
                spotify.api.trackAudioFeatures(token)
                    .onMain()
                    .fulfillingAny(.analysis, of: promise)
                    .sink(receiveCompletion: appLogErrors) { [unowned self] features in
                        self.extractAttributes(from: features)
                    }
                    .store(in: &cancellables)
            }
        }
    }
}
