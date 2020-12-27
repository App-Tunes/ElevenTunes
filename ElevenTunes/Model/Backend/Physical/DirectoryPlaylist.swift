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

public class DirectoryPlaylist: RemotePlaylist {
    enum InterpretationError: Error {
        case noDirectory
    }

    var url: URL
    
    init(_ url: URL) {
        self.url = url
        super.init()
        _attributes[PlaylistAttribute.title] = url.lastPathComponent
    }
    
    static func create(fromURL url: URL) throws -> DirectoryPlaylist {
        if !(try url.isFileDirectory()) {
            throw InterpretationError.noDirectory
        }

        return DirectoryPlaylist(url)
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

    static let _icon: Image = Image(systemName: "folder")
    public override var icon: Image { DirectoryPlaylist._icon }
    public override var accentColor: Color { .accentColor }
    
    public override var id: String { url.absoluteString }
    
    public override func supportsChildren() -> Bool { true }
    
    public override func load(atLeast level: LoadLevel, deep: Bool, library: Library) -> Bool {
        let url = self.url
        let interpreter = library.interpreter
        
        Future {
            try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey])
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

extension DirectoryPlaylist {
    enum CodingKeys: String, CodingKey {
      case url
    }
}
