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

public class M3UPlaylistToken: PlaylistToken {
    enum InterpretationError: Error {
        case noFile
    }

    enum CodingKeys: String, CodingKey {
      case url
    }

    var url: URL
    
    init(_ url: URL) {
        self.url = url
        super.init()
    }
    
    static func create(fromURL url: URL) throws -> M3UPlaylistToken {
        if try url.isFileDirectory() {
            throw InterpretationError.noFile
        }
        
        return M3UPlaylistToken(url)
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        url = try container.decode(URL.self, forKey: .url)
        try super.init(from: decoder)
    }

    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(url, forKey: .url)
        try super.encode(to: encoder)
    }
    
    public override var id: String { url.absoluteString }
}

public class M3UPlaylist: RemotePlaylist {
    let library: Library
    let token: M3UPlaylistToken
    
    init(_ token: M3UPlaylistToken, library: Library) {
        self.library = library
        self.token = token
        super.init()
        loadMinimal()
        contentSet.formUnion([.minimal, .attributes])
    }
    
    public override var asToken: PlaylistToken { token }

    public override var icon: Image { Image(systemName: "doc.text") }
    
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
    
    func loadMinimal() {
        _attributes[PlaylistAttribute.title] = token.url.lastPathComponent
    }
    
    public override func load(atLeast mask: PlaylistContentMask, library: Library) {
        contentSet.promise(mask) { promise in
            let url = token.url
            let interpreter = library.interpreter

            promise.fulfilling([.minimal, .attributes]) {
                loadMinimal()
            }

            guard promise.includesAny([.tracks, .children]) else {
                return
            }

            Future {
                try String(contentsOf: url)
            }
            .map { file in
                M3UPlaylist.interpretFile(file, relativeTo: url)
            }
            .flatMap {
                interpreter.interpret(urls: $0)
                    ?? Just([]).eraseError().eraseToAnyPublisher()
            }
            .flatMap { (contents: [Content]) -> AnyPublisher<([AnyTrack], [AnyPlaylist]), Never> in
                let (tracks, children) = ContentInterpreter.collect(fromContents: contents)
                
                let tracksMerge = tracks.map { $0.expand(library) }.combineLatest()
                let playlistsMerge = children.map { $0.expand(library) }.combineLatest()

                return tracksMerge.zip(playlistsMerge).eraseToAnyPublisher()
            }
            .onMain()
            .fulfillingAny([.tracks, .children], of: promise)
            .sink(receiveCompletion: appLogErrors(_:)) { [unowned self] (tracks, children) in
                _tracks = tracks
                _children = children
            }.store(in: &cancellables)
        }
    }
}
