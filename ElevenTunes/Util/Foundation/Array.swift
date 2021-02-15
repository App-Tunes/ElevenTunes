//
//  Array.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 20.12.20.
//

import Foundation

extension Array {
    public subscript(index: Int, default defaultValue: @autoclosure () -> Element) -> Element {
        guard index >= 0, index < endIndex else {
            return defaultValue()
        }

        return self[index]
    }

    mutating func popFirst() -> Element? {
        if isEmpty { return nil}
        return removeFirst()
    }
    
    mutating func prepend(_ element: Element) {
        self = [element] + self
    }
    
    func removeDuplicates<T: Hashable>(by: (Element) -> T) -> [Element] {
        var result = [Element]()
        var set = Set<T>()

        for value in self {
            if set.insert(by(value)).inserted {
                result.append(value)
            }
        }

        return result
    }
    	
	func moving(fromOffsets src: IndexSet, toOffset dst: Int) -> [Element] {
		var copy = self
		copy.move(fromOffsets: src, toOffset: dst)
		return copy
	}
	
	mutating func insert<C: Collection>(contentsOf collection: C, at index: Int?) where C.Element == Element {
		if let index = index {
			insert(contentsOf: collection, at: index)
		}
		else {
			self = self + collection
		}
	}
	
	func inserting<C: Collection>(contentsOf collection: C, at index: Int?) -> Array where C.Element == Element {
		var copy = self
		copy.insert(contentsOf: collection, at: index)
		return copy
	}
}

extension Array where Element: Hashable {
    func removeDuplicates() -> [Element] {
        var result = [Element]()
        var set = Set<Element>()

        for value in self {
            if set.insert(value).inserted {
                result.append(value)
            }
        }

        return result
    }
}
