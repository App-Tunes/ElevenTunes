//
//  SpotifyAudioDeviceProvider.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 23.03.21.
//

import Foundation

class SpotifyAudioDeviceProvider: AudioDeviceProxy {
	let spotify: Spotify

	init(spotify: Spotify) {
		self.spotify = spotify
	}
	
	var options: [SpotifyAudioDevice] {
		spotify.devices.all.map {
			SpotifyAudioDevice(spotify: spotify, device: $0)
		}
	}
}
