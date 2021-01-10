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
    var asToken: TrackToken { get }
    
    var origin: URL? { get }

	func invalidateCaches()

	/// Registers a persistent demand for some attributes. The track promises that it will try to
	/// evolve the attribute's `State.missing` to some other state.
	func demand(_ demand: Set<TrackAttribute>) -> AnyCancellable
	/// A stream of attributes, and the last changed attribute identifiers. The identifiers are useful for ignoring
	/// irrelevant updates.
	var attributes: AnyPublisher<TrackAttributes.Update, Never> { get }

    func emitter(context: PlayContext) -> AnyPublisher<AnyAudioEmitter, Error>
    
    var icon: Image { get }
    var accentColor: Color { get }
}

extension AnyTrack {
	public var icon: Image { Image(systemName: "music.note") }
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
