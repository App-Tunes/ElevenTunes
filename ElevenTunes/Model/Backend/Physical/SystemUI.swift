//
//  SystemUI.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 01.01.21.
//

import SwiftUI

class SystemUI {
    static let pureColor: Color = .accentColor
    static let color: Color = Color(hue: Double(pureColor.hsva.hue), saturation: Double(pureColor.hsva.saturation / 3 * 2), brightness: Double(pureColor.hsva.value))
}
