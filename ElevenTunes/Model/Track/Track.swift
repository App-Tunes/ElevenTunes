//
//  Track.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 18.12.20.
//

import Foundation

class Track {
    var backend: TrackBackend?
    
    let id = UUID()
    private let attributes: TypedDict<Track.AttributeKey>
    
    init(_ backend: TrackBackend?, attributes: TypedDict<Track.AttributeKey>) {
        self.backend = backend
        self.attributes = attributes
    }
    
    subscript<T>(_ attribute: TypedKey<AttributeKey, T>) -> T {
        return self.attributes[attribute]
    }    
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
