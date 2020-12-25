//
//  ContentInterpreter.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 23.12.20.
//

import Foundation
import Combine
import UniformTypeIdentifiers

enum Content {
    case playlist(_ playlist: Playlist)
    case track(_ track: Track)
}

protocol ContentConvertible {
    var asContent: Content { get }
}

extension Track: ContentConvertible {
    var asContent: Content { .track(self) }
}

extension Playlist: ContentConvertible {
    var asContent: Content { .playlist(self) }
}

class ContentInterpreter {
    enum InterpretationError: Error {
        case noInterpreter
        case invalidData
    }
    
    static let types: [UTType] = [.fileURL, .url, .m3uPlaylist]

    var interpreters: [(URL) -> AnyPublisher<Content, Error>?] = []
    
    func interpret(urls: [URL]) -> AnyPublisher<[Content], Error>? {
        var publishers: [AnyPublisher<Content, Error>] = []

        for url in urls {
            if let publisher = try? interpret(url: url) {
                publishers.append(publisher)
            }
        }
        
        guard !publishers.isEmpty else {
            return nil
        }
        
        return Publishers.MergeMany(publishers)
            .collect()
            .eraseToAnyPublisher()
    }
    
    func interpret(url: URL) throws -> AnyPublisher<Content, Error> {
        for interpreter in interpreters {
            if let publisher = interpreter(url) {
                return publisher
            }
        }

        throw InterpretationError.noInterpreter
    }
    
    func interpret(_ item: NSSecureCoding, type: UTType) throws -> AnyPublisher<Content, Error> {
        if type == .fileURL || type == .url {
            guard
                let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil)
            else {
                throw InterpretationError.invalidData
            }

            return try interpret(url: url)
        }
        else {
            fatalError()
        }
    }
    
    static func collect(fromContents contents: [Content]) -> ([Track], [Playlist]) {
        var playlists: [Playlist] = []
        var tracks: [Track] = []
        
        for content in contents {
            switch content {
            case .playlist(let playlist):
                playlists.append(playlist)
            case .track(let track):
                tracks.append(track)
            }
        }

        return (tracks, playlists)
    }
    
    static func library(fromContents contents: [Content], name: String) -> AnyLibrary {
        var (tracks, playlists) = collect(fromContents: contents)
        
        if !tracks.isEmpty {
            playlists.append(Playlist(attributes: .init([
                .title: "Tracks"
            ]), tracks: tracks))
        }
        
        return DirectLibrary(allTracks: tracks, allPlaylists: playlists)
    }
    
}
