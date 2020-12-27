//
//  Environment.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 25.12.20.
//

import Foundation
import SwiftUI

struct LibraryEnvironmentKey: EnvironmentKey {
    static let defaultValue: Library? = nil
}

extension EnvironmentValues {
    var library: Library? {
        get { self[LibraryEnvironmentKey] }
        set { self[LibraryEnvironmentKey] = newValue }
    }
}
