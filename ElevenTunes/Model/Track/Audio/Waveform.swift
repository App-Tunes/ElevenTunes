//
//  Waveform.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 02.04.21.
//

import Foundation
import TunesUI

extension Waveform {
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

extension Waveform {
	struct ByteRepresentation: Codable {
		public var loudness: [UInt8]
		public var pitch: [UInt8]
		
		public var count: Int { min(loudness.count, pitch.count) }
		
		public init(_ waveform: Waveform) {
			loudness = waveform.loudness.map { UInt8(round($0 * 255)) }
			pitch = waveform.pitch.map { UInt8(round($0 * 255)) }
		}
		
		public var asWaveform: Waveform {
			Waveform(
				loudness: loudness.map { Float($0) / 255 },
				pitch: pitch.map { Float($0) / 255 }
			)
		}
	}
}
