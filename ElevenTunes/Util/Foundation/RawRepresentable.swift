//
//  RawRepresentable.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 27.12.20.
//

import Foundation

public func < <T: RawRepresentable>(lhs: T, rhs: T) -> Bool where T.RawValue: Comparable {
    return lhs.rawValue < rhs.rawValue
}
