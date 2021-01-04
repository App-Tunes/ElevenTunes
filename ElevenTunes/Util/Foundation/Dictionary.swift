//
//  Dictionary.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 04.01.21.
//

import Foundation

extension Dictionary {
    mutating func get(_ key: Key, insertingDefault closure: @autoclosure () -> Value) -> Value {
        if let value = self[key] {
            return value
        }
        
        let value = closure()
        self[key] = value
        return value
    }
}
