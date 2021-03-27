//
//  AnyAudioDevice.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 21.03.21.
//

import Foundation
import SwiftUI

public protocol AudioDevice: ObservableObject, Identifiable, Equatable {
	var name: String? { get }
	var icon: Image { get }

	var volume: Double { get set }
}

class UnsupportedAudioDeviceError: LocalizedError {
	var errorDescription: String? {
		"Track is not compatible with any of the selected audio devices."
	}
}

public class BranchingAudioDevice {
	let av: AVAudioDevice?
	let spotify: SpotifyAudioDevice?
	
	init(av: AVAudioDevice? = nil, spotify: SpotifyAudioDevice? = nil) {
		self.av = av
		self.spotify = spotify
	}
}
