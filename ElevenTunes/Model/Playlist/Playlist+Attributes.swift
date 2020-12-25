//
//  Playlist+Attributes.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 25.12.20.
//

import Foundation

extension Playlist {
    class AttributeKey: RawRepresentable, Hashable {
        let rawValue: String
        
        required init(rawValue: String) {
            self.rawValue = rawValue
        }
    }
}

extension Playlist.AttributeKey {
    class Title: Playlist.AttributeKey, TypedKey {
        typealias Value = String
    }
    
    static let title = Title(rawValue: "title")
}

