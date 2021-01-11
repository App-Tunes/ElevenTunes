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
		case url, read
	}
	
	let mapper = Requests(relation: [
		.url: [.title],
		.read: [.tracks, .children]
	])

    init(_ token: DirectoryPlaylistToken, library: Library) {
        self.library = library
        self.token = token
		loadURL()
		mapper.requestFeatureSet.insert(.url)
    }
    
	static let _icon: Image = Image(systemName: "folder")
	public var icon: Image { DirectoryPlaylist._icon }
	public var accentColor: Color { SystemUI.color }
		
	public var contentType: PlaylistContentType { .hybrid }

    func loadURL() {
		guard let modificationDate = try? token.url.modificationDate() else {
			return
		}
		
		mapper.attributes.update(.init([
			.title: token.url.lastPathComponent
		]), state: .version(modificationDate.isoFormat))
    }
    
//    public override func load(atLeast mask: PlaylistContentMask) {
//        let library = self.library
//
//        contentSet.promise(mask) { promise in
//            let url = token.url
//            let interpreter = library.interpreter
//
//            promise.fulfilling(.attributes) {
//                loadMinimal()
//            }
//
//            guard promise.includesAny([.tracks, .children]) else {
//                return
//            }
//
//
//
//            Future {
//                try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey])
//            }
//            .flatMap {
//                interpreter.interpret(urls: $0)
//                    ?? Just([]).eraseError().eraseToAnyPublisher()
//            }
//            .map { (contents: [Content]) -> ([AnyTrack], [AnyPlaylist]) in
//                let (tracks, children) = ContentInterpreter.collect(fromContents: contents)
//
//                return (tracks.map { $0.expand(library) }, children.map { $0.expand(library) })
//            }
//            .tryMap { ($0, $1, try url.modificationDate().isoFormat) }
//            .onMain()
//            .fulfillingAny([.tracks, .children], of: promise)
//            .sink(receiveCompletion: appLogErrors(_:)) { [unowned self] (tracks, children, version) in
//				self.tracks.update(tracks, version: version)
//				self.children.update(children, version: version)
//            }.store(in: &cancellables)
//        }
//
//        return
//    }
}

extension DirectoryPlaylist: RequestMapperDelegate {
	func onDemand(_ request: Request) -> AnyPublisher<VolatileAttributes<PlaylistAttribute, PlaylistVersion>.ValueGroupSnapshot, Error> {
		// TODO
		fatalError()
	}
}
