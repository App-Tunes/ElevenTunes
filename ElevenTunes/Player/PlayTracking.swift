//
//  PlayTracking.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 06.06.21.
//

import Combine

struct PlayerTrackState {
	var track: AnyTrack? = nil
	var audio: AudioTrack? = nil
	var state: PlayerState = .init(isPlaying: false, currentTime: nil)

	static func current(ofPlayer player: Player) -> PlayerTrackState {
		PlayerTrackState(track: player.current, audio: player.singlePlayer.playing, state: player.singlePlayer.state)
	}
	
	static func observing(_ player: Player) -> AnyPublisher<PlayerTrackState, Never> {
		player.$current
			.combineLatest(player.singlePlayer.$playing, player.singlePlayer.$state)
			.map {
				PlayerTrackState(track: $0, audio: $1, state: $2)
			}
			.eraseToAnyPublisher()
	}
	
	func viewedAs(_ track: AnyTrack?) -> PlayerTrackState {
		let isCurrent = track?.id == track?.id
		
		return .init(
			track: isCurrent ? track : nil,
			audio: isCurrent ? audio : nil,
			state: isCurrent ? state : .init(isPlaying: false, currentTime: nil)
		)
	}
}
