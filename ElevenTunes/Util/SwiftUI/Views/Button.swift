//
//  Button.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 28.12.20.
//

import Foundation
import SwiftUI

extension Button where Label == Text {
    static func invisible(_ action: @escaping () -> Void) -> some View {
        Button("", action: action)
            .buttonStyle(InvisibleButtonStyle())
    }
}

struct InvisibleButtonStyle: ButtonStyle {
	func makeBody(configuration: Configuration) -> some View {
		configuration.label
			.frame(width: 0, height: 0)
	}
}

struct InfinityButtonStyle: ButtonStyle {
	func makeBody(configuration: Configuration) -> some View {
		configuration.label
			.frame(maxWidth: .infinity, maxHeight: .infinity)
	}
}
