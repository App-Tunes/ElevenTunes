//
//  Set.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 28.12.20.
//

extension Set {
	/// Useful for selections: Assuming the element is part of the group,
	/// return either just the element, or the whole group.
	func allIfContains(_ element: Element) -> Set {
		contains(element) ? self : [element]
	}
}
