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
	
	public func attribute<TK: TypedKey & TrackAttribute>(_ attribute: TK) -> AnyPublisher<VolatileSnapshot<TK.Value?, TrackVersion>, Never>  {
		attributes.filtered(toJust: attribute)
	}
	
	public var previewImage: AnyPublisher<VolatileSnapshot<NSImage?, String>, Never> {
		let demand = self.demand([.previewImage])
		
		return attribute(TrackAttribute.previewImage)
			.flatMap { (snapshot: TrackAttributes.ValueSnapshot<NSImage?>) -> AnyPublisher<VolatileSnapshot<NSImage?, String>, Never> in
				_ = demand  // This is just to keep a reference to demand
				
				if !snapshot.state.isKnown || snapshot.value != nil {
					// Reasonable to return the track's image
					return Just(snapshot).eraseToAnyPublisher()
				}
				
				// Refer to album image
				return self.attribute(TrackAttribute.album)
					.flatMap { albumSnapshot -> AnyPublisher<VolatileSnapshot<NSImage?, String>, Never> in
						guard let album = albumSnapshot.value else {
							// No album, can't ask, but we can propagate the state
							return Just(.init(nil, state: albumSnapshot.state))
								.eraseToAnyPublisher()
						}
						
						let albumDemand = album.demand([PlaylistAttribute.previewImage])
						return album.attribute(PlaylistAttribute.previewImage)
							.map {
								_ = albumDemand  // Keep reference to playlist demand too
								return $0
							}
							.eraseToAnyPublisher()
					}
					.eraseToAnyPublisher()
			}
			.eraseToAnyPublisher()
	}
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
