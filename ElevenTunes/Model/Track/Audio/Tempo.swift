//
//  Tempo.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 02.01.21.
//

import TunesLogic
import SwiftUI

extension Tempo {
	var title: String {
		beatsPerMinute.format(precision: 1)
	}
	
	var color: Color {
		Color(hue: rotation, saturation: 0.2, brightness: 0.75)
	}
		
	var nscolor: NSColor {
		NSColor(hue: CGFloat(rotation), saturation: 0.2, brightness: 0.75, alpha: 1)
	}
}
