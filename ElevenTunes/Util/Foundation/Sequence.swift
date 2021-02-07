//
//  Sequence.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 27.12.20.
//

import Foundation

func flatSequence<T>(first: [T], next: @escaping (T) -> [T]) -> UnfoldSequence<T, [T]> {
    sequence(state: first) { state in
        guard let object = state.popLast() else {
            return nil
        }
        state += next(object)
        return object
    }
}
