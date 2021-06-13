//
//  Waveform.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 02.04.21.
//

import Foundation
import TunesUI

extension Waveform {
	static let desiredLength = 256
	
	static func from(_ waveform: EssentiaWaveform) -> Waveform {
		let wmax = waveform.integratedLoudness + 6
		let wmin = waveform.integratedLoudness - waveform.loudnessRange - 6
		let range = wmax - wmin

		return Waveform.init(
			loudness: Array(UnsafeBufferPointer(start: waveform.loudness, count: Int(waveform.count)))
				.map { max(0, min(1, ($0 - wmin) / range)) }, // In LUFS. 23 is recommended standard. We'll use -40 as absolute 0.
			pitch: Array(UnsafeBufferPointer(start: waveform.pitch, count: Int(waveform.count)))
				.map { max(0, min(1, (log(max(10, $0) / 3000) + 2) / 2)) }  // in frequency space: log(40 / 3000) ~ -2
		)
	}
}

extension ByteWaveform {
	init(_ waveform: Waveform) {
		self.init()
		loudness = Data(bytes: waveform.loudness.map { UInt8(round($0 * 255)) }, count: waveform.count)
		pitch = Data(bytes: waveform.pitch.map { UInt8(round($0 * 255)) }, count: waveform.count)
	}
	
	var asWaveform: Waveform {
		Waveform(
			loudness: loudness.map { Float($0) / 255 },
			pitch: pitch.map { Float($0) / 255 }
		)
	}
}
