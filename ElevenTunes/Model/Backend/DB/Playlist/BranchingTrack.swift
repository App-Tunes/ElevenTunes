//
//  BranchingTrack.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 25.01.21.
//

import Foundation
import Combine
import SwiftUI

enum EmitterFail: Error {
	case noBackend
}

public class BranchingTrack: AnyTrack {
	let library: Library
	let cache: DBTrack
	let backend: AnyTrack?
	
	var backendObservers = Set<AnyCancellable>()

	var cancellables: Set<AnyCancellable> = []

	init(library: Library, cache: DBTrack, backend: AnyTrack?) {
		self.library = library
		self.cache = cache
		self.backend = backend
		setupObservers()
	}
	
	func setupObservers() {
		guard let backend = backend else {
			return
		}
		
		backend.attributes
			.sink(receiveValue: cache.onUpdate)
			.store(in: &cancellables)
	}

	public var asToken: TrackToken { fatalError() }
	
	public var id: String { cache.objectID.description }
	
	public var origin: URL? { backend?.origin ?? nil }
	
	public var icon: Image { backend?.icon ?? Image(systemName: "questionmark") }
	public var accentColor: Color { backend?.accentColor ?? .primary }
	
	public func invalidateCaches() {
		guard let backend = backend else {
			return  // No caches here!
		}
		
		// TODO Invalidate our caches
		backend.invalidateCaches()
	}

	lazy var _attributes: AnyPublisher<TrackAttributes.Update, Never> = {
		guard let backend = backend else {
			// Everything is always 'cached'
			return cache.attributes.$update.eraseToAnyPublisher()
		}
		
		// Depending on setup, other values will be in cache.attributes.
		// This does not affect our logic here.
		return backend.attributes
			.combineLatest(cache.attributes.$update)
			.compactMap { (backend, cache) -> TrackAttributes.Update in
				// TODO If change comes from cache, not from backend, 'change' value will be wrong.
				return (backend.0.merging(cache: cache.0), change: backend.change)
			}.eraseToAnyPublisher()
	}()
	public var attributes: AnyPublisher<TrackAttributes.Update, Never> {
		return _attributes
	}
	
	public func demand(_ demand: Set<TrackAttribute>) -> AnyCancellable {
		guard let backend = backend else {
			// TODO Only update the attributes if there's a watcher? Does that help?
			return AnyCancellable {}
		}
		
		// First figure out what we haven't cached yet
		let missing = demand.subtracting(cache.attributes.knownKeys)
		// Now explode so we get a cacheable package some time
		return backend.demand(DBTrack.attributeGroups.explode(missing))
	}

	public func emitter(context: PlayContext) -> AnyPublisher<AnyAudioEmitter, Error> {
		backend?.emitter(context: context)
			?? Fail(error: EmitterFail.noBackend).eraseToAnyPublisher()
	}
}
