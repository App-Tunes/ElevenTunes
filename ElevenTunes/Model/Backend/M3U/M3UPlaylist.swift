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
    
    public override var id: String { url.absoluteString }

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
    
    static func create(fromURL url: URL) throws -> M3UPlaylistToken {
        if try url.isFileDirectory() {
            throw InterpretationError.noFile
        }
        
        return M3UPlaylistToken(url)
    }
    
    override func expand(_ context: Library) -> AnyPlaylist {
        M3UPlaylist(self, library: context)
    }
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
        _attributes.value[PlaylistAttribute.title] = token.url.lastPathComponent
    }
    
    public override func load(atLeast mask: PlaylistContentMask) {
        contentSet.promise(mask) { promise in
            let url = token.url
            let library = self.library
            let interpreter = library.interpreter

            promise.fulfillingAny([.minimal, .attributes]) {
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
            .map { (contents: [Content]) -> ([AnyTrack], [AnyPlaylist]) in
                let (tracks, children) = ContentInterpreter.collect(fromContents: contents)
                
                return (tracks.map { $0.expand(library) }, children.map { $0.expand(library) })
            }
            .onMain()
            .fulfillingAny([.tracks, .children], of: promise)
            .sink(receiveCompletion: appLogErrors(_:)) { [unowned self] (tracks, children) in
                _tracks.value = tracks
                _children.value = children
            }.store(in: &cancellables)
        }
    }
}
