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
	
	func editMovement(to: [Element]) -> [(Int, Int)]? {
		guard to.count == count else {
			return nil
		}
		
		// Direct approach
		guard to.count > 50 else {
			// Any more and it looks shit
			// Can reasonably do index(of)
			let indices = compactMap { to.firstIndex(of: $0) }
			// Everything has a unique index
			guard Set(indices).count == to.count else {
				return nil
			}
			var movement = indices.enumerated().map { ($0.0, $0.1) }
				//                .filter { $0.0 != $0.1 }
				.sorted { $0.1 < $1.1 }
			
			for i in 0..<movement.count {
				let (src, dst) = movement[i]
				movement[dst+1..<movement.count] = (movement[dst+1..<movement.count].map { (src2, dst2) in
					return (src2 + (src2 < src ? 1 : 0), dst2)
				}).fullSlice()
			}
			
			return movement.filter { $0.0 != $0.1 }
		}
		
		let (left, right) = (self, to)
		
		var leftIdx = 0
		var rightIdx = 0
		
		var bucket: [Int] = []
		var movements: [(Int, Int)] = []
		
		// We run through both lists, keeping an irregularity bucket
		// Whenever the objects aren't the same, we check if we can use the first bucket object -> Movement
		// Otherwise we put the current objects at the end of the bucket
		while leftIdx < right.count || rightIdx < right.count {
			if rightIdx < right.count, leftIdx < left.count, left[leftIdx] == right[rightIdx] {
				leftIdx += 1
				rightIdx += 1
			}
			else if rightIdx < right.count, let first = bucket.first, left[first] == right[rightIdx] {
				movements.append((bucket.removeFirst(), rightIdx))
				rightIdx += 1
			}
			else if leftIdx < left.count {
				bucket.append(leftIdx)
				leftIdx += 1
			}
			else {
				return nil
			}
		}
		
		return bucket.count == 0 ? movements.sorted { $0.1 > $1.1 } : nil
	}
}
