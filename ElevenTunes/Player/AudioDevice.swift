//
//  AnyAudioDevice.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 21.03.21.
//

import Foundation

public protocol AudioDevice {
	
}

class UnsupportedAudioDeviceError: Error { }

public class BranchingAudioDevice {
	let av: AVAudioDevice?
	let spotify: SpotifyAudioDevice?
	
	init(av: AVAudioDevice? = nil, spotify: SpotifyAudioDevice? = nil) {
		self.av = av
		self.spotify = spotify
	}
}
