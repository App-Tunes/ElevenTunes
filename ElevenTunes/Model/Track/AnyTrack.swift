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
    static let analysis = TrackContentMask(rawValue: 1 << 1)
    // More to come? In any case, bools aren't more efficient anyway
}

public protocol AnyTrack: AnyObject {
    var id: String { get }
    var asToken: TrackToken { get }
    
    var origin: URL? { get }

    func cacheMask() -> AnyPublisher<TrackContentMask, Never>
    func artists() -> AnyPublisher<[AnyPlaylist], Never>
    func album() -> AnyPublisher<AnyPlaylist?, Never>
    func attributes() -> AnyPublisher<TypedDict<TrackAttribute>, Never>

    func emitter(context: PlayContext) -> AnyPublisher<AnyAudioEmitter, Error>
    
    var icon: Image { get }
    var accentColor: Color { get }

    func previewImage() -> AnyPublisher<NSImage?, Never>

    func invalidateCaches(_ mask: TrackContentMask)
}

class TrackBackendTypedCodable: TypedCodable<String> {
    static let _registry = CodableRegistry<String>()
        .register(MockTrack.self, for: "mock")
        .register(FileTrackToken.self, for: "file")
        .register(FileVideoToken.self, for: "videofile")
        .register(SpotifyTrackToken.self, for: "spotify")

    override class var registry: CodableRegistry<String> { _registry }
}

@objc(TrackBackendTransformer)
class TrackBackendTransformer: TypedJSONCodableTransformer<String, TrackBackendTypedCodable> {}

extension NSValueTransformerName {
    static let trackBackendName = NSValueTransformerName(rawValue: "TrackBackendTransformer")
}
