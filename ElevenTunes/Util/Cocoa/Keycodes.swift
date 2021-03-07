//
//  Keycodes.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 14.02.21.
//

import Foundation

enum Keycodes: Int {
	case returnKey = 36, enterKey = 76
	case delete = 51, forwardDelete = 117
	
	struct Either {
		static let enter = Either([Keycodes.returnKey, Keycodes.enterKey])
		static let delete = Either([Keycodes.delete, Keycodes.forwardDelete])
		
		let codes: [Keycodes]
		
		init(_ codes: [Keycodes]) {
			self.codes = codes
		}
		
		func matches(event: NSEvent) -> Bool {
			codes.anySatisfy { $0.matches(event: event) }
		}
	}

	func matches(event: NSEvent) -> Bool {
		return event.keyCode == UInt16(self.rawValue)
	}
}
