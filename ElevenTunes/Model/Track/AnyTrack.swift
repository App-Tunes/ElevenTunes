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

    func emitter() -> AnyPublisher<AnyAudioEmitter, Error>
    var icon: Image { get }
    
    @discardableResult
    func load(atLeast level: LoadLevel) -> Bool
}

public class PersistentTrack: NSObject, AnyTrack, Codable {
    public var id: String { fatalError() }
    
    public var icon: Image { Image(systemName: "music.note") }
    
    public var loadLevel: AnyPublisher<LoadLevel, Never> { fatalError() }
    
    public var attributes: AnyPublisher<TypedDict<TrackAttribute>, Never> { fatalError() }
    
    public func emitter() -> AnyPublisher<AnyAudioEmitter, Error> {
        fatalError()
    }
    
    public func load(atLeast level: LoadLevel) -> Bool {
        fatalError()
    }
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
