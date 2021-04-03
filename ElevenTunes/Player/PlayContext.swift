//
//  PlayContext.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 21.03.21.
//

import Foundation
import Combine
import AVFoundation

public class PlayContext: ObservableObject {
	let avProvider: AVAudioDeviceProvider
	@Published var avOutputDevice: AVAudioDevice?

	let spotifyProvider: SpotifyAudioDeviceProvider?
	@Published var spotifyDevice: SpotifyAudioDevice?
		
	var cancellables: Set<AnyCancellable> = []
	
	init(spotify: Spotify? = nil) {
		self.avProvider = .init()
		self.spotifyProvider = spotify.map { .init(spotify: $0) }
		
		avOutputDevice = .systemDefault
		
		if let spotify = spotify {
			spotify.devices.$online.sink { [weak self] devices in
				guard let self = self else { return }
				
				self.spotifyDevice = devices.first.map { SpotifyAudioDevice(spotify: spotify, device: $0) }
			}.store(in: &cancellables)
		}
	}
	
	var deviceStream: AnyPublisher<BranchingAudioDevice, Never> {
		$avOutputDevice.combineLatest($spotifyDevice)
			.map { (avDevice, spotifyDevice) in
			BranchingAudioDevice(
				av: avDevice,
				spotify: spotifyDevice
			)
		}
		.eraseToAnyPublisher()
	}
}
