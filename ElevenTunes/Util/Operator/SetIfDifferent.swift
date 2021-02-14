//
//  SetIfDifferent.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 07.01.21.
//

import Foundation

//infix operator ?=: AssignmentPrecedence
//
// F in the chat boys, this doesn't work because of copy-in copy-out
//func ?=<T: Equatable>(lhs: inout T, rhs: T) {
//    if lhs != rhs {
//		lhs = rhs
//	}
//}

/// Now what the fuck do you need this for?
/// It's shorthand for updating a value if it's changed.
///  This is super useful when you have change observers,
///  but you don't know yet if the value has even changed.
func setIfDifferent<O, T: Equatable>(_ lhs: inout O, _ v: WritableKeyPath<O, T>, _ rhs: T) {
	if lhs[keyPath: v] != rhs {
		lhs[keyPath: v] = rhs
	}
}

func setIfDifferent<O, T: Equatable>(_ lhs: O, _ v: ReferenceWritableKeyPath<O, T>, _ rhs: T) {
	if lhs[keyPath: v] != rhs {
		lhs[keyPath: v] = rhs
	}
}
