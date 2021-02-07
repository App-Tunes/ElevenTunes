//
//  M3UPlaylist+CoreDataClass.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 25.12.20.
//
//

import Foundation
import CoreData
import SwiftUI
import Combine

public final class M3UPlaylist: RemotePlaylist {
	enum InterpretationError: Error {
		case noFile
	}

	let url: URL
	let library: Library

	enum Request {
		case url, read
	}
	
	let mapper = Requests(relation: [
		.url: [.title],
		.read: [.tracks, .children]
	])

	init(_ url: URL, library: Library) {
        self.url = url
		self.library = library
		mapper.offer(.url, update: urlAttributes())
    }
    
	static func create(fromURL url: URL, library: Library) throws -> M3UPlaylist {
		if try url.isFileDirectory() {
			throw InterpretationError.noFile
		}
		
		return M3UPlaylist(url, library: library)
	}

    public var icon: Image { Image(systemName: "doc.text") }
    
    public var accentColor: Color { SystemUI.color }
	
	public var contentType: PlaylistContentType { .hybrid }
    
	public var origin: URL? { url }

	public var id: String { url.absoluteString }

    public static func interpretFile(_ file: String, relativeTo directory: URL) -> [URL] {
        let lines = file.split(whereSeparator: \.isNewline)
        
        var urls: [URL] = []
        
        for line in lines {
            let string = line.trimmingCharacters(in: .whitespaces)
            let fileURL = URL(fileURLWithPath: string, relativeTo: directory).absoluteURL
            do {
                if try fileURL.isFileDirectory() {
                    let dirURLs = try FileManager.default.contentsOfDirectory(at: fileURL, includingPropertiesForKeys: [.isDirectoryKey])
                    
                    // Append all file URLs
                    urls += dirURLs.filter { !((try? $0.isFileDirectory()) ?? true) }
                }
                else {
                    urls.append(fileURL)
                }
            }
            catch {
                // On crash, it wasn't a file URL
                if let url = URL(string: string) {
                    urls.append(url)
                }
            }
        }
        
        return urls
    }
    
	func urlAttributes() -> PlaylistAttributes.PartialGroupSnapshot {
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

extension M3UPlaylist: RequestMapperDelegate {
	func onDemand(_ request: Request) -> AnyPublisher<VolatileAttributes<PlaylistAttribute, PlaylistVersion>.PartialGroupSnapshot, Error> {
		let url = self.url
		let library = self.library
		let interpreter = library.interpreter
		
		switch request {
		case .url:
			return Future {
				self.urlAttributes()
			}.eraseToAnyPublisher()
		case .read:
			return Future {
				try String(contentsOf: url)
			}
			.map { file in
				M3UPlaylist.interpretFile(file, relativeTo: url)
			}
			.flatMap {
				interpreter.interpret(urls: $0)
					?? Just([]).eraseError().eraseToAnyPublisher()
			}
			.map { (contents: [Content]) -> UninterpretedLibrary in
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
