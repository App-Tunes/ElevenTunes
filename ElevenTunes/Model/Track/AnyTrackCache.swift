//
//  AnyTrackCache.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 25.01.21.
//

import Foundation

public protocol AnyTrackCache {
	func expand(library: Library) -> AnyTrack
}
