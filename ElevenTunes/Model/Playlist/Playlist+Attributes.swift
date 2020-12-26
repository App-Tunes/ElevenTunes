//
//  Playlist+Attributes.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 25.12.20.
//

import Foundation

class PlaylistAttribute: RawRepresentable, Hashable {
    class Typed<K>: PlaylistAttribute, TypedKey {
        typealias Value = K
    }

    let rawValue: String
    
    required init(rawValue: String) {
        self.rawValue = rawValue
    }
}

extension PlaylistAttribute {
    static let title = Typed<String>(rawValue: "title")
}
