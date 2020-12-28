//
//  Button.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 28.12.20.
//

import Foundation
import SwiftUI

extension Button where Label == Text {
    static func invisible(_ action: @escaping () -> Void) -> AnyView {
        AnyView(Button("", action: action)
            .buttonStyle(BorderlessButtonStyle())
            .frame(width: 0, height: 0))
    }
}
