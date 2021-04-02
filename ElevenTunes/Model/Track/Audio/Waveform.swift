//
//  Waveform.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 02.04.21.
//

import Foundation

struct Waveform {
	var loudness: [Float]
	var pitch: [Float]
	
	var count: Int { min(loudness.count, pitch.count) }
	
	static func from(_ waveform: EssentiaWaveform) -> Waveform {
		let range = waveform.loudnessRange * 1.3
		let min = waveform.integratedLoudness - range

		return Waveform(
			loudness: Array(UnsafeBufferPointer(start: waveform.loudness, count: Int(waveform.count)))
				.map { ($0 - min) / range }, // In LUFS. 23 is recommended standard. We'll use -40 as absolute 0.
			pitch: Array(UnsafeBufferPointer(start: waveform.pitch, count: Int(waveform.count)))
				.map { (log(max(1, $0) / 5000) + 2.4) / 2.4 }  // in frequency space: log(20 / 5000) = 2.4
		)
	}
}
