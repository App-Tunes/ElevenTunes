//
//  Tempo.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 02.01.21.
//

import SwiftUI

struct Tempo: Equatable {
    private let value: Double
    
    init(_ value: Double) {
        self.value = value
    }
    
    var title: String {
        value.format(precision: 1)
    }
    
    var rotation: Double {
        log2(value).remainder(dividingBy: 1)
    }
    
    var color: Color {
        Color(hue: rotation, saturation: 0.2, brightness: 0.75)
    }
	
	var bpm: Double { value }
	
	var bps: Double { value / 60 }
}
