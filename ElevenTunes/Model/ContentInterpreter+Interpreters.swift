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
    static func simple(matches: @escaping (URL) throws -> Bool, interpret: @escaping (URL, SettingsLevel) -> AnyPublisher<Content, Error>) -> Interpreter {
        return { url, settings in
            if !((try? matches(url)) ?? false) { return nil }
            return interpret(url, settings)
                .eraseToAnyPublisher()
        }
    }

    static func simple(matches: @escaping (URL) throws -> Bool, interpret: @escaping (URL, SettingsLevel) throws -> Content) -> Interpreter {
        return { url, settings in
            if !((try? matches(url)) ?? false) { return nil }
            return Future { try interpret(url, settings) }
                .eraseToAnyPublisher()
        }
    }

    // TODO Split up properly
	static func createDefault(settings: SettingsLevel, library: Library) -> ContentInterpreter {
		// TODO Remove library argument
		let interpreter = ContentInterpreter(settings: settings)
        
        let register = { interpreter.interpreters.append($0) }
        
        interpreter.interpreters += defaultSpotify()
        
        register(simple(matches: AVTrack.understands) { (url, settings) in
            .track(try AVTrack.create(fromURL: url))
        })

		register(simple { $0.pathExtension == "m3u" } interpret: { (url, settings) in
			.playlist(try M3UPlaylist.create(fromURL: url, library: library))
		})
		
		register(simple {
			try $0.isFileDirectory()
		} interpret: { (url, settings) in
			.playlist(try DirectoryPlaylist.create(fromURL: url, library: library))
		})

        return interpreter
    }
}
