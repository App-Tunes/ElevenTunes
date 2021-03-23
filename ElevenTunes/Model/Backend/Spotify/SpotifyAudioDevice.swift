//
//  SpotifyAudioDevice.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 21.03.21.
//

import Foundation

public class SpotifyAudioDevice: AudioDevice {	
	let spotify: Spotify
	
	init(spotify: Spotify) {
		self.spotify = spotify
	}
	
	public var id: String {
		"spotify"
	}
	
	public var name: String? {
		"Spotify"  // TODO
	}
	
	public var icon: String {
		"hifispeaker"
	}
	
	public var volume: Double = 1 {
		willSet { objectWillChange.send() }
	}
	
	public static func ==(lhs: SpotifyAudioDevice, rhs: SpotifyAudioDevice) -> Bool {
		lhs.id == rhs.id
	}
}
