//
//  EssentiaAnalyzer.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 03.04.21.
//

import Foundation
import Combine
import TunesLogic

class EssentiaAnalyzer: TrackAlgorithm {
	let track: AVTrack
	
	init(track: AVTrack) {
		self.track = track
	}
	
	static func parseKey(_ analysis: EssentiaKeyAnalysis) -> MusicalKey? {
		guard
			let keyString = analysis.key,
			let scaleString = analysis.scale,
			let note = MusicalNote.parse(keyString),
			let mode = MusicalMode.byString[scaleString]
		else {
			return nil
		}
		
		return MusicalKey(note: note, mode: mode)
	}
	
	func run() -> AnyPublisher<TrackAttributes.PartialGroupSnapshot, Error> {
		let url = track.url
		
		return Future.tryOnQueue(.global(qos: .default)) {
			AppDelegate.essentiaWork.wait()
			defer { AppDelegate.essentiaWork.signal() }
			
			let file = EssentiaFile(url: url)
			let analysis = try AppDelegate.heavyWork.waitAndDo {
				try file.analyze()
			}
			let keyAnalysis = analysis.keyAnalysis!
			let rhythmAnalysis = analysis.rhythmAnalysis!

			return .init(.unsafe([
				// TODO lol parse these separately
				.key: Self.parseKey(keyAnalysis),
				.tempo: Tempo(beatsPerMinute: rhythmAnalysis.bpm)
			]), state: .valid)
		}
			.eraseError().eraseToAnyPublisher()
	}
}
