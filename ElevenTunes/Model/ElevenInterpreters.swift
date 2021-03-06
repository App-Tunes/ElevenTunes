//
//  ElevenInterpreters.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 16.02.21.
//

import Foundation
import UniformTypeIdentifiers

class TrackInterpreter: ContentInterpreter<TrackToken> {
	override var types: [UTType] { [.fileURL, .url] }
	
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
	override var types: [UTType] { [.fileURL, .url, .m3uPlaylist] }
	
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
