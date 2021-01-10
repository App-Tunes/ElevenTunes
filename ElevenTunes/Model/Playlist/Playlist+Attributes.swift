//
//  Playlist+Attributes.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 25.12.20.
//

import Foundation

public typealias PlaylistVersion = String

public class PlaylistAttribute: RawRepresentable, Hashable {
    class Typed<K>: PlaylistAttribute, TypedKey, CustomStringConvertible {
        typealias Value = K
        var description: String { rawValue }
    }

    public let rawValue: String
    
    public required init(rawValue: String) {
        self.rawValue = rawValue
    }
}

extension PlaylistAttribute {
//	static let version = Typed<PlaylistVersion>(rawValue: "version")
	static let tracks = Typed<[AnyTrack]>(rawValue: "tracks")
	static let children = Typed<[AnyPlaylist]>(rawValue: "children")

	static let title = Typed<String>(rawValue: "title")
	
	static let previewImage = Typed<NSImage>(rawValue: "previewImage")
}

public typealias PlaylistAttributes = VolatileAttributes<PlaylistAttribute, PlaylistVersion>

extension PlaylistAttribute {
	static let common: Set<PlaylistAttribute> = [
		.title
	]
}
