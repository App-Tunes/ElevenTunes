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
	
	var one : Element? {
		count == 1 ? first! : nil
	}
	
	func noneSatisfy(_ predicate: (Self.Element) throws -> Bool) rethrows -> Bool {
		try allSatisfy { try !predicate($0) }
	}
	
	func anySatisfy(_ predicate: (Self.Element) throws -> Bool) rethrows -> Bool {
		try contains(where: predicate)
	}
}
