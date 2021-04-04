//
//  Double.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 02.01.21.
//

extension Double {
    func format(precision: Int) -> String {
        String(format: "%.\(precision)f", self)
    }
	
	var truePositiveOrNil: Self? {
		return self > 0 ? self : nil
	}

	var positiveOrNil: Self? {
		return self >= 0 ? self : nil
	}

	var nonZeroOrNil: Self? {
		return self != 0 ? self : nil
	}
}
