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
        
        let backend = cache.$backendP.flatMap { (token: PlaylistToken?) in
            token?.expand(self)
                .map { $0 as AnyPlaylist? }.eraseToAnyPublisher()
                ?? Just<AnyPlaylist?>(nil).eraseToAnyPublisher()
        }
        
        return backend.combineLatest(cache.$isIndexedP, cache.$isDirectoryP)
            .map { (backend: AnyPlaylist?, isIndexed: Bool, isDirectory: Bool) -> AnyPlaylist in
                DBLibraryPlaylist(library: self, cache: cache, backend: backend, isIndexed: isIndexed, isDirectory: isDirectory)
            }
            .eraseToAnyPublisher()
    }
    
    func track(cachedBy cache: DBTrack) -> AnyPublisher<AnyTrack, Never> {
        _ = cache.backend // Fire Fault
        
        let backend = cache.$backendP.flatMap { (token: TrackToken?) in
            token?.expand(self).map { $0 as AnyTrack? }.eraseToAnyPublisher()
                ?? Just<AnyTrack?>(nil).eraseToAnyPublisher()
        }
        
        return backend
            .map { backend in
                DBLibraryTrack(library: self, cache: cache, backend: backend)
            }
            .eraseToAnyPublisher()
    }
}
