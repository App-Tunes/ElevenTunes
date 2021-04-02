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
		let wmax = waveform.integratedLoudness + 6
		let wmin = waveform.integratedLoudness - waveform.loudnessRange - 6
		let range = wmax - wmin

		return Waveform(
			loudness: Array(UnsafeBufferPointer(start: waveform.loudness, count: Int(waveform.count)))
				.map { ($0 - wmin) / range }, // In LUFS. 23 is recommended standard. We'll use -40 as absolute 0.
			pitch: Array(UnsafeBufferPointer(start: waveform.pitch, count: Int(waveform.count)))
				.map { (log(max(1, $0) / 3000) + 2) / 2 }  // in frequency space: log(40 / 3000) ~ -2
		)
	}
}