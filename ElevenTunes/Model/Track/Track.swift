//
//  Track.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 18.12.20.
//

import Foundation
import SwiftUI

class Track {
    var backend: TrackBackend?
    
    let id = UUID()
    private let attributes: TypedDict<AttributeKey>

    init(_ backend: TrackBackend?, attributes: TypedDict<Track.AttributeKey>) {
        self.backend = backend
        self.attributes = attributes
    }
    
    subscript<T: AttributeKey & TypedKey>(_ attribute: T) -> T.Value? {
        return self.attributes[attribute]
    }
    
    var icon: Image { backend?.icon ?? Image(systemName: "music.note") }
}

extension Track: Hashable, Identifiable {
    static func == (lhs: Track, rhs: Track) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}

extension Track: ObservableObject {
    
}

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

