//
//  SpotifyAudioDevice.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 21.03.21.
//

import Foundation
import SpotifyWebAPI

public class SpotifyAudioDevice: AudioDevice {
	let spotify: Spotify
	let device: SpotifyWebAPI.Device
	
	init(spotify: Spotify, device: SpotifyWebAPI.Device) {
		self.spotify = spotify
		self.device = device
	}
	
	public var id: String { device.id! }
	
	public var name: String? { device.name }
	
	public var icon: String {
		"􀝎"
	}
	
	public var volume: Double = 1 {
		willSet { objectWillChange.send() }
	}
	
	public static func ==(lhs: SpotifyAudioDevice, rhs: SpotifyAudioDevice) -> Bool {
		lhs.id == rhs.id
	}
}
