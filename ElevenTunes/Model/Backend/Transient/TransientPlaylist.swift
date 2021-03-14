//
//  TransientPlaylis.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 26.12.20.
//

import Foundation
import Combine
import SwiftUI

class TransientPlaylist: PlaylistToken, AnyPlaylist {
    enum CodingError: Error {
        case encode, decode
    }

    var uuid = UUID()
    var id: String { uuid.description }
    
    var origin: URL? { nil }
    
    var icon: Image { Image(systemName: "music.note.list") }
    var accentColor: Color { .primary }
    
    var contentType: PlaylistContentType
    
    var hasCaches: Bool { false }
    func invalidateCaches() {}
	
	let _attributes: VolatileAttributes<PlaylistAttribute, PlaylistVersion> = .init()
    
    init(_ type: PlaylistContentType, attributes: TypedDict<PlaylistAttribute>) {
        self.contentType = type
		version = UUID().uuidString
		_attributes.update(.init(keys: Set(attributes.keys), attributes: attributes, state: .valid))
    }
    
    func expand(_ context: Library) -> AnyPlaylist { self }
        
    func refreshVersion() {
        version = UUID().uuidString
    }

    @Published var version: PlaylistVersion

	func demand(_ demand: Set<PlaylistAttribute>) -> AnyCancellable {
		// The ones we don't have, we can never fulfill either
		_attributes.updateEmptyMissing(demand)
		return AnyCancellable { }
	}
	
	var attributes: AnyPublisher<PlaylistAttributes.Update, Never> {
		_attributes.$update.eraseToAnyPublisher()
	}
	
	public func supports(_ capability: PlaylistCapability) -> Bool {
		false
	}
	
	func `import`(library: UninterpretedLibrary, toIndex index: Int?) throws {
		throw PlaylistImportError.unimportable  // TODO We can do this bois
    }
	
	func delete() throws {
		throw PlaylistDeleteError.undeletable
	}
}

extension TransientPlaylist: BranchablePlaylist {
	func store(in playlist: DBPlaylist) throws -> DBPlaylist.Representation {
		playlist.title = _attributes.snapshot[PlaylistAttribute.title].value
		playlist.initialSetup()  // Re-read attributes
		
		return .none
	}
}
