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

public class SpotifyTrack: RemoteTrack {
    enum SpotifyError: Error {
        case noURI
    }

    var spotify: Spotify
    var uri: String
    
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
    
    init(_ spotify: Spotify, uri: String) {
        self.spotify = spotify
        self.uri = uri
        super.init()
    }

    init(_ spotify: Spotify, track: ExistingSpotifyTrack) {
        self.spotify = spotify
        self.uri = track.uri
        super.init()
        self._attributes = SpotifyTrack.extractAttributes(from: track)
        self._loadLevel = .detailed
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        guard let spotify = decoder.userInfo[CodingUserInfoKey.spotify] as? Spotify else {
            throw SpotifyDecodeError.noSpotify
        }
        self.spotify = spotify
        uri = try container.decode(String.self, forKey: .uri)
        try super.init(from: decoder)
    }

    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(uri, forKey: .uri)
        try super.encode(to: encoder)
    }

    public override var id: String { uri }

    override public var icon: Image { Image("spotify-logo") }

    static func create(_ spotify: Spotify, fromURL url: URL) -> AnyPublisher<SpotifyTrack, Error> {
        return Future { try spotifyURI(fromURL: url) }
            .flatMap { uri in
                spotify.api.track(uri).compactMap(ExistingSpotifyTrack.init)
            }
            .map { SpotifyTrack(spotify, uri: $0.uri) }
            .eraseToAnyPublisher()
    }
    
    public override func emitter() -> AnyPublisher<AnyAudioEmitter, Error> {
        let spotify = self.spotify
        
        let spotifyTrack = spotify.api.track(uri)
            .compactMap(ExistingSpotifyTrack.init)
        let device = spotify.devices.$selected
            .compactMap { $0 }
            .eraseError()
        
        return spotifyTrack.zip(device)
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
    
    public override func load(atLeast level: LoadLevel) -> Bool {
        let spotify = self.spotify
        let uri = self.uri
        
        spotify.api.track(uri)
            .compactMap(ExistingSpotifyTrack.init)
            .sink(receiveCompletion: appLogErrors) { track in
                self._attributes = SpotifyTrack.extractAttributes(from: track)
                self._loadLevel = .detailed
            }
            .store(in: &cancellables)
        
        return true
    }
}

extension SpotifyTrack {
    enum CodingKeys: String, CodingKey {
      case uri
    }
}
