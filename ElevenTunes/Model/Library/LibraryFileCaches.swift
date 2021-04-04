//
//  LibraryFileCaches.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 04.04.21.
//

import Foundation

class LibraryFileCaches {
	let avPreviewImages: ImageDatabase<UUID>
	
	init(url: @escaping () -> URL?) {
		let imagesURL = { url()?.appendingPathComponent("images") }
		
		avPreviewImages = .init(
			urlProvider: { imagesURL()?.appendingPathComponent("av-preview") },
			size: (128, 128)
		)
	}
}
