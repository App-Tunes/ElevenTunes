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
		
		mapper.offer(.url, update: loadURL())
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
		let library = self.library

		switch request {
		case .url:
			return Future {
				self.loadURL()
			}.eraseToAnyPublisher()
		case .contents:
			return Future {
				try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey])
			}
			.tryMap { try TrackInterpreter.standard.interpret(urls: $0) }
			.tryMap { try $0.map { try $0.expand(library) } }
			.tryMap { ($0, try url.modificationDate().isoFormat) }
			.map { (tracks, version) in
				return .init(.unsafe([
					.tracks: tracks,
				]), state: .valid)
			}.eraseToAnyPublisher()
		}
	}
}
