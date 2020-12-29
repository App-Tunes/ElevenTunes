//
//  AnyTrack.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 25.12.20.
//

import Foundation
import SwiftUI
import Combine

public struct TrackContentMask: OptionSet, Hashable {
    public let rawValue: Int16
    
    public init(rawValue: Int16) {
        self.rawValue = rawValue
    }
    
    static let minimal = TrackContentMask(rawValue: 1 << 0)
    // More to come? In any case, bools aren't more efficient anyway
}

public protocol AnyTrack: AnyObject {
    var id: String { get }
    
    var cacheMask: AnyPublisher<TrackContentMask, Never> { get }
    var attributes: AnyPublisher<TypedDict<TrackAttribute>, Never> { get }

    func emitter(context: PlayContext) -> AnyPublisher<AnyAudioEmitter, Error>
    var icon: Image { get }
    
    func load(atLeast level: TrackContentMask, library: Library)
    
    func invalidateCaches(_ mask: TrackContentMask)
}

class TrackBackendTypedCodable: TypedCodable<String> {
    static let _registry = CodableRegistry<String>()
        .register(MockTrack.self, for: "mock")
        .register(FileTrack.self, for: "file")
        .register(FileVideo.self, for: "videofile")
        .register(SpotifyTrack.self, for: "spotify")

    override class var registry: CodableRegistry<String> { _registry }
}

@objc(TrackBackendTransformer)
class TrackBackendTransformer: TypedJSONCodableTransformer<String, TrackBackendTypedCodable> {}

extension NSValueTransformerName {
    static let trackBackendName = NSValueTransformerName(rawValue: "TrackBackendTransformer")
}
