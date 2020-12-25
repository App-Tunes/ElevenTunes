//
//  Track+Attributes.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 25.12.20.
//

import Foundation

extension Track {
    class AttributeKey: RawRepresentable, Hashable {
        let rawValue: String
        
        required init(rawValue: String) {
            self.rawValue = rawValue
        }
    }
}

extension Track.AttributeKey {
    class Title: Track.AttributeKey, TypedKey {
        typealias Value = String
    }
    
    static let title = Title(rawValue: "title")
}

