//
//  Track+Attributes.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 25.12.20.
//

import Foundation

class TrackAttribute: RawRepresentable, Hashable {
    class Typed<K>: TrackAttribute, TypedKey {
        typealias Value = K
    }

    let rawValue: String
    
    required init(rawValue: String) {
        self.rawValue = rawValue
    }
}

extension TrackAttribute {
    static let title = Typed<String>(rawValue: "title")
}
