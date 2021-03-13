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

	var pitchClass: Int { rawValue }
	
	var title: String { Self.titles[rawValue] }
}

enum MusicalMode {
	case major, minor
	
	var shorthand: String {
		switch self {
		case .major:
			return "d"
		case .minor:
			return "m"
		}
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
	
	var title: String { note.title + mode.shorthand }

	var openKeyNotation: Int {
		((note.pitchClass + mode.shiftToMajor) * 7) % 12 + 1
	}
    
	var color: Color { Self.colors[openKeyNotation - 1] }
}
