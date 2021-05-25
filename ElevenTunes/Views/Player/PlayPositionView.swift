//
//  PlayPositionView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 15.12.20.
//

import SwiftUI
import AVFoundation
import TunesUI

struct PlayPositionLabelsView: View {
	var duration: TimeInterval?
	var playerState: PlayerState

	var body: some View {
		let now = Date()
		
		HStack {
			if let time = playerState.currentTime {
				let start = now.advanced(by: -time)
				
				CountdownText(to: start, currentDate: now, advancesAutomatically: playerState.isPlaying)
					.foregroundColor(.secondary)
					.frame(width: 60, height: 20)
					.background(Rectangle().fill(Color.black).cornerRadius(5).opacity(0.4))
					.padding(.leading)
				
				Spacer()

				if let duration = duration {
					CountdownText(to: start.advanced(by: duration), currentDate: now, advancesAutomatically: playerState.isPlaying)
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
	var track: AnyTrack?
	var isSecondary: Bool = false

	@ObservedObject var snapshot: TrackAnalysisSnapshot

	var moveStep: TimeInterval? {
		// 16 beats = 4 bars = 1 phrase
		snapshot.tempo.map { TimeInterval(1 / $0.bps) * 16 }
	}
	
    var body: some View {
		PlayTrackingView(player: player) { tstate in
			GeometryReader { geo in
				let isCurrent = tstate.track?.id == track?.id
				let audio = isCurrent ? tstate.audio : nil
				let state = isCurrent ? tstate.state : .init(isPlaying: false, currentTime: nil)

				ZStack {
					WaveformView(
						colorLUT: Gradients.pitchCG,
						waveform: snapshot.waveform,
						resample: ResampleToSize.best
					)
						.allowsHitTesting(false)
						.frame(height: geo.size.height * 0.7, alignment: .bottom)
						.frame(height: geo.size.height, alignment: .bottom)

					if let duration = (isCurrent ? audio?.duration : snapshot.duration) {
						PositionControlView(
							locationProvider: { audio?.currentTime.map(CGFloat.init) },
							range: 0...CGFloat(duration),
							fps: state.isPlaying ? 10 : nil,
							action: {
								switch $0 {
								case .relative(let movement):
									try? audio?.move(by: TimeInterval(movement))
								case .absolute(let position):
									if let audio = audio {
										try? audio.move(to: TimeInterval(position))
									}
									else {
										player.play(track, at: TimeInterval(position))
									}
								}
							}
						)
							.jumpInterval(moveStep.map(CGFloat.init)) {
								!NSEvent.modifierFlags.contains(.option)
							}
							.barWidth(max(1, min(2, 3 - geo.size.height / 20)) + 0.5)
						
						if !isSecondary, geo.size.height >= 26, geo.size.width >= 200 {
							PlayPositionLabelsView(duration: duration, playerState: state)
								.allowsHitTesting(false)
						}
					}
				}
			}
		}
        // TODO hugging / compression resistance:
        // setting min height always compressed down to min height :<
    }
}

struct CurrentPlayPositionView: View {
	@ObservedObject var snapshot: TrackAnalysisSnapshot
	@Environment(\.player) private var player: Player!
	
	var body: some View {
		ZStack {
			// If this isn't here, we might not have a size, and .background
			// modifiers won't work
			Rectangle().fill(Color.clear)

			PlayPositionView(player: player, track: snapshot.track, snapshot: snapshot)
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
