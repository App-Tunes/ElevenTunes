//
//  Int.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 07.03.21.
//

import Foundation

extension Int {
	var positiveOrNil: Int? {
		return self >= 0 ? self : nil
	}
}
