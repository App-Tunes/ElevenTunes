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
		
	func inserting<C: Collection>(contentsOf collection: C, atIndex index: Int?) -> NSOrderedSet {
		let cArray = Array(collection)

		guard let index = index else {
			let left = mutableCopy() as! NSMutableOrderedSet
			left.minus(NSOrderedSet(array: cArray))
			return NSOrderedSet(array: left + cArray)
		}
				
		// Guaranteed to not contain the elements
		let left = NSMutableOrderedSet(array: Array(array[..<index]))
		left.minus(NSOrderedSet(array: cArray))
		
		let right = array[index...]
		
		// First objects trump latter, so right gets stripped of existing objects too
		return NSOrderedSet(array: left + cArray + right)
	}
}
