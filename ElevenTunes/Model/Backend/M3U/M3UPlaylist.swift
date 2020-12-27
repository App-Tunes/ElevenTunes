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

public class M3UPlaylist: RemotePlaylist {
    enum InterpretationError: Error {
        case noFile
    }
    
    var url: URL
    
    init(_ url: URL) {
        self.url = url
        super.init()
        _attributes[PlaylistAttribute.title] = url.lastPathComponent
    }
    
    static func create(fromURL url: URL) throws -> M3UPlaylist {
        if try url.isFileDirectory() {
            throw InterpretationError.noFile
        }
        
        return M3UPlaylist(url)
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
    
    public override func load(atLeast level: LoadLevel, deep: Bool, library: Library) -> Bool {
        let url = self.url
        let interpreter = library.interpreter
        
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
        .sink(receiveCompletion: appLogErrors(_:)) { [unowned self] contents in
            let library = ContentInterpreter.collect(fromContents: contents)
            _tracks = library.0
            _children = library.1
            _attributes[PlaylistAttribute.title] = url.lastPathComponent
            _loadLevel = .detailed
        }.store(in: &cancellables)

        return true
    }
}

extension M3UPlaylist {
    enum CodingKeys: String, CodingKey {
      case url
    }
}
