//
//  SpotifyAudioDeviceProvider.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 23.03.21.
//

import Foundation

class SpotifyAudioDeviceProvider: AudioDeviceProxy {
	let context: PlayContext

	init(context: PlayContext) {
		self.context = context
	}
	
	var options: [SpotifyAudioDevice] {
		[]
	}
	
	var current: SpotifyAudioDevice? {
		get { context.spotifyDevice }
		set { context.spotifyDevice = newValue }
	}
}
