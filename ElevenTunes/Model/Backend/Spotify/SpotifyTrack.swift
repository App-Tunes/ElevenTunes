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
    static let filters = "uri"

    var uri: String
}

public class SpotifyTrackToken: TrackToken {
    enum CodingKeys: String, CodingKey {
      case uri
    }
    
    enum SpotifyError: Error {
        case noURI
    }

    var uri: String

    public override var id: String { uri }

    init(_ uri: String) {
        self.uri = uri
        super.init()
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        uri = try container.decode(String.self, forKey: .uri)
        try super.init(from: decoder)
    }

    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(uri, forKey: .uri)
        try super.encode(to: encoder)
    }
    
    static func spotifyURI(fromURL url: URL) throws -> String {
        guard
            url.host == "open.spotify.com",
            url.pathComponents.dropFirst().first == "track",
            let id = url.pathComponents.last
        else {
            throw SpotifyError.noURI
        }
        return "spotify:track:\(id)"
    }
    
    static func create(_ spotify: Spotify, fromURL url: URL) -> AnyPublisher<SpotifyTrackToken, Error> {
        return Future { try spotifyURI(fromURL: url) }
            .flatMap { uri in
                spotify.api.track(uri).compactMap(ExistingSpotifyTrack.init)
            }
            .map { SpotifyTrackToken($0.uri) }
            .eraseToAnyPublisher()
    }
    
    override func expand(_ context: Library) -> AnyTrack {
        SpotifyTrack(self, spotify: context.spotify)
    }
}

public class SpotifyTrack: RemoteTrack {
    static var _icon: Image { Image("spotify-logo") }

    let spotify: Spotify
    let token: SpotifyTrackToken
        
    init(_ token: SpotifyTrackToken, spotify: Spotify) {
        self.token = token
        self.spotify = spotify
        super.init()
    }

    init(track: ExistingSpotifyTrack, spotify: Spotify) {
        self.token = SpotifyTrackToken(track.uri)
        self.spotify = spotify
        super.init()
        self._attributes.value = SpotifyTrack.extractAttributes(from: track)
        contentSet.insert(.minimal)
    }

    public override var asToken: TrackToken { token }
    
    override public var icon: Image { SpotifyTrack._icon }
    
    public override func emitter(context: PlayContext) -> AnyPublisher<AnyAudioEmitter, Error> {
        let spotify = context.spotify
        
        let spotifyTrack = spotify.api.track(token.uri)
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
    
    static func extractAttributes(from track: ExistingSpotifyTrack) -> TypedDict<TrackAttribute> {
        .init([
            .title: track.info.name
        ])
    }
    
    public override func load(atLeast mask: TrackContentMask) {
        contentSet.promise(mask) { promise in
            let spotify = self.spotify
            let uri = token.uri
            
            spotify.api.track(uri)
                .compactMap(ExistingSpotifyTrack.init)
                .onMain()
                .fulfillingAny(.minimal, of: promise)
                .sink(receiveCompletion: appLogErrors) { [unowned self] track in
                    self._attributes.value = SpotifyTrack.extractAttributes(from: track)
                    self._album.value = TransientAlbum(attributes: .init([
                        .title: track.info.album?.name
                    ]))
                    self._artists.value = (track.info.artists ?? []).map {
                        TransientArtist(attributes: .init([
                            .title: $0.name
                        ]))
                    }
                }
                .store(in: &cancellables)
        }
    }
}
