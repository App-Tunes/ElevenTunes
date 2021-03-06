//
//  FilePlaylist.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 09.01.21.
//

import Foundation

public class FilePlaylistToken: PlaylistToken {
	var url: URL
	
	init(_ url: URL) {
		self.url = url
	}
	
	public var id: String { url.absoluteString }
	
	public var origin: URL? { url }
	
	public func expand(_ context: Library) throws -> AnyPlaylist {
		fatalError()
	}
}
