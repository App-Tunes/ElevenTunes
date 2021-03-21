//
//  AnyAudioDevice.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 21.03.21.
//

import Foundation

public class AudioDevice: ObservableObject {
	public var name: String { "Unknown Device" }
	@Published public var volume: Double = 1
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
