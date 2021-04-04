//
//  Hasher.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 08.01.21.
//

import Foundation

extension Hasher {
    static func combine<T: Hashable>(_ values: [T]) -> Int {
        var hasher = Hasher()
        values.forEach { hasher.combine($0) }
        return hasher.finalize()
    }
}
