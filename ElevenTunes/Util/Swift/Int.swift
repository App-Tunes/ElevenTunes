//
//  Int.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 07.03.21.
//

extension BinaryInteger {
	var positiveOrNil: Self? {
		return self >= 0 ? self : nil
	}

	var nonZeroOrNil: Self? {
		return self != 0 ? self : nil
	}
}
