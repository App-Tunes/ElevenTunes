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
		guard let strictType = (types ?? []).first(where: {
			UTType($0.rawValue)?.conforms(to: type) ?? false
		}) else {
			return Future { throw MissingError() }
		}
		
		return Future {
			try self.data(forType: strictType).unwrap(orThrow: MissingError()) as NSSecureCoding
		}
	}
}
