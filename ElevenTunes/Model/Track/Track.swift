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
    private let attributes: TypedDict<Track.AttributeKey>
    
    init(_ backend: TrackBackend?, attributes: TypedDict<Track.AttributeKey>) {
        self.backend = backend
        self.attributes = attributes
        backend?.frontend = self
    }
    
    subscript<T>(_ attribute: TypedKey<AttributeKey, T>) -> T? {
        return self.attributes[attribute]
    }
    
    var icon: Image { backend?.icon ?? Image(systemName: "music.note") }
}

extension Track {
    final class AttributeKey: Hashable {
        let id: String
        
        init(_ id: String) {
            self.id = id
        }
        
        static func == (lhs: AttributeKey, rhs: AttributeKey) -> Bool {
            lhs.id == rhs.id
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(self.id)
        }
    }
}

extension AnyTypedKey {
    static let ttitle = TypedKey<Track.AttributeKey, String>(.init("Title"))
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

extension Track: CustomStringConvertible {
    var description: String {
        self[.ttitle] ?? "Unknown Track"
    }
}
