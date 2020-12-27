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

    public override var icon: Image { Image(systemName: "doc.text.fill") }
    
    public override func load(atLeast level: LoadLevel, deep: Bool, library: Library) -> Bool {
        let url = self.url
        let interpreter = library.interpreter
        
        Future {
            try String(contentsOf: url).split(whereSeparator: \.isNewline)
        }
        .map {
            $0.compactMap { URL(fileURLWithPath: String($0), relativeTo: url).absoluteURL }
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
