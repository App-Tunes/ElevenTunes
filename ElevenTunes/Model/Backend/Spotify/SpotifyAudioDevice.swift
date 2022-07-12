//
//  SpotifyAudioDevice.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 21.03.21.
//

import Foundation
import SpotifyWebAPI
import SwiftUI
import TunesUI

public class SpotifyAudioDevice: AudioDevice {
	let spotify: Spotify
	let device: SpotifyWebAPI.Device
	
	init(spotify: Spotify, device: SpotifyWebAPI.Device) {
		self.spotify = spotify
		self.device = device
	}
	
	public var id: String { device.id! }
	
	public var name: String? { device.name }
	
	public var icon: Image {
		switch device.type {
		case .computer:
			return Image(systemName: "laptopcomputer")
		case .tablet:
			return Image(systemName: "ipad")
		case .smartphone:
			return Image(systemName: "iphone")
		case .tv:
			return Image(systemName: "tv")
		case .automobile:
			return Image(systemName: "car")
		case .avr:
			return Image(systemName: "cpu")
		case .gameConsole:
			return Image(systemName: "gamecontroller")
		default:
			return Image(systemName: "hifispeaker")
		}
	}
	
	public var volume: Double = 1 {
		willSet { objectWillChange.send() }
	}
	
	public static func ==(lhs: SpotifyAudioDevice, rhs: SpotifyAudioDevice) -> Bool {
		lhs.id == rhs.id
	}
}
