//
//  Array.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 20.12.20.
//

import Foundation

extension Array {
    mutating func popFirst() -> Element? {
        if isEmpty { return nil}
        return removeFirst()
    }
}
