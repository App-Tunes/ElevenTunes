//
//  AnyPlaylistRepresentation.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 25.01.21.
//

import Foundation

public protocol AnyPlaylistCache {
	func expand(library: Library) -> AnyPlaylist
}
