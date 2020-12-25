//
//  Environment.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 25.12.20.
//

import Foundation
import SwiftUI

struct SpotifyEnvironmentKey: EnvironmentKey {
    static let defaultValue: Spotify? = nil
}

struct InterpreterEnvironmentKey: EnvironmentKey {
    static let defaultValue: ContentInterpreter? = nil
}

extension EnvironmentValues {
    var spotify: Spotify? {
        get { self[SpotifyEnvironmentKey] }
        set { self[SpotifyEnvironmentKey] = newValue }
    }

    var interpreter: ContentInterpreter? {
        get { self[InterpreterEnvironmentKey] }
        set { self[InterpreterEnvironmentKey] = newValue }
    }
}
