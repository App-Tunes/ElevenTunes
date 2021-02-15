//
//  MultiPlaylist.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 02.01.21.
//

import Foundation
import Combine
import CombineExt
import SwiftUI

class MultiPlaylist: AnyPlaylist {
    let playlists: [AnyPlaylist]
    
    init(_ playlists: [AnyPlaylist]) {
        self.playlists = playlists
    }
    
    static func combine(_ versions: [PlaylistVersion?]) -> PlaylistVersion? {
        guard let versions = versions.explodeMap({ $0 }) else {
            return nil
        }
        return Hasher.combine(versions).description
    }
    
    var id: String { "multi:\(playlists.map { $0.id }.joined(separator: ":"))" }
        
    var contentType: PlaylistContentType { .tracks }
    
    var origin: URL? { nil }
    
    var hasCaches: Bool { playlists.contains { $0.hasCaches } }
    
    func invalidateCaches() {
        playlists.forEach { $0.invalidateCaches() }
    }
//
//    func tracks() -> AnyPublisher<TracksSnapshot, Never> {
//        playlists.map { $0.tracks() }
//            .combineLatestOrJust()
//            .map {
//                TracksSnapshot(
//                    $0.flatMap { $0.data },
//                    version: MultiPlaylist.combine($0.map { $0.version })
//                )
//            }
//            .eraseToAnyPublisher()
//    }
//
//    func children() -> AnyPublisher<PlaylistsSnapshot, Never> {
//        playlists.map { $0.children() }
//            .combineLatestOrJust()
//            .map {
//                PlaylistsSnapshot(
//                    $0.flatMap { $0.data },
//                    version: MultiPlaylist.combine($0.map { $0.version })
//                )
//            }
//            .eraseToAnyPublisher()
//    }
//
//    func attributes() -> AnyPublisher<PlaylistAttributesSnapshot, Never> {
//        playlists.map { $0.attributes() }
//            .combineLatestOrJust()
//            .map {
//                PlaylistAttributesSnapshot(
//                    TypedDict<PlaylistAttribute>([
//                        .title: "Multiple Playlists"
//                    ]),
//                    version: MultiPlaylist.combine($0.map { $0.version })
//                )
//            }
//            .eraseToAnyPublisher()
//    }
    
	func demand(_ demand: Set<PlaylistAttribute>) -> AnyCancellable {
//		playlists.map { $0.demand(demand) }
		fatalError()
	}
	
	var attributes: AnyPublisher<PlaylistAttributes.Update, Never> {
		fatalError() // TODO
	}
	
	func movePlaylists(fromIndices: IndexSet, toIndex index: Int) throws {
		throw PlaylistEditError.notSupported
	}
	
	func `import`(library: UninterpretedLibrary, toIndex index: Int?) throws {
		throw PlaylistImportError.unimportable
	}
	
	func delete() throws {
		throw PlaylistDeleteError.undeletable
	}
}
