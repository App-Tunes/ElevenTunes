//
//  TransientTrack.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 26.12.20.
//

import Foundation
import Combine
import SwiftUI

class Track: AnyTrack, ObservableObject {
    var backend: AnyTrack
    
    init(_ backend: AnyTrack) {
        self.backend = backend
        
        loadLevel = backend.loadLevel
        attributes = backend.attributes
        
        backend.loadLevel.assign(to: &$_loadLevel)
        backend.attributes.assign(to: &$_attributes)
    }
    
    var id: String { backend.id }

    @Published var _loadLevel: LoadLevel = .none
    var loadLevel: AnyPublisher<LoadLevel, Never>
    
    @Published var _attributes: TypedDict<TrackAttribute> = .init()
    var attributes: AnyPublisher<TypedDict<TrackAttribute>, Never>

    func emitter(context: PlayContext) -> AnyPublisher<AnyAudioEmitter, Error> {
        backend.emitter(context: context)
    }

    var icon: Image { backend.icon }
    
    @discardableResult
    func load(atLeast level: LoadLevel, library: Library) -> Bool {
        backend.load(atLeast: level, library: library)
    }

    subscript<T: TrackAttribute & TypedKey>(_ attribute: T) -> T.Value? {
        _attributes[attribute]
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
