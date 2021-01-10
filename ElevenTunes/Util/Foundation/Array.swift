//
//  Array.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 20.12.20.
//

import Foundation

extension Array {
    public subscript(safe index: Int) -> Element? {
        guard index >= 0, index < endIndex else {
            return nil
        }

        return self[index]
    }

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
    
    func explodeMap<T>(_ map: (Element) -> T?) -> [T]? {
        let map = compactMap(map)
        return map.count == count ? map : nil
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
