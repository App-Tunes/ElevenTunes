//
//  RemoteTrack.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 26.12.20.
//

import Foundation
import Combine
import SwiftUI

protocol RemoteTrack: AnyTrack, RequestMapperDelegate where Snapshot == TrackAttributes.ValueGroupSnapshot {
	associatedtype Token: TrackToken
	typealias Requests = RequestMapper<TrackAttribute, TrackVersion, Self>

	var mapper: Requests { get }
	var token: Token { get }
}

extension RemoteTrack {
	public var attributes: AnyPublisher<TrackAttributes.Update, Never> {
		mapper.attributes.$snapshot.eraseToAnyPublisher()
	}
	
	public func demand(_ demand: Set<TrackAttribute>) -> AnyCancellable {
		mapper.demand.add(demand)
	}
	
	public var hasCaches: Bool { true }
	
	public func invalidateCaches() {
		let snapshot = mapper.attributes.snapshot.0.attributes
		
		snapshot[TrackAttribute.artists]?.forEach { $0.invalidateCaches() }
		snapshot[TrackAttribute.album]?.invalidateCaches()
		
		mapper.invalidateCaches()
	}
	
	public func `import`(library: AnyLibrary) -> Bool { false }

	public var asToken: TrackToken { token }
	public var origin: URL? { token.origin }

	public var id: String { token.id }
}
