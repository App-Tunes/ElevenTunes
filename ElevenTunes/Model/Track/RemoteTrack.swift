//
//  RemoteTrack.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 26.12.20.
//

import Foundation
import Combine
import SwiftUI

protocol RemoteTrack: AnyTrack, RequestMapperDelegate where Snapshot == TrackAttributes.PartialGroupSnapshot {
	typealias Requests = RequestMapper<TrackAttribute, TrackVersion, Self>

	var mapper: Requests { get }
}

extension RemoteTrack {
	public var attributes: AnyPublisher<TrackAttributes.Update, Never> {
		mapper.attributes.$update.eraseToAnyPublisher()
	}
	
	public func demand(_ demand: Set<TrackAttribute>) -> AnyCancellable {
		mapper.demand.add(demand)
	}
	
	public var hasCaches: Bool { true }
	
	public func invalidateCaches() {
		mapper.invalidateCaches()
	}
	
	public func delete() throws {
		throw PlaylistDeleteError.undeletable
	}
}
