//
//  Tempo.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 02.01.21.
//

import SwiftUI

struct Tempo: Equatable {
    let bpm: Double
    
    init(bpm: Double) {
        self.bpm = bpm
    }
    
    var title: String {
		bpm.format(precision: 1)
    }
    
    var rotation: Double {
        log2(bpm).truncatingRemainder(dividingBy: 1)
    }
    
	var color: Color {
		Color(hue: rotation, saturation: 0.2, brightness: 0.75)
	}
		
	var nscolor: NSColor {
		NSColor(hue: CGFloat(rotation), saturation: 0.2, brightness: 0.75, alpha: 1)
	}
		
	var bps: Double { bpm / 60 }
	
	var phraseSeconds: TimeInterval {
		TimeInterval(1 / bps) * 16
	}
}
