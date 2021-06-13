//
//  LibraryFileCaches.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 04.04.21.
//

import Foundation

class LibraryFileCaches {
	let avPreviewImages: ImageDatabase<UUID>
	let avWaveforms: WaveformDatabase<UUID>

	init(url: @escaping () -> URL?) {
		let imagesURL = { url()?.appendingPathComponent("images") }
		let waveformsURL = { url()?.appendingPathComponent("waveforms") }

		avPreviewImages = .init(
			urlProvider: { imagesURL()?.appendingPathComponent("av-preview") },
			size: (128, 128),
			fileExtension: "tiff"
		) {
			$0.tiffRepresentation(using: .lzw, factor: 0.6)
		}
		
		avWaveforms = .init(
			urlProvider: { waveformsURL()?.appendingPathComponent("av") }
		)
	}
}
