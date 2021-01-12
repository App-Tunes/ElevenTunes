//
//  RemotePlaylist.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 09.01.21.
//

import Foundation
import Combine

protocol RemotePlaylist: AnyPlaylist, RequestMapperDelegate where Snapshot == PlaylistAttributes.ValueGroupSnapshot {
	associatedtype Token: PlaylistToken
	
	typealias Requests = RequestMapper<PlaylistAttribute, PlaylistVersion, Self>

	var mapper: Requests { get }
	var token: Token { get }
}

extension RemotePlaylist {
	public var attributes: AnyPublisher<PlaylistAttributes.Update, Never> {
		mapper.attributes.$snapshot.eraseToAnyPublisher()
	}
	
	public func demand(_ demand: Set<PlaylistAttribute>) -> AnyCancellable {
		mapper.demand.add(demand)
	}
	
	public var hasCaches: Bool { true }
	
	public func invalidateCaches() {
		mapper.attributes.invalidate()
	}
	
	public func `import`(library: AnyLibrary) -> Bool { false }

	public var asToken: PlaylistToken { token }
	public var origin: URL? { token.origin }

	public var id: String { token.id }
}
