//
//  TrackInterpreter.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 19.12.20.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers
import Combine

class TrackInterpreter {
    class UnknownType: Error { }
    
    static let types: [UTType] = [.fileURL, .url]
    let spotify: Spotify

    var cancellables: Set<AnyCancellable> = []
    
    init(spotify: Spotify) {
        self.spotify = spotify
    }
    
    func accept(dropInfo info: DropInfo, for playlist: Playlist) -> Bool {
        var publishers: [AnyPublisher<Track, Error>] = []

        for type in Self.types {
            for provider in info.itemProviders(for: [type]) {
                publishers.append(
                    provider.loadItem(forType: type)
                        .tryFlatMap { item in try self.loadTrack(item, type: type) }
                        .catch { error -> AnyPublisher<Track, Error> in
                            appLogger.error("Error reading track: \(error)")
                            return Empty<Track, Error>(completeImmediately: true).eraseToAnyPublisher()
                        }
                        .eraseToAnyPublisher()
                    )
            }
        }
        
        guard !publishers.isEmpty else {
            return false
        }
        
        Publishers.MergeMany(publishers)
            .collect()
            .sink(receiveCompletion: appLogErrors(_:)) { tracks in
                playlist.add(tracks: tracks)
            }
            .store(in: &cancellables)
        
        return true
    }

    func loadTrack(_ item: NSSecureCoding, type: UTType) throws -> AnyPublisher<Track, Error> {
        if type == .fileURL {
            guard let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) else { throw UnknownType() }

            return Future { try FileTrack.create(fromURL: url) }
                .eraseToAnyPublisher()
        }
        else if type == .url {
            guard let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) else { throw UnknownType() }

            return SpotifyTrack.create(spotify, fromURL: url)
                .eraseToAnyPublisher()
        }
        else {
            throw UnknownType()
        }
    }
}

class TrackDropInterpreter: DropDelegate {
    let interpreter: TrackInterpreter
    let playlist: Playlist
    
    init(_ interpreter: TrackInterpreter, playlist: Playlist) {
        self.interpreter = interpreter
        self.playlist = playlist
    }
    
    func dropEntered(info: DropInfo) {
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        return interpreter.accept(dropInfo: info, for: playlist)
    }
}
