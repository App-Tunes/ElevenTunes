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
    enum CodingKeys: String, CodingKey {
      case attributes, tracks, children
    }
    
    enum CodingError: Error {
        case encode, decode
    }

    var uuid = UUID()
    override var id: String { uuid.description }
    
    override var origin: URL? { nil }
    
    var icon: Image { Image(systemName: "music.note.list") }
    var accentColor: Color { .primary }
    
    var contentType: PlaylistContentType
    
    var hasCaches: Bool { false }
    func invalidateCaches() {}
	
	let _attributes: VolatileAttributes<PlaylistAttribute, PlaylistVersion> = .init()
    
    init(_ type: PlaylistContentType, attributes: TypedDict<PlaylistAttribute>) {
        self.contentType = type
		version = UUID().uuidString
        super.init()
		_attributes.update(attributes, state: .version(version))
    }
    
    public required init(from decoder: Decoder) throws {
        throw CodingError.decode
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        _tracks = try container.decode([PersistentTrack].self, forKey: .tracks)
//        _children = try container.decode([PersistentPlaylist].self, forKey: .children)
    }

    public override func encode(to encoder: Encoder) throws {
        throw CodingError.encode
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(_tracks, forKey: .tracks)
//        try container.encode(_children, forKey: .children)
    }
    
    override func expand(_ context: Library) -> AnyPlaylist { self }
    
    var asToken: PlaylistToken { self }
    
    func refreshVersion() {
        version = UUID().uuidString
    }

    @Published var version: PlaylistVersion

	func demand(_ demand: Set<PlaylistAttribute>) -> AnyCancellable {
		AnyCancellable {}
	}
	
	var attributes: AnyPublisher<PlaylistAttributes.Update, Never> {
		_attributes.$snapshot.eraseToAnyPublisher()
	}

    func `import`(library: AnyLibrary) -> Bool {
        return false  // TODO We can do this bois
    }
    
    func previewImage() -> AnyPublisher<NSImage?, Never> {
        Just(nil).eraseToAnyPublisher()
    }
}
