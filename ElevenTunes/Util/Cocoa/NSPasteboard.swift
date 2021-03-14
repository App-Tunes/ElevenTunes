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

	func loadFirstData(forType type: UTType) throws -> Data {
		guard let strictType = (types ?? []).first(where: {
			UTType($0.rawValue)?.conforms(to: type) ?? false
		}) else {
			throw MissingError()
		}
		
		return try self.data(forType: strictType).unwrap(orThrow: MissingError())
	}
}

extension NSPasteboardItem {
	func loadData(forType type: UTType) throws -> Data {
		guard let strictType = types.first(where: {
			UTType($0.rawValue)?.conforms(to: type) ?? false
		}) else {
			throw NSPasteboard.MissingError()
		}
		
		return try self.data(forType: strictType).unwrap(orThrow: NSPasteboard.MissingError())
	}
}
