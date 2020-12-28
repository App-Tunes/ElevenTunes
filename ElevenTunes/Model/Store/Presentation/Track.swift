//
//  TransientTrack.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 26.12.20.
//

import Foundation
import Combine
import SwiftUI

class Track: ObservableObject {
    var backend: AnyTrack
    
    init(_ backend: AnyTrack) {
        self.backend = backend
        
        backend.cacheMask.assign(to: &$cacheMask)
        backend.attributes.assign(to: &$attributes)
    }
    
    var id: String { backend.id }

    @Published var cacheMask: TrackContentMask = []
    
    @Published var attributes: TypedDict<TrackAttribute> = .init()

    func emitter(context: PlayContext) -> AnyPublisher<AnyAudioEmitter, Error> {
        backend.emitter(context: context)
    }

    var icon: Image { backend.icon }
    
    func load(atLeast mask: TrackContentMask, library: Library) {
        let missing = mask.subtracting(cacheMask)
        guard !missing.isEmpty else {
            return
        }
        
        backend.load(atLeast: missing, library: library)
    }

    func invalidateCaches(_ mask: TrackContentMask) {
        cacheMask.subtract(mask)  // Let's immediately invalidate ourselves
        backend.invalidateCaches(mask)
    }

    subscript<T: TrackAttribute & TypedKey>(_ attribute: T) -> T.Value? {
        attributes[attribute]
    }
}

extension Track: Hashable, Identifiable {
    static func == (lhs: Track, rhs: Track) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension Track {
    static let defaultIcon: Image = Image(systemName: "music.note")
}
