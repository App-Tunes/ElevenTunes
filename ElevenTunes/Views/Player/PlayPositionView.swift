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

struct PlayPositionView: View {
    var player: Player
	var track: AnyTrack?
	var isSecondary: Bool = false

	@State var state: PlayerTrackState = .init()
	@ObservedObject var snapshot: TrackAnalysisSnapshot
	
    var body: some View {
		GeometryReader { geo in
			let state = self.state.viewedAs(track)

			ZStack {
				WaveformView(
					colorLUT: Gradients.pitchCG,
					waveform: snapshot.waveform ?? .empty,
					resample: ResampleToSize.bestOrZero
				)
					.allowsHitTesting(false)
					.frame(height: geo.size.height * 0.7, alignment: .bottom)
					.frame(height: geo.size.height, alignment: .bottom)

				if let duration = (state.audio?.duration ?? snapshot.duration) {
					PositionControlView(
						locationProvider: { () -> CGFloat? in
							state.audio?.currentTime.map { CGFloat($0) }
						},
						range: 0...CGFloat(duration),
						fps: state.state.isPlaying ? PlayPositionViewCocoa.activeFPS : nil,
						action: {
							switch $0 {
							case .relative(let movement):
								try? state.audio?.move(by: TimeInterval(movement))
							case .absolute(let position):
								if let audio = state.audio {
									try? audio.move(to: TimeInterval(position))
								}
								else {
									player.play(track, at: TimeInterval(position))
								}
							}
						}
					)
						.jumpInterval((snapshot.tempo?.phraseSeconds).map(CGFloat.init)) {
							!NSEvent.modifierFlags.contains(.option)
						}
						.barWidth(max(1, min(2, 3 - geo.size.height / 20)) + 0.5)
					
					if !isSecondary, geo.size.height >= 26, geo.size.width >= 200 {
						PlayPositionLabelsView(duration: duration, playerState: state.state)
							.allowsHitTesting(false)
					}
				}
			}
		}
		.onReceive(PlayerTrackState.observing(player)) {
			self.state = $0
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
