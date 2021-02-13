//
//  NSOrderedSet.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 25.12.20.
//

import Foundation

extension NSOrderedSet {
    static func +<T>(lhs: NSOrderedSet, rhs: [T]) -> NSOrderedSet {
        return NSOrderedSet(array: lhs.array + rhs)
    }
	
	func moving(fromOffsets src: IndexSet, toOffset dst: Int) -> NSOrderedSet {
		NSOrderedSet(array: array.moving(fromOffsets: src, toOffset: dst))
	}
}
