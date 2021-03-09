//
//  ElevenInterpreters.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 16.02.21.
//

import Foundation
import UniformTypeIdentifiers

class TrackInterpreter: ContentInterpreter<TrackToken> {
	override var types: [UTType] { [.url] }
	
	static let standard = createDefault()
	
	static func createDefault() -> TrackInterpreter {
		let interpreter = TrackInterpreter()
		
		interpreter.register(
			matches: AVTrackToken.understands,
			interpret: AVTrackToken.create
		)
		
		interpreter.registerDefaultSpotify()
		
		return interpreter
	}
}

class PlaylistInterpreter: ContentInterpreter<PlaylistToken> {
	override var types: [UTType] { [.url, .m3uPlaylist] }
	
	static let standard = createDefault()
	
	static func createDefault() -> PlaylistInterpreter {
		let interpreter = PlaylistInterpreter()
		
		interpreter.register(
			matches: { $0.pathExtension == "m3u" },
			interpret: M3UPlaylistToken.create
		)
		
		interpreter.register(
			matches: { try $0.isFileDirectory() },
			interpret: DirectoryPlaylistToken.create
		)
		
		interpreter.register(
			matches: DBPlaylistToken.understands,
			interpret: DBPlaylistToken.create(fromUrl:)
		)

		interpreter.registerDefaultSpotify()
		
		return interpreter
	}
}


enum LibraryContent {
	case playlist(PlaylistToken)
	case track(TrackToken)
}

class LibraryContentInterpreter: ContentInterpreter<LibraryContent> {
	override var types: [UTType] {
		TrackInterpreter.standard.types + PlaylistInterpreter.standard.types
	}
	
	static let standard = createDefault()
	
	static func createDefault() -> LibraryContentInterpreter {
		let interpreter = LibraryContentInterpreter()
		
		interpreter.register { url in
			try TrackInterpreter.standard.interpret(url: url).map { .track($0) }
		}
		
		interpreter.register { url in
			try PlaylistInterpreter.standard.interpret(url: url).map { .playlist($0) }
		}
		
		return interpreter
	}
	
	static func separate(_ contents: [LibraryContent]) -> UninterpretedLibrary {
		var playlists: [PlaylistToken] = []
		var tracks: [TrackToken] = []
		
		for content in contents {
			switch content {
			case .playlist(let playlist):
				playlists.append(playlist)
			case .track(let track):
				tracks.append(track)
			}
		}
		
		return .init(tracks: tracks, playlists: playlists)
	}
}

