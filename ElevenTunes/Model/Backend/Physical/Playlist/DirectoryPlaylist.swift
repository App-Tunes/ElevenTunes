//
//  DirectoryPlaylist+CoreDataClass.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 25.12.20.
//
//

import Foundation
import SwiftUI
import Combine

public struct DirectoryPlaylistToken: PlaylistToken {
	enum InterpretationError: Error {
		case noDirectory
	}

	let url: URL
	
	public var id: String { url.absoluteString }
	public var origin: URL? { url }
	
	static func create(fromURL url: URL) throws -> DirectoryPlaylistToken {
		if !(try url.isFileDirectory()) {
			throw InterpretationError.noDirectory
		}

		return DirectoryPlaylistToken(url: url)
	}
	
	public func expand(_ context: Library) throws -> AnyPlaylist {
		DirectoryPlaylist(url, library: context)
	}
}

public final class DirectoryPlaylist: RemotePlaylist {
	enum Request {
		case url, contents
	}
	
	let library: Library
	let url: URL

	let mapper = Requests(relation: [
		.url: [.title],
		.contents: [.tracks, .children]
	])

    init(_ url: URL, library: Library) {
		self.url = url
        self.library = library
		mapper.delegate = self
		mapper.offer(.url, update: loadURL())
    }
    
	public var icon: Image { Image(systemName: "folder.fill") }
	public var accentColor: Color { SystemUI.color }
		
	public var contentType: PlaylistContentType { .hybrid }
	
	public var origin: URL? { url }
	public var id: String { url.absoluteString }

	func loadURL() -> PlaylistAttributes.PartialGroupSnapshot {
		do {
			return .init(.unsafe([
				.title: url.lastPathComponent
		 ]), state: .valid)
		}
		catch let error {
			return .empty(state: .error(error))
		}
    }
	
	public func supports(_ capability: PlaylistCapability) -> Bool {
		false
	}
}

extension DirectoryPlaylist: RequestMapperDelegate {
	func onDemand(_ request: Request) -> AnyPublisher<VolatileAttributes<PlaylistAttribute, PlaylistVersion>.PartialGroupSnapshot, Error> {
		let url = self.url
		let library = self.library

		switch request {
		case .url:
			return Future.tryOnQueue(.global(qos: .default)) {
				self.loadURL()
			}.eraseToAnyPublisher()
		case .contents:
			return Future.tryOnQueue(.global(qos: .default)) {
				try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey])
			}
			.map(LibraryContentInterpreter.standard.compactInterpret)
			.map(LibraryContentInterpreter.separate(_:))
			.tryMap { dlibrary in (
				try dlibrary.playlists.map { try $0.expand(library) },
				try dlibrary.tracks.map { try $0.expand(library) }
			)}
			.tryMap { ($0.0, $0.1, try url.modificationDate().isoFormat) }
			.map { (playlists, tracks, version) in
				return .init(.unsafe([
					.tracks: tracks,
					.children: playlists
				]), state: .valid)
			}.eraseToAnyPublisher()
		}
	}
	
	func onUpdate(_ snapshot: VolatileAttributes<PlaylistAttribute, String>.PartialGroupSnapshot, from request: Request) {
		// TODO
	}
}

extension DirectoryPlaylist: BranchablePlaylist {
	func store(in playlist: DBPlaylist) throws -> DBPlaylist.Representation {
		guard
			let context = playlist.managedObjectContext,
			let model = context.persistentStoreCoordinator?.managedObjectModel,
			let playlistModel = model.entitiesByName["DBDirectoryPlaylist"]
		else {
			fatalError("Failed to find model in MOC")
		}

		let cache = DBDirectoryPlaylist(entity: playlistModel, insertInto: context)
		cache.url = url
		
		playlist.directoryRepresentation = cache
		
		return .directory
	}
}
