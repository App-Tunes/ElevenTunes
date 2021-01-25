//
//  Library+Contents.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 30.12.20.
//

import Foundation
import Combine

extension Library {
    func playlist(cachedBy cache: DBPlaylist) -> AnyPublisher<AnyPlaylist, Never> {
        _ = cache.backend // Fire Fault
        
        return cache.$backendP.map {
                $0?.expand(self)
            }
            .combineLatest(cache.$isIndexedP, cache.$contentTypeP)
            .map { (backend: AnyPlaylist?, isIndexed: Bool, contentType: PlaylistContentType) -> AnyPlaylist in
                BranchingPlaylist(library: self, cache: cache, backend: backend, isIndexed: isIndexed, contentType: contentType)
            }
            .eraseToAnyPublisher()
    }
    
    func track(cachedBy cache: DBTrack) -> AnyPublisher<AnyTrack, Never> {
        _ = cache.backend // Fire Fault
        
        return cache.$backendP.map {
                $0?.expand(self)
            }
            .map { backend in
                BranchingTrack(library: self, cache: cache, backend: backend)
            }
            .eraseToAnyPublisher()
    }
}
