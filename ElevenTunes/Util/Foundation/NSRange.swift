//
//  NSRange.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 06.06.21.
//

import Foundation

extension NSRange {
	var asRange: Range<Int> { lowerBound ..< upperBound }
}
