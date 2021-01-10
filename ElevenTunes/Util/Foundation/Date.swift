//
//  Date.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 08.01.21.
//

import Foundation

extension Date {
    static let isoFormatter = ISO8601DateFormatter()
    
    var isoFormat: String {
        Date.isoFormatter.string(from: self)
    }
}
