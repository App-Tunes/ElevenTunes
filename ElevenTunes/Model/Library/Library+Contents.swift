//
//  Library+Contents.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 30.12.20.
//

import Foundation
import Combine

extension Library {
    func playlist(cachedBy cache: DBPlaylist) -> AnyPublisher<BranchingPlaylist, Never> {
		_ = cache.primaryRepresentation  // Fire fault
		
		return cache.$primaryRepresentationP
			.combineLatest(cache.$representationsP, cache.$contentTypeP)
			.map { (primary, representations, contentType) in
				let secondaries = representations.filter { $0.key != primary }.values
				
				return BranchingPlaylist(
					cache: cache,
					primary: representations[primary]?.expand(library: self) ?? JustCachePlaylist(cache, library: self),
					secondary: secondaries.map { $0.expand(library: self) },
					contentType: contentType
				)
			}.eraseToAnyPublisher()
    }
    
	func track(cachedBy cache: DBTrack) -> AnyPublisher<BranchingTrack, Never> {
		_ = cache.primaryRepresentation  // Fire fault
		
		return cache.$primaryRepresentationP.combineLatest(cache.$representationsP)
			.map { (primary, representations) in
				let secondaries = representations.filter { $0.key != primary }.values
				
				return BranchingTrack(
					cache: cache,
					primary: representations[primary]?.expand(library: self) ?? JustCacheTrack(cache),
					secondary: secondaries.map { $0.expand(library: self) }
				)
			}.eraseToAnyPublisher()
    }
}
