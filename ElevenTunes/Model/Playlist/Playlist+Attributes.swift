//
//  Playlist+Attributes.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 25.12.20.
//

import Foundation

public class PlaylistAttribute: RawRepresentable, Hashable {
    class Typed<K>: PlaylistAttribute, TypedKey, CustomStringConvertible {
        typealias Value = K
        var description: String { rawValue }
    }

    public let rawValue: String
    
    public required init(rawValue: String) {
        self.rawValue = rawValue
    }
}

extension PlaylistAttribute {
    static let title = Typed<String>(rawValue: "title")
}
