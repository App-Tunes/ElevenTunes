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

public class DirectoryPlaylistToken: FilePlaylistToken {
    enum InterpretationError: Error {
        case noDirectory
    }

    static func create(fromURL url: URL) throws -> DirectoryPlaylistToken {
        if !(try url.isFileDirectory()) {
            throw InterpretationError.noDirectory
        }

        return DirectoryPlaylistToken(url)
    }
    
    override func expand(_ context: Library) -> AnyPlaylist {
        DirectoryPlaylist(self, library: context)
    }
}

public final class DirectoryPlaylist: RemotePlaylist {
    let library: Library
    let token: DirectoryPlaylistToken
        
	enum Request {
		case url, contents
	}
	
	let mapper = Requests(relation: [
		.url: [.title],
		.contents: [.tracks, .children]
	])

    init(_ token: DirectoryPlaylistToken, library: Library) {
        self.library = library
        self.token = token
		
		mapper.offer(.url, update: loadURL())
    }
    
	static let _icon: Image = Image(systemName: "folder")
	public var icon: Image { DirectoryPlaylist._icon }
	public var accentColor: Color { SystemUI.color }
		
	public var contentType: PlaylistContentType { .hybrid }

	func loadURL() -> PlaylistAttributes.PartialGroupSnapshot {
		do {
			return .init(.unsafe([
				.title: token.url.lastPathComponent
		 ]), state: .version(try token.url.modificationDate().isoFormat))
		}
		catch let error {
			return .empty(state: .error(error))
		}
    }
}

extension DirectoryPlaylist: RequestMapperDelegate {
	func onDemand(_ request: Request) -> AnyPublisher<VolatileAttributes<PlaylistAttribute, PlaylistVersion>.PartialGroupSnapshot, Error> {
		let url = token.url
		let interpreter = library.interpreter
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
			.flatMap {
				interpreter.interpret(urls: $0)
					?? Just([]).eraseError().eraseToAnyPublisher()
			}
			.map { (contents: [Content]) -> ([AnyTrack], [AnyPlaylist]) in
				let (tracks, children) = ContentInterpreter.collect(fromContents: contents)

				return (tracks.map { $0.expand(library) }, children.map { $0.expand(library) })
			}
			.tryMap { ($0, $1, try url.modificationDate().isoFormat) }
			.map { (tracks, children, version) in
				return .init(.unsafe([
					.tracks: tracks,
					.children: children
				]), state: .version(version))
			}.eraseToAnyPublisher()
		}
	}
}
