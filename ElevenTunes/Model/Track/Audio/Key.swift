//
//  Key.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 02.01.21.
//

import TunesLogic
import SwiftUI

extension MusicalKey {
	static let colors: [Color] = (0..<12).map {
		// / 12 * 5 gives close representations to notes being quint / quart apart
		Color(hue: Double($0) / 12 * 5, saturation: 0.5, brightness: 0.75)
	}
	static let nscolors: [NSColor] = (0..<12).map {
		NSColor(hue: (CGFloat($0) / 12 * 5).truncatingRemainder(dividingBy: 1), saturation: 0.5, brightness: 0.75, alpha: 1)
	}

	/// Like open key notation, but 0-11 for proper indexing
	var likenessIndex: Int {
		CircleOfFifths.camelot.index(of: self)
	}
	    
	var color: Color { Self.colors[likenessIndex] }

	var nscolor: NSColor { Self.nscolors[likenessIndex] }
}
