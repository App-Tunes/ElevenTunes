//
//  EssentiaAnalyzer.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 03.04.21.
//

import Foundation
import Combine

class EssentiaAnalyzer: TrackAlgorithm {
	let track: AVTrack
	
	init(track: AVTrack) {
		self.track = track
	}
	
	func run() -> AnyPublisher<TrackAttributes.PartialGroupSnapshot, Error> {
		let url = track.url
		
		return Future.tryOnQueue(.global(qos: .default)) {
			let file = EssentiaFile(url: url)
			let analysis = try AppDelegate.heavyWork.waitAndDo {
				try file.analyze()
			}
			let keyAnalysis = analysis.keyAnalysis!
			let rhythmAnalysis = analysis.rhythmAnalysis!

			return .init(.unsafe([
				// TODO lol parse these separately
				.key: MusicalKey.parse("\(keyAnalysis.key)\(keyAnalysis.scale)"),
				.tempo: Tempo(bpm: rhythmAnalysis.bpm)
			]), state: .valid)
		}
			.eraseError().eraseToAnyPublisher()
	}
}
