//
//  LibraryPlaylist.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 25.12.20.
//

import Cocoa
import SwiftUI
import Combine
import CombineExt

class LibraryPlaylist: AnyPlaylist {
    let managedObjectContext: NSManagedObjectContext
    var playContext: PlayContext

    @Published var staticPlaylists: [AnyPlaylist] = []

    var cancellables = Set<AnyCancellable>()
    var library: Library?  // Weak because reference cycle
        
	let _attributes: VolatileAttributes<PlaylistAttribute, PlaylistVersion> = .init()
	
    init(library: Library, playContext: PlayContext) {
        self.managedObjectContext = library.managedObjectContext
        self.playContext = playContext
        self.library = library
        
		// TODO
//        _tracks = CDPublisher(request: DBTrack.createFetchRequest(), context: managedObjectContext)
//            // TODO Apparently, sometimes the same object is emitted twice
//            .map { $0.removeDuplicates() }
//            .removeDuplicates()
//            .flatMap {
//                $0.map { [weak self] in self!.library!.track(cachedBy: $0) }
//                    .combineLatest()
//            }
//            .replaceError(with: [])
//            .map { TracksSnapshot($0) }
//            .eraseToAnyPublisher()
//
//        _children = CDPublisher(request: LibraryPlaylist.playlistFetchRequest, context: managedObjectContext)
//            // TODO Apparently, sometimes the same object is emitted twice
//            .map { $0.removeDuplicates { $0.uuid } }
//            .removeDuplicates()
//            .flatMap {
//                $0
//                    .map { [weak self] in self!.library!.playlist(cachedBy: $0) }
//                    .combineLatest()
//            }
//            .combineLatest($staticPlaylists.eraseError()).map { $1 + $0 }
//            .replaceError(with: [])
//            .map { PlaylistsSnapshot($0) }
//            .eraseToAnyPublisher()
                
        staticPlaylists = [
            SpotifyUser(spotify: library.spotify)
        ]
    }
    
    var id: String {
        "Library" // TODO
    }
    
    var contentType: PlaylistContentType { .hybrid }
    
    var origin: URL? { nil }
    
    var accentColor: Color { .accentColor }
    
    var hasCaches: Bool { false }
    
    var asToken: PlaylistToken { fatalError() }
    
	func invalidateCaches() {
		// We have no caches lol
	}
	
	func demand(_ demand: Set<PlaylistAttribute>) -> AnyCancellable {
		// TODO We may want to invalidate CD Publishers if there's no demand
		AnyCancellable { }
	}

	var attributes: AnyPublisher<PlaylistAttributes.Update, Never> {
		_attributes.$snapshot.eraseToAnyPublisher()
	}
    
    func previewImage() -> AnyPublisher<NSImage?, Never> {
        Just(nil).eraseToAnyPublisher()
    }

    static var playlistFetchRequest: NSFetchRequest<DBPlaylist> {
        let request = DBPlaylist.createFetchRequest()
        request.predicate = NSPredicate(format: "parent == nil")
        request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        return request
    }
        
    var icon: Image { Image(systemName: "house.fill" ) }
            
    func `import`(library: AnyLibrary) -> Bool {
        guard let defaultPlaylist = self.library?.defaultPlaylist else {
            return false
        }

        return Library.import(library, to: defaultPlaylist)
    }
}
