//
//  JustCacheTrack.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 26.01.21.
//

import Foundation
import Combine
import SwiftUI

class JustCacheTrack: AnyTrack {
	enum EmitterFail: Error {
		case noBackend
	}
	
	let cache: DBTrack
	
	init(_ cache: DBTrack) {
		self.cache = cache
	}
	
	/// TODO Use UUID
	var id: String { cache.objectID.description }
	
	var origin: URL? { nil }
	
	var accentColor: Color { .primary }
	
	func invalidateCaches() { }
	
	func demand(_ demand: Set<TrackAttribute>) -> AnyCancellable {
		_ = cache.primaryRepresentation // Fire fault
		
		// Set all we don't have yet to valid / don't know this
		cache.attributes.updateEmpty(demand.subtracting(cache.attributes.snapshot.keys), state: .valid)
		
		return AnyCancellable {}
	}
	
	var attributes: AnyPublisher<TrackAttributes.Update, Never> {
		cache.attributes.$update.eraseToAnyPublisher()
	}
	
	func emitter(context: PlayContext) -> AnyPublisher<AnyAudioEmitter, Error> {
		Fail(error: EmitterFail.noBackend).eraseToAnyPublisher()
	}
}

extension JustCacheTrack: BranchableTrack {
	func store(in track: DBTrack) throws -> DBTrack.Representation {
		.none
	}
}
