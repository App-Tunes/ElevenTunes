//
//  Key.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 02.01.21.
//

import Foundation
import SwiftUI

struct MusicalKey: Equatable {
    static let titles = [
        "C", "D♭", "D", "E♭", "E",
        "F", "G♭", "G", "A♭", "A", "B♭", "B"
    ]
    
    static let colors: [Color] = (0..<12).map {
        // / 12 * 5 gives close representations to notes being quint / quart apart
        Color(hue: Double($0) / 12 * 5, saturation: 0.5, brightness: 0.75)
    }
    
    var notation: Int
    
    init?(_ notation: Int) {
        guard notation >= 0 && notation < 12 else {
            return nil
        }
        
        self.notation = notation
    }
    
    var title: String { Self.titles[notation] }
    
    var color: Color { Self.colors[notation] }
}
