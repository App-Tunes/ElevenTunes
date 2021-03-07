//
//  ArrayDifference.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 07.03.21.
//

import Foundation

enum EditDifference {
	case remove(elements: [Int])
	case add(elements: [Int])
	
	var array: [Int] {
		switch self {
		case .remove(let elements):
			return elements
		case .add(let elements):
			return elements
		}
	}
}

extension Array where Element: Equatable {
	func editDifference(from: [Element]) -> EditDifference? {
		let leftSmaller = self.count < from.count
		let (left, right) = leftSmaller ? (self, from) : (from, self)
		var difference: [Int] = []
		difference.reserveCapacity(right.count - left.count)
		
		var rightIdx = -1
		
		for item in left {
			repeat {
				rightIdx += 1
				if rightIdx >= right.count {
					return nil
				}
				
				// Add current item
				if right[rightIdx] != item { difference.append(rightIdx) }
			}
				while right[rightIdx] != item
		}
		
		// Add the rest
		difference += Array<Int>((rightIdx + 1)..<right.count)
		
		return leftSmaller ? .add(elements: difference) : .remove(elements: difference)
	}
}
