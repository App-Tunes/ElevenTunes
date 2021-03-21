//
//  PlayContext.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 21.03.21.
//

import Foundation
import Combine
import AVFoundation

public class PlayContext {
	@Published var avOutputDevice: AVAudioDevice

	let spotify: Spotify
	@Published var spotifyDevice: SpotifyAudioDevice?
		
	var cancellables: Set<AnyCancellable> = []
	
	init(spotify: Spotify) {
		self.spotify = spotify
		avOutputDevice = .systemDefault
		
		spotify.authenticator.$isAuthorized.sink { [weak self] in
			guard let self = self else { return }
			
			self.spotifyDevice = $0 ? SpotifyAudioDevice(spotify: self.spotify) : nil
		}.store(in: &cancellables)
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
