//
//  PlaylistInterpreter.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 20.12.20.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers
import Combine

class PlaylistInterpreter {
    enum InterpretationError: Error {
        case unknownType(_ type: UTType)
    }

    static let types: [UTType] = [.fileURL, .url]
    let spotify: Spotify

    var cancellables: Set<AnyCancellable> = []
    
    init(spotify: Spotify) {
        self.spotify = spotify
    }
    
    func accept(dropInfo info: DropInfo, for playlist: Playlist) -> Bool {
        var publishers: [AnyPublisher<Playlist, Error>] = []

        for type in Self.types {
            for provider in info.itemProviders(for: [type]) {
                publishers.append(
                    provider.loadItem(forType: type)
                        .tryFlatMap { item in try self.loadPlaylist(item, type: type) }
                        .catch { error -> AnyPublisher<Playlist, Error> in
                            appLogger.error("Error reading playlist: \(error)")
                            return Empty<Playlist, Error>(completeImmediately: true).eraseToAnyPublisher()
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
            .sink(receiveCompletion: appLogErrors(_:)) { playlists in
                playlist.add(children: playlists)
            }
            .store(in: &cancellables)
        
        return true
    }

    func loadPlaylist(_ item: NSSecureCoding, type: UTType) throws -> AnyPublisher<Playlist, Error> {
        if type == .fileURL {
            guard let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) else { throw InterpretationError.unknownType(type) }

            let isDirectory = try url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory!
            
            if isDirectory {
                return Future { try DirectoryPlaylist.create(fromURL: url) }
                    .eraseToAnyPublisher()
            }
            else {
                return Future { try M3UPlaylist.create(fromURL: url) }
                    .eraseToAnyPublisher()
            }
        }
        else if type == .url {
            guard let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) else { throw InterpretationError.unknownType(type) }

            return SpotifyPlaylist.create(spotify, fromURL: url)
                .eraseToAnyPublisher()
        }
        else {
            throw InterpretationError.unknownType(type)
        }
    }
}

class PlaylistDropInterpreter: DropDelegate {
    let interpreter: PlaylistInterpreter
    let parent: Playlist
    
    init(_ interpreter: PlaylistInterpreter, parent: Playlist) {
        self.interpreter = interpreter
        self.parent = parent
    }
    
    func dropEntered(info: DropInfo) {
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        return interpreter.accept(dropInfo: info, for: parent)
    }
}
