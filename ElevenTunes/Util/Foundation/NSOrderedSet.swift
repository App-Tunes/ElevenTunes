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
}
