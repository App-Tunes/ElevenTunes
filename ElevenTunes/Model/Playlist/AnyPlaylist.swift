//
//  AnyPlaylist.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 25.12.20.
//

import Foundation
import SwiftUI
import Combine

@objc public enum PlaylistContentType: Int16 {
    /// Can only contain tracks
    case tracks
    /// Can only contain playlists (as children)
    case playlists
    /// Can contain both tracks and playlists (e.g. filesystem folders, artists)
    case hybrid
}

enum PlaylistImportError: Error {
	case unimportable, empty
}

enum PlaylistDeleteError: Error {
	case undeletable
}

public protocol AnyPlaylist: AnyObject {
    var id: String { get }

    var contentType: PlaylistContentType { get }
    
    var origin: URL? { get }
    
    var icon: Image { get }
    var accentColor: Color { get }

    var hasCaches: Bool { get }
	func invalidateCaches()

	/// Registers a persistent demand for some attributes. The playlist promises that it will try to
	/// evolve the attribute's `State.missing` to some other state.
	func demand(_ demand: Set<PlaylistAttribute>) -> AnyCancellable
	/// A stream of attributes, and the last changed attribute identifiers. The identifiers are useful for ignoring
	/// irrelevant updates.
    var attributes: AnyPublisher<PlaylistAttributes.Update, Never> { get }

    func `import`(library: UninterpretedLibrary) throws
	
	func delete() throws
}

extension AnyPlaylist {
	public var icon: Image { Image(systemName: "music.note.list") }
    var accentColor: Color { .primary }
	
	public func attribute<TK: TypedKey & PlaylistAttribute>(_ attribute: TK) -> AnyPublisher<VolatileSnapshot<TK.Value, PlaylistVersion>, Never>  {
		attributes.filtered(toJust: attribute)
	}
}
