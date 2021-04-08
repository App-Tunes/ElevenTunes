//
//  Key.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 02.01.21.
//

import Foundation
import SwiftUI

enum MusicalNote: Int, CaseIterable {
	case C, Db, D, Eb, E, F, Gb, G, Ab, A, Bb, B

	static let titles = [
		"C", "D♭", "D", "E♭", "E",
		"F", "G♭", "G", "A♭", "A", "B♭", "B"
	]
		
	static let byPitchClass = allCases
	
	init?(pitchClass: Int) {
		self.init(rawValue: pitchClass)
	}
	
	static func parse<S: StringProtocol>(_ string: S) -> MusicalNote? {
		switch string.lowercased() {
		case "a":
			return .A
		case "a#", "bb":
			return .Bb
		case "b":
			return .B
		case "c":
			return .C
		case "c#", "db":
			return .Db
		case "d":
			return .D
		case "d#", "eb":
			return .Eb
		case "e":
			return .E
		case "f":
			return .F
		case "f#", "gb":
			return .Gb
		case "g":
			return .G
		case "g#", "ab":
			return .Ab
		default:
			break
		}
		
		return nil
	}

	var pitchClass: Int { rawValue }
	
	var title: String { Self.titles[rawValue] }
}

enum MusicalMode: CaseIterable {
	case major, minor
	
	static let byShorthand: [String: MusicalMode] = [
		"maj": .major,
		"min": .minor,
		"d": .major,
		"m": .minor
	]
	
	var shorthand: String {
		return [
			.major: "d",
			.minor: "m"
		][self]!
	}
	
	var shiftToMajor: Int {
		switch self {
		case .major:
			return 0
		case .minor:
			return 3
		}
	}
}

struct MusicalKey: Equatable {
	let note: MusicalNote
	let mode: MusicalMode
	
	static let colors: [Color] = (0..<12).map {
		// / 12 * 5 gives close representations to notes being quint / quart apart
		Color(hue: Double($0) / 12 * 5, saturation: 0.5, brightness: 0.75)
	}
	static let nscolors: [NSColor] = (0..<12).map {
		NSColor(hue: (CGFloat($0) / 12 * 5).truncatingRemainder(dividingBy: 1), saturation: 0.5, brightness: 0.75, alpha: 1)
	}

	static func parse(_ toParse: String) -> MusicalKey? {
		if toParse.count == 0 {
			return nil
		}
		let string = toParse.lowercased()

		// Open Key?
		if string.last == "a" || string.last == "b", let openKey = Int(string.dropLast()) {
			let mode: MusicalMode = string.last == "a" ? .minor : .major
			guard let note = MusicalNote(pitchClass: ((openKey - 1) * 7) % 12 - mode.shiftToMajor) else {
				return nil
			}
			return MusicalKey(note: note, mode: mode)
		}
		
		// Camelot?
		if string.last == "m" || string.last == "d", let camelot = Int(string.dropLast()) {
			let mode: MusicalMode = string.last == "m" ? .minor : .major
			guard let note = MusicalNote(pitchClass: ((camelot - 1) * 7) % 12 - mode.shiftToMajor) else {
				return nil
			}
			return MusicalKey(note: note, mode: mode)
		}
		
		// Musical?
		for splitIndex in 1...min(2, string.count) {
			let strSplitIndex = string.index(string.startIndex, offsetBy: splitIndex)
			if
				let note = MusicalNote.parse(string[..<strSplitIndex]),
				let mode = (splitIndex == string.count) ? MusicalMode.major : MusicalMode.byShorthand[String(string[strSplitIndex...])]
			{
				return MusicalKey(note: note, mode: mode)
			}
		}
		
		return nil
	}

	var title: String { note.title + mode.shorthand }

	/// Like open key notation, but 0-11 for proper indexing
	var likenessIndex: Int {
		((note.pitchClass + mode.shiftToMajor) * 7) % 12
	}
	
	var openKeyNotation: Int {
		likenessIndex + 1
	}
    
	var color: Color { Self.colors[likenessIndex] }

	var nscolor: NSColor { Self.nscolors[likenessIndex] }
}
