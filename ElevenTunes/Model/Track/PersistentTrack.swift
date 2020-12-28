//
//  PersistentTrack.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 27.12.20.
//

import Foundation
import Combine
import SwiftUI

public class PersistentTrack: NSObject, AnyTrack, Codable {
    public var id: String { fatalError() }
    
    public var icon: Image { Track.defaultIcon }
    
    public var cacheMask: AnyPublisher<TrackContentMask, Never> { fatalError() }
    
    public var attributes: AnyPublisher<TypedDict<TrackAttribute>, Never> { fatalError() }
    
    public func emitter(context: PlayContext) -> AnyPublisher<AnyAudioEmitter, Error> {
        fatalError()
    }
    
    public func load(atLeast mask: TrackContentMask, library: Library) {
        fatalError()
    }
    
    public func invalidateCaches(_ mask: TrackContentMask) { }
    
    // NSObject gedöns
    
    public override var hash: Int { id.hash }
    
    public override func isEqual(_ other: Any?) -> Bool {
        guard let other = other as? PersistentTrack else { return false }
        return self.id == other.id
    }
}

extension PersistentTrack: Identifiable { }
