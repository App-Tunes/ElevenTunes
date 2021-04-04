//
//  Sequence.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 27.12.20.
//

/// Like sequence (unfold operation), but each element may return multiple elements
func flatSequence<T>(first: [T], next: @escaping (T) -> [T]) -> UnfoldSequence<T, [T]> {
    sequence(state: first) { state in
        guard let object = state.popLast() else {
            return nil
        }
        state += next(object)
        return object
    }
}
