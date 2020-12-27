//
//  AnyTrack.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 25.12.20.
//

import Foundation
import SwiftUI
import Combine

public protocol AnyTrack: AnyObject {
    var id: String { get }
    
    var loadLevel: AnyPublisher<LoadLevel, Never> { get }
    var attributes: AnyPublisher<TypedDict<TrackAttribute>, Never> { get }

    func emitter(context: PlayContext) -> AnyPublisher<AnyAudioEmitter, Error>
    var icon: Image { get }
    
    @discardableResult
    func load(atLeast level: LoadLevel, context: PlayContext) -> Bool
}

class TrackBackendTypedCodable: TypedCodable<String> {
    static let _registry = CodableRegistry<String>()
        .register(MockTrack.self, for: "mock")
        .register(FileTrack.self, for: "file")
        .register(SpotifyTrack.self, for: "spotify")

    override class var registry: CodableRegistry<String> { _registry }
}

@objc(TrackBackendTransformer)
class TrackBackendTransformer: TypedJSONCodableTransformer<String, TrackBackendTypedCodable> {}

extension NSValueTransformerName {
    static let trackBackendName = NSValueTransformerName(rawValue: "TrackBackendTransformer")
}
