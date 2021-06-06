//
//  PlayPositionViewCocoa.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 30.05.21.
//

import TunesUI
import Combine

class PlayPositionViewCocoa: WaveformPositionCocoa {
	public static let activeFPS: Double = 10
	
	@Published public var track: AnyTrack? = nil
	
	@Published public var player: Player? = nil
	
	override func sharedInit() {
		waveformView.colorLUT = Gradients.pitchCG
		waveformView.resample = ResampleToSize.bestOrZero(data:toSize:)

		positionControl.timer.fps = nil
		positionControl.action = { [weak self] in
			guard let track = self?.track, let player = self?.player else {
				return
			}
			
			switch $0 {
			case .absolute(let position):
				if track.id == player.current?.id {
					try? player.singlePlayer.playing?.move(to: TimeInterval(position))
				}
				else {
					player.play(track, at: TimeInterval(position))
				}
			case .relative(let movement):
				try? player.singlePlayer.playing?.move(by: TimeInterval(movement))
			}
		}

		positionControl.useJumpInterval = {
			!NSEvent.modifierFlags.contains(.option)
		}

		positionControl.locationProvider = { [weak self] in
			guard let player = self?.player else { return nil }
			
			return player.current?.id == self?.track?.id
				? player.singlePlayer.playing?.currentTime.map { CGFloat($0) }
				: nil
		}
		
		func observeAttribute<TK: TypedKey & TrackAttribute>(_ attribute: TK) -> AnyPublisher<TrackAttributes.ValueSnapshot<TK.Value>, Never> {
			$track
				.flatMap { track -> AnyPublisher<TrackAttributes.ValueSnapshot<TK.Value>, Never> in
					guard let track = track else {
						return Just(TrackAttributes.ValueSnapshot(nil, state: .valid))
							.eraseToAnyPublisher()
					}
					
					return track.attribute(attribute)
						.attach(track.demand([attribute]))
						.eraseToAnyPublisher()
				}
				.onMain()
				.eraseToAnyPublisher()
		}
		
		waveformObserver = observeAttribute(TrackAttribute.waveform)
			.sink { [weak self] waveform in
				self?.waveformView.waveform = waveform.value ?? .empty
			}

		durationObserver = observeAttribute(TrackAttribute.duration)
			.sink { [weak self] duration in
				self?.positionControl.range = 0...(duration.value.map { CGFloat($0)} ?? 1)
			}

		tempoObserver = observeAttribute(TrackAttribute.tempo)
			.sink { [weak self] tempo in
				self?.positionControl.jumpInterval = (tempo.value?.phraseSeconds).map { CGFloat($0) }
			}
		
		super.sharedInit()
	}
	
	private var waveformObserver: AnyCancellable?
	private var durationObserver: AnyCancellable?
	private var tempoObserver: AnyCancellable?
}
