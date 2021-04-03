//
//  PlayPositionView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 15.12.20.
//

import SwiftUI
import AVFoundation

struct PlayPositionLabelsView: View {
	var duration: TimeInterval?
	var playerState: PlayerState

	var body: some View {
		let now = Date()
		
		HStack {
			if let time = playerState.currentTime {
				let start = now.advanced(by: -time)
				
				CountdownText(referenceDate: start, advancesAutomatically: playerState.isPlaying, currentDate: now)
					.foregroundColor(.secondary)
					.frame(width: 60, height: 20)
					.background(Rectangle().fill(Color.black).cornerRadius(5).opacity(0.4))
					.padding(.leading)
				
				Spacer()

				if let duration = duration {
					CountdownText(referenceDate: start.advanced(by: duration), advancesAutomatically: playerState.isPlaying, currentDate: now)
						.foregroundColor(.secondary)
						.frame(width: 60, height: 20)
						.background(Rectangle().fill(Color.black).cornerRadius(5).opacity(0.4))
						.padding(.trailing)
				}
			}
		}
		.id(playerState)
	}
}

struct PlayTrackingView<V: View>: View {
	struct PlayerTrackState {
		var track: AnyTrack? = nil
		var audio: AudioTrack? = nil
		var state: PlayerState = .init(isPlaying: false, currentTime: nil)
	}
	
	var player: Player
	var callback: (PlayerTrackState) -> V

	@State var state: PlayerTrackState = .init()

	var body: some View {
		callback(state)
			.onReceive(player.singlePlayer.$playing) {
				self.state.audio = $0
			}
			.onReceive(player.$current) {
				self.state.track = $0
			}
			.onReceive(player.singlePlayer.$state) {
				self.state.state = $0
			}
	}
}

struct PlayPositionView: View {
    var player: Player
	var track: AnyTrack
	var isSecondary: Bool = false

	@State var duration: TimeInterval?
	@State var tempo: Tempo?
	@State var waveform: Waveform?

	var moveStep: TimeInterval? {
		return tempo.map { TimeInterval(1 / $0.bps) * 32 }
	}
	
    var body: some View {
		PlayTrackingView(player: player) { tstate in
			GeometryReader { geo in
				let isCurrent = tstate.track?.id == track.id
				let audio = isCurrent ? tstate.audio : nil
				let state = isCurrent ? tstate.state : .init(isPlaying: false, currentTime: nil)

				ZStack {
					if let waveform = waveform {
						ResamplingWaveformView(
							gradient: Gradients.pitch,
							waveform: waveform
						)
							.allowsHitTesting(false)
							.frame(height: geo.size.height * 0.7, alignment: .bottom)
							.frame(height: geo.size.height, alignment: .bottom)
					}

					if let duration = (isCurrent ? audio?.duration : duration) {
						PositionControl(
							currentTimeProvider: { audio?.currentTime },
							currentTime: audio?.currentTime,
							duration: duration,
							advancesAutomatically: state.isPlaying,
							moveStepDuration: moveStep,
							moveTo: {
								if let audio = audio {
									try? audio.move(to: $0)
								}
								else {
									player.play(track, at: $0)
								}
							},
							moveBy: {
								if let audio = audio, let time = audio.currentTime {
									try? audio.move(to: $0 + time)
								}
							}
						)
							.id(state)
						
						if !isSecondary, geo.size.height >= 26, geo.size.width >= 200 {
							PlayPositionLabelsView(duration: duration, playerState: state)
								.allowsHitTesting(false)
						}
					}
				}
			}
		}
		.id(track.id) // Required because sometimes bars don't reset :<
		.whileActive(track.demand([.tempo, .waveform, .duration]))
		.onReceive(track.attributes) { (snapshot, _) in
			setIfDifferent(self, \.duration, snapshot[TrackAttribute.duration].value)
			setIfDifferent(self, \.tempo, snapshot[TrackAttribute.tempo].value)
			setIfDifferent(self, \.waveform, snapshot[TrackAttribute.waveform].value)
		}
        // TODO hugging / compression resistance:
        // setting min height always compressed down to min height :<
    }
}

struct CurrentPlayPositionView: View {
	var player: Player
	@State var track: AnyTrack?

	var body: some View {
		Group {
			if let track = track {
				PlayPositionView(player: player, track: track)
			}
			else {
				// Otherwise we don't have any size...
				Rectangle().fill(Color.clear)
			}
		}
		.onReceive(player.$current) {
			self.track = $0
		}
	}
}

//struct PlayPositionView_Previews: PreviewProvider {
//    static var previews: some View {
//		let player = Player(context: .init())
//		player.play(LibraryMock.track())
//
//		return PlayPositionView(player: player)
//    }
//}
