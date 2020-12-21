//
//  SpotifyBackend.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 20.12.20.
//

import Foundation
import Combine
import AVFoundation
import SpotifyWebAPI
import SwiftUI

class SpotifyTrack: TrackBackend {
    enum SpotifyError: Error {
        case noURI
    }

    weak var frontend: Track?

    let spotify: Spotify
    let uri: String

    init(_ spotify: Spotify, uri: String) {
        self.spotify = spotify
        self.uri = uri
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
    
    static func create(_ spotify: Spotify, fromURL url: URL) -> AnyPublisher<Track, Error> {
        return Future { try spotifyURI(fromURL: url) }
            .flatMap { uri in
                spotify.api.track(uri).compactMap(ExistingSpotifyTrack.init)
            }
            .map { convert(spotify, from: $0) }
            .eraseToAnyPublisher()
    }

    static func convert(_ spotify: Spotify, from track: ExistingSpotifyTrack) -> Track {
        Track(SpotifyTrack(spotify, uri: track.uri), attributes: .init([
            AnyTypedKey.ttitle.id: track.info.name
        ]))
    }
    
    var icon: Image? { nil }
    
    func emitter() -> AnyPublisher<AnyAudioEmitter, Error> {
        let spotify = self.spotify
        
        let spotifyTrack = spotify.api.track(uri)
            .compactMap(ExistingSpotifyTrack.init)
        let device = spotify.api.availableDevices().map { devices in
            devices[0]  // TODO Which device?
        }.eraseToAnyPublisher()
        
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
}
