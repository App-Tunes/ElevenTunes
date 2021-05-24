//
//  TrackAnalysisSnapshot.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 10.04.21.
//

import Foundation
import Combine
import TunesUI

class TrackAnalysisSnapshot: ObservableObject {
	static let attributes: Set<TrackAttribute> = [.tempo, .waveform, .duration]
	
	@Published var track: AnyTrack? = nil

	@Published var duration: TimeInterval? = nil
	@Published var tempo: Tempo? = nil

	@Published var waveform: Waveform? = nil

	private var trackObserver: AnyCancellable?
	private var attributesObserver: AnyCancellable?

	init<P: Publisher>(track: P) where P.Output == AnyTrack?, P.Failure == Never {
		trackObserver = track.sink { [weak self] in self?.track = $0 }
		attributesObserver = $track
			.flatMap { (track: AnyTrack?) in
				track?.attributes
					.attach(track?.demand(TrackAnalysisSnapshot.attributes))
					.filtered(toChanges: TrackAnalysisSnapshot.attributes)
					.map(Optional.some)
					.eraseToAnyPublisher()
					?? Just(nil).eraseToAnyPublisher()
			}.sink { [weak self] attributes in
				guard let self = self else { return }
				
				setIfDifferent(self, \.duration, attributes?[TrackAttribute.duration].value)
				setIfDifferent(self, \.tempo, attributes?[TrackAttribute.tempo].value)
				setIfDifferent(self, \.waveform, attributes?[TrackAttribute.waveform].value)
			}
	}
}
