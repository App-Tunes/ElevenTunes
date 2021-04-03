//
//  Collection.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 14.02.21.
//

import Foundation

extension Collection {
	/// Returns the element at the specified index if it is within bounds, otherwise nil.
	subscript (safe index: Index) -> Element? {
		indices.contains(index) ? self[index] : nil
	}
	
	func explodeMap<T>(_ map: (Element) -> T?) -> [T]? {
		let map = compactMap(map)
		return map.count == count ? map : nil
	}

	var one: Element? {
		count == 1 ? first! : nil
	}
	
	var nonEmpty: Self? {
		isEmpty ? nil : self
	}

	func noneSatisfy(_ predicate: (Self.Element) throws -> Bool) rethrows -> Bool {
		try allSatisfy { try !predicate($0) }
	}
	
	func anySatisfy(_ predicate: (Self.Element) throws -> Bool) rethrows -> Bool {
		try contains(where: predicate)
	}
}
