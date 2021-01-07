//
//  SetIfDifferent.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 07.01.21.
//

import Foundation

/// Now what the fuck do you need this for?
/// It's shorthand for updating a value if it's changed.
///  This is super useful when you have change observers,
///  but you don't know yet if the value has even changed.
infix operator ?=: AssignmentPrecedence

func ?=<T: Equatable>(lhs: inout T, rhs: T) {
    if lhs != rhs { lhs = rhs }
}
