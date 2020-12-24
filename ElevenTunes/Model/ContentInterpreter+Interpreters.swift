//
//  ContentInterpreter+Interpreters.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 23.12.20.
//

import Foundation
import Combine
import UniformTypeIdentifiers

extension ContentInterpreter {
    static func simple<T: ContentConvertible>(matches: @escaping (URL) throws -> Bool, interpret: @escaping (URL) -> AnyPublisher<T, Error>) -> ((URL) -> AnyPublisher<Content, Error>?) {
        return { url in
            if !((try? matches(url)) ?? false) { return nil }
            return interpret(url)
                .map(\.asContent)
                .eraseToAnyPublisher()
        }
    }

    static func simple<T: ContentConvertible>(matches: @escaping (URL) throws -> Bool, interpret: @escaping (URL) throws -> T) -> ((URL) -> AnyPublisher<Content, Error>?) {
        return { url in
            if !((try? matches(url)) ?? false) { return nil }
            return Future { try interpret(url).asContent }
                .eraseToAnyPublisher()
        }
    }

    // TODO Split up properly
    static func createDefault(spotify: Spotify) -> ContentInterpreter {
        let interpreter = ContentInterpreter()
        
        let register = { interpreter.interpreters.append($0) }
        
        register(simple {
            (try? SpotifyTrack.spotifyURI(fromURL: $0)) != nil
        } interpret: {
            SpotifyTrack.create(spotify, fromURL: $0)
        })
        
        register(simple {
            (try? SpotifyPlaylist.spotifyURI(fromURL: $0)) != nil
        } interpret: {
            SpotifyPlaylist.create(spotify, fromURL: $0)
        })
        
        register(simple { $0.pathExtension == "m3u" } interpret: {
            try M3UPlaylist.create(fromURL: $0)
        })
        
        register(simple {
            try $0.isFileDirectory()
        } interpret: {
            DirectoryPlaylist.create(fromURL: $0)
        })
        
        register(simple(matches: FileTrack.understands) {
            try FileTrack.create(fromURL: $0)
        })
        
        return interpreter
    }
}
