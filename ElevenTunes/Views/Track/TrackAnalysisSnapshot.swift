//
//  TrackAnalysisSnapshot.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 10.04.21.
//

import Foundation
import Combine

class ResamplingWaveform: ObservableObject {
	@Published var source: Waveform = .empty
	@Published var desiredCount: Int = 0

	@Published var waveform: Waveform = .empty
	
	private var observer: AnyCancellable?

	init(debounce: TimeInterval) {
		observer = $source.combineLatest($desiredCount)
			.debounce(for: .seconds(debounce), scheduler: DispatchQueue.global(qos: .default))
			.removeDuplicates { l, r in
				l.0 == r.0 && l.1 == r.1
			}
			.map { [weak self] waveform, samples in
				guard let source = self?.source else { return Waveform.empty }
				
				return Waveform(
					loudness: (try? ResampleToSize.best(data: source.loudness, toSize: samples)) ?? [],
					pitch: (try? ResampleToSize.best(data: source.pitch, toSize: samples)) ?? []
				)
			}
			.onMain()
			.sink { [weak self] in
				self?.waveform = $0
			}
	}
	
	static func constant(_ waveform: Waveform) -> ResamplingWaveform {
		let rs = ResamplingWaveform(debounce: 0)
		rs.source = waveform
		rs.desiredCount = waveform.count
		return rs
	}
	
	func updateSamples(_ desired: Int) {
		setIfDifferent(self, \.desiredCount, desired)
	}
	
	var loudness: [Float] { waveform.loudness }
	var pitch: [Float] { waveform.pitch }
}

class TrackAnalysisSnapshot: ObservableObject {
	static let attributes: Set<TrackAttribute> = [.tempo, .waveform, .duration]
	
	@Published var track: AnyTrack? = nil

	@Published var duration: TimeInterval? = nil
	@Published var tempo: Tempo? = nil

	let waveform = ResamplingWaveform(debounce: 0.3)

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
				setIfDifferent(self.waveform, \.source, attributes?[TrackAttribute.waveform].value ?? .empty)
			}
	}
}
