//
//  NSRegularExpression.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 13.03.21.
//

import Foundation

extension NSRegularExpression {
	func matchStrings(in string: String) -> [String] {
		let results = matches(in: string, range: NSRange(string.startIndex..., in: string))
		return results.map {
			String(string[Range($0.range, in: string)!])
		}
	}

	func split(string: String) -> [String] {
		let results = matches(in: string, range: NSRange(string.startIndex..., in: string))
		let indices = [NSMakeRange(0, string.startIndex.utf16Offset(in: string))] + results.map { $0.range } + [NSMakeRange(string.endIndex.utf16Offset(in: string), 0)]
		
		return indices.neighbors.map { arg in
			let (prev, next) = arg
			let middle = NSMakeRange(prev.upperBound, next.lowerBound - prev.upperBound)
			return String(string[Range(middle, in: string)!])
		}
	}
}
