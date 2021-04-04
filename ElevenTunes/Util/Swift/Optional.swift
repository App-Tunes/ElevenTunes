//
//  Optional.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 01.01.21.
//

extension Optional {
    func unwrap(orThrow error: @autoclosure () -> Error) throws -> Wrapped {
        switch self {
        case .some(let w): return w
        case .none: throw error()
        }
    }
}
