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
    
    static var _icon: Image { Image("spotify-logo") }

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
    
    init(uri: String) {
        self.uri = uri
        super.init()
    }

    init(track: ExistingSpotifyTrack) {
        self.uri = track.uri
        super.init()
        self._attributes = SpotifyTrack.extractAttributes(from: track)
        self._cacheMask = [.minimal]
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

    public override var id: String { uri }

    override public var icon: Image { SpotifyTrack._icon }

    static func create(_ spotify: Spotify, fromURL url: URL) -> AnyPublisher<SpotifyTrack, Error> {
        return Future { try spotifyURI(fromURL: url) }
            .flatMap { uri in
                spotify.api.track(uri).compactMap(ExistingSpotifyTrack.init)
            }
            .map { SpotifyTrack(uri: $0.uri) }
            .eraseToAnyPublisher()
    }
    
    public override func emitter(context: PlayContext) -> AnyPublisher<AnyAudioEmitter, Error> {
        let spotify = context.spotify
        
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
    
    public override func load(atLeast mask: TrackContentMask, library: Library) {
        let spotify = library.spotify
        let uri = self.uri
        
        spotify.api.track(uri)
            .compactMap(ExistingSpotifyTrack.init)
            .onMain()
            .sink(receiveCompletion: appLogErrors) { track in
                self._attributes = SpotifyTrack.extractAttributes(from: track)
                self._cacheMask = [.minimal]
            }
            .store(in: &cancellables)
    }
}

extension SpotifyTrack {
    enum CodingKeys: String, CodingKey {
      case uri
    }
}
