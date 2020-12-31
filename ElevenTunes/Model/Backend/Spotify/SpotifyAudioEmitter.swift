//
//  SpotifyAudioEmitter.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 20.12.20.
//

import Foundation
import Combine
import SpotifyWebAPI

class ExistingSpotifyTrack: SpotifyURIConvertible {
    let info: SpotifyWebAPI.Track
    let id: String
    
    init?(_ track: SpotifyWebAPI.Track?) {
        guard let track = track, let id = track.id else {
            return nil
        }
        self.info = track
        self.id = id
    }
    
    var uri: String { "spotify:track:\(id)" }
}

class SpotifyAudioEmitter: RemoteAudioEndpoint {
    weak var delegate: RemoteAudioEndpointDelegate?
    
    let spotify: Spotify
    var device: Device
    
    let context: ContextOption
    let track: ExistingSpotifyTrack

    var cancellables: Set<AnyCancellable> = []
    
    init(_ spotify: Spotify, device: Device, context: ContextOption,
         track: ExistingSpotifyTrack) {
        self.spotify = spotify
        self.device = device
        self.context = context
        self.track = track        
    }
    
    var duration: TimeInterval? {
        track.info.durationMS.map { Double($0) / 1000.0 }
    }
    
    func start(at time: TimeInterval) {
        let playbackRequest = PlaybackRequest(
            context: context,
            offset: .uri(track),
            positionMS: Int(time * 1000)
        )

        spotify.api.play(playbackRequest, deviceId: device.id)
            .sink(receiveCompletion: Self.checkForError(_:))
            .store(in: &cancellables)
    }
    
    func seek(to time: TimeInterval) {
        spotify.api.seekToPosition(Int(time * 1000), deviceId: device.id)
            .sink(receiveCompletion: Self.checkForError(_:))
            .store(in: &cancellables)
    }
    
    func stop() {
        spotify.api.pausePlayback(deviceId: device.id)
            .sink(receiveCompletion: Self.checkForError(_:))
            .store(in: &cancellables)
    }
    
    private static func checkForError(_ completion: Subscribers.Completion<Error>) {
        switch completion {
        case .failure(let error):
            appLogger.error("Spotify API Error: \(error)")
        default:
            return
        }
    }
}

extension SpotifyAudioEmitter: ActiveStateQueryingAudioEndpoint {
    func queryState() {
        spotify.api.currentPlayback()
            .sink(receiveCompletion: Self.checkForError(_:)) { [weak self] context in
                guard let self = self else {
                    return
                }
                
                let delegate = self.delegate
                let track = self.track
                
                guard let context = context else {
                    delegate?.endpointDidStop(self)
                    return
                }
                
                switch context.item {
                case .track(track.info):
                    let state = PlayerState(isPlaying: context.isPlaying, currentTime: context.progressMS.map { TimeInterval($0) / 1000 })
                    
                    delegate?.endpoint(self, updatedState: state, at: context.timestamp)
                default:
                    // It's playing something else. So the track stopped lol
                    delegate?.endpointDidStop(self)
                }
            }
            .store(in: &cancellables)
    }
}
