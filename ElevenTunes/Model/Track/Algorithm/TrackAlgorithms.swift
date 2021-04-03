//
//  TrackAlgorithms.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 03.04.21.
//

import Foundation
import Combine

protocol TrackAlgorithm {
	func run() -> AnyPublisher<TrackAttributes.PartialGroupSnapshot, Error>
}

class TrackAlgorithms {
	static func `for`<S>(_ tracks: S) -> [(String, [TrackAlgorithm])] where S: Collection, S.Element == AnyTrack {
		var algorithms: [(String, [TrackAlgorithm])] = []
		
		if let avTracks = tracks.compactMap({
			$0.allRepresentations.compactMap { $0 as? AVTrack }.first
		}).nonEmpty {
			algorithms.append(("Files (Essentia)", avTracks.map {
				EssentiaAnalyzer(track: $0) as TrackAlgorithm
			}))
		}
		
		return algorithms
	}
	
	static func run(_ algorithms: [TrackAlgorithm]) {
		for algorithm in algorithms {
			algorithm.run()
			.sink { value in
				// TODO
			}
			.store(in: &AlgorithmRunner.cancellables)
		}
	}
}
