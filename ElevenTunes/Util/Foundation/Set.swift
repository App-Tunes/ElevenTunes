//
//  Set.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 28.12.20.
//

import Foundation

extension Set {
	func allIfContains(_ element: Element) -> Set {
		contains(element) ? self : [element]
	}
}

extension Collection {
    var one: Element? { count == 1 ? first : nil }
}
