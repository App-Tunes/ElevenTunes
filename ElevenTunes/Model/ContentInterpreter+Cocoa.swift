//
//  ContentInterpreter+Cocoa.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 14.02.21.
//

import Cocoa
import Combine
import UniformTypeIdentifiers

extension ContentInterpreter {
	func interpret(pasteboard: NSPasteboard) -> [Interpreted]? {
		pasteboard.pasteboardItems?
			.compactMap(self.interpret)
			.nonEmpty
	}
	
	func interpret(pasteboardItem item: NSPasteboardItem) -> Interpreted? {
		self.types.compactMap { type in
			(try? item.loadData(forType: type)).flatMap { data in
				try? self.interpret(data as NSSecureCoding, type: type)
			}
		}.first
	}
}
