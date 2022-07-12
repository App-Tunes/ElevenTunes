//
//  SpotifyAudioDeviceProvider.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 23.03.21.
//

import Foundation
import SwiftUI
import TunesUI

class SpotifyAudioDeviceProvider: AudioDeviceProvider {
	let spotify: Spotify

	init(spotify: Spotify) {
		self.spotify = spotify
	}
	
	var options: [SpotifyAudioDevice] {
		spotify.devices.all.map {
			SpotifyAudioDevice(spotify: spotify, device: $0)
		}
	}
	
	var icon: Image { Spotify.logo }
	
	var color: Color { Spotify.color }
}
