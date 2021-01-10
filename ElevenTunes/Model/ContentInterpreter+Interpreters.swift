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
    static func simple(matches: @escaping (URL) throws -> Bool, interpret: @escaping (URL) -> AnyPublisher<Content, Error>) -> Interpreter {
        return { url in
            if !((try? matches(url)) ?? false) { return nil }
            return interpret(url)
                .eraseToAnyPublisher()
        }
    }

    static func simple(matches: @escaping (URL) throws -> Bool, interpret: @escaping (URL) throws -> Content) -> Interpreter {
        return { url in
            if !((try? matches(url)) ?? false) { return nil }
            return Future { try interpret(url) }
                .eraseToAnyPublisher()
        }
    }

    // TODO Split up properly
    static func createDefault(settings: SettingsLevel) -> ContentInterpreter {
        let interpreter = ContentInterpreter()
        
        let register = { interpreter.interpreters.append($0) }
        
        interpreter.interpreters += defaultSpotify(spotify: settings.spotify)
        
        register(simple(matches: FileVideoToken.understands) {
            .track(try FileVideoToken.create(fromURL: $0))
        })
        
        register(simple(matches: AVAudioTrackToken.understands) {
            .track(try AVAudioTrackToken.create(fromURL: $0))
        })

        return interpreter
    }
}
