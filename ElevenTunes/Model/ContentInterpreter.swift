//
//  ContentInterpreter.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 23.12.20.
//

import Foundation
import Combine
import UniformTypeIdentifiers
import Cocoa

enum Content {
    case playlist(_ playlist: AnyPlaylist)
    case track(_ track: AnyTrack)
}

class ContentInterpreter {
    enum InterpretationError: Error {
        case noInterpreter
        case invalidData
    }
    
    typealias Interpreter = (URL, SettingsLevel) -> AnyPublisher<Content, Error>?
    
	static let types: [UTType] = [.fileURL, .url, .m3uPlaylist]

	let settings: SettingsLevel
	
	init(settings: SettingsLevel) {
		self.settings = settings
	}
	
    var interpreters: [Interpreter] = []
    
    func interpret(urls: [URL]) -> AnyPublisher<[Content], Error>? {
        var publishers: [AnyPublisher<Content, Error>] = []

        for url in urls {
            if let publisher = try? interpret(url: url) {
                publishers.append(
                    publisher
                        .catch { _ in
                            Empty<Content, Error>(completeImmediately: true)
                                .eraseToAnyPublisher()
                        }
                        .eraseToAnyPublisher()
                )
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
            if let publisher = interpreter(url, settings) {
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
    
    static func collect(fromContents contents: [Content]) -> UninterpretedLibrary {
        var playlists: [AnyPlaylist] = []
        var tracks: [AnyTrack] = []
        
        for content in contents {
            switch content {
            case .playlist(let playlist):
                playlists.append(playlist)
            case .track(let track):
                tracks.append(track)
            }
        }

        return UninterpretedLibrary(tracks: tracks, playlists: playlists)
    }
}
