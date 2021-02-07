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

public final class DirectoryPlaylist: RemotePlaylist {
	enum Request {
		case url, contents
	}
	
	enum InterpretationError: Error {
		case noDirectory
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
		
		mapper.offer(.url, update: loadURL())
    }
    
	static func create(fromURL url: URL, library: Library) throws -> DirectoryPlaylist {
		if !(try url.isFileDirectory()) {
			throw InterpretationError.noDirectory
		}

		return DirectoryPlaylist(url, library: library)
	}

	static let _icon: Image = Image(systemName: "folder")
	public var icon: Image { DirectoryPlaylist._icon }
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
}

extension DirectoryPlaylist: RequestMapperDelegate {
	func onDemand(_ request: Request) -> AnyPublisher<VolatileAttributes<PlaylistAttribute, PlaylistVersion>.PartialGroupSnapshot, Error> {
		let url = self.url
		let interpreter = library.interpreter

		switch request {
		case .url:
			return Future {
				self.loadURL()
			}.eraseToAnyPublisher()
		case .contents:
			return Future {
				try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey])
			}
			.flatMap {
				interpreter.interpret(urls: $0)
					?? Just([]).eraseError().eraseToAnyPublisher()
			}
			.tryMap { (contents: [Content]) -> UninterpretedLibrary in
				ContentInterpreter.collect(fromContents: contents)
			}
			.tryMap { ($0, try url.modificationDate().isoFormat) }
			.map { (library, version) in
				return .init(.unsafe([
					.tracks: library.tracks,
					.children: library.playlists
				]), state: .valid)
			}.eraseToAnyPublisher()
		}
	}
}
