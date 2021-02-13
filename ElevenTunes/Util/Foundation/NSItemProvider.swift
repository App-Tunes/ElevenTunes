//
//  NSItemProvider.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 13.02.21.
//

import Foundation

extension NSItemProvider {
	/// For the lazy where the item is quick to load
	open func registerDataRepresentation(forTypeIdentifier typeIdentifier: String, visibility: NSItemProviderRepresentationVisibility, provider: @escaping () throws -> Data) {
		registerDataRepresentation(forTypeIdentifier: typeIdentifier, visibility: visibility) { cb in
			let progress = Progress.discreteProgress(totalUnitCount: 1)
			DispatchQueue.global(qos: .userInitiated).async {
				do {
					let data = try provider()
					cb(data, nil)
				}
				catch let error {
					cb(nil, error)
				}
				progress.completedUnitCount += 1
			}
			return progress
		}
	}
	
	/// 0-entry item providers are not allowed, but it is not possible to return nil in some provider contexts.
	/// Thus this ugly hack.
	func registerDummyIfNeeded() {
		if registeredTypeIdentifiers.count == 0 {
			registerDataRepresentation(forTypeIdentifier: "dummy.emptydata", visibility: .ownProcess) {
				Data()
			}
		}
	}
}
