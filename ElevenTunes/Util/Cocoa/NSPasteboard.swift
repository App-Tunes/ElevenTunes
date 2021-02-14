//
//  NSPasteboard.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 14.02.21.
//

import Cocoa
import Combine
import UniformTypeIdentifiers

extension NSPasteboard {
	class MissingError: Error { }

	func loadData(forType type: UTType) -> Future<NSSecureCoding, Error> {
		let pboardType = NSPasteboard.PasteboardType(rawValue: type.identifier)
		
		return Future {
			try self.data(forType: pboardType).unwrap(orThrow: MissingError()) as NSSecureCoding
		}
	}
}
